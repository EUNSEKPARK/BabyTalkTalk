import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/services/record_service.dart';

/// 마지막 수유 시각과(선택) 최근 수유 간격을 바탕으로 한 로컬 수유 알림
class NotificationService extends ChangeNotifier {
  static const int _feedingReminderId = 9001;
  static const String _channelId = 'feeding_reminders';

  static const String _prefsEnabled = 'feeding_reminder_enabled';
  static const String _prefsInterval = 'feeding_reminder_interval_hours';
  static const String _prefsUseSmart = 'feeding_reminder_use_smart_interval';

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  RecordService? _recordService;

  bool _enabled = false;
  int _intervalHours = 3;
  bool _useSmartInterval = true;
  bool _initialized = false;

  bool get feedingReminderEnabled => _enabled;
  int get intervalHours => _intervalHours;
  bool get useSmartInterval => _useSmartInterval;

  Future<void> init() async {
    tzdata.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Seoul'));

    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(settings: initSettings);

    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefsEnabled) ?? false;
    _intervalHours = (prefs.getInt(_prefsInterval) ?? 3).clamp(2, 6);
    _useSmartInterval = prefs.getBool(_prefsUseSmart) ?? true;
    _initialized = true;

    const channel = AndroidNotificationChannel(
      _channelId,
      '수유 알림',
      description: '다음 수유 예상 시각 안내',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    notifyListeners();
  }

  void attachRecordService(RecordService service) {
    _recordService?.removeListener(_onRecordsChanged);
    _recordService = service;
    service.addListener(_onRecordsChanged);
    if (_enabled) {
      rescheduleFeedingReminder();
    }
  }

  void _onRecordsChanged() {
    if (_enabled) {
      rescheduleFeedingReminder();
    }
  }

  Future<void> setFeedingReminderEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsEnabled, value);
    if (value) {
      await requestPermissionIfNeeded();
      await rescheduleFeedingReminder();
    } else {
      await _plugin.cancel(id: _feedingReminderId);
    }
    notifyListeners();
  }

  Future<void> setIntervalHours(int hours) async {
    _intervalHours = hours.clamp(2, 6);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsInterval, _intervalHours);
    if (_enabled) await rescheduleFeedingReminder();
    notifyListeners();
  }

  Future<void> setUseSmartInterval(bool value) async {
    _useSmartInterval = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsUseSmart, value);
    if (_enabled) await rescheduleFeedingReminder();
    notifyListeners();
  }

  Future<bool> requestPermissionIfNeeded() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? true;
    }
    return true;
  }

  int _effectiveIntervalHours() {
    if (!_useSmartInterval || _recordService == null) return _intervalHours;

    final feedings = _recordService!.records
        .where((r) => r.category == RecordCategory.feeding)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    if (feedings.length < 2) return _intervalHours;

    var totalMin = 0;
    var count = 0;
    for (var i = 0; i < feedings.length - 1 && i < 5; i++) {
      final gap = feedings[i].timestamp.difference(feedings[i + 1].timestamp);
      final m = gap.inMinutes;
      if (m >= 60 && m <= 360) {
        totalMin += m;
        count++;
      }
    }
    if (count == 0) return _intervalHours;
    final avgH = (totalMin / count / 60).round();
    return avgH.clamp(2, 5);
  }

  Future<void> rescheduleFeedingReminder() async {
    if (!_initialized || !_enabled || _recordService == null) return;

    await _plugin.cancel(id: _feedingReminderId);

    final last = _recordService!.lastFeedingRecord;
    if (last == null) return;

    final hours = _effectiveIntervalHours();
    var next = last.timestamp.add(Duration(hours: hours));
    final now = DateTime.now();
    if (!next.isAfter(now)) {
      next = now.add(const Duration(minutes: 15));
    }

    final scheduled = tz.TZDateTime.from(next, tz.local);
    if (!scheduled.isAfter(tz.TZDateTime.now(tz.local))) return;

    final babyName = _recordService!.profile?.name ?? '아기';

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        '수유 알림',
        channelDescription: '다음 수유 시간 안내',
        importance: Importance.high,
        priority: Priority.high,
      ),
    );

    await _plugin.zonedSchedule(
      id: _feedingReminderId,
      title: '수유 시간을 확인해 보세요',
      body: '$babyName의 다음 수유 예상 시각이에요.',
      scheduledDate: scheduled,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
