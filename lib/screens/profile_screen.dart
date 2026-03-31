import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:chat_baby_time/utils/app_theme.dart';
import 'package:chat_baby_time/services/record_service.dart';
import 'package:chat_baby_time/screens/growth_report_screen.dart';
import 'package:chat_baby_time/screens/milestone_screen.dart';
import 'package:chat_baby_time/screens/growth_curve_screen.dart';
import 'package:chat_baby_time/screens/parenting_info_screen.dart';
import 'package:chat_baby_time/screens/growth_diary_screen.dart';
import 'package:chat_baby_time/screens/settings_screen.dart';
import 'package:chat_baby_time/widgets/growth_diary_cover_sheet.dart';
import 'package:chat_baby_time/widgets/growth_diary_thumbnail.dart';
import 'package:chat_baby_time/screens/tutorial_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Consumer<RecordService>(
        builder: (context, recordService, _) {
          final profile = recordService.profile;

          if (profile == null) {
            return Center(
              child: Text(
                '프로필이 없습니다',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              // Top spacing
              SliverToBoxAdapter(
                child: SizedBox(height: 16),
              ),

              // Baby Info Card (Asymmetric)
              SliverToBoxAdapter(
                child: _BabyInfoCard(profile: profile),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              // Feature Grid (2x2)
              SliverToBoxAdapter(
                child: _FeatureGrid(),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 32)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Material(
                    color: AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    child: ListTile(
                      leading: Icon(Icons.auto_stories_outlined, color: AppTheme.primary),
                      title: const Text('튜토리얼 다시 보기'),
                      subtitle: const Text('앱 사용법 가이드를 처음부터 볼 수 있어요'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onTap: () => TutorialScreen.openAgain(context),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Material(
                    color: AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    child: ListTile(
                      leading: Icon(Icons.notifications_active_outlined, color: AppTheme.primary),
                      title: const Text('알림 및 백업'),
                      subtitle: const Text('수유 알림 · JSON 백업/복원'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      ),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // Growth Diary Section
              SliverToBoxAdapter(
                child: _GrowthDiarySection(),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 40)),

              // Start Recording Button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _StartRecordingButton(),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 120)), // Space for bottom nav
            ],
          );
        },
      ),
    );
  }
}

/// Baby Info Card with asymmetric border radius
class _BabyInfoCard extends StatelessWidget {
  final dynamic profile;

  const _BabyInfoCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final ageInDays = profile.ageInDays;
    final weeks = ageInDays ~/ 7;
    final days = ageInDays % 7;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(48),
          bottomRight: Radius.circular(48),
          topRight: Radius.circular(32),
          bottomLeft: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // Background gradient blob
          Positioned(
            top: -32,
            right: -32,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.1),
                    blurRadius: 32,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
          ),
          // Content
          Row(
            children: [
              // Avatar
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primaryContainer.withOpacity(0.2),
                    width: 4,
                  ),
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/baby_avatar_default.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(width: 24),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Baby name
                    Text(
                      profile.name,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppTheme.onSurface,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                    ),
                    SizedBox(height: 8),
                    // Age info
                    Text(
                      'D+$ageInDays, ${weeks}주 $days일',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    SizedBox(height: 16),
                    // Manager chip
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.person,
                            size: 16,
                            color: AppTheme.primaryContainer,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '${profile.name} 관리 중',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: AppTheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ],
                      ),
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
}

/// Feature Grid with 2x2 layout
class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.count(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: [
          _FeatureCard(
            imagePath: 'assets/images/icon_growth.png',
            title: '성장 분석 보고서',
            subtitle: 'AI가 분석한 주간 리포트',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GrowthReportScreen())),
          ),
          _FeatureCard(
            imagePath: 'assets/images/milestone_celebration.png',
            title: '마일스톤',
            subtitle: '발달 단계 체크리스트',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MilestoneScreen())),
          ),
          _FeatureCard(
            imagePath: 'assets/images/growth_curve_header.png',
            title: '성장곡선',
            subtitle: '키·몸무게 표준 비교',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GrowthCurveScreen())),
          ),
          _FeatureCard(
            imagePath: 'assets/images/icon_medicine.png',
            title: '육아 정보',
            subtitle: '맞춤 가이드와 팁',
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ParentingInfoScreen())),
          ),
        ],
      ),
    );
  }
}

/// Individual feature card
class _FeatureCard extends StatefulWidget {
  final String imagePath;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FeatureCard({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _isHovered
                ? AppTheme.surfaceContainer
                : AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Image icon
              AnimatedScale(
                scale: _isHovered ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 200),
                child: ClipOval(
                  child: Image.asset(
                    widget.imagePath,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              // Text
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppTheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.onSurfaceVariant,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Growth Diary Section with horizontal scroll
class _GrowthDiarySection extends StatelessWidget {
  const _GrowthDiarySection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '최근 성장 일기',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GrowthDiaryScreen()),
                  );
                },
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  '전체보기',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.primaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        // Scrollable diary cards
        Consumer<RecordService>(
          builder: (context, recordService, _) {
            // Show recent dates that have records
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final recentDates = <DateTime>[];
            for (int i = 0; i < 14 && recentDates.length < 4; i++) {
              final date = today.subtract(Duration(days: i));
              final records = recordService.getRecordsForDate(date);
              if (records.isNotEmpty) {
                recentDates.add(date);
              }
            }

            if (recentDates.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/empty_diary.png',
                          width: 100,
                          height: 100,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '아직 기록이 없어요',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '첫 기록을 남겨보세요!',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: recentDates.map((date) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: _DiaryCard(date: date, recordService: recordService),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Individual diary photo card
class _DiaryCard extends StatelessWidget {
  final DateTime date;
  final RecordService recordService;

  const _DiaryCard({required this.date, required this.recordService});

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

    return SizedBox(
      width: 140,
      height: 175,
      child: Stack(
        fit: StackFit.expand,
        children: [
          GrowthDiaryThumbnail(
            date: date,
            width: 140,
            height: 175,
            borderRadius: 16,
            onTap: () => showGrowthDiaryCoverSheet(context, recordService, date),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            child: Text(
              dateLabel,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.6),
                        blurRadius: 4,
                      ),
                    ],
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width "Start Recording" button with gradient
class _StartRecordingButton extends StatefulWidget {
  const _StartRecordingButton();

  @override
  State<_StartRecordingButton> createState() => _StartRecordingButtonState();
}

class _StartRecordingButtonState extends State<_StartRecordingButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () {
        // Navigate to main screen's record tab (index 0)
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFFE0E0),
                AppTheme.primary,
              ],
            ),
            borderRadius: BorderRadius.circular(9999),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.2),
                blurRadius: 32,
                spreadRadius: 0,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.edit_note,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                '기록 시작하기',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
