import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:uuid/uuid.dart';

import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/models/routine.dart';
import 'package:chat_baby_time/services/record_service.dart';

/// 알림 액션 식별자
const String kActionQuickRecord = 'QUICK_RECORD';
const String kActionSnooze = 'SNOOZE';

/// 알림 채널
const String kRoutineChannelId = 'routine_reminders';
const String kRoutineChannelName = '루틴 알림';
const String kRoutineChannelDesc = '수유·기저귀·수면 루틴 알림';

/// 백그라운드 알림 액션 핸들러 (top-level 함수여야 함)
@pragma('vm:entry-point')
void onNotificationActionBackground(NotificationResponse response) {
  // 백그라운드에서 액션 처리는 SharedPreferences 큐에 기록
  // 앱이 다음에 열릴 때 RecordService가 처리
  _enqueuePendingAction(response);
}

Future<void> _enqueuePendingAction(NotificationResponse response) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList('pending_notification_actions') ?? [];
    final payload = response.payload ?? '';
    final action = response.actionId ?? '';
    final entry = jsonEncode({
      'action': action,
      'payload': payload,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    pending.add(entry);
    await prefs.setStringList('pending_notification_actions', pending);
  } catch (e) {
    debugPrint('enqueuePendingAction error: $e');
  }
}

/// 루틴 엔진 + 알림 스케줄러
///
/// 책임:
/// 1. 루틴 목록 관리 (CRUD + SharedPreferences 영속화)
/// 2. 기록이 들어올 때마다 해당 카테고리 루틴의 다음 알림 계산·스케줄
/// 3. 액션 알림(즉시 기록 / 스누즈) 처리
class RoutineSchedulerService extends ChangeNotifier {
  static const String _prefsRoutinesKey = 'routines_json';
  static const String _prefsSnoozeCountPrefix = 'snooze_count_';

  final FlutterLocalNotificationsPlugin _plugin;
  RecordService? _recordService;

  List<Routine> _routines = [];
  bool _initialized = false;

  List<Routine> get routines => List.unmodifiable(_routines);
  bool get initialized => _initialized;

  RoutineSchedulerService(this._plugin);

  // ─────────────────────────────────────────
  // 초기화
  // ─────────────────────────────────────────

  Future<void> init() async {
    // 알림 채널 생성
    const channel = AndroidNotificationChannel(
      kRoutineChannelId,
      kRoutineChannelName,
      description: kRoutineChannelDesc,
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 저장된 루틴 로드
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsRoutinesKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _routines =
            list.map((e) => Routine.fromJson(Map<String, dynamic>.from(e))).toList();
      } catch (e) {
        debugPrint('루틴 로드 실패: $e');
        _routines = [];
      }
    }

    // 첫 실행이면 기본 루틴 생성
    if (_routines.isEmpty) {
      _routines = Routine.defaultRoutines();
      await _saveRoutines();
    }

    _initialized = true;
    notifyListeners();
  }

  /// RecordService 연결 — 기록 변경 시 자동 재스케줄
  void attachRecordService(RecordService service) {
    _recordService?.removeListener(_onRecordsChanged);
    _recordService = service;
    service.addListener(_onRecordsChanged);
    // 연결 즉시 모든 활성 루틴 스케줄
    rescheduleAll();
  }

  void _onRecordsChanged() {
    rescheduleAll();
  }

  // ─────────────────────────────────────────
  // 루틴 CRUD
  // ─────────────────────────────────────────

  Future<void> addRoutine(Routine routine) async {
    _routines.add(routine);
    await _saveRoutines();
    await _scheduleRoutine(routine);
    notifyListeners();
  }

  Future<void> updateRoutine(Routine routine) async {
    final idx = _routines.indexWhere((r) => r.id == routine.id);
    if (idx >= 0) {
      // 이전 알림 취소
      await _plugin.cancel(id: _routines[idx].notificationId);
      _routines[idx] = routine;
      await _saveRoutines();
      if (routine.enabled) {
        await _scheduleRoutine(routine);
      }
      notifyListeners();
    }
  }

  Future<void> deleteRoutine(String id) async {
    final idx = _routines.indexWhere((r) => r.id == id);
    if (idx >= 0) {
      await _plugin.cancel(id: _routines[idx].notificationId);
      _routines.removeAt(idx);
      await _saveRoutines();
      notifyListeners();
    }
  }

  Future<void> toggleRoutine(String id, bool enabled) async {
    final idx = _routines.indexWhere((r) => r.id == id);
    if (idx >= 0) {
      _routines[idx] = _routines[idx].copyWith(enabled: enabled);
      await _saveRoutines();
      if (enabled) {
        await _scheduleRoutine(_routines[idx]);
      } else {
        await _plugin.cancel(id: _routines[idx].notificationId);
      }
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────
  // 스케줄링 코어
  // ─────────────────────────────────────────

  /// 모든 활성 루틴 재스케줄
  Future<void> rescheduleAll() async {
    if (!_initialized || _recordService == null) return;
    for (final routine in _routines) {
      if (routine.enabled) {
        await _scheduleRoutine(routine);
      }
    }
  }

  /// 특정 카테고리 기록이 추가됐을 때 해당 루틴만 재스케줄
  Future<void> onRecordAdded(RecordCategory category) async {
    if (!_initialized) return;
    for (final routine in _routines) {
      if (routine.enabled && routine.targetCategory == category) {
        // 스누즈 카운트 리셋
        await _resetSnoozeCount(routine.id);
        await _scheduleRoutine(routine);
      }
    }
  }

  /// 개별 루틴 스케줄
  Future<void> _scheduleRoutine(Routine routine) async {
    if (_recordService == null) return;

    // 기존 알림 취소
    await _plugin.cancel(id: routine.notificationId);

    final nextTime = _calculateNextTrigger(routine);
    if (nextTime == null) return;

    final scheduled = tz.TZDateTime.from(nextTime, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (!scheduled.isAfter(now)) return;

    final babyName = _recordService!.profile?.name ?? '아기';

    // 알림 제목/본문
    final title = routine.notificationTitle ?? '${routine.name} 시간이에요';
    final body = routine.notificationBody ??
        '$babyName의 ${_categoryLabel(routine.targetCategory)} 시간을 확인해 보세요.';

    // 액션 알림 설정
    final quickLabel = _quickRecordLabel(routine);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        kRoutineChannelId,
        kRoutineChannelName,
        channelDescription: kRoutineChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            kActionQuickRecord,
            quickLabel,
            showsUserInterface: false,
          ),
          AndroidNotificationAction(
            kActionSnooze,
            '${routine.snoozePolicy.intervalMinutes}분 뒤 🔔',
            showsUserInterface: false,
          ),
        ],
      ),
    );

    // payload에 루틴 정보 직렬화
    final payload = jsonEncode({
      'routineId': routine.id,
      'category': routine.targetCategory.index,
      'defaults': routine.defaults.toJson(),
    });

    await _plugin.zonedSchedule(
      id: routine.notificationId,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );

    debugPrint(
        '[RoutineScheduler] ${routine.name} → ${scheduled.toIso8601String()}');
  }

  /// 다음 트리거 시각 계산
  DateTime? _calculateNextTrigger(Routine routine) {
    final now = DateTime.now();

    switch (routine.triggerType) {
      case RoutineTriggerType.fixedTime:
        if (routine.fixedHour == null) return null;
        var next = DateTime(
          now.year,
          now.month,
          now.day,
          routine.fixedHour!,
          routine.fixedMinute ?? 0,
        );
        // 오늘 시각이 지났으면 내일
        if (!next.isAfter(now)) {
          next = next.add(const Duration(days: 1));
        }
        return next;

      case RoutineTriggerType.sinceLastRecord:
        final last = _lastRecordFor(routine.targetCategory);
        final interval = _effectiveInterval(routine);
        if (last == null) {
          // 기록이 없으면 15분 후
          return now.add(const Duration(minutes: 15));
        }
        var next = last.timestamp.add(Duration(minutes: interval));
        if (!next.isAfter(now)) {
          // 이미 지났으면 15분 후
          next = now.add(const Duration(minutes: 15));
        }
        return next;
    }
  }

  /// 스마트 간격 계산 (최근 5건 평균)
  int _effectiveInterval(Routine routine) {
    if (!routine.useSmartInterval || _recordService == null) {
      return routine.intervalMinutes ?? 180;
    }

    final records = _recordService!.records
        .where((r) => r.category == routine.targetCategory)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (records.length < 2) return routine.intervalMinutes ?? 180;

    var totalMin = 0;
    var count = 0;
    for (var i = 0; i < records.length - 1 && i < 5; i++) {
      final gap = records[i].timestamp.difference(records[i + 1].timestamp);
      final m = gap.inMinutes;
      // 유효 범위: 30분 ~ 6시간
      if (m >= 30 && m <= 360) {
        totalMin += m;
        count++;
      }
    }
    if (count == 0) return routine.intervalMinutes ?? 180;
    return (totalMin / count).round().clamp(60, 360);
  }

  BabyRecord? _lastRecordFor(RecordCategory category) {
    if (_recordService == null) return null;
    try {
      return _recordService!.records.firstWhere(
        (r) => r.category == category,
      );
    } catch (_) {
      return null;
    }
  }

  // ─────────────────────────────────────────
  // 액션 핸들러 (포그라운드)
  // ─────────────────────────────────────────

  /// 알림 액션 처리 (포그라운드에서 호출됨)
  Future<void> handleNotificationAction(NotificationResponse response) async {
    final action = response.actionId;
    final payloadStr = response.payload;
    if (payloadStr == null || payloadStr.isEmpty) return;

    Map<String, dynamic> payload;
    try {
      payload = jsonDecode(payloadStr) as Map<String, dynamic>;
    } catch (_) {
      return;
    }

    final routineId = payload['routineId'] as String?;
    if (routineId == null) return;

    switch (action) {
      case kActionQuickRecord:
        await _handleQuickRecord(payload);
        break;
      case kActionSnooze:
        await _handleSnooze(routineId);
        break;
    }
  }

  /// 즉시 기록 처리
  Future<void> _handleQuickRecord(Map<String, dynamic> payload) async {
    if (_recordService == null) return;

    final catIdx = payload['category'] as int? ?? 0;
    final category = catIdx < RecordCategory.values.length
        ? RecordCategory.values[catIdx]
        : RecordCategory.feeding;

    final defaultsMap = payload['defaults'] as Map<String, dynamic>? ?? {};
    final defaults = RecordDefaults.fromJson(defaultsMap);

    final record = BabyRecord(
      id: const Uuid().v4(),
      category: category,
      timestamp: DateTime.now(),
      feedingType: defaults.feedingType,
      amountMl: defaults.amountMl,
      durationMinutes: defaults.durationMinutes,
      diaperType: defaults.diaperType,
      sleepStatus: defaults.sleepStatus,
      inputSource: 'notification',
      memo: '알림에서 빠른 기록',
    );

    await _recordService!.addRecord(record);
    debugPrint('[RoutineScheduler] 빠른 기록 완료: ${record.summary}');
  }

  /// 스누즈 처리
  Future<void> _handleSnooze(String routineId) async {
    final routine = _routines.cast<Routine?>().firstWhere(
          (r) => r?.id == routineId,
          orElse: () => null,
        );
    if (routine == null) return;

    // 스누즈 횟수 체크
    final count = await _getSnoozeCount(routineId);
    if (routine.snoozePolicy.maxCount > 0 &&
        count >= routine.snoozePolicy.maxCount) {
      debugPrint('[RoutineScheduler] 스누즈 최대 횟수 초과: $routineId');
      return;
    }

    await _incrementSnoozeCount(routineId);

    // 스누즈 시간만큼 뒤에 다시 스케줄
    final snoozeTime = DateTime.now()
        .add(Duration(minutes: routine.snoozePolicy.intervalMinutes));
    final scheduled = tz.TZDateTime.from(snoozeTime, tz.local);

    final babyName = _recordService?.profile?.name ?? '아기';
    final title = '⏰ ${routine.name} (다시 알림)';
    final body = '$babyName ${_categoryLabel(routine.targetCategory)} 확인해 주세요!';
    final quickLabel = _quickRecordLabel(routine);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        kRoutineChannelId,
        kRoutineChannelName,
        channelDescription: kRoutineChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        actions: <AndroidNotificationAction>[
          AndroidNotificationAction(
            kActionQuickRecord,
            quickLabel,
            showsUserInterface: false,
          ),
          AndroidNotificationAction(
            kActionSnooze,
            '${routine.snoozePolicy.intervalMinutes}분 뒤 🔔',
            showsUserInterface: false,
          ),
        ],
      ),
    );

    final payload = jsonEncode({
      'routineId': routine.id,
      'category': routine.targetCategory.index,
      'defaults': routine.defaults.toJson(),
    });

    await _plugin.zonedSchedule(
      id: routine.notificationId,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: details,
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );

    debugPrint(
        '[RoutineScheduler] 스누즈: ${routine.name} → ${scheduled.toIso8601String()}');
  }

  // ─────────────────────────────────────────
  // 보류 중인 백그라운드 액션 처리
  // ─────────────────────────────────────────

  /// 앱 시작 시 호출 — 백그라운드에서 큐잉된 액션 처리
  Future<void> processPendingActions() async {
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList('pending_notification_actions') ?? [];
    if (pending.isEmpty) return;

    for (final entry in pending) {
      try {
        final map = jsonDecode(entry) as Map<String, dynamic>;
        final action = map['action'] as String? ?? '';
        final payload = map['payload'] as String? ?? '';

        final response = NotificationResponse(
          notificationResponseType:
              NotificationResponseType.selectedNotificationAction,
          actionId: action,
          payload: payload,
        );
        await handleNotificationAction(response);
      } catch (e) {
        debugPrint('processPendingActions: $e');
      }
    }

    await prefs.setStringList('pending_notification_actions', []);
  }

  // ─────────────────────────────────────────
  // 위젯용 — 다음 예정 루틴 정보
  // ─────────────────────────────────────────

  /// 다음으로 트리거될 루틴과 예상 시각 반환
  ({Routine? routine, DateTime? nextTime}) get nextScheduledRoutine {
    if (!_initialized || _recordService == null) {
      return (routine: null, nextTime: null);
    }

    DateTime? earliest;
    Routine? earliestRoutine;

    for (final routine in _routines) {
      if (!routine.enabled) continue;
      final next = _calculateNextTrigger(routine);
      if (next != null && (earliest == null || next.isBefore(earliest))) {
        earliest = next;
        earliestRoutine = routine;
      }
    }

    return (routine: earliestRoutine, nextTime: earliest);
  }

  // ─────────────────────────────────────────
  // 내부 유틸
  // ─────────────────────────────────────────

  Future<void> _saveRoutines() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(_routines.map((r) => r.toJson()).toList());
    await prefs.setString(_prefsRoutinesKey, json);
  }

  Future<int> _getSnoozeCount(String routineId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_prefsSnoozeCountPrefix$routineId') ?? 0;
  }

  Future<void> _incrementSnoozeCount(String routineId) async {
    final prefs = await SharedPreferences.getInstance();
    final count = (prefs.getInt('$_prefsSnoozeCountPrefix$routineId') ?? 0) + 1;
    await prefs.setInt('$_prefsSnoozeCountPrefix$routineId', count);
  }

  Future<void> _resetSnoozeCount(String routineId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefsSnoozeCountPrefix$routineId');
  }

  String _categoryLabel(RecordCategory cat) {
    switch (cat) {
      case RecordCategory.feeding:
        return '수유';
      case RecordCategory.diaper:
        return '기저귀';
      case RecordCategory.sleep:
        return '수면';
      case RecordCategory.babyfood:
        return '이유식';
      case RecordCategory.snack:
        return '간식';
      case RecordCategory.health:
        return '건강';
      default:
        return '육아';
    }
  }

  String _quickRecordLabel(Routine routine) {
    switch (routine.targetCategory) {
      case RecordCategory.feeding:
        final ml = routine.defaults.amountMl ?? 160;
        return '${ml}ml 기록 ✅';
      case RecordCategory.diaper:
        return '기저귀 기록 ✅';
      case RecordCategory.sleep:
        return '수면 기록 ✅';
      default:
        return '기록하기 ✅';
    }
  }
}
