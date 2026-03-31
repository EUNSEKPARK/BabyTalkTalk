import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/services/record_service.dart';
import 'package:chat_baby_time/utils/app_theme.dart';

/// 메인 화면 상단의 오늘 요약 카드 (미드저니 아이콘 버전)
class TodaySummaryCard extends StatelessWidget {
  const TodaySummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    final service = context.watch<RecordService>();
    final counts = service.todayCategoryCounts;

    final feedingCount = counts[RecordCategory.feeding] ?? 0;
    final sleepCount = counts[RecordCategory.sleep] ?? 0;
    final diaperCount = counts[RecordCategory.diaper] ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
        border: Border.all(
          color: AppTheme.primaryContainer.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppTheme.feedingBg,
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: Image.asset(
                  'assets/images/icon_bottle.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '오늘의 기록',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              if (service.todayTotalFeedingMl > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.feedingBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '총 ${service.todayTotalFeedingMl}ml',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.feedingColor,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  iconPath: 'assets/images/icon_bottle.png',
                  count: feedingCount,
                  label: '수유',
                  color: AppTheme.feedingColor,
                  bgColor: AppTheme.feedingBg,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  iconPath: 'assets/images/icon_sleep.png',
                  count: sleepCount,
                  label: '수면',
                  color: AppTheme.sleepColor,
                  bgColor: AppTheme.sleepBg,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  iconPath: 'assets/images/icon_diaper.png',
                  count: diaperCount,
                  label: '기저귀',
                  color: AppTheme.diaperColor,
                  bgColor: AppTheme.diaperBg,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String iconPath;
  final int count;
  final String label;
  final Color color;
  final Color bgColor;

  const _MiniStat({
    required this.iconPath,
    required this.count,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          ClipOval(
            child: Image.asset(
              iconPath,
              width: 32,
              height: 32,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$count회',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
