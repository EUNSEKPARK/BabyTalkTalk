import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat_baby_time/services/record_service.dart';
import 'package:chat_baby_time/utils/app_theme.dart';
import 'package:chat_baby_time/utils/time_utils.dart';

/// 홈 화면 (타임라인/기록)
/// stitch/home/code.html 디자인 참조
class HomeScreenNew extends StatefulWidget {
  const HomeScreenNew({super.key});

  @override
  State<HomeScreenNew> createState() => _HomeScreenNewState();
}

class _HomeScreenNewState extends State<HomeScreenNew> {
  final List<Map<String, dynamic>> _categories = [
    {'icon': '🤱', 'label': '모유'},
    {'icon': '🍼', 'label': '분유'},
    {'icon': '🥣', 'label': '이유식'},
    {'icon': '🧷', 'label': '기저귀'},
    {'icon': '😴', 'label': '수면'},
    {'icon': '🤱', 'label': '유축'},
  ];

  @override
  Widget build(BuildContext context) {
    final service = context.watch<RecordService>();
    final records = service.getRecordsForDate(DateTime.now());

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(service),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildCategoryIconBar(),
                    const SizedBox(height: 32),
                    _buildLastRecordBento(),
                    const SizedBox(height: 32),
                    _buildQuickNoteBanner(),
                    const SizedBox(height: 32),
                    _buildTimelineSection(records),
                    const SizedBox(height: 150),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(RecordService service) {
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
                service.profile?.ageText ?? '13개월 18일 (D+411)',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.add, color: AppTheme.primary),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.more_horiz, color: AppTheme.primary),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryIconBar() {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 24),
        itemBuilder: (context, index) {
          final category = _categories[index];
          return Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceBright,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    category['icon'],
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category['label'],
                style: TextStyle(
                  color: AppTheme.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLastRecordBento() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.0,
      children: [
        _buildBentoCard(
          label: '마지막 기저귀',
          value: '10시간 24분전',
          subtitle: '(대변)',
        ),
        _buildBentoCard(
          label: '마지막 수유',
          value: '10시간 50분전',
          subtitle: '40시간 12분전',
          subtitleColor: AppTheme.tertiary,
        ),
        _buildBentoCard(
          label: '마지막 잠',
          value: '9시간 48분전',
          subtitle: '(낮잠)',
        ),
      ],
    );
  }

  Widget _buildBentoCard({
    required String label,
    required String value,
    String? subtitle,
    Color? subtitleColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: AppTheme.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: subtitleColor ?? AppTheme.onSurfaceVariant.withOpacity(0.7),
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickNoteBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerHigh.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border(
          left: BorderSide(
            color: AppTheme.primary,
            width: 4,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '퀵 노트 도움말...',
            style: TextStyle(
              color: AppTheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: AppTheme.onSurfaceVariant,
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineSection(List records) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${DateTime.now().month}월 ${DateTime.now().day}일 (${_getWeekday()}) 오늘',
              style: TextStyle(
                color: AppTheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '(160ml)',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildTimeline(),
        const SizedBox(height: 32),
        _buildYesterdaySection(),
      ],
    );
  }

  String _getWeekday() {
    final weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return weekdays[DateTime.now().weekday - 1];
  }

  Widget _buildTimeline() {
    final records = [
      {'time': '01:02 PM', 'icon': Icons.bedtime, 'color': AppTheme.secondary, 'text': '낮잠 0분', 'isRecent': true},
      {'time': '12:26 PM', 'icon': Icons.edit, 'color': AppTheme.tertiary, 'text': '대변 🟡', 'isRecent': false},
      {'time': '12:00 PM', 'icon': Icons.restaurant, 'color': AppTheme.primary, 'text': '이유식 160ml', 'subtitle': '(소고기, 비타민d)', 'isRecent': false},
    ];

    return Stack(
      children: [
        // Dotted vertical line
        Positioned(
          left: 7,
          top: 8,
          bottom: 8,
          child: CustomPaint(
            painter: DottedLinePainter(),
            size: const Size(2, double.infinity),
          ),
        ),
        // Timeline items
        Column(
          children: records.map((record) {
            final isRecent = record['isRecent'] as bool;
            return Padding(
              padding: const EdgeInsets.only(left: 24, bottom: 16),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Dot indicator
                  Positioned(
                    left: -21,
                    top: 20,
                    child: Container(
                      width: isRecent ? 16 : 12,
                      height: isRecent ? 16 : 12,
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
                  // Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Text(
                          record['time'] as String,
                          style: TextStyle(
                            color: AppTheme.onSurfaceVariant,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          record['icon'] as IconData,
                          color: record['color'] as Color,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                record['text'] as String,
                                style: TextStyle(
                                  color: AppTheme.onSurface,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (record.containsKey('subtitle')) ...[
                                const SizedBox(height: 2),
                                Text(
                                  record['subtitle'] as String,
                                  style: TextStyle(
                                    color: AppTheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildYesterdaySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${DateTime.now().month}월 ${DateTime.now().day - 1}일 (금) D+410',
          style: TextStyle(
            color: AppTheme.onSurface.withOpacity(0.6),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer.withOpacity(0.4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.outlineVariant.withOpacity(0.1),
            ),
          ),
          child: Center(
            child: Text(
              '어제 기록 요약 보기',
              style: TextStyle(
                color: AppTheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dotted line painter for timeline
class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.outlineVariant.withOpacity(0.3)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    const dashHeight = 4.0;
    const dashSpace = 4.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
