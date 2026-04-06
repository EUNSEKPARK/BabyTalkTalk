import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chat_baby_time/constants/growth_diary_assets.dart';
import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/models/baby_profile.dart';
import 'package:chat_baby_time/services/family_service.dart';
import 'package:chat_baby_time/services/notification_service.dart';

/// 육아 기록 데이터 관리 서비스
class RecordService extends ChangeNotifier {
  static const String _recordBoxName = 'baby_records';
  static const String _profileBoxName = 'baby_profile';
  static const String _growthBoxName = 'growth_measurements';
  static const String _milestoneBoxName = 'milestone_checks';
  static const String _diaryCoverBoxName = 'growth_diary_covers';
  static const String _prefActiveProfileId = 'active_profile_id';

  late Box<BabyRecord> _recordBox;
  late Box<BabyProfile> _profileBox;
  late Box _growthBox;
  late Box _milestoneBox;
  late Box<String> _diaryCoverBox;
  Directory? _appDocsDirectory;

  bool _initialized = false;
  List<BabyRecord> _allRecords = []; // 전체 기록 (모든 프로필)
  List<BabyRecord> _records = []; // 현재 활성 프로필의 기록
  BabyProfile? _profile;
  String? _activeProfileId;
  String? _lastError;

  /// 가족 공유 기록 (Firestore에서 받은 다른 가족 구성원의 기록)
  List<BabyRecord> _familyRecords = [];

  /// 가족 공유 기록 포함 전체 기록 (현재 활성 프로필 기준)
  List<BabyRecord> get allRecords {
    if (_familyRecords.isEmpty) return _records;
    final merged = <String, BabyRecord>{};
    for (final r in _records) {
      merged[r.id] = r;
    }
    for (final r in _familyRecords) {
      // 가족 기록도 현재 프로필 기준으로 필터 (profileId가 없으면 포함)
      if (r.profileId == null || r.profileId == _activeProfileId) {
        merged.putIfAbsent(r.id, () => r);
      }
    }
    final list = merged.values.toList();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  /// Firestore에서 동기화된 기록 반영
  void mergeFamilyRecords(List<Map<String, dynamic>> firestoreRecords) {
    _familyRecords = firestoreRecords.map((data) {
      return _recordFromFirestore(data);
    }).toList();
    notifyListeners();
  }

  static BabyRecord _recordFromFirestore(Map<String, dynamic> data) {
    final catIdx = data['category'] as int? ?? 0;
    final category = catIdx >= 0 && catIdx < RecordCategory.values.length
        ? RecordCategory.values[catIdx]
        : RecordCategory.other;

    FeedingType? feedingType;
    final ft = data['feedingType'] as int?;
    if (ft != null && ft >= 0 && ft < FeedingType.values.length) {
      feedingType = FeedingType.values[ft];
    }

    SleepStatus? sleepStatus;
    final ss = data['sleepStatus'] as int?;
    if (ss != null && ss >= 0 && ss < SleepStatus.values.length) {
      sleepStatus = SleepStatus.values[ss];
    }

    DiaperType? diaperType;
    final dt = data['diaperType'] as int?;
    if (dt != null && dt >= 0 && dt < DiaperType.values.length) {
      diaperType = DiaperType.values[dt];
    }

    return BabyRecord(
      id: data['id'] as String? ?? '',
      category: category,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        data['timestamp'] as int? ?? 0,
      ),
      rawInput: data['rawInput'] as String?,
      feedingType: feedingType,
      amountMl: (data['amountMl'] as num?)?.toInt(),
      durationMinutes: (data['durationMinutes'] as num?)?.toInt(),
      sleepStatus: sleepStatus,
      diaperType: diaperType,
      temperature: (data['temperature'] as num?)?.toDouble(),
      medicine: data['medicine'] as String?,
      memo: data['memo'] as String?,
      inputSource: data['inputSource'] as String?,
      authorId: data['authorId'] as String?,
      authorName: data['authorName'] as String?,
      profileId: data['profileId'] as String?,
      photoPath: data['photoPath'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        data['createdAt'] as int? ?? 0,
      ),
    );
  }

  bool get initialized => _initialized;
  List<BabyRecord> get records => _records;
  BabyProfile? get profile => _profile;
  String? get activeProfileId => _activeProfileId;
  String? get lastError => _lastError;

  bool get hasProfile => _profile != null;

  /// 등록된 모든 아기 프로필 목록
  List<BabyProfile> get allProfiles {
    try {
      return _profileBox.values.toList();
    } catch (e) {
      debugPrint('allProfiles error: $e');
      return _profile != null ? [_profile!] : [];
    }
  }

  /// 개별 Hive 박스를 안전하게 열기 (손상 시 삭제 후 재생성)
  Future<Box<T>> _openBoxSafe<T>(String name) async {
    try {
      return await Hive.openBox<T>(name);
    } catch (e) {
      debugPrint('Box "$name" 손상 감지, 복구 시도: $e');
      await Hive.deleteBoxFromDisk(name);
      return await Hive.openBox<T>(name);
    }
  }

  /// Hive 초기화
  Future<void> init() async {
    try {
      try {
        _appDocsDirectory = await getApplicationDocumentsDirectory();
      } catch (e) {
        debugPrint('getApplicationDocumentsDirectory: $e');
      }

      _recordBox = await _openBoxSafe<BabyRecord>(_recordBoxName);
      _profileBox = await _openBoxSafe<BabyProfile>(_profileBoxName);
      _growthBox = await _openBoxSafe(_growthBoxName);
      _milestoneBox = await _openBoxSafe(_milestoneBoxName);
      _diaryCoverBox = await _openBoxSafe<String>(_diaryCoverBoxName);

      // 전체 레코드 로드 (개별 항목 오류 시 건너뛰기)
      _allRecords = [];
      for (final key in _recordBox.keys) {
        try {
          final record = _recordBox.get(key);
          if (record != null) {
            _allRecords.add(record);
          }
        } catch (e) {
          debugPrint('레코드 로드 실패 (key=$key): $e');
        }
      }
      _allRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // 프로필 로드 및 마이그레이션
      if (_profileBox.isNotEmpty) {
        try {
          // 기존 단일 프로필 → 멀티 프로필 마이그레이션
          final firstProfile = _profileBox.getAt(0);
          if (firstProfile != null && firstProfile.profileId.isEmpty) {
            // profileId가 없는 기존 프로필에 ID 부여
            firstProfile.profileId = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
            await _profileBox.putAt(0, firstProfile);
          }

          // 활성 프로필 ID 로드
          final prefs = await SharedPreferences.getInstance();
          _activeProfileId = prefs.getString(_prefActiveProfileId);

          // 활성 프로필 ID가 없거나 유효하지 않으면 첫 번째 프로필로 설정
          final profiles = _profileBox.values.toList();
          if (_activeProfileId == null ||
              !profiles.any((p) => p.profileId == _activeProfileId)) {
            _activeProfileId = profiles.first.profileId;
            await prefs.setString(_prefActiveProfileId, _activeProfileId!);
          }

          _profile = profiles.firstWhere(
            (p) => p.profileId == _activeProfileId,
            orElse: () => profiles.first,
          );

          // 기존 기록 중 profileId가 없는 것들은 첫 번째 프로필에 할당
          final defaultId = profiles.first.profileId;
          for (final r in _allRecords) {
            if (r.profileId == null || r.profileId!.isEmpty) {
              r.profileId = defaultId;
              await _recordBox.put(r.id, r);
            }
          }
        } catch (e) {
          debugPrint('프로필 로드 실패: $e');
          await _profileBox.clear();
          _profile = null;
          _activeProfileId = null;
        }
      }

      // 활성 프로필 기준으로 기록 필터링
      _filterRecordsByActiveProfile();

      _initialized = true;
    } catch (e) {
      debugPrint('RecordService init error: $e');
      _lastError = '데이터 초기화 중 오류가 발생했습니다.';
      _initialized = true;
    }

    notifyListeners();
  }

  /// 활성 프로필 기준으로 기록 필터링
  void _filterRecordsByActiveProfile() {
    if (_activeProfileId == null) {
      _records = List.from(_allRecords);
    } else {
      _records = _allRecords
          .where((r) =>
              r.profileId == null ||
              r.profileId!.isEmpty ||
              r.profileId == _activeProfileId)
          .toList();
    }
    _records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  // ===== 프로필 관리 =====

  /// 현재 활성 프로필 저장 (기존 호환)
  Future<void> saveProfile(BabyProfile profile) async {
    try {
      if (_activeProfileId != null) {
        // 기존 프로필 수정
        profile.profileId = _activeProfileId!;
        final idx = _profileBox.values
            .toList()
            .indexWhere((p) => p.profileId == _activeProfileId);
        if (idx >= 0) {
          await _profileBox.putAt(idx, profile);
        } else {
          await _profileBox.add(profile);
        }
      } else if (_profileBox.isEmpty) {
        await _profileBox.add(profile);
        _activeProfileId = profile.profileId;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefActiveProfileId, _activeProfileId!);
      } else {
        await _profileBox.putAt(0, profile);
      }
      _profile = profile;
      _lastError = null;
    } catch (e) {
      debugPrint('saveProfile error: $e');
      _lastError = '프로필 저장 중 오류가 발생했습니다.';
    }
    notifyListeners();
  }

  /// 새 아기 프로필 추가
  Future<void> addNewProfile(BabyProfile profile) async {
    try {
      await _profileBox.add(profile);
      // 새로 추가한 프로필을 활성으로 전환
      await switchProfile(profile.profileId);
      _lastError = null;
    } catch (e) {
      debugPrint('addNewProfile error: $e');
      _lastError = '프로필 추가에 실패했습니다.';
      notifyListeners();
    }
  }

  /// 활성 프로필 전환
  Future<void> switchProfile(String profileId) async {
    try {
      final profiles = _profileBox.values.toList();
      final target = profiles.firstWhere(
        (p) => p.profileId == profileId,
      );
      _activeProfileId = profileId;
      _profile = target;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefActiveProfileId, profileId);

      _filterRecordsByActiveProfile();
      _lastError = null;
      notifyListeners();
    } catch (e) {
      debugPrint('switchProfile error: $e');
      _lastError = '프로필 전환에 실패했습니다.';
      notifyListeners();
    }
  }

  /// 특정 프로필 수정
  Future<void> updateProfile(BabyProfile updated) async {
    try {
      final profiles = _profileBox.values.toList();
      final idx = profiles.indexWhere((p) => p.profileId == updated.profileId);
      if (idx >= 0) {
        await _profileBox.putAt(idx, updated);
        if (updated.profileId == _activeProfileId) {
          _profile = updated;
        }
        _lastError = null;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('updateProfile error: $e');
      _lastError = '프로필 수정에 실패했습니다.';
      notifyListeners();
    }
  }

  /// 프로필 삭제 (해당 프로필의 기록도 모두 삭제)
  Future<String?> deleteProfile(String profileId) async {
    try {
      final profiles = _profileBox.values.toList();
      if (profiles.length <= 1) {
        return '마지막 프로필은 삭제할 수 없습니다.';
      }

      // 해당 프로필의 기록 삭제
      final recordsToDelete =
          _allRecords.where((r) => r.profileId == profileId).toList();
      for (final r in recordsToDelete) {
        await _recordBox.delete(r.id);
      }
      _allRecords.removeWhere((r) => r.profileId == profileId);

      // 프로필 삭제
      final idx = profiles.indexWhere((p) => p.profileId == profileId);
      if (idx >= 0) {
        await _profileBox.deleteAt(idx);
      }

      // 활성 프로필이 삭제된 경우 첫 번째로 전환
      if (_activeProfileId == profileId) {
        final remaining = _profileBox.values.toList();
        if (remaining.isNotEmpty) {
          await switchProfile(remaining.first.profileId);
        }
      } else {
        _filterRecordsByActiveProfile();
        notifyListeners();
      }

      return null;
    } catch (e) {
      debugPrint('deleteProfile error: $e');
      return '프로필 삭제에 실패했습니다.';
    }
  }

  /// 현재 프로필의 기록 수
  int recordCountForProfile(String profileId) {
    return _allRecords.where((r) => r.profileId == profileId).length;
  }

  /// 가족 서비스 연결 (Firestore 동기화용)
  FamilyService? _familyService;
  void attachFamilyService(FamilyService fs) {
    _familyService = fs;
  }

  /// 알림 서비스 연결 (루틴 엔진 연동)
  NotificationService? _notificationService;
  void attachNotificationService(NotificationService ns) {
    _notificationService = ns;
  }

  // ===== 기록 CRUD =====

  Future<bool> addRecord(BabyRecord record) async {
    try {
      // 활성 프로필 ID 자동 할당
      record.profileId ??= _activeProfileId;
      await _recordBox.put(record.id, record);
      _allRecords.insert(0, record);
      _allRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _filterRecordsByActiveProfile();
      _lastError = null;
      notifyListeners();

      // 루틴 엔진에 기록 추가 알림 → 다음 알림 재스케줄
      _notificationService?.onRecordAdded(record.category);

      // 가족 공유 중이면 Firestore에도 업로드
      _familyService?.uploadRecord(record);

      return true;
    } catch (e) {
      debugPrint('addRecord error: $e');
      _lastError = '기록 저장 중 오류가 발생했습니다.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateRecord(BabyRecord record) async {
    try {
      await _recordBox.put(record.id, record);
      final allIdx = _allRecords.indexWhere((r) => r.id == record.id);
      if (allIdx >= 0) {
        _allRecords[allIdx] = record;
        _allRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
      final idx = _records.indexWhere((r) => r.id == record.id);
      if (idx >= 0) {
        _records[idx] = record;
        _records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
      _lastError = null;
      notifyListeners();

      // 가족 공유 중이면 Firestore에도 업데이트
      _familyService?.uploadRecord(record);

      return true;
    } catch (e) {
      debugPrint('updateRecord error: $e');
      _lastError = '기록 수정 중 오류가 발생했습니다.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRecord(String id) async {
    try {
      await _recordBox.delete(id);
      _allRecords.removeWhere((r) => r.id == id);
      _records.removeWhere((r) => r.id == id);
      _lastError = null;
      notifyListeners();

      // 가족 공유 중이면 Firestore에서도 삭제
      _familyService?.deleteRemoteRecord(id);

      return true;
    } catch (e) {
      debugPrint('deleteRecord error: $e');
      _lastError = '기록 삭제 중 오류가 발생했습니다.';
      notifyListeners();
      return false;
    }
  }

  // ===== 성장 기록 (키/몸무게) =====

  Future<bool> addGrowthMeasurement({
    required double heightCm,
    required double weightKg,
    double? headCircCm,
    DateTime? date,
  }) async {
    try {
      final measureDate = date ?? DateTime.now();
      final key = '${measureDate.year}-${measureDate.month.toString().padLeft(2, '0')}-${measureDate.day.toString().padLeft(2, '0')}';
      final data = <String, dynamic>{
        'heightCm': heightCm,
        'weightKg': weightKg,
        'date': measureDate.millisecondsSinceEpoch,
      };
      if (headCircCm != null) data['headCircCm'] = headCircCm;
      await _growthBox.put(key, data);
      _lastError = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('addGrowthMeasurement error: $e');
      _lastError = '성장 기록 저장 중 오류가 발생했습니다.';
      notifyListeners();
      return false;
    }
  }

  List<Map<String, dynamic>> get growthMeasurements {
    try {
      final results = <Map<String, dynamic>>[];
      for (final key in _growthBox.keys) {
        final data = _growthBox.get(key);
        if (data is Map) {
          results.add({
            'key': key,
            'heightCm': (data['heightCm'] as num?)?.toDouble() ?? 0,
            'weightKg': (data['weightKg'] as num?)?.toDouble() ?? 0,
            'headCircCm': (data['headCircCm'] as num?)?.toDouble(),
            'date': DateTime.fromMillisecondsSinceEpoch(data['date'] as int),
          });
        }
      }
      results.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
      return results;
    } catch (e) {
      debugPrint('growthMeasurements error: $e');
      return [];
    }
  }

  // ===== 마일스톤 체크 =====

  Future<void> setMilestoneChecked(String key, bool checked) async {
    try {
      await _milestoneBox.put(key, checked);
      notifyListeners();
    } catch (e) {
      debugPrint('setMilestoneChecked error: $e');
    }
  }

  bool isMilestoneChecked(String key) {
    try {
      return _milestoneBox.get(key, defaultValue: false) as bool;
    } catch (e) {
      return false;
    }
  }

  Map<String, bool> get allMilestoneChecks {
    try {
      final result = <String, bool>{};
      for (final key in _milestoneBox.keys) {
        result[key as String] = _milestoneBox.get(key, defaultValue: false) as bool;
      }
      return result;
    } catch (e) {
      return {};
    }
  }

  // ===== 쿼리 =====

  /// 특정 날짜의 기록들
  List<BabyRecord> getRecordsForDate(DateTime date) {
    return _records.where((r) {
      return r.timestamp.year == date.year &&
          r.timestamp.month == date.month &&
          r.timestamp.day == date.day;
    }).toList();
  }

  // ===== 성장 일기 표지 (날짜별 앱 에셋 / 업로드 사진) =====

  static String diaryDateKey(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  /// 썸네일: 업로드 파일 → 지정 앱 에셋 → 날짜 기본 에셋
  ({String? asset, String? filePath}) diaryCoverForDate(DateTime date) {
    if (kGrowthDiaryCoverAssets.isEmpty) {
      return (asset: null, filePath: null);
    }
    final key = diaryDateKey(date);
    final raw = _diaryCoverBox.get(key);
    final root = _appDocsDirectory?.path;

    if (raw != null && raw.startsWith('f:') && root != null) {
      final name = raw.substring(2);
      final path = '$root/diary_covers/$name';
      if (File(path).existsSync()) {
        return (asset: null, filePath: path);
      }
    }
    if (raw != null && raw.startsWith('a:')) {
      final i = int.tryParse(raw.substring(2)) ?? 0;
      final safe = i % kGrowthDiaryCoverAssets.length;
      return (asset: kGrowthDiaryCoverAssets[safe], filePath: null);
    }
    final def = defaultDiaryCoverAssetIndex(date);
    return (asset: kGrowthDiaryCoverAssets[def], filePath: null);
  }

  Future<void> _deleteDiaryCoverFileIfAny(String dateKey) async {
    final raw = _diaryCoverBox.get(dateKey);
    if (raw == null || !raw.startsWith('f:')) return;
    final root = _appDocsDirectory?.path;
    if (root == null) return;
    final f = File('$root/diary_covers/${raw.substring(2)}');
    try {
      if (await f.exists()) await f.delete();
    } catch (e) {
      debugPrint('delete diary cover file: $e');
    }
  }

  Future<void> setDiaryCoverAsset(DateTime date, int assetIndex) async {
    try {
      final key = diaryDateKey(date);
      await _deleteDiaryCoverFileIfAny(key);
      if (kGrowthDiaryCoverAssets.isEmpty) return;
      final i = assetIndex % kGrowthDiaryCoverAssets.length;
      await _diaryCoverBox.put(key, 'a:$i');
      _lastError = null;
      notifyListeners();
    } catch (e) {
      debugPrint('setDiaryCoverAsset: $e');
      _lastError = '표지 저장에 실패했습니다.';
      notifyListeners();
    }
  }

  Future<void> clearDiaryCoverToDefault(DateTime date) async {
    try {
      final key = diaryDateKey(date);
      await _deleteDiaryCoverFileIfAny(key);
      await _diaryCoverBox.delete(key);
      _lastError = null;
      notifyListeners();
    } catch (e) {
      debugPrint('clearDiaryCoverToDefault: $e');
      notifyListeners();
    }
  }

  Future<bool> setDiaryCoverFromPickedFile(DateTime date, String sourcePath) async {
    final root = _appDocsDirectory?.path;
    if (root == null) {
      _lastError = '저장 경로를 사용할 수 없습니다.';
      notifyListeners();
      return false;
    }
    try {
      final key = diaryDateKey(date);
      await _deleteDiaryCoverFileIfAny(key);
      final dir = Directory('$root/diary_covers');
      await dir.create(recursive: true);
      final ext = _imageExtensionFromPath(sourcePath);
      final fileName = '$key$ext';
      final destPath = '${dir.path}/$fileName';
      await File(sourcePath).copy(destPath);
      await _diaryCoverBox.put(key, 'f:$fileName');
      _lastError = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('setDiaryCoverFromPickedFile: $e');
      _lastError = '사진 저장에 실패했습니다.';
      notifyListeners();
      return false;
    }
  }

  static String _imageExtensionFromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return '.png';
    if (lower.endsWith('.gif')) return '.gif';
    if (lower.endsWith('.webp')) return '.webp';
    if (lower.endsWith('.heic')) return '.heic';
    return '.jpg';
  }

  /// 오늘 기록
  List<BabyRecord> get todayRecords => getRecordsForDate(DateTime.now());

  /// 카테고리별 오늘 기록 수
  Map<RecordCategory, int> get todayCategoryCounts {
    final today = todayRecords;
    final map = <RecordCategory, int>{};
    for (final cat in RecordCategory.values) {
      map[cat] = today.where((r) => r.category == cat).length;
    }
    return map;
  }

  /// 오늘 총 수유량 (ml)
  int get todayTotalFeedingMl {
    return todayRecords
        .where((r) => r.category == RecordCategory.feeding && r.amountMl != null)
        .fold(0, (sum, r) => sum + r.amountMl!);
  }

  /// 오늘 기저귀 교체 횟수
  int get todayDiaperCount {
    return todayRecords.where((r) => r.category == RecordCategory.diaper).length;
  }

  /// 오늘 수면 기록 (시작/종료 쌍)
  int get todaySleepCount {
    return todayRecords.where((r) => r.category == RecordCategory.sleep).length;
  }

  /// 마지막 수유 기록
  BabyRecord? get lastFeedingRecord {
    try {
      return _records.firstWhere((r) => r.category == RecordCategory.feeding);
    } catch (_) {
      return null;
    }
  }

  /// 마지막 수면 기록
  BabyRecord? get lastSleepRecord {
    try {
      return _records.firstWhere((r) => r.category == RecordCategory.sleep);
    } catch (_) {
      return null;
    }
  }

  /// 마지막 기저귀 기록
  BabyRecord? get lastDiaperRecord {
    try {
      return _records.firstWhere((r) => r.category == RecordCategory.diaper);
    } catch (_) {
      return null;
    }
  }

  /// 최근 N일간 카테고리별 기록 수 (차트용)
  Map<String, Map<RecordCategory, int>> getWeeklyStats({int days = 7}) {
    final result = <String, Map<RecordCategory, int>>{};
    final now = DateTime.now();

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = '${date.month}/${date.day}';
      final dayRecords = getRecordsForDate(date);

      result[key] = {};
      for (final cat in RecordCategory.values) {
        result[key]![cat] = dayRecords.where((r) => r.category == cat).length;
      }
    }

    return result;
  }

  // ===== 백업 / 복원 (로컬 JSON, 버전 1) =====

  Map<String, dynamic> exportBackupMap() {
    final profileJson = _profile == null
        ? null
        : {
            'name': _profile!.name,
            'birthDate': _profile!.birthDate.toIso8601String(),
            'gender': _profile!.gender,
            'birthWeight': _profile!.birthWeight,
            'birthHeight': _profile!.birthHeight,
            'growthStageIndex': _profile!.growthStageIndex,
            'profileId': _profile!.profileId,
          };

    final recordsJson = _records.map(_recordToJson).toList();

    final growth = <String, dynamic>{};
    for (final key in _growthBox.keys) {
      final data = _growthBox.get(key);
      if (data is Map) {
        growth[key.toString()] = {
          'heightCm': data['heightCm'],
          'weightKg': data['weightKg'],
          'date': data['date'],
        };
      }
    }

    final milestones = <String, dynamic>{};
    for (final key in _milestoneBox.keys) {
      milestones[key.toString()] = _milestoneBox.get(key);
    }

    final diaryCovers = <String, dynamic>{};
    for (final key in _diaryCoverBox.keys) {
      final v = _diaryCoverBox.get(key);
      if (v != null) diaryCovers[key.toString()] = v;
    }

    return {
      'version': 1,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'profile': profileJson,
      'records': recordsJson,
      'growth': growth,
      'milestones': milestones,
      'diaryCovers': diaryCovers,
    };
  }

  String? exportBackupJsonString() {
    try {
      return const JsonEncoder.withIndent('  ').convert(exportBackupMap());
    } catch (e, st) {
      debugPrint('exportBackupJsonString $e $st');
      return null;
    }
  }

  /// 성공 시 null, 실패 시 사용자에게 보여줄 메시지
  Future<String?> importBackupFromJsonString(String jsonStr) async {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is! Map) {
        return '잘못된 백업 파일입니다.';
      }
      final map = Map<String, dynamic>.from(decoded);
      if (map['version'] != 1) {
        return '지원하지 않는 백업 버전입니다.';
      }

      final list = map['records'];
      if (list is! List) {
        return '기록 데이터가 없습니다.';
      }

      final parsedRecords = <BabyRecord>[];
      for (final item in list) {
        if (item is! Map) {
          return '기록 항목 형식이 올바르지 않습니다.';
        }
        parsedRecords.add(_recordFromJson(Map<String, dynamic>.from(item)));
      }

      BabyProfile? parsedProfile;
      final p = map['profile'];
      if (p != null) {
        if (p is! Map) {
          return '프로필 데이터가 올바르지 않습니다.';
        }
        parsedProfile = _profileFromJson(Map<String, dynamic>.from(p));
      }

      await _recordBox.clear();
      await _profileBox.clear();
      await _growthBox.clear();
      await _milestoneBox.clear();

      for (final r in parsedRecords) {
        await _recordBox.put(r.id, r);
      }
      if (parsedProfile != null) {
        await _profileBox.add(parsedProfile);
      }

      final g = map['growth'];
      if (g is Map) {
        for (final e in g.entries) {
          final v = e.value;
          if (v is Map) {
            final inner = Map<String, dynamic>.from(
              v.map((k, val) => MapEntry(k.toString(), val)),
            );
            await _growthBox.put(e.key.toString(), inner);
          }
        }
      }

      final m = map['milestones'];
      if (m is Map) {
        for (final e in m.entries) {
          await _milestoneBox.put(e.key.toString(), e.value == true);
        }
      }

      final dc = map['diaryCovers'];
      if (dc is Map) {
        await _diaryCoverBox.clear();
        for (final e in dc.entries) {
          final v = e.value;
          if (v is String && (v.startsWith('a:') || v.startsWith('f:'))) {
            await _diaryCoverBox.put(e.key.toString(), v);
          }
        }
      }

      // 복원 후 안전한 레코드 로드
      _allRecords = [];
      for (final key in _recordBox.keys) {
        try {
          final record = _recordBox.get(key);
          if (record != null) {
            _allRecords.add(record);
          }
        } catch (e) {
          debugPrint('복원 후 레코드 로드 실패 (key=$key): $e');
        }
      }
      _allRecords.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (_profileBox.isNotEmpty) {
        try {
          _profile = _profileBox.getAt(0);
          _activeProfileId = _profile?.profileId;
          // 복원된 기록에 profileId 할당
          if (_activeProfileId != null) {
            for (final r in _allRecords) {
              if (r.profileId == null || r.profileId!.isEmpty) {
                r.profileId = _activeProfileId;
                await _recordBox.put(r.id, r);
              }
            }
          }
        } catch (e) {
          debugPrint('복원 후 프로필 로드 실패: $e');
          _profile = null;
          _activeProfileId = null;
        }
      } else {
        _profile = null;
        _activeProfileId = null;
      }
      _filterRecordsByActiveProfile();
      _lastError = null;
      notifyListeners();
      return null;
    } catch (e, st) {
      debugPrint('importBackupFromJsonString $e $st');
      return '복원에 실패했습니다. 파일을 확인해 주세요.';
    }
  }

  static Map<String, dynamic> _recordToJson(BabyRecord r) {
    return {
      'id': r.id,
      'category': r.category.index,
      'timestamp': r.timestamp.toIso8601String(),
      'rawInput': r.rawInput,
      'feedingType': r.feedingType?.index,
      'amountMl': r.amountMl,
      'durationMinutes': r.durationMinutes,
      'sleepStatus': r.sleepStatus?.index,
      'diaperType': r.diaperType?.index,
      'temperature': r.temperature,
      'medicine': r.medicine,
      'memo': r.memo,
      'createdAt': r.createdAt.toIso8601String(),
      'profileId': r.profileId,
      'photoPath': r.photoPath,
    };
  }

  static BabyRecord _recordFromJson(Map<String, dynamic> j) {
    final catIdx = j['category'] as int? ?? 0;
    final category = catIdx >= 0 && catIdx < RecordCategory.values.length
        ? RecordCategory.values[catIdx]
        : RecordCategory.other;

    FeedingType? feedingType;
    final ft = j['feedingType'] as int?;
    if (ft != null && ft >= 0 && ft < FeedingType.values.length) {
      feedingType = FeedingType.values[ft];
    }

    SleepStatus? sleepStatus;
    final ss = j['sleepStatus'] as int?;
    if (ss != null && ss >= 0 && ss < SleepStatus.values.length) {
      sleepStatus = SleepStatus.values[ss];
    }

    DiaperType? diaperType;
    final dt = j['diaperType'] as int?;
    if (dt != null && dt >= 0 && dt < DiaperType.values.length) {
      diaperType = DiaperType.values[dt];
    }

    return BabyRecord(
      id: j['id'] as String,
      category: category,
      timestamp: DateTime.parse(j['timestamp'] as String),
      rawInput: j['rawInput'] as String?,
      feedingType: feedingType,
      amountMl: (j['amountMl'] as num?)?.toInt(),
      durationMinutes: (j['durationMinutes'] as num?)?.toInt(),
      sleepStatus: sleepStatus,
      diaperType: diaperType,
      temperature: (j['temperature'] as num?)?.toDouble(),
      medicine: j['medicine'] as String?,
      memo: j['memo'] as String?,
      profileId: j['profileId'] as String?,
      photoPath: j['photoPath'] as String?,
      createdAt: DateTime.parse(j['createdAt'] as String),
    );
  }

  static BabyProfile _profileFromJson(Map<String, dynamic> p) {
    return BabyProfile(
      name: (p['name'] as String?) ?? '우리 아기',
      birthDate: p['birthDate'] != null
          ? DateTime.parse(p['birthDate'] as String)
          : DateTime.now(),
      gender: p['gender'] as String?,
      birthWeight: (p['birthWeight'] as num?)?.toDouble(),
      birthHeight: (p['birthHeight'] as num?)?.toDouble(),
      growthStageIndex: (p['growthStageIndex'] as int?) ?? 0,
      profileId: p['profileId'] as String?,
    );
  }
}
