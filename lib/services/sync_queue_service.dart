import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/services/family_service.dart';

/// 오프라인 동기화 큐 (아웃박스 패턴)
///
/// Hive에 먼저 기록을 저장하고, Firestore 업로드 실패 시
/// 이 큐에 넣어 나중에 재시도합니다.
///
/// 구조:
/// - SharedPreferences "sync_outbox" 키에 JSON 배열로 저장
/// - 각 항목: { "action": "add|update|delete", "recordJson": {...}, "retryCount": N }
/// - 앱 시작 시 + 네트워크 복구 시 flush 시도
class SyncQueueService extends ChangeNotifier {
  static const String _prefsOutboxKey = 'sync_outbox';
  static const int _maxRetries = 5;

  FamilyService? _familyService;
  List<Map<String, dynamic>> _queue = [];
  bool _isFlushing = false;

  int get pendingCount => _queue.length;
  bool get hasPending => _queue.isNotEmpty;
  bool get isFlushing => _isFlushing;

  /// 초기화 — 저장된 큐 로드
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsOutboxKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _queue = list.map((e) => Map<String, dynamic>.from(e)).toList();
      } catch (e) {
        debugPrint('SyncQueue 로드 실패: $e');
        _queue = [];
      }
    }
    notifyListeners();
  }

  void attachFamilyService(FamilyService service) {
    _familyService = service;
  }

  /// 기록 업로드 실패 시 큐에 추가
  Future<void> enqueueAdd(BabyRecord record) async {
    _queue.add({
      'action': 'add',
      'recordJson': _recordToJson(record),
      'retryCount': 0,
      'enqueuedAt': DateTime.now().millisecondsSinceEpoch,
    });
    await _persist();
    notifyListeners();
  }

  /// 삭제 실패 시 큐에 추가
  Future<void> enqueueDelete(String recordId) async {
    _queue.add({
      'action': 'delete',
      'recordId': recordId,
      'retryCount': 0,
      'enqueuedAt': DateTime.now().millisecondsSinceEpoch,
    });
    await _persist();
    notifyListeners();
  }

  /// 큐 비우기 — 순서대로 Firestore 업로드 시도
  Future<void> flush() async {
    if (_isFlushing || _familyService == null || !_familyService!.isInFamily) {
      return;
    }

    _isFlushing = true;
    notifyListeners();

    final completed = <int>[];

    for (var i = 0; i < _queue.length; i++) {
      final item = _queue[i];
      final action = item['action'] as String? ?? '';
      final retryCount = item['retryCount'] as int? ?? 0;

      if (retryCount >= _maxRetries) {
        // 최대 재시도 초과 → 드롭
        completed.add(i);
        debugPrint('SyncQueue: 최대 재시도 초과, 항목 드롭');
        continue;
      }

      try {
        switch (action) {
          case 'add':
            final recordJson = item['recordJson'] as Map<String, dynamic>?;
            if (recordJson != null) {
              final record = _recordFromJson(recordJson);
              await _familyService!.uploadRecord(record);
              completed.add(i);
            }
            break;
          case 'delete':
            final recordId = item['recordId'] as String?;
            if (recordId != null) {
              await _familyService!.deleteRemoteRecord(recordId);
              completed.add(i);
            }
            break;
        }
      } catch (e) {
        // 실패 → 재시도 카운트 증가
        _queue[i] = {...item, 'retryCount': retryCount + 1};
        debugPrint('SyncQueue: 동기화 실패 (${retryCount + 1}회차): $e');
      }
    }

    // 성공 항목 제거 (역순으로)
    for (final idx in completed.reversed) {
      _queue.removeAt(idx);
    }

    _isFlushing = false;
    await _persist();
    notifyListeners();

    if (completed.isNotEmpty) {
      debugPrint('SyncQueue: ${completed.length}건 동기화 완료, ${_queue.length}건 남음');
    }
  }

  /// SharedPreferences에 큐 저장
  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsOutboxKey, jsonEncode(_queue));
  }

  // ── 직렬화 유틸 ──

  static Map<String, dynamic> _recordToJson(BabyRecord r) {
    return {
      'id': r.id,
      'category': r.category.index,
      'timestamp': r.timestamp.millisecondsSinceEpoch,
      'rawInput': r.rawInput,
      'feedingType': r.feedingType?.index,
      'amountMl': r.amountMl,
      'durationMinutes': r.durationMinutes,
      'sleepStatus': r.sleepStatus?.index,
      'diaperType': r.diaperType?.index,
      'temperature': r.temperature,
      'medicine': r.medicine,
      'memo': r.memo,
      'createdAt': r.createdAt.millisecondsSinceEpoch,
      'inputSource': r.inputSource,
      'authorId': r.authorId,
      'authorName': r.authorName,
    };
  }

  static BabyRecord _recordFromJson(Map<String, dynamic> j) {
    final catIdx = j['category'] as int? ?? 0;
    final category = catIdx < RecordCategory.values.length
        ? RecordCategory.values[catIdx]
        : RecordCategory.other;

    FeedingType? feedingType;
    final ft = j['feedingType'] as int?;
    if (ft != null && ft < FeedingType.values.length) {
      feedingType = FeedingType.values[ft];
    }

    SleepStatus? sleepStatus;
    final ss = j['sleepStatus'] as int?;
    if (ss != null && ss < SleepStatus.values.length) {
      sleepStatus = SleepStatus.values[ss];
    }

    DiaperType? diaperType;
    final dt = j['diaperType'] as int?;
    if (dt != null && dt < DiaperType.values.length) {
      diaperType = DiaperType.values[dt];
    }

    return BabyRecord(
      id: j['id'] as String? ?? '',
      category: category,
      timestamp: DateTime.fromMillisecondsSinceEpoch(
        j['timestamp'] as int? ?? 0,
      ),
      rawInput: j['rawInput'] as String?,
      feedingType: feedingType,
      amountMl: (j['amountMl'] as num?)?.toInt(),
      durationMinutes: (j['durationMinutes'] as num?)?.toInt(),
      sleepStatus: sleepStatus,
      diaperType: diaperType,
      temperature: (j['temperature'] as num?)?.toDouble(),
      medicine: j['medicine'] as String?,
      memo: j['memo'] as String?,
      inputSource: j['inputSource'] as String?,
      authorId: j['authorId'] as String?,
      authorName: j['authorName'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        j['createdAt'] as int? ?? 0,
      ),
    );
  }
}
