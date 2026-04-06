import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/services/record_service.dart';
import 'package:chat_baby_time/services/family_service.dart';
import 'package:chat_baby_time/utils/app_theme.dart';

/// 데이케어/어린이집 모드 화면
class DaycareScreen extends StatelessWidget {
  const DaycareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('어린이집 모드'),
        backgroundColor: AppTheme.background,
      ),
      body: Consumer2<RecordService, FamilyService>(
        builder: (context, recordService, familyService, _) {
          final profile = recordService.profile;
          final isInFamily = familyService.isInFamily;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // 설명 카드
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.secondary.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Text('🏫', style: TextStyle(fontSize: 36)),
                    const SizedBox(height: 12),
                    Text('어린이집 모드', style: TextStyle(fontSize: 18,
                      fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                    const SizedBox(height: 8),
                    Text(
                      '선생님에게 초대 코드를 공유하면\n어린이집에서도 기록을 작성할 수 있어요.\n실시간으로 부모에게 알림이 전송됩니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 가족 그룹 상태
              if (!isInFamily) ...[
                // 가족 그룹 미생성 상태
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.group_add_outlined, size: 48, color: AppTheme.textHint),
                      const SizedBox(height: 12),
                      Text('가족 그룹이 없습니다', style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                      const SizedBox(height: 8),
                      Text('먼저 하단 설정 탭 > 가족 공유에서\n가족 그룹을 만들어주세요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              ] else ...[
                // 초대 코드 공유
                Text('선생님 초대하기', style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.w700, color: AppTheme.primary)),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      Text('초대 코드', style: TextStyle(fontSize: 13,
                        color: AppTheme.textSecondary)),
                      const SizedBox(height: 8),
                      Text(
                        familyService.familyGroup?.inviteCode ?? '------',
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary, letterSpacing: 6),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () {
                              final code = familyService.familyGroup?.inviteCode ?? '';
                              Clipboard.setData(ClipboardData(text: code));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('초대 코드가 복사되었어요'),
                                  backgroundColor: AppTheme.primary,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                ),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 16),
                            label: const Text('복사'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '이 코드를 어린이집 선생님에게 알려주세요.\n선생님이 앱을 설치하고 코드로 참여하면\n${profile?.name ?? '아기'}의 기록을 함께 관리할 수 있어요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.5),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // 오늘의 어린이집 기록
                Text('오늘의 기록', style: TextStyle(fontSize: 16,
                  fontWeight: FontWeight.w700, color: AppTheme.primary)),
                const SizedBox(height: 12),

                Builder(builder: (context) {
                  final myUid = familyService.uid;
                  final todayRecords = recordService.todayRecords;
                  final caregiverRecords = todayRecords
                      .where((r) => r.authorId != null && r.authorId != myUid)
                      .toList();
                  final myRecords = todayRecords
                      .where((r) => r.authorId == null || r.authorId == myUid)
                      .toList();

                  if (caregiverRecords.isEmpty && myRecords.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text('오늘 기록이 없습니다',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (caregiverRecords.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(children: [
                            Icon(Icons.school_outlined, size: 16, color: AppTheme.onSecondary),
                            const SizedBox(width: 6),
                            Text('선생님 기록 (${caregiverRecords.length}건)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                color: AppTheme.onSecondary)),
                          ]),
                        ),
                        ...caregiverRecords.map((r) => _RecordTile(record: r)),
                      ],
                      if (myRecords.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(children: [
                            Icon(Icons.person_outline, size: 16, color: AppTheme.primary),
                            const SizedBox(width: 6),
                            Text('내 기록 (${myRecords.length}건)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                color: AppTheme.primary)),
                          ]),
                        ),
                        ...myRecords.take(5).map((r) => _RecordTile(record: r)),
                      ],
                    ],
                  );
                }),
              ],

              const SizedBox(height: 80),
            ],
          );
        },
      ),
    );
  }
}

class _RecordTile extends StatelessWidget {
  final BabyRecord record;
  const _RecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Text(record.categoryEmoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.summary, style: TextStyle(fontSize: 13,
                    color: AppTheme.textPrimary)),
                  if (record.authorName != null)
                    Text('by ${record.authorName}', style: TextStyle(
                      fontSize: 10, color: AppTheme.textHint)),
                ],
              ),
            ),
            Text(DateFormat('HH:mm').format(record.timestamp),
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }
}
