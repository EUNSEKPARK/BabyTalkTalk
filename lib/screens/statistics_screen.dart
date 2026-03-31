import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:chat_baby_time/utils/app_theme.dart';
import 'package:chat_baby_time/services/record_service.dart';
import 'package:chat_baby_time/models/baby_record.dart';

/// 통계 화면
/// stitch/statistics/code.html 디자인 참조
class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _selectedPeriod = 1; // 0: 일, 1: 주, 2: 월
  bool _showDiaperChart = false;

  final List<String> _periods = ['일', '주', '월'];

  /// 선택된 기간의 일 수 반환
  int _getDaysForPeriod(int period) {
    switch (period) {
      case 0:
        return 1; // 일
      case 1:
        return 7; // 주
      case 2:
        return 30; // 월
      default:
        return 7;
    }
  }

  /// 기간 시작/종료 날짜 계산
  (DateTime, DateTime) _getDateRange(int period) {
    final now = DateTime.now();
    final days = _getDaysForPeriod(period);
    final startDate = now.subtract(Duration(days: days - 1));
    return (startDate, now);
  }

  /// 기간 텍스트 포매팅
  String _formatDateRange(int period) {
    final (start, end) = _getDateRange(period);
    if (period == 0) {
      return DateFormat('M월 d일').format(end);
    } else {
      return '${DateFormat('M월 d일').format(start)} - ${DateFormat('d일').format(end)}';
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildControls(),
                    const SizedBox(height: 24),
                    _buildSectionHeader(),
                    const SizedBox(height: 24),
                    _buildFeedingTrendCard(context),
                    const SizedBox(height: 20),
                    _buildSleepDurationCard(context),
                    const SizedBox(height: 24),
                    _buildSummaryStats(context),
                    const SizedBox(height: 24),
                    if (_showDiaperChart) ...[
                      _buildDiaperTrendCard(context),
                      const SizedBox(height: 20),
                    ],
                    _buildAddGraphButton(),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Consumer<RecordService>(
        builder: (context, recordService, _) {
          final profile = recordService.profile;
          final ageText = profile != null
              ? '${profile.ageInMonths}개월 ${profile.ageInDays % 30}일 (D+${profile.ageInDays})'
              : '정보 없음';

          return Row(
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
              PopupMenuButton<String>(
                icon: Icon(Icons.more_horiz, color: AppTheme.primary),
                color: AppTheme.surfaceContainerHigh,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  switch (value) {
                    case 'reset_period':
                      setState(() => _selectedPeriod = 1);
                      break;
                    case 'export':
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('데이터 내보내기는 다음 업데이트에서 지원됩니다'),
                          backgroundColor: AppTheme.surfaceContainerHigh,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'reset_period',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, size: 18, color: AppTheme.onSurface),
                        SizedBox(width: 8),
                        Text('기간 초기화', style: TextStyle(color: AppTheme.onSurface)),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'export',
                    child: Row(
                      children: [
                        Icon(Icons.file_download_outlined, size: 18, color: AppTheme.onSurface),
                        SizedBox(width: 8),
                        Text('데이터 내보내기', style: TextStyle(color: AppTheme.onSurface)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Period selector
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: List.generate(_periods.length, (index) {
              final isSelected = _selectedPeriod == index;
              return GestureDetector(
                onTap: () => setState(() => _selectedPeriod = index),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.surfaceBright
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _periods[index],
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.primary
                          : AppTheme.onSurfaceVariant,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        // Date range
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: AppTheme.onSurfaceVariant,
                size: 14,
              ),
              const SizedBox(width: 8),
              Text(
                _formatDateRange(_selectedPeriod),
                style: TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader() {
    final now = DateTime.now();
    final monthYear = DateFormat('MMMM yyyy').format(now).toUpperCase();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              Icons.insights,
              color: AppTheme.tertiary,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              '그래프',
              style: TextStyle(
                color: AppTheme.tertiary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        Text(
          monthYear,
          style: TextStyle(
            color: AppTheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildFeedingTrendCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Consumer<RecordService>(
        builder: (context, recordService, _) {
          final days = _getDaysForPeriod(_selectedPeriod);
          final (startDate, endDate) = _getDateRange(_selectedPeriod);

          // 일일 수유량 계산
          final dailyFeedingMl = <DateTime, int>{};
          for (int i = 0; i < days; i++) {
            final date = startDate.add(Duration(days: i));
            final dayRecords = recordService.getRecordsForDate(date);
            final totalMl = dayRecords
                .where((r) =>
                    r.category == RecordCategory.feeding && r.amountMl != null)
                .fold(0, (sum, r) => sum + (r.amountMl ?? 0));
            dailyFeedingMl[date] = totalMl;
          }

          // 평균값 계산
          final totalMl =
              dailyFeedingMl.values.fold(0, (sum, ml) => sum + ml);
          final avgMl = days > 0 ? (totalMl / days).round() : 0;

          // 최대값 결정 (최소 500)
          final maxMl = dailyFeedingMl.values.isEmpty
              ? 1000
              : dailyFeedingMl.values.fold(0, (a, b) => a > b ? a : b);
          final chartMaxY = (maxMl * 1.2).toInt().toDouble();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DATA INSIGHT',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '수유량 추이',
                        style: TextStyle(
                          color: AppTheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        avgMl.toString(),
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ml avg',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildBarChart(dailyFeedingMl, chartMaxY, startDate, days),
              const SizedBox(height: 12),
              _buildBarChartLabels(startDate, days),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBarChart(
      Map<DateTime, int> dailyData, double maxY, DateTime startDate, int days) {
    final now = DateTime.now();
    final barGroups = <BarChartGroupData>[];

    // 30일(월간)일 때 바 너비를 줄여서 오버플로우 방지
    final barWidth = days > 7 ? 8.0 : 20.0;

    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final value = (dailyData[date] ?? 0).toDouble();
      final isToday = date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;

      barGroups.add(_buildBarGroup(i, value, isToday, maxY, barWidth: barWidth));
    }

    return SizedBox(
      height: 160,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceEvenly,
          maxY: maxY > 0 ? maxY : 100,
          barTouchData: BarTouchData(enabled: false),
          titlesData: FlTitlesData(show: false),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
        ),
      ),
    );
  }

  BarChartGroupData _buildBarGroup(
      int x, double y, bool isHighlighted, double maxY, {double barWidth = 20.0}) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: barWidth,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          gradient: isHighlighted
              ? LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppTheme.primaryContainer,
                    AppTheme.primary,
                  ],
                )
              : null,
          color: isHighlighted ? null : AppTheme.surfaceContainerHigh,
        ),
      ],
    );
  }

  Widget _buildBarChartLabels(DateTime startDate, int days) {
    final labels = <Widget>[];

    // 30일(월간)일 때는 5일 간격으로만 라벨 표시하여 오버플로우 방지
    final labelInterval = days > 7 ? 5 : 1;

    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final isToday = date.year == DateTime.now().year &&
          date.month == DateTime.now().month &&
          date.day == DateTime.now().day;

      if (days > 7 && (i % labelInterval != 0) && !isToday) {
        labels.add(const SizedBox(width: 8));
      } else {
        labels.add(_buildLabel(date.day.toString(), isToday));
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: labels,
    );
  }

  Widget _buildLabel(String text, bool isHighlighted) {
    return Text(
      text,
      style: TextStyle(
        color: isHighlighted ? AppTheme.primary : AppTheme.onSurfaceVariant,
        fontSize: 10,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildSleepDurationCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Consumer<RecordService>(
        builder: (context, recordService, _) {
          final days = _getDaysForPeriod(_selectedPeriod);
          final (startDate, endDate) = _getDateRange(_selectedPeriod);

          // 일일 수면 시간 계산
          final dailySleepHours = <DateTime, double>{};
          for (int i = 0; i < days; i++) {
            final date = startDate.add(Duration(days: i));
            final dayRecords = recordService.getRecordsForDate(date);

            // sleep start/end 쌍 찾기
            final sleepRecords = dayRecords
                .where((r) => r.category == RecordCategory.sleep)
                .toList();

            double totalMinutes = 0;
            for (int j = 0; j < sleepRecords.length; j += 2) {
              if (j + 1 < sleepRecords.length) {
                // start와 end 쌍
                final start = sleepRecords[j].timestamp;
                final end = sleepRecords[j + 1].timestamp;
                totalMinutes += end.difference(start).inMinutes.abs();
              }
            }

            dailySleepHours[date] = totalMinutes / 60;
          }

          // 평균값 계산
          final totalHours =
              dailySleepHours.values.fold(0.0, (sum, h) => sum + h);
          final avgHours = days > 0 ? totalHours / days : 0;

          // 최대값 결정
          final maxHours = dailySleepHours.values.isEmpty
              ? 14.0
              : dailySleepHours.values.fold(0.0, (a, b) => a > b ? a : b);
          final chartMaxY = (maxHours * 1.1).ceilToDouble();

          // LineChart 스팟 생성
          final spots = <FlSpot>[];
          for (int i = 0; i < days; i++) {
            final date = startDate.add(Duration(days: i));
            final hours = dailySleepHours[date] ?? 0.0;
            spots.add(FlSpot(i.toDouble(), hours));
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SLEEP CYCLE',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '수면 시간',
                        style: TextStyle(
                          color: AppTheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        avgHours.toStringAsFixed(1),
                        style: TextStyle(
                          color: AppTheme.tertiary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'hrs avg',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildLineChart(spots, chartMaxY, days),
              const SizedBox(height: 12),
              _buildLineChartLabels(days),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLineChart(List<FlSpot> spots, double maxY, int days) {
    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: AppTheme.onSurface.withOpacity(0.05),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (spots.length - 1).toDouble().clamp(0, (days - 1).toDouble()),
          minY: 0,
          maxY: maxY > 0 ? maxY : 14,
          lineBarsData: [
            LineChartBarData(
              spots: spots.isEmpty ? [FlSpot(0, 0)] : spots,
              isCurved: true,
              color: AppTheme.tertiary,
              barWidth: 2,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  // 마지막 점만 표시
                  final isLast = index == spots.length - 1;
                  return FlDotCirclePainter(
                    radius: isLast ? 4 : 0,
                    color: AppTheme.tertiary,
                    strokeWidth: 0,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.tertiary.withOpacity(0.2),
                    AppTheme.tertiary.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChartLabels(int days) {
    final dayLabels = ['월', '화', '수', '목', '금', '토', '일'];
    final now = DateTime.now();

    final labels = <Widget>[];
    // 30일(월간)일 때는 5일 간격으로 날짜 표시
    final labelInterval = days > 7 ? 5 : 1;

    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: days - 1 - i));

      if (days > 7) {
        // 월간 보기: 날짜(숫자) 표시, 5일 간격
        final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
        if (i % labelInterval == 0 || isToday) {
          labels.add(Text(
            date.day.toString(),
            style: TextStyle(
              color: isToday ? AppTheme.primary : AppTheme.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ));
        } else {
          labels.add(const SizedBox(width: 8));
        }
      } else {
        // 주간/일간 보기: 요일 표시
        final dayOfWeek = date.weekday - 1;
        labels.add(Text(
          dayLabels[dayOfWeek],
          style: TextStyle(
            color: AppTheme.onSurfaceVariant,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ));
      }
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: labels,
    );
  }

  Widget _buildSummaryStats(BuildContext context) {
    return Consumer<RecordService>(
      builder: (context, recordService, _) {
        final days = _getDaysForPeriod(_selectedPeriod);
        final (startDate, endDate) = _getDateRange(_selectedPeriod);

        // 총 수유 횟수
        int totalFeedingCount = 0;
        for (int i = 0; i < days; i++) {
          final date = startDate.add(Duration(days: i));
          final dayRecords = recordService.getRecordsForDate(date);
          totalFeedingCount += dayRecords
              .where((r) => r.category == RecordCategory.feeding)
              .length;
        }

        // 평균 취침 시각 계산
        String avgBedtime = '--:--';
        int totalSleepStartMinutes = 0;
        int sleepStartCount = 0;

        for (int i = 0; i < days; i++) {
          final date = startDate.add(Duration(days: i));
          final dayRecords = recordService.getRecordsForDate(date);
          final sleepStarts = dayRecords.where(
              (r) =>
                  r.category == RecordCategory.sleep &&
                  r.sleepStatus == SleepStatus.start);

          for (final record in sleepStarts) {
            final minutes = record.timestamp.hour * 60 + record.timestamp.minute;
            totalSleepStartMinutes += minutes;
            sleepStartCount++;
          }
        }

        if (sleepStartCount > 0) {
          final avgMinutes = totalSleepStartMinutes ~/ sleepStartCount;
          final hours = (avgMinutes ~/ 60) % 24;
          final minutes = avgMinutes % 60;
          avgBedtime =
              '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
        }

        // 지난 기간과 비교하여 트렌드 계산
        final prevStartDate =
            startDate.subtract(Duration(days: days));
        int prevFeedingCount = 0;
        for (int i = 0; i < days; i++) {
          final date = prevStartDate.add(Duration(days: i));
          final dayRecords = recordService.getRecordsForDate(date);
          prevFeedingCount += dayRecords
              .where((r) => r.category == RecordCategory.feeding)
              .length;
        }

        String trendText = '안정적인 패턴 유지 중';
        IconData? trendIcon;
        if (prevFeedingCount > 0) {
          final percentChange =
              ((totalFeedingCount - prevFeedingCount) / prevFeedingCount * 100)
                  .round();
          if (percentChange > 5) {
            trendText = '지난 기간 대비 ${percentChange}% 증가';
            trendIcon = Icons.trending_up;
          } else if (percentChange < -5) {
            trendText = '지난 기간 대비 ${percentChange}% 감소';
            trendIcon = Icons.trending_down;
          }
        }

        return Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.opacity,
                iconColor: AppTheme.primary,
                label: '총 수유 횟수',
                value: totalFeedingCount.toString(),
                unit: '회',
                trend: trendText,
                trendIcon: trendIcon,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                icon: Icons.bedtime,
                iconColor: AppTheme.tertiary,
                label: '평균 취침 시각',
                value: avgBedtime,
                unit: '',
                trend: '안정적인 패턴 유지 중',
                trendIcon: null,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String unit,
    required String trend,
    IconData? trendIcon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.surfaceBright,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: AppTheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (unit.isNotEmpty) ...
                [
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: TextStyle(
                      color: AppTheme.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (trendIcon != null) ...
                [
                  Icon(
                    trendIcon,
                    color: AppTheme.primary,
                    size: 12,
                  ),
                  const SizedBox(width: 4),
                ],
              Flexible(
                child: Text(
                  trend,
                  style: TextStyle(
                    color: trendIcon != null
                        ? AppTheme.primary
                        : AppTheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddGraphButton() {
    return GestureDetector(
      onTap: () {
        setState(() => _showDiaperChart = !_showDiaperChart);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: _showDiaperChart
              ? AppTheme.surfaceContainerHigh
              : AppTheme.surfaceContainer,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: _showDiaperChart
                ? AppTheme.tertiary.withOpacity(0.3)
                : AppTheme.outlineVariant,
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showDiaperChart ? Icons.remove_circle_outline : Icons.add_chart,
              color: _showDiaperChart ? AppTheme.tertiary : AppTheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(width: 8),
            Text(
              _showDiaperChart ? '추가 그래프 숨기기' : '＋ 기저귀 그래프 추가',
              style: TextStyle(
                color: _showDiaperChart ? AppTheme.tertiary : AppTheme.onSurfaceVariant,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiaperTrendCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Consumer<RecordService>(
        builder: (context, recordService, _) {
          final days = _getDaysForPeriod(_selectedPeriod);
          final (startDate, endDate) = _getDateRange(_selectedPeriod);

          final dailyDiaperCount = <DateTime, int>{};
          for (int i = 0; i < days; i++) {
            final date = startDate.add(Duration(days: i));
            final dayRecords = recordService.getRecordsForDate(date);
            dailyDiaperCount[date] = dayRecords
                .where((r) => r.category == RecordCategory.diaper)
                .length;
          }

          final totalCount =
              dailyDiaperCount.values.fold(0, (sum, c) => sum + c);
          final avgCount =
              days > 0 ? (totalCount / days).toStringAsFixed(1) : '0';

          final maxCount = dailyDiaperCount.values.isEmpty
              ? 10
              : dailyDiaperCount.values.fold(0, (a, b) => a > b ? a : b);
          final chartMaxY = (maxCount * 1.3).ceil().toDouble();

          final now = DateTime.now();
          final barGroups = <BarChartGroupData>[];
          final diaperBarWidth = days > 7 ? 8.0 : 20.0;
          for (int i = 0; i < days; i++) {
            final date = startDate.add(Duration(days: i));
            final count = (dailyDiaperCount[date] ?? 0).toDouble();
            final isToday = date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;
            barGroups.add(
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: count,
                    width: diaperBarWidth,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(8)),
                    gradient: isToday
                        ? const LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              AppTheme.primary,
                              Color(0xFFFFB5B5),
                            ],
                          )
                        : null,
                    color: isToday ? null : AppTheme.surfaceContainerHigh,
                  ),
                ],
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DIAPER LOG',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '기저귀 교체',
                        style: TextStyle(
                          color: AppTheme.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        avgCount,
                        style: TextStyle(
                          color: AppTheme.tertiary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '회 avg',
                        style: TextStyle(
                          color: AppTheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 160,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceEvenly,
                    maxY: chartMaxY > 0 ? chartMaxY : 10,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(show: false),
                    gridData: FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    barGroups: barGroups,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildBarChartLabels(startDate, days),
            ],
          );
        },
      ),
    );
  }
}
