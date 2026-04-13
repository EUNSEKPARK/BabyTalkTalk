import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart' show rootBundle;

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

          // ── 앱 정보 ──
          Text(
            '앱 정보',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Card(
            color: AppTheme.surfaceContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppTheme.primary),
                  title: const Text('개인정보처리방침'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  onTap: () => _showPrivacyPolicy(context),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: AppTheme.primary),
                  title: const Text('앱 버전'),
                  subtitle: const Text('1.0.0'),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
              ],
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

  void _showPrivacyPolicy(BuildContext context) {
    // TODO: 웹 호스팅 URL 확보 후 launchUrl로 변경
    // 현재는 앱 내 다이얼로그로 표시
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('개인정보처리방침'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  '아기톡톡 (ChatBabyTime)\n시행일: 2026년 4월 1일\n개발자: PARK EUN (pes1228@gmail.com)\n',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '1. 수집하는 개인정보 항목\n\n'
                  '1-1. 기기 내 저장 (로컬 전용)\n'
                  '아기 이름, 생년월일, 성별, 출생 체중/신장, 육아 기록, 성장 일기, 앱 설정 등은 '
                  '사용자의 기기에만 저장되며 외부 서버로 전송되지 않습니다.\n\n'
                  '1-2. 선택적 수집 (사용자 동의 시)\n'
                  '익명화된 텍스트 입력·인식 결과·수정 내역을 자연어 인식 정확도 개선 목적으로 '
                  'Firebase Firestore에 저장합니다. 앱 최초 실행 시 동의 팝업을 통해 동의한 경우에만 '
                  '수집되며, 설정에서 언제든 중단할 수 있습니다.\n\n'
                  '2. 접근 권한\n'
                  '• 마이크: 음성 입력 (선택)\n'
                  '• 인터넷: Firebase 동기화 (필수)\n'
                  '• 알림: 수유 리마인더 (선택)\n'
                  '• 사진: 일기 표지 이미지 (선택)\n\n'
                  '3. 개인정보의 보관 및 파기\n'
                  '로컬 데이터는 앱 삭제 시 완전 삭제됩니다. 수집 동의 데이터는 익명화 상태로 저장되며, '
                  '목적 달성 후 파기합니다. 설정에서 데이터 초기화가 가능합니다.\n\n'
                  '4. 제3자 제공\n'
                  '개인정보를 제3자에게 제공하지 않습니다.\n\n'
                  '5. 아동 개인정보 보호\n'
                  '아기톡톡은 부모(보호자)용 도구이며, 아동이 직접 사용하도록 설계되지 않았습니다.\n\n'
                  '문의: pes1228@gmail.com',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('닫기'),
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

