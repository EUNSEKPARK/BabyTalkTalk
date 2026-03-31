import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/services/record_service.dart';
import 'package:chat_baby_time/utils/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<RecordService>();
    final todayCounts = service.todayCategoryCounts;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '대시보드',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            // 오늘 요약 그리드
            _buildTodaySummaryGrid(service, todayCounts),
            const SizedBox(height: 24),

            // 주간 활동 차트
            const Text(
              '주간 활동',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildWeeklyChart(service),
            const SizedBox(height: 24),

            // 마지막 기록 타이머
            const Text(
              '마지막 기록',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            _buildLastRecordTimers(service),
          ],
        ),
      ),
    );
  }

  Widget _buildTodaySummaryGrid(
    RecordService service,
    Map<RecordCategory, int> counts,
  ) {
    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            emoji: '🍼',
            title: '수유',
            value: '${counts[RecordCategory.feeding] ?? 0}회',
            subtitle: '총 ${service.todayTotalFeedingMl}ml',
            color: AppTheme.feedingColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryTile(
            emoji: '😴',
            title: '수면',
            value: '${counts[RecordCategory.sleep] ?? 0}회',
            subtitle: '',
            color: AppTheme.sleepColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryTile(
            emoji: '🧷',
            title: '기저귀',
            value: '${service.todayDiaperCount}회',
            subtitle: '',
            color: AppTheme.diaperColor,
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyChart(RecordService service) {
    final stats = service.getWeeklyStats();
    final labels = stats.keys.toList();

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxY(stats),
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < labels.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        labels[value.toInt()],
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          barGroups: List.generate(labels.length, (i) {
            final day = stats[labels[i]]!;
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: (day[RecordCategory.feeding] ?? 0).toDouble(),
                  color: AppTheme.feedingColor,
                  width: 8,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
                BarChartRodData(
                  toY: (day[RecordCategory.sleep] ?? 0).toDouble(),
                  color: AppTheme.sleepColor,
                  width: 8,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
                BarChartRodData(
                  toY: (day[RecordCategory.diaper] ?? 0).toDouble(),
                  color: AppTheme.diaperColor,
                  width: 8,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  double _getMaxY(Map<String, Map<RecordCategory, int>> stats) {
    double max = 5;
    for (final day in stats.values) {
      for (final count in day.values) {
        if (count > max) max = count.toDouble();
      }
    }
    return max + 2;
  }

  Widget _buildLastRecordTimers(RecordService service) {
    return Column(
      children: [
        _LastRecordTile(
          emoji: '🍼',
          title: '마지막 수유',
          record: service.lastFeedingRecord,
          color: AppTheme.feedingColor,
        ),
        const SizedBox(height: 8),
        _LastRecordTile(
          emoji: '😴',
          title: '마지막 수면',
          record: service.lastSleepRecord,
          color: AppTheme.sleepColor,
        ),
        const SizedBox(height: 8),
        _LastRecordTile(
          emoji: '🧷',
          title: '마지막 기저귀',
          record: service.lastDiaperRecord,
          color: AppTheme.diaperColor,
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _SummaryTile({
    required this.emoji,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: color.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LastRecordTile extends StatelessWidget {
  final String emoji;
  final String title;
  final BabyRecord? record;
  final Color color;

  const _LastRecordTile({
    required this.emoji,
    required this.title,
    required this.record,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final elapsed = record != null
        ? _elapsedText(record!.timestamp)
        : '기록 없음';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (record != null)
                  Text(
                    record!.summary,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            elapsed,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _elapsedText(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}분 전';
    if (diff.inHours < 24) return '${diff.inHours}시간 전';
    return '${diff.inDays}일 전';
  }
}
