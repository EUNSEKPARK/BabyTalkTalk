import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:chat_baby_time/constants/growth_diary_assets.dart';
import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/models/baby_profile.dart';

/// 육아 기록 데이터 관리 서비스
class RecordService extends ChangeNotifier {
  static const String _recordBoxName = 'baby_records';
  static const String _profileBoxName = 'baby_profile';
  static const String _growthBoxName = 'growth_measurements';
  static const String _milestoneBoxName = 'milestone_checks';
  static const String _diaryCoverBoxName = 'growth_diary_covers';

  late Box<BabyRecord> _recordBox;
  late Box<BabyProfile> _profileBox;
  late Box _growthBox;
  late Box _milestoneBox;
  late Box<String> _diaryCoverBox;
  Directory? _appDocsDirectory;

  bool _initialized = false;
  List<BabyRecord> _records = [];
  BabyProfile? _profile;
  String? _lastError;

  bool get initialized => _initialized;
  List<BabyRecord> get records => _records;
  BabyProfile? get profile => _profile;
  String? get lastError => _lastError;

  bool get hasProfile => _profile != null;

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

      // 레코드 로드 (개별 항목 오류 시 건너뛰기)
      _records = [];
      for (final key in _recordBox.keys) {
        try {
          final record = _recordBox.get(key);
          if (record != null) {
            _records.add(record);
          }
        } catch (e) {
          debugPrint('레코드 로드 실패 (key=$key): $e');
        }
      }
      _records.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      // 프로필 로드
      if (_profileBox.isNotEmpty) {
        try {
          _profile = _profileBox.getAt(0);
        } catch (e) {
          debugPrint('프로필 로드 실패: $e');
          // 손상된 프로필 제거
          await _profileBox.clear();
          _profile = null;
        }
      }

      _initialized = true;
    } catch (e) {
      debugPrint('RecordService init error: $e');
      _lastError = '데이터 초기화 중 오류가 발생했습니다.';
      _initialized = true; // 에러 시에도 초기화 완료로 표시하여 앱 진행
    }

    notifyListeners();
  }

  void clearError() {
    _lastError = null;
    notifyListeners();
  }

  // ===== 프로필 관리 =====

  Future<void> saveProfile(BabyProfile profile) async {
    try {
      if (_profileBox.isEmpty) {
        await _profileBox.add(profile);
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

  // ===== 기록 CRUD =====

  Future<bool> addRecord(BabyRecord record) async {
    try {
      await _recordBox.put(record.id, record);
      _records.insert(0, record);
      _records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _lastError = null;
      notifyListeners();
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
      final idx = _records.indexWhere((r) => r.id == record.id);
      if (idx >= 0) {
        _records[idx] = record;
        _records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
      _lastError = null;
      notifyListeners();
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
      _records.removeWhere((r) => r.id == id);
      _lastError = null;
      notifyListeners();
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
    DateTime? date,
  }) async {
    try {
      final measureDate = date ?? DateTime.now();
      final key = '${measureDate.year}-${measureDate.month.toString().padLeft(2, '0')}-${measureDate.day.toString().padLeft(2, '0')}';
      await _growthBox.put(key, {
        'heightCm': heightCm,
        'weightKg': weightKg,
        'date': measureDate.millisecondsSinceEpoch,
      });
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
      _records = [];
      for (final key in _recordBox.keys) {
        try {
          final record = _recordBox.get(key);
          if (record != null) {
            _records.add(record);
          }
        } catch (e) {
          debugPrint('복원 후 레코드 로드 실패 (key=$key): $e');
        }
      }
      _records.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      if (_profileBox.isNotEmpty) {
        try {
          _profile = _profileBox.getAt(0);
        } catch (e) {
          debugPrint('복원 후 프로필 로드 실패: $e');
          _profile = null;
        }
      } else {
        _profile = null;
      }
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
    );
  }
}
