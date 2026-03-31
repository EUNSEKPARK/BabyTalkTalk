import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';

import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/services/record_service.dart';

/// Android 홈 화면 위젯과 동일한 SharedPreferences 키로 데이터를 씁니다.
class BabyTimeHomeWidget {
  BabyTimeHomeWidget._();

  static const String qualifiedAndroidProvider =
      'com.chatbabytime.app.BabyTimeWidgetProvider';

  /// 앱 시작 시 한 번 호출 (iOS 확장용 그룹 ID; Android는 무시됨)
  static Future<void> ensureConfigured() async {
    await HomeWidget.setAppGroupId('group.com.chatbabytime.app');
  }

  static Future<void> sync(RecordService recordService) async {
    if (kIsWeb || !Platform.isAndroid) return;

    try {
      final profile = recordService.profile;
      final name = profile?.name ?? '아기톡톡';

      final counts = recordService.todayCategoryCounts;
      final feeding = counts[RecordCategory.feeding] ?? 0;
      final diaper = counts[RecordCategory.diaper] ?? 0;
      final sleep = counts[RecordCategory.sleep] ?? 0;
      final summaryLine = '오늘 수유 $feeding · 기저귀 $diaper · 수면 $sleep';

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

      await HomeWidget.saveWidgetData<String>('baby_name', name);
      await HomeWidget.saveWidgetData<String>('summary_line', summaryLine);
      await HomeWidget.saveWidgetData<String>('detail_line', detailLine);
      await HomeWidget.updateWidget(
        qualifiedAndroidName: qualifiedAndroidProvider,
      );
    } catch (e, st) {
      debugPrint('BabyTimeHomeWidget.sync: $e\n$st');
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
}
