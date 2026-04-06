import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/services/record_service.dart';
import 'package:chat_baby_time/services/routine_scheduler_service.dart';

/// Android 홈 화면 위젯과 데이터를 동기화합니다.
///
/// 데이터 흐름:
/// 1. Flutter → Widget: 기록 변경 시 SharedPreferences에 요약 데이터 쓰기
/// 2. Widget → Flutter: 위젯 퀵 액션으로 생성된 pending 기록을 Hive로 흡수
/// 3. 루틴 엔진 → Widget: 다음 예정 루틴 정보 표시
class BabyTimeHomeWidget {
  BabyTimeHomeWidget._();

  static const String qualifiedAndroidProvider =
      'com.chatbabytime.app.BabyTimeWidgetProvider';

  /// 앱 시작 시 한 번 호출 (iOS 확장용 그룹 ID; Android는 무시됨)
  static Future<void> ensureConfigured() async {
    await HomeWidget.setAppGroupId('group.com.chatbabytime.app');
  }

  /// Flutter → Widget 동기화
  static Future<void> sync(
    RecordService recordService, {
    RoutineSchedulerService? routineScheduler,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      final profile = recordService.profile;
      final name = profile?.name ?? '아기톡톡';

      // ── 오늘 요약 ──
      final counts = recordService.todayCategoryCounts;
      final feeding = counts[RecordCategory.feeding] ?? 0;
      final diaper = counts[RecordCategory.diaper] ?? 0;
      final sleep = counts[RecordCategory.sleep] ?? 0;
      final summaryLine = '오늘 수유 $feeding · 기저귀 $diaper · 수면 $sleep';

      // ── 마지막 수유 상세 ──
      String detailLine;
      final last = recordService.lastFeedingRecord;
      if (last == null) {
        detailLine = '수유 기록이 없어요';
      } else {
        final diff = DateTime.now().difference(last.timestamp);
        if (diff.inMinutes < 1) {
          detailLine = '방금 수유 기록됨';
        } else if (diff.inMinutes < 60) {
          detailLine = '마지막 수유 ${diff.inMinutes}분 전';
        } else if (diff.inHours < 24) {
          detailLine = '마지막 수유 ${diff.inHours}시간 전';
        } else {
          detailLine =
              '마지막 수유 ${DateFormat('M/d HH:mm').format(last.timestamp)}';
        }
      }

      // ── 다음 루틴 예정 ──
      String nextRoutineLine = '';
      if (routineScheduler != null) {
        final next = routineScheduler.nextScheduledRoutine;
        if (next.routine != null && next.nextTime != null) {
          final diff = next.nextTime!.difference(DateTime.now());
          final routineName = next.routine!.name;
          if (diff.isNegative) {
            nextRoutineLine = '$routineName 시간 지남';
          } else if (diff.inMinutes < 60) {
            nextRoutineLine = '$routineName ${diff.inMinutes}분 후';
          } else {
            nextRoutineLine =
                '$routineName ${diff.inHours}시간 ${diff.inMinutes % 60}분 후';
          }
        }
      }

      await HomeWidget.saveWidgetData<String>('baby_name', name);
      await HomeWidget.saveWidgetData<String>('summary_line', summaryLine);
      await HomeWidget.saveWidgetData<String>('detail_line', detailLine);
      await HomeWidget.saveWidgetData<String>(
          'next_routine_line', nextRoutineLine);
      await HomeWidget.updateWidget(
        qualifiedAndroidName: qualifiedAndroidProvider,
      );
    } catch (e, st) {
      debugPrint('BabyTimeHomeWidget.sync: $e\n$st');
    }
  }

  /// Widget → Flutter: 위젯에서 생성된 pending 기록을 Hive로 흡수
  ///
  /// QuickRecordReceiver가 SharedPreferences "pending_widget_records"에
  /// JSON 배열로 기록을 남기면, 이 메서드가 파싱하여 RecordService에 추가합니다.
  static Future<int> processPendingWidgetRecords(
      RecordService recordService) async {
    if (kIsWeb || !Platform.isAndroid) return 0;

    try {
      final raw =
          await HomeWidget.getWidgetData<String>('pending_widget_records');
      if (raw == null || raw.isEmpty) return 0;

      final decoded = jsonDecode(raw);
      if (decoded is! List) return 0;
      int count = 0;

      for (final item in decoded) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);

        final catIdx = _asInt(map['category']);
        final category = catIdx < RecordCategory.values.length
            ? RecordCategory.values[catIdx]
            : RecordCategory.feeding;

        FeedingType? feedingType;
        final ft = _asIntOrNull(map['feedingType']);
        if (ft != null && ft < FeedingType.values.length) {
          feedingType = FeedingType.values[ft];
        }

        DiaperType? diaperType;
        final dt = _asIntOrNull(map['diaperType']);
        if (dt != null && dt < DiaperType.values.length) {
          diaperType = DiaperType.values[dt];
        }

        SleepStatus? sleepStatus;
        final ss = _asIntOrNull(map['sleepStatus']);
        if (ss != null && ss < SleepStatus.values.length) {
          sleepStatus = SleepStatus.values[ss];
        }

        final tsMs = _asInt(
          map['timestamp'],
          DateTime.now().millisecondsSinceEpoch,
        );

        final idRaw = map['id'];
        final idStr = idRaw is String && idRaw.isNotEmpty
            ? idRaw
            : idRaw?.toString();
        final record = BabyRecord(
          id: (idStr != null && idStr.isNotEmpty) ? idStr : const Uuid().v4(),
          category: category,
          timestamp: DateTime.fromMillisecondsSinceEpoch(tsMs),
          feedingType: feedingType,
          amountMl: _asIntOrNull(map['amountMl']),
          diaperType: diaperType,
          sleepStatus: sleepStatus,
          inputSource: map['inputSource'] as String? ?? 'widget',
          memo: map['memo'] as String?,
        );

        final success = await recordService.addRecord(record);
        if (success) count++;
      }

      // 처리 완료 → 큐 클리어
      await HomeWidget.saveWidgetData<String>(
          'pending_widget_records', null);
      debugPrint('BabyTimeHomeWidget: $count개 위젯 기록 흡수 완료');
      return count;
    } catch (e, st) {
      debugPrint('processPendingWidgetRecords: $e\n$st');
      return 0;
    }
  }

  static Future<void> requestPin() async {
    if (kIsWeb || !Platform.isAndroid) return;
    await HomeWidget.requestPinWidget(
      qualifiedAndroidName: qualifiedAndroidProvider,
    );
  }

  static Future<bool> isPinSupported() async {
    if (kIsWeb || !Platform.isAndroid) return false;
    final v = await HomeWidget.isRequestPinWidgetSupported();
    return v == true;
  }

  static int _asInt(dynamic v, [int defaultVal = 0]) {
    if (v == null) return defaultVal;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return defaultVal;
  }

  static int? _asIntOrNull(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return null;
  }
}
