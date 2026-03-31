import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'package:chat_baby_time/models/nlp_log.dart';

/// NLP 분석 데이터 수집 서비스
///
/// 사용자 입력 → NLP 결과 → 수정 내역을 수집하여
/// 1) 로컬 JSON 파일에 저장 (오프라인 백업)
/// 2) Firebase Firestore에 업로드 (클라우드 분석)
///
/// 개인정보 동의 여부에 따라 수집 on/off 제어.
class NlpAnalyticsService extends ChangeNotifier {
  static const _uuid = Uuid();
  static const _prefKeyConsent = 'nlp_analytics_consent';
  static const _prefKeyDeviceId = 'nlp_analytics_device_id';
  static const _prefKeyConsentShown = 'nlp_analytics_consent_shown';
  static const _appVersion = '1.0.0';

  bool _isConsentGiven = false;
  bool _isConsentShown = false;
  String _deviceId = '';
  final List<NlpLog> _pendingLogs = []; // 아직 업로드 안 된 로그
  final List<NlpLog> _recentLogs = []; // 최근 로그 (메모리 캐시, 대시보드용)

  // ── Getters ──
  bool get isConsentGiven => _isConsentGiven;
  bool get isConsentShown => _isConsentShown;
  String get deviceId => _deviceId;
  List<NlpLog> get recentLogs => List.unmodifiable(_recentLogs);
  int get pendingCount => _pendingLogs.length;

  // ── 초기화 ──
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isConsentGiven = prefs.getBool(_prefKeyConsent) ?? false;
    _isConsentShown = prefs.getBool(_prefKeyConsentShown) ?? false;

    // 익명 디바이스 ID 생성 (최초 1회)
    _deviceId = prefs.getString(_prefKeyDeviceId) ?? '';
    if (_deviceId.isEmpty) {
      _deviceId = _uuid.v4();
      await prefs.setString(_prefKeyDeviceId, _deviceId);
    }

    // 로컬에 저장된 미전송 로그 로드
    await _loadPendingLogs();

    debugPrint('[NlpAnalytics] init: consent=$_isConsentGiven, device=$_deviceId, pending=${_pendingLogs.length}');
  }

  // ── 동의 관리 ──
  Future<void> setConsent(bool value) async {
    _isConsentGiven = value;
    _isConsentShown = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyConsent, value);
    await prefs.setBool(_prefKeyConsentShown, true);
    notifyListeners();

    if (value) {
      // 동의 켜면 대기 중 로그 업로드 시도
      _uploadPendingLogs();
    }
  }

  Future<void> markConsentShown() async {
    _isConsentShown = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyConsentShown, true);
  }

  // ── 로그 기록 ──

  /// NLP 파싱 직후 호출 — 파싱 결과 기록
  NlpLog? logParse({
    required String rawInput,
    required String inputSource,
    required String detectedCategory,
    required double confidence,
    required Map<String, double> scores,
    String? detectedSubType,
    String? parsedTimeSource,
    required String appAction,
    required int responseTimeMs,
  }) {
    if (!_isConsentGiven) return null;

    final now = DateTime.now();
    final log = NlpLog(
      id: _uuid.v4(),
      timestamp: now,
      rawInput: rawInput,
      inputSource: inputSource,
      detectedCategory: detectedCategory,
      confidence: confidence,
      scores: scores,
      detectedSubType: detectedSubType,
      parsedTimeSource: parsedTimeSource,
      appAction: appAction,
      hourOfDay: now.hour,
      dayOfWeek: now.weekday,
      inputLength: rawInput.length,
      responseTimeMs: responseTimeMs,
      appVersion: _appVersion,
      deviceId: _deviceId,
    );

    _addLog(log);
    return log;
  }

  /// 사용자가 확인 카드에서 "저장" 눌렀을 때
  void logConfirm(String logId) {
    if (!_isConsentGiven) return;
    _updateLog(logId, (log) => log.copyWithCorrection(wasConfirmed: true));
  }

  /// 사용자가 확인 카드에서 "취소" 눌렀을 때
  void logCancel(String logId) {
    if (!_isConsentGiven) return;
    _updateLog(logId, (log) => log.copyWithCorrection(wasCancelled: true));
  }

  /// 사용자가 카테고리를 수정했을 때
  void logCorrection(String logId, String correctedCategory) {
    if (!_isConsentGiven) return;
    _updateLog(logId, (log) => log.copyWithCorrection(
      correctedCategory: correctedCategory,
    ));
  }

  // ── 내부 로직 ──

  void _addLog(NlpLog log) {
    _recentLogs.add(log);
    _pendingLogs.add(log);

    // 메모리 캐시 100개 제한
    if (_recentLogs.length > 100) {
      _recentLogs.removeRange(0, _recentLogs.length - 100);
    }

    // 로컬 저장 (비동기)
    _savePendingLogs();

    // Firebase 업로드 시도
    _uploadLog(log);

    notifyListeners();
  }

  void _updateLog(String logId, NlpLog Function(NlpLog) updater) {
    // recentLogs에서 찾아 업데이트
    final idx = _recentLogs.indexWhere((l) => l.id == logId);
    if (idx != -1) {
      _recentLogs[idx] = updater(_recentLogs[idx]);
    }
    // pending에서도 업데이트
    final pidx = _pendingLogs.indexWhere((l) => l.id == logId);
    if (pidx != -1) {
      _pendingLogs[pidx] = updater(_pendingLogs[pidx]);
    }

    _savePendingLogs();

    // Firebase에 업데이트 전송
    if (idx != -1) {
      _uploadLog(_recentLogs[idx]);
    }

    notifyListeners();
  }

  // ── Firebase 업로드 ──

  bool _permissionDenied = false; // 권한 거부 시 불필요한 재시도 방지

  Future<void> _uploadLog(NlpLog log) async {
    if (_permissionDenied) return; // 권한 거부 상태면 업로드 시도 안 함

    try {
      await FirebaseFirestore.instance
          .collection('nlp_logs')
          .doc(log.id)
          .set(log.toJson(), SetOptions(merge: true));

      _pendingLogs.removeWhere((l) => l.id == log.id);
      _savePendingLogs();

      debugPrint('[NlpAnalytics] uploaded: ${log.rawInput} → ${log.detectedCategory} (${log.confidence})');
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        _permissionDenied = true;
        debugPrint('[NlpAnalytics] 권한 거부 — Firestore 보안 규칙을 확인하세요. 재시도를 중단합니다.');
      } else {
        debugPrint('[NlpAnalytics] Firebase 오류 (${e.code}): ${e.message}');
      }
    } catch (e) {
      debugPrint('[NlpAnalytics] upload failed: $e');
      // 네트워크 오류 등은 pending에 남겨두고 나중에 재시도
    }
  }

  Future<void> _uploadPendingLogs() async {
    if (_pendingLogs.isEmpty || _permissionDenied) return;
    debugPrint('[NlpAnalytics] uploading ${_pendingLogs.length} pending logs...');

    final toUpload = List<NlpLog>.from(_pendingLogs);
    for (final log in toUpload) {
      if (_permissionDenied) break; // 중간에 권한 거부되면 즉시 중단
      await _uploadLog(log);
    }
  }

  /// 권한 거부 상태 초기화 (보안 규칙 수정 후 재시도할 때 호출)
  void resetPermissionState() {
    _permissionDenied = false;
    _uploadPendingLogs();
  }

  // ── 로컬 파일 저장/로드 ──

  Future<File> get _localFile async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/nlp_analytics_pending.json');
  }

  Future<void> _savePendingLogs() async {
    try {
      final file = await _localFile;
      final jsonList = _pendingLogs.map((l) => l.toJson()).toList();
      await file.writeAsString(jsonEncode(jsonList));
    } catch (e) {
      debugPrint('[NlpAnalytics] save failed: $e');
    }
  }

  Future<void> _loadPendingLogs() async {
    try {
      final file = await _localFile;
      if (await file.exists()) {
        final content = await file.readAsString();
        final jsonList = jsonDecode(content) as List;
        _pendingLogs.clear();
        _recentLogs.clear();
        for (final json in jsonList) {
          final log = NlpLog.fromJson(json as Map<String, dynamic>);
          _pendingLogs.add(log);
          _recentLogs.add(log);
        }
        // 최근 100개만 메모리에 유지
        if (_recentLogs.length > 100) {
          _recentLogs.removeRange(0, _recentLogs.length - 100);
        }
      }
    } catch (e) {
      debugPrint('[NlpAnalytics] load failed: $e');
    }
  }

  // ── 통계 (대시보드용) ──

  /// 전체 로그 수
  int get totalLogs => _recentLogs.length;

  /// 자동저장 비율
  double get autoSaveRate {
    if (_recentLogs.isEmpty) return 0;
    final auto = _recentLogs.where((l) => l.appAction == 'autoSaved').length;
    return auto / _recentLogs.length;
  }

  /// 사용자 수정 비율 (핵심 지표 — 낮을수록 NLP 정확도 높음)
  double get correctionRate {
    if (_recentLogs.isEmpty) return 0;
    final corrected = _recentLogs.where((l) => l.wasEdited).length;
    return corrected / _recentLogs.length;
  }

  /// 확인 카드 수락 비율
  double get confirmRate {
    final confirmCards = _recentLogs.where((l) => l.appAction == 'confirmCard').toList();
    if (confirmCards.isEmpty) return 0;
    final confirmed = confirmCards.where((l) => l.wasConfirmed).length;
    return confirmed / confirmCards.length;
  }

  /// 카테고리별 정확도
  Map<String, double> get categoryAccuracy {
    final result = <String, double>{};
    final categories = ['feeding', 'sleep', 'diaper', 'health'];

    for (final cat in categories) {
      final catLogs = _recentLogs.where((l) => l.detectedCategory == cat).toList();
      if (catLogs.isEmpty) {
        result[cat] = 0;
        continue;
      }
      final correct = catLogs.where((l) => !l.wasEdited).length;
      result[cat] = correct / catLogs.length;
    }
    return result;
  }

  /// 평균 신뢰도
  double get avgConfidence {
    if (_recentLogs.isEmpty) return 0;
    final sum = _recentLogs.fold<double>(0, (s, l) => s + l.confidence);
    return sum / _recentLogs.length;
  }

  /// 오인식이 많은 입력 패턴 (개선 우선순위)
  List<NlpLog> get correctedLogs =>
      _recentLogs.where((l) => l.wasEdited).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  /// 취소된 로그 (인식 실패 패턴)
  List<NlpLog> get cancelledLogs =>
      _recentLogs.where((l) => l.wasCancelled).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

  /// 시간대별 사용 빈도
  Map<int, int> get hourlyUsage {
    final result = <int, int>{};
    for (final log in _recentLogs) {
      result[log.hourOfDay] = (result[log.hourOfDay] ?? 0) + 1;
    }
    return result;
  }

  /// 자주 쓰는 표현 Top N
  List<MapEntry<String, int>> topExpressions({int limit = 20}) {
    final freq = <String, int>{};
    for (final log in _recentLogs) {
      final normalized = log.rawInput.trim().toLowerCase();
      freq[normalized] = (freq[normalized] ?? 0) + 1;
    }
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(limit).toList();
  }

  // ── 데이터 내보내기 ──

  /// JSON으로 전체 로그 내보내기
  Future<String> exportToJson() async {
    final jsonList = _recentLogs.map((l) => l.toJson()).toList();
    return const JsonEncoder.withIndent('  ').convert({
      'exportDate': DateTime.now().toIso8601String(),
      'totalLogs': _recentLogs.length,
      'logs': jsonList,
    });
  }

  /// CSV로 전체 로그 내보내기
  Future<String> exportToCsv() async {
    final sb = StringBuffer();
    sb.writeln('timestamp,rawInput,detectedCategory,confidence,wasEdited,correctedCategory,appAction,inputSource,hourOfDay');
    for (final log in _recentLogs) {
      final input = log.rawInput.replaceAll(',', ' ').replaceAll('\n', ' ');
      sb.writeln('${log.timestamp.toIso8601String()},$input,${log.detectedCategory},${log.confidence},${log.wasEdited},${log.correctedCategory ?? ""},${log.appAction},${log.inputSource},${log.hourOfDay}');
    }
    return sb.toString();
  }
}
