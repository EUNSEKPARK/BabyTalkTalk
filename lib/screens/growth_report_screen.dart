import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat_baby_time/utils/app_theme.dart';
import 'package:chat_baby_time/services/record_service.dart';
import 'package:chat_baby_time/models/baby_record.dart';

class GrowthReportScreen extends StatelessWidget {
  const GrowthReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('성장 분석 보고서'),
        backgroundColor: AppTheme.background,
      ),
      backgroundColor: AppTheme.background,
      body: Consumer<RecordService>(
        builder: (context, recordService, _) {
          final weeklyStats = recordService.getWeeklyStats(days: 7);

          int totalFeedingCount = 0;
          int totalFeedingMl = 0;
          int totalDiaperCount = 0;
          int totalSleepCount = 0;

          for (final dayStats in weeklyStats.values) {
            totalFeedingCount += dayStats[RecordCategory.feeding] ?? 0;
            totalDiaperCount += dayStats[RecordCategory.diaper] ?? 0;
            totalSleepCount += dayStats[RecordCategory.sleep] ?? 0;
          }

          final now = DateTime.now();
          final sevenDaysAgo = now.subtract(const Duration(days: 7));
          final recentRecords = recordService.records
              .where((r) => r.timestamp.isAfter(sevenDaysAgo) && r.category == RecordCategory.feeding)
              .toList();

          for (final record in recentRecords) {
            if (record.amountMl != null) {
              totalFeedingMl += record.amountMl!;
            }
          }

          final profile = recordService.profile;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Weekly Summary Card
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.primary.withOpacity(0.2),
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '최근 7일 요약',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SummaryItem(
                          icon: '🍼',
                          label: '수유',
                          value: '$totalFeedingCount회',
                          subtitle: '총 ${totalFeedingMl}ml',
                        ),
                        _SummaryItem(
                          icon: '🧷',
                          label: '기저귀',
                          value: '$totalDiaperCount회',
                        ),
                        _SummaryItem(
                          icon: '😴',
                          label: '수면',
                          value: '$totalSleepCount회',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // AI Analysis Section
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.tertiary.withOpacity(0.2),
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('📊', style: TextStyle(fontSize: 24)),
                        const SizedBox(width: 8),
                        Text(
                          'AI 분석',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.tertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildAnalysisText(
                      context,
                      totalFeedingCount,
                      totalFeedingMl,
                      totalDiaperCount,
                      totalSleepCount,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Baby Age Info
              if (profile != null)
                Container(
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${profile.name}의 나이',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        profile.ageText,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnalysisText(
    BuildContext context,
    int feedingCount,
    int feedingMl,
    int diaperCount,
    int sleepCount,
  ) {
    final analyses = <String>[];

    if (feedingCount >= 7 && feedingCount <= 12) {
      analyses.add('이번 주 수유 패턴이 안정적입니다');
    } else if (feedingCount > 12) {
      analyses.add('수유 횟수가 평소보다 많습니다. 아기의 건강 상태를 확인해주세요');
    }

    if (feedingMl >= 700 && feedingMl <= 1000) {
      analyses.add('수유량이 적정 범위 내입니다');
    } else if (feedingMl > 1000) {
      analyses.add('수유량이 충분합니다');
    } else if (feedingMl > 0 && feedingMl < 700) {
      analyses.add('수유량을 증가시킬 필요가 있을 수 있습니다');
    }

    if (diaperCount >= 5 && diaperCount <= 8) {
      analyses.add('기저귀 교체 횟수가 정상 범위입니다');
    } else if (diaperCount < 5 && diaperCount > 0) {
      analyses.add('기저귀 교체 횟수가 줄어든 것 같습니다');
    }

    if (sleepCount >= 4 && sleepCount <= 10) {
      analyses.add('수면 시간이 적절합니다');
    } else if (sleepCount < 4 && sleepCount > 0) {
      analyses.add('수면 시간이 부족해 보입니다');
    }

    if (analyses.isEmpty) {
      analyses.add('아직 기록된 데이터가 충분하지 않습니다. 계속 기록해주세요');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: analyses
          .map((text) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '•',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ))
          .toList(),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final String? subtitle;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: AppTheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
