import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat_baby_time/utils/app_theme.dart';
import 'package:chat_baby_time/services/record_service.dart';

class MilestoneScreen extends StatefulWidget {
  const MilestoneScreen({super.key});

  @override
  State<MilestoneScreen> createState() => _MilestoneScreenState();
}

class _MilestoneScreenState extends State<MilestoneScreen> {

  static const Map<String, List<String>> milestonesData = {
    '0-3개월': [
      '고개 들기',
      '눈 초점 맞추기',
      '옹알이',
      '손가락 쥐기',
      '미소 짓기',
    ],
    '3-6개월': [
      '뒤집기',
      '물체 잡기',
      '앉기 (도움 받아)',
      '옹알이 발전',
      '음식에 관심',
    ],
    '6-9개월': [
      '앉기 (혼자)',
      '기어다니기',
      '물체 집어 던지기',
      '첫 이',
      '발음 연습',
    ],
    '9-12개월': [
      '일어서기 (도움 받아)',
      '걷기 (도움 받아)',
      '손가락으로 가리키기',
      '첫 단어',
      '박수치기',
      '손흔들기',
    ],
  };

  String _getCurrentAgeGroup(int ageInMonths) {
    if (ageInMonths < 3) return '0-3개월';
    if (ageInMonths < 6) return '3-6개월';
    if (ageInMonths < 9) return '6-9개월';
    return '9-12개월';
  }

  @override
  Widget build(BuildContext context) {
    final recordService = context.watch<RecordService>();
    final profile = recordService.profile;
    final currentAgeInMonths = profile?.ageInMonths ?? 0;
    final currentAgeGroup = _getCurrentAgeGroup(currentAgeInMonths);

    return Scaffold(
      appBar: AppBar(
        title: const Text('마일스톤'),
        backgroundColor: AppTheme.background,
      ),
      backgroundColor: AppTheme.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Current Age Info
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('👶', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '현재 발달 단계: $currentAgeGroup',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppTheme.primary,
                      ),
                    ),
                    if (profile != null)
                      Text(
                        profile.ageText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Milestones List
          ...milestonesData.entries.map((entry) {
            final ageGroup = entry.key;
            final milestones = entry.value;
            final isCurrentGroup = ageGroup == currentAgeGroup;
            // Count checked in this group
            final checkedCount = milestones.where((m) => recordService.isMilestoneChecked('$ageGroup-$m')).length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCurrentGroup
                        ? AppTheme.primary.withOpacity(0.15)
                        : AppTheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: isCurrentGroup
                        ? Border.all(color: AppTheme.primary.withOpacity(0.3))
                        : null,
                  ),
                  child: Row(
                    children: [
                      Text(
                        ageGroup,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: isCurrentGroup ? AppTheme.primary : AppTheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (isCurrentGroup)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '현재',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      const Spacer(),
                      Text(
                        '$checkedCount/${milestones.length}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: checkedCount == milestones.length
                              ? AppTheme.primary
                              : AppTheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Milestone Items
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.surfaceContainerHigh),
                  ),
                  child: Column(
                    children: milestones.asMap().entries.map((mEntry) {
                      final index = mEntry.key;
                      final milestone = mEntry.value;
                      final key = '$ageGroup-$milestone';
                      final isChecked = recordService.isMilestoneChecked(key);

                      return Column(
                        children: [
                          CheckboxListTile(
                            value: isChecked,
                            onChanged: (value) {
                              recordService.setMilestoneChecked(key, value ?? false);
                            },
                            title: Text(
                              milestone,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: isChecked ? AppTheme.onSurfaceVariant : AppTheme.onSurface,
                                decoration: isChecked ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            activeColor: AppTheme.primary,
                            checkColor: AppTheme.onPrimary,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            dense: true,
                          ),
                          if (index < milestones.length - 1)
                            Divider(
                              color: AppTheme.surfaceContainerHigh,
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          }),

          // Tip Card
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.onSurfaceVariant.withOpacity(0.2)),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '💡 팁',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppTheme.tertiary),
                ),
                const SizedBox(height: 8),
                Text(
                  '각 아기는 고유한 속도로 발달합니다. 개인차가 있으므로 참고만 하시기 바랍니다. 발달에 대한 우려사항이 있다면 의료진과 상담하세요.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
