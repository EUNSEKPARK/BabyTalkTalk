import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/services/record_service.dart';
import 'package:chat_baby_time/services/routine_scheduler_service.dart';

/// 알림 서비스 (루틴 엔진 통합)
///
/// 이전의 단독 수유 알림 + 새 루틴 스케줄러를 모두 관리합니다.
/// 기존 설정 키(feeding_reminder_*)는 하위 호환을 위해 유지하며,
/// 루틴 엔진으로 자동 마이그레이션합니다.
class NotificationService extends ChangeNotifier {
  // 레거시 (하위 호환)
  static const String _prefsEnabled = 'feeding_reminder_enabled';
  static const String _prefsInterval = 'feeding_reminder_interval_hours';
  static const String _prefsUseSmart = 'feeding_reminder_use_smart_interval';
  static const String _prefsMigrated = 'routine_migration_done';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  late final RoutineSchedulerService _routineScheduler;

  RecordService? _recordService;

  bool _initialized = false;

  // 레거시 getters (설정 화면 호환용)
  bool _legacyEnabled = false;
  int _legacyIntervalHours = 3;
  bool _legacyUseSmart = true;

  bool get feedingReminderEnabled => _legacyEnabled;
  int get intervalHours => _legacyIntervalHours;
  bool get useSmartInterval => _legacyUseSmart;
  bool get initialized => _initialized;

  FlutterLocalNotificationsPlugin get plugin => _plugin;
  RoutineSchedulerService get routineScheduler => _routineScheduler;

  Future<void> init() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _plugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onForegroundAction,
      onDidReceiveBackgroundNotificationResponse:
          onNotificationActionBackground,
    );

    // 레거시 설정 로드
    final prefs = await SharedPreferences.getInstance();
    _legacyEnabled = prefs.getBool(_prefsEnabled) ?? false;
    _legacyIntervalHours = (prefs.getInt(_prefsInterval) ?? 3).clamp(2, 6);
    _legacyUseSmart = prefs.getBool(_prefsUseSmart) ?? true;

    // 루틴 스케줄러 초기화
    _routineScheduler = RoutineSchedulerService(_plugin);
    await _routineScheduler.init();

    // 레거시 → 루틴 마이그레이션
    await _migrateIfNeeded(prefs);

    // 보류 중인 백그라운드 액션 처리
    await _routineScheduler.processPendingActions();

    _initialized = true;
    notifyListeners();
  }

  /// 레거시 수유 알림 → 루틴 엔진 마이그레이션
  Future<void> _migrateIfNeeded(SharedPreferences prefs) async {
    if (prefs.getBool(_prefsMigrated) == true) return;

    // 기존에 수유 알림을 사용 중이었다면 기본 루틴의 수유 루틴을 활성화
    final wasEnabled = prefs.getBool(_prefsEnabled) ?? false;
    if (wasEnabled) {
      final feedingRoutine = _routineScheduler.routines
          .cast<dynamic>()
          .firstWhere(
            (r) => r.id == 'default_feeding',
            orElse: () => null,
          );
      if (feedingRoutine != null) {
        await _routineScheduler.toggleRoutine('default_feeding', true);
      }
    }

    await prefs.setBool(_prefsMigrated, true);
  }

  void _onForegroundAction(NotificationResponse response) {
    _routineScheduler.handleNotificationAction(response);
  }

  void attachRecordService(RecordService service) {
    _recordService?.removeListener(_onRecordsChanged);
    _recordService = service;
    service.addListener(_onRecordsChanged);
    _routineScheduler.attachRecordService(service);
  }

  void _onRecordsChanged() {
    // 루틴 스케줄러가 자동으로 재스케줄하므로 여기서는 추가 작업 없음
  }

  // ─────────────────────────────────────────
  // 레거시 API (설정 화면 호환)
  // 내부적으로 루틴 엔진에 위임
  // ─────────────────────────────────────────

  Future<void> setFeedingReminderEnabled(bool value) async {
    _legacyEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsEnabled, value);

    if (value) {
      await requestPermissionIfNeeded();
    }
    await _routineScheduler.toggleRoutine('default_feeding', value);
    notifyListeners();
  }

  Future<void> setIntervalHours(int hours) async {
    _legacyIntervalHours = hours.clamp(2, 6);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsInterval, _legacyIntervalHours);

    // 루틴 엔진의 수유 루틴 간격 업데이트
    final feedingRoutine = _routineScheduler.routines
        .cast<dynamic>()
        .firstWhere((r) => r.id == 'default_feeding', orElse: () => null);
    if (feedingRoutine != null) {
      await _routineScheduler.updateRoutine(
        feedingRoutine.copyWith(intervalMinutes: _legacyIntervalHours * 60),
      );
    }
    notifyListeners();
  }

  Future<void> setUseSmartInterval(bool value) async {
    _legacyUseSmart = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsUseSmart, value);

    final feedingRoutine = _routineScheduler.routines
        .cast<dynamic>()
        .firstWhere((r) => r.id == 'default_feeding', orElse: () => null);
    if (feedingRoutine != null) {
      await _routineScheduler.updateRoutine(
        feedingRoutine.copyWith(useSmartInterval: value),
      );
    }
    notifyListeners();
  }

  Future<bool> requestPermissionIfNeeded() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? true;
    }
    return true;
  }

  /// RecordService에서 기록 추가 후 호출
  Future<void> onRecordAdded(RecordCategory category) async {
    await _routineScheduler.onRecordAdded(category);
  }

  /// 레거시 호환 - 더 이상 직접 스케줄하지 않음
  Future<void> rescheduleFeedingReminder() async {
    await _routineScheduler.rescheduleAll();
  }
}
