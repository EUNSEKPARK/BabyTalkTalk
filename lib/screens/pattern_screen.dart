import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:chat_baby_time/services/record_service.dart';
import 'package:chat_baby_time/models/baby_record.dart';
import 'package:chat_baby_time/utils/time_utils.dart';
import 'package:chat_baby_time/utils/app_theme.dart';
import 'package:intl/intl.dart';

/// 간격 패턴 화면
/// stitch/pattern/code.html 디자인 참조
class PatternScreen extends StatefulWidget {
  const PatternScreen({super.key});

  @override
  State<PatternScreen> createState() => _PatternScreenState();
}

class _PatternScreenState extends State<PatternScreen> {
  int _selectedTabIndex = 2; // 간격 패턴이 기본 선택
  String _selectedCategory = '분유';

  final List<String> _tabs = ['일과표', '주간 패턴', '간격 패턴'];
  final List<Map<String, dynamic>> _categories = [
    {'icon': Icons.local_drink, 'label': '분유', 'image': 'assets/images/icon_bottle.png'},
    {'icon': Icons.child_care, 'label': '모유', 'image': 'assets/images/icon_breastfeeding.png'},
    {'icon': Icons.restaurant, 'label': '이유식', 'image': 'assets/images/icon_babyfood.png'},
    {'icon': Icons.cookie, 'label': '간식', 'image': 'assets/images/icon_snack.png'},
    {'icon': Icons.bedtime, 'label': '수면', 'image': 'assets/images/icon_sleep.png'},
    {'icon': Icons.opacity, 'label': '배변', 'image': 'assets/images/icon_diaper.png'},
    {'icon': Icons.medical_services, 'label': '투약', 'image': 'assets/images/icon_medicine.png'},
    {'icon': Icons.shower, 'label': '목욕', 'image': 'assets/images/icon_bath.png'},
  ];

  /// 카테고리 라벨을 RecordCategory로 변환
  RecordCategory _getLabelCategory(String label) {
    switch (label) {
      case '분유':
        return RecordCategory.feeding;
      case '모유':
        return RecordCategory.feeding;
      case '이유식':
        return RecordCategory.babyfood;
      case '간식':
        return RecordCategory.snack;
      case '투약':
        return RecordCategory.health;
      case '수면':
        return RecordCategory.sleep;
      case '배변':
        return RecordCategory.diaper;
      case '목욕':
        return RecordCategory.other;
      default:
        return RecordCategory.feeding;
    }
  }

  /// 선택된 카테고리의 기록들을 필터링
  List<BabyRecord> _getFilteredRecords(List<BabyRecord> allRecords) {
    final category = _getLabelCategory(_selectedCategory);
    // 분유/모유는 같은 RecordCategory.feeding이지만 FeedingType으로 구분
    if (_selectedCategory == '분유') {
      return allRecords.where((r) =>
        r.category == RecordCategory.feeding &&
        r.feedingType == FeedingType.formula).toList();
    } else if (_selectedCategory == '모유') {
      return allRecords.where((r) =>
        r.category == RecordCategory.feeding &&
        r.feedingType == FeedingType.breast).toList();
    }
    return allRecords.where((r) => r.category == category).toList();
  }

  /// 간격을 계산하는 헬퍼 함수
  String _formatInterval(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    if (days > 0) {
      return '$days일 ${hours}시간';
    } else if (hours > 0) {
      return '$hours시간 ${minutes}분';
    } else {
      return '${minutes}분';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildTabNavigation(),
                    const SizedBox(height: 24),
                    _buildCategoryFilter(),
                    const SizedBox(height: 24),
                    _buildContentForTab(context),
                    const SizedBox(height: 16),
                    _buildInsightCard(context),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Consumer<RecordService>(
      builder: (context, recordService, _) {
        final profile = recordService.profile;
        String ageText = '아기톡톡';

        if (profile != null) {
          final daysInCurrentMonth = profile.ageInDays % 30;
          ageText = '${profile.ageInMonths}개월 $daysInCurrentMonth일 (D+${profile.ageInDays})';
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.music_note,
                    color: AppTheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    ageText,
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.ios_share_rounded, color: AppTheme.primary),
                onPressed: () => _showShareSheet(context, recordService),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTabNavigation() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(_tabs.length, (index) {
          final isSelected = _selectedTabIndex == index;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTabIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.surfaceContainerHigh
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _tabs[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['label'];
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = category['label']),
              child: Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primaryContainer
                          : AppTheme.surfaceContainerHigh,
                      shape: BoxShape.circle,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.primary.withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(
                        category['image'],
                        width: 28,
                        height: 28,
                        errorBuilder: (_, __, ___) => Icon(
                          category['icon'],
                          color: isSelected
                              ? AppTheme.onPrimaryContainer
                              : AppTheme.onSurfaceVariant,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category['label'],
                    style: TextStyle(
                      color: isSelected ? AppTheme.primary : AppTheme.onSurfaceVariant,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentForTab(BuildContext context) {
    return Consumer<RecordService>(
      builder: (context, recordService, _) {
        if (_selectedTabIndex == 0) {
          // 일과표 - Today's all records as timeline
          return _buildDailyTimeline(recordService.todayRecords);
        } else if (_selectedTabIndex == 1) {
          // 주간 패턴 - Last 7 days grouped by day
          return _buildWeeklyPattern(recordService);
        } else {
          // 간격 패턴 - Intervals between same category records
          final filtered = _getFilteredRecords(recordService.records);
          return _buildIntervalTimeline(filtered);
        }
      },
    );
  }

  /// 일과표: 오늘 모든 기록을 시간순으로 표시
  Widget _buildDailyTimeline(List<BabyRecord> todayRecords) {
    if (todayRecords.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/empty_records.png',
                  width: 140,
                  height: 140,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '오늘 기록이 없습니다',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Sort by timestamp, newest first
    final sorted = List<BabyRecord>.from(todayRecords)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return Stack(
      children: [
        // Vertical gradient line
        Positioned(
          left: 24,
          top: 32,
          bottom: 0,
          child: Opacity(
            opacity: 0.2,
            child: Container(
              width: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primary,
                    AppTheme.surfaceVariant,
                    AppTheme.surfaceContainerLowest,
                  ],
                ),
              ),
            ),
          ),
        ),
        Column(
          children: List.generate(sorted.length, (index) {
            return _buildDailyRecordItem(sorted[index], index == 0);
          }),
        ),
      ],
    );
  }

  Widget _buildDailyRecordItem(BabyRecord record, bool isRecent) {
    return Padding(
      padding: const EdgeInsets.only(left: 56, bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          // Record card
          Stack(
            children: [
              // Pulse orb indicator
              Positioned(
                left: -37,
                top: 20,
                child: Container(
                  width: isRecent ? 12 : 8,
                  height: isRecent ? 12 : 8,
                  decoration: BoxDecoration(
                    color: isRecent ? AppTheme.primary : AppTheme.surfaceVariant,
                    shape: BoxShape.circle,
                    boxShadow: isRecent
                        ? [
                            BoxShadow(
                              color: AppTheme.primary,
                              blurRadius: 12,
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
              // Card content
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isRecent
                      ? AppTheme.surfaceContainer.withOpacity(0.7)
                      : AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: isRecent
                      ? Border.all(
                          color: Colors.white.withOpacity(0.05),
                        )
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      TimeUtils.formatTime(record.timestamp),
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          record.categoryEmoji,
                          style: const TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            record.summary,
                            style: TextStyle(
                              color: isRecent
                                  ? AppTheme.onSurface
                                  : AppTheme.onSurface.withOpacity(0.8),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 주간 패턴: 지난 7일간의 기록을 요일별로 그룹화
  Widget _buildWeeklyPattern(RecordService recordService) {
    final now = DateTime.now();
    final days = <DateTime, List<BabyRecord>>{};

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      days[date] = recordService.getRecordsForDate(date);
    }

    return Column(
      children: days.entries.map((entry) {
        final date = entry.key;
        final records = entry.value;
        final dayName = DateFormat('E', 'ko_KR').format(date);
        final dateStr = '${date.month}/${date.day}';

        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$dateStr ($dayName)',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              if (records.isEmpty)
                Text(
                  '기록 없음',
                  style: TextStyle(
                    color: AppTheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: List.generate(records.length, (index) {
                      final record = records[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < records.length - 1 ? 8 : 0,
                        ),
                        child: Row(
                          children: [
                            Text(
                              record.categoryEmoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                record.summary,
                                style: TextStyle(
                                  color: AppTheme.onSurface,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            Text(
                              TimeUtils.formatTime(record.timestamp),
                              style: TextStyle(
                                color: AppTheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 간격 패턴: 같은 카테고리 기록들 사이의 간격을 표시
  Widget _buildIntervalTimeline(List<BabyRecord> filteredRecords) {
    if (filteredRecords.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/empty_stats.png',
                  width: 140,
                  height: 140,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$_selectedCategory 기록이 없습니다',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Build intervals
    final items = <Map<String, dynamic>>[];
    for (int i = 0; i < filteredRecords.length; i++) {
      final current = filteredRecords[i];
      String? interval;

      if (i < filteredRecords.length - 1) {
        final next = filteredRecords[i + 1];
        final duration = current.timestamp.difference(next.timestamp);
        interval = _formatInterval(duration);
      }

      items.add({
        'record': current,
        'interval': interval,
        'isRecent': i == 0,
      });
    }

    return Stack(
      children: [
        // Vertical gradient line
        Positioned(
          left: 24,
          top: 32,
          bottom: 0,
          child: Opacity(
            opacity: 0.2,
            child: Container(
              width: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.primary,
                    AppTheme.surfaceVariant,
                    AppTheme.surfaceContainerLowest,
                  ],
                ),
              ),
            ),
          ),
        ),
        // Records
        Column(
          children: List.generate(items.length, (index) {
            return _buildIntervalRecordItem(items[index]);
          }),
        ),
      ],
    );
  }

  Widget _buildIntervalRecordItem(Map<String, dynamic> item) {
    final record = item['record'] as BabyRecord;
    final interval = item['interval'] as String?;
    final isRecent = item['isRecent'] as bool;

    return Padding(
      padding: const EdgeInsets.only(left: 56, bottom: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Interval badge (if not the last one)
          if (interval != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isRecent
                    ? AppTheme.primaryContainer.withOpacity(0.2)
                    : AppTheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                interval,
                style: TextStyle(
                  color: isRecent ? AppTheme.primary : AppTheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          // Record card
          Stack(
            children: [
              // Pulse orb indicator
              Positioned(
                left: -37,
                top: 20,
                child: Container(
                  width: isRecent ? 12 : 8,
                  height: isRecent ? 12 : 8,
                  decoration: BoxDecoration(
                    color: isRecent ? AppTheme.primary : AppTheme.surfaceVariant,
                    shape: BoxShape.circle,
                    boxShadow: isRecent
                        ? [
                            BoxShadow(
                              color: AppTheme.primary,
                              blurRadius: 12,
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
              // Card content
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isRecent
                      ? AppTheme.surfaceContainer.withOpacity(0.7)
                      : AppTheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: isRecent
                      ? Border.all(
                          color: Colors.white.withOpacity(0.05),
                        )
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            TimeUtils.formatTime(record.timestamp),
                            style: TextStyle(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: isRecent
                                      ? AppTheme.primary
                                      : AppTheme.surfaceVariant,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  record.summary,
                                  style: TextStyle(
                                    color: isRecent
                                        ? AppTheme.onSurface
                                        : AppTheme.onSurface.withOpacity(0.8),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Amount display (if available)
                    if (record.amountMl != null)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            record.amountMl.toString(),
                            style: TextStyle(
                              color: isRecent
                                  ? AppTheme.primary
                                  : AppTheme.onSurfaceVariant,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'ml',
                            style: TextStyle(
                              color: AppTheme.onSurfaceVariant,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // 공유하기
  // ─────────────────────────────────────────

  void _showShareSheet(BuildContext context, RecordService recordService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 핸들 바
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '패턴 공유하기',
                  style: TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                // 텍스트 요약 공유
                _ShareOption(
                  icon: Icons.text_snippet_outlined,
                  label: '텍스트로 공유',
                  subtitle: '오늘 요약을 텍스트로 공유합니다',
                  onTap: () {
                    Navigator.pop(ctx);
                    _shareAsText(context, recordService);
                  },
                ),
                const SizedBox(height: 12),
                // CSV 내보내기
                _ShareOption(
                  icon: Icons.table_chart_outlined,
                  label: 'CSV 파일로 내보내기',
                  subtitle: '선택한 카테고리의 기록을 CSV로 저장합니다',
                  onTap: () {
                    Navigator.pop(ctx);
                    _shareAsCsv(context, recordService);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _shareAsText(
      BuildContext context, RecordService recordService) async {
    final profile = recordService.profile;
    final babyName = profile?.name ?? '아기';
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy년 M월 d일').format(now);

    final filtered = _getFilteredRecords(recordService.records);
    final todayFiltered = filtered
        .where((r) =>
            r.timestamp.year == now.year &&
            r.timestamp.month == now.month &&
            r.timestamp.day == now.day)
        .toList();

    final buffer = StringBuffer();
    buffer.writeln('📊 $babyName의 $_selectedCategory 패턴 ($dateStr)');
    buffer.writeln();

    if (todayFiltered.isEmpty) {
      buffer.writeln('오늘 $_selectedCategory 기록이 없습니다.');
    } else {
      buffer.writeln('오늘 $_selectedCategory ${todayFiltered.length}건:');
      for (final r in todayFiltered) {
        buffer.writeln(
            '  • ${TimeUtils.formatTime(r.timestamp)} — ${r.summary}');
      }
    }

    // 평균 간격 추가
    if (filtered.length > 1) {
      Duration total = Duration.zero;
      int count = 0;
      for (int i = 0; i < filtered.length - 1 && i < 10; i++) {
        final diff =
            filtered[i].timestamp.difference(filtered[i + 1].timestamp);
        if (!diff.isNegative) {
          total += diff;
          count++;
        }
      }
      if (count > 0) {
        final avg = total ~/ count;
        buffer.writeln();
        buffer.writeln(
            '⏱ 평균 간격: ${avg.inHours}시간 ${avg.inMinutes % 60}분');
      }
    }

    buffer.writeln();
    buffer.writeln('— 아기톡톡 앱에서 기록');

    await SharePlus.instance.share(
      ShareParams(text: buffer.toString()),
    );
  }

  Future<void> _shareAsCsv(
      BuildContext context, RecordService recordService) async {
    final filtered = _getFilteredRecords(recordService.records);
    if (filtered.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_selectedCategory 기록이 없습니다'),
            backgroundColor: AppTheme.surfaceContainerHigh,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('날짜,시간,카테고리,요약,양(ml),시간(분)');
    for (final r in filtered) {
      final date = DateFormat('yyyy-MM-dd').format(r.timestamp);
      final time = DateFormat('HH:mm').format(r.timestamp);
      final summary = r.summary.replaceAll(',', ' ');
      buffer.writeln(
          '$date,$time,$_selectedCategory,$summary,${r.amountMl ?? ''},${r.durationMinutes ?? ''}');
    }

    final dir = await getTemporaryDirectory();
    final fileName =
        '패턴_${_selectedCategory}_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(buffer.toString());

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: '아기톡톡 $_selectedCategory 패턴 데이터',
      ),
    );
  }

  Widget _buildInsightCard(BuildContext context) {
    return Consumer<RecordService>(
      builder: (context, recordService, _) {
        final filtered = _getFilteredRecords(recordService.records);
        String insightMessage = '';

        if (filtered.length > 1) {
          // Calculate average interval
          Duration totalDuration = Duration.zero;
          int intervalCount = 0;
          for (int i = 0; i < filtered.length - 1; i++) {
            final diff = filtered[i].timestamp.difference(filtered[i + 1].timestamp);
            if (!diff.isNegative) {
              totalDuration += diff;
              intervalCount++;
            }
          }
          // Safe division: avoid divide by zero
          final avgDuration = intervalCount > 0
              ? totalDuration ~/ intervalCount
              : Duration.zero;
          final avgHours = avgDuration.inHours;
          final avgMinutes = avgDuration.inMinutes % 60;

          insightMessage = '$_selectedCategory 평균 간격은 ${avgHours}시간 ${avgMinutes}분입니다. ';

          // Add some dynamic insight based on category
          switch (_getLabelCategory(_selectedCategory)) {
            case RecordCategory.feeding:
              if (avgHours >= 3) {
                insightMessage += '규칙적인 식사 패턴이 형성되고 있습니다.';
              } else {
                insightMessage += '아직 식사 간격이 불규칙합니다.';
              }
              break;
            case RecordCategory.sleep:
              insightMessage += '수면 패턴을 모니터링 중입니다.';
              break;
            case RecordCategory.diaper:
              insightMessage += '배변 패턴을 기록하고 있습니다.';
              break;
            case RecordCategory.health:
              insightMessage += '건강 상태를 관찰 중입니다.';
              break;
            case RecordCategory.other:
              insightMessage += '기타 활동을 기록 중입니다.';
              break;
            default:
              insightMessage += '이 카테고리를 계속 모니터링하세요.';
          }
        } else {
          insightMessage = '더 많은 $_selectedCategory 기록이 필요합니다. 계속 기록해주세요!';
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.tertiaryContainer.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.tertiary.withOpacity(0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.tips_and_updates,
                color: AppTheme.tertiary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '간격 알림',
                      style: TextStyle(
                        color: AppTheme.tertiary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      insightMessage,
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 공유 옵션 아이템 위젯
class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppTheme.primary, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
