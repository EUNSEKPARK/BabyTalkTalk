import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chat_baby_time/utils/app_theme.dart';
import 'package:chat_baby_time/services/record_service.dart';
import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/screens/record_detail_screen.dart';
import 'package:chat_baby_time/widgets/growth_diary_cover_sheet.dart';
import 'package:chat_baby_time/widgets/growth_diary_thumbnail.dart';

/// 성장 일기 전체보기 화면
class GrowthDiaryScreen extends StatelessWidget {
  const GrowthDiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final recordService = context.watch<RecordService>();

    // 최근 30일간 기록을 날짜별로 그룹핑
    final now = DateTime.now();
    final groupedRecords = <DateTime, List<BabyRecord>>{};

    for (int i = 0; i < 30; i++) {
      final date = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
      final records = recordService.getRecordsForDate(date);
      if (records.isNotEmpty) {
        groupedRecords[date] = records;
      }
    }

    final sortedDates = groupedRecords.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('성장 일기'),
        backgroundColor: AppTheme.background,
      ),
      backgroundColor: AppTheme.background,
      body: sortedDates.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/empty_diary.png',
                        width: 200,
                        height: 200,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '아직 성장일기가 없어요',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '기록을 시작하면 자동으로 일기가 만들어져요',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppTheme.textHint, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedDates.length,
              itemBuilder: (context, index) {
                final date = sortedDates[index];
                final records = groupedRecords[date]!;
                return _buildDayCard(context, date, records, recordService);
              },
            ),
    );
  }

  Widget _buildDayCard(
    BuildContext context,
    DateTime date,
    List<BabyRecord> records,
    RecordService recordService,
  ) {
    final profile = recordService.profile;
    final dPlus = profile != null
        ? 'D+${date.difference(profile.birthDate).inDays}'
        : '';

    // 일간 통계
    final feedingCount = records.where((r) => r.category == RecordCategory.feeding).length;
    final sleepCount = records.where((r) => r.category == RecordCategory.sleep).length;
    final diaperCount = records.where((r) => r.category == RecordCategory.diaper).length;
    final totalMl = records
        .where((r) => r.category == RecordCategory.feeding && r.amountMl != null)
        .fold<int>(0, (sum, r) => sum + r.amountMl!);

    final isToday = date.year == DateTime.now().year &&
        date.month == DateTime.now().month &&
        date.day == DateTime.now().day;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: isToday
            ? Border.all(color: AppTheme.primary.withOpacity(0.3), width: 1)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 날짜 헤더
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerHigh,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GrowthDiaryThumbnail(
                  date: date,
                  width: 52,
                  height: 64,
                  borderRadius: 12,
                  onTap: () =>
                      showGrowthDiaryCoverSheet(context, recordService, date),
                ),
                const SizedBox(width: 12),
                if (isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '오늘',
                      style: TextStyle(color: AppTheme.primary, fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                  ),
                Expanded(
                  child: Text(
                    DateFormat('M월 d일 (E)', 'ko_KR').format(date),
                    style: const TextStyle(
                      color: AppTheme.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (dPlus.isNotEmpty)
                  Text(
                    dPlus,
                    style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11),
                  ),
                const SizedBox(width: 8),
                Text(
                  '${records.length}건',
                  style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),

          // 일간 요약 칩
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (feedingCount > 0)
                  _buildSummaryChip(
                    '🍼 수유 $feedingCount회${totalMl > 0 ? ' (${totalMl}ml)' : ''}',
                  ),
                if (sleepCount > 0)
                  _buildSummaryChip('😴 수면 $sleepCount회'),
                if (diaperCount > 0)
                  _buildSummaryChip('🧷 기저귀 $diaperCount회'),
              ],
            ),
          ),

          // 개별 기록
          ...records.map((record) => InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecordDetailScreen(record: record),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48,
                        child: Text(
                          DateFormat('HH:mm').format(record.timestamp),
                          style: const TextStyle(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(record.categoryEmoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          record.summary,
                          style: const TextStyle(color: AppTheme.onSurface, fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: AppTheme.onSurfaceVariant,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.onSurface,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
