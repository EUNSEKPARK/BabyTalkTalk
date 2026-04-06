import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:chat_baby_time/services/notification_service.dart';
import 'package:chat_baby_time/services/record_service.dart';
import 'package:chat_baby_time/services/nlp_analytics_service.dart';
import 'package:chat_baby_time/screens/nlp_analytics_screen.dart';
import 'package:chat_baby_time/utils/app_theme.dart';
import 'package:chat_baby_time/screens/tutorial_screen.dart';

/// 알림, 로컬 백업/복원
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('알림 및 백업'),
        backgroundColor: AppTheme.background,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Text(
            '수유 알림',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Consumer<NotificationService>(
            builder: (context, notif, _) {
              return Card(
                color: AppTheme.surfaceContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('다음 수유 알림'),
                        subtitle: const Text('마지막 수유 시각과 간격을 바탕으로 한 번 알려드려요'),
                        value: notif.feedingReminderEnabled,
                        onChanged: (v) => notif.setFeedingReminderEnabled(v),
                      ),
                      if (notif.feedingReminderEnabled) ...[
                        const Divider(),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('최근 패턴 반영'),
                          subtitle: const Text('최근 수유 간격(2~5시간)을 자동으로 추정'),
                          value: notif.useSmartInterval,
                          onChanged: notif.setUseSmartInterval,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '기본 간격: ${notif.intervalHours}시간 (패턴이 부족할 때 사용)',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.onSurfaceVariant,
                              ),
                        ),
                        Slider(
                          value: notif.intervalHours.toDouble(),
                          min: 2,
                          max: 6,
                          divisions: 4,
                          label: '${notif.intervalHours}시간',
                          onChanged: (x) => notif.setIntervalHours(x.round()),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 28),

          // ── 서비스 개선 참여 (NLP 분석 데이터 수집) ──
          Text(
            '서비스 개선 참여',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Consumer<NlpAnalyticsService>(
            builder: (context, analytics, _) {
              return Card(
                color: AppTheme.surfaceContainer,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('채팅 인식 데이터 수집'),
                        subtitle: Text(
                          analytics.isConsentGiven
                              ? '익명 데이터가 서비스 개선에 활용됩니다'
                              : '데이터를 수집하지 않습니다',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        value: analytics.isConsentGiven,
                        onChanged: (value) => analytics.setConsent(value),
                        secondary: Icon(
                          analytics.isConsentGiven ? Icons.analytics : Icons.analytics_outlined,
                          color: analytics.isConsentGiven ? AppTheme.primary : Colors.grey,
                        ),
                      ),
                      if (analytics.isConsentGiven && analytics.totalLogs > 0)
                        GestureDetector(
                          onLongPress: () {
                            // 숨겨진 진입점: 개발자 대시보드
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (_) => const NlpAnalyticsScreen(),
                            ));
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '수집된 데이터: ${analytics.totalLogs}건 · '
                              '수정율: ${(analytics.correctionRate * 100).toStringAsFixed(1)}%',
                              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 28),

          // ── 튜토리얼 다시 보기 ──
          Text(
            '앱 가이드',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            color: AppTheme.surfaceContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              leading: const Icon(Icons.school_outlined, color: AppTheme.primary),
              title: const Text('튜토리얼 다시 보기'),
              subtitle: const Text('앱 사용법 가이드를 다시 볼 수 있어요'),
              trailing: const Icon(Icons.chevron_right_rounded),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onTap: () => TutorialScreen.openAgain(context),
            ),
          ),
          const SizedBox(height: 28),

          Text(
            '데이터 백업',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '기기에만 저장된 데이터를 JSON 파일로 보내거나, 같은 형식의 파일로 복원할 수 있어요.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          Consumer<RecordService>(
            builder: (context, records, _) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: () => _exportBackup(context, records),
                    icon: const Icon(Icons.upload_file_rounded),
                    label: const Text('백업 파일보내기'),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _importBackup(context, records),
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('백업에서 복원'),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _exportBackup(BuildContext context, RecordService records) async {
    final json = records.exportBackupJsonString();
    if (json == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('보내기에 실패했습니다.'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    final dir = await getTemporaryDirectory();
    final name =
        'chatbabytime_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
    final file = File('${dir.path}/$name');
    await file.writeAsString(json, encoding: utf8);
    if (!context.mounted) return;

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: '아기톡톡 백업',
        text: '아기톡톡 데이터 백업 파일입니다.',
      ),
    );
  }

  Future<void> _importBackup(BuildContext context, RecordService records) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['json'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final f = result.files.single;
    String? content;
    if (f.path != null) {
      content = await File(f.path!).readAsString(encoding: utf8);
    } else if (f.bytes != null) {
      content = utf8.decode(f.bytes!);
    }

    if (content == null || content.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('파일을 읽을 수 없습니다.'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    if (!context.mounted) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('데이터 복원'),
        content: const Text(
          '현재 기기의 모든 기록·프로필·성장 데이터가 백업 내용으로 바뀝니다. 계속할까요?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('복원')),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    final err = await records.importBackupFromJsonString(content);
    if (!context.mounted) return;

    if (err == null) {
      context.read<NotificationService>().rescheduleFeedingReminder();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('복원이 완료되었습니다.'),
          backgroundColor: AppTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}

