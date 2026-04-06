import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:chat_baby_time/utils/app_theme.dart';
import 'package:chat_baby_time/services/record_service.dart';
import 'package:chat_baby_time/services/family_service.dart';
import 'package:chat_baby_time/services/widget_sync_service.dart';
import 'package:chat_baby_time/screens/growth_report_screen.dart';
import 'package:chat_baby_time/screens/milestone_screen.dart';
import 'package:chat_baby_time/screens/growth_curve_screen.dart';
import 'package:chat_baby_time/screens/parenting_info_screen.dart';
import 'package:chat_baby_time/screens/growth_diary_screen.dart';
import 'package:chat_baby_time/screens/settings_screen.dart';
import 'package:chat_baby_time/screens/family_screen.dart';
import 'package:chat_baby_time/screens/my_info_screen.dart';
import 'package:chat_baby_time/screens/lullaby_screen.dart';
import 'package:chat_baby_time/screens/timer_screen.dart';
import 'package:chat_baby_time/screens/vaccination_screen.dart';
import 'package:chat_baby_time/screens/sleep_prediction_screen.dart';
import 'package:chat_baby_time/screens/mom_health_screen.dart';
import 'package:chat_baby_time/screens/baby_food_guide_screen.dart';
import 'package:chat_baby_time/screens/daycare_screen.dart';
import 'package:chat_baby_time/screens/pdf_report_screen.dart';
import 'package:chat_baby_time/widgets/growth_diary_cover_sheet.dart';
import 'package:chat_baby_time/widgets/growth_diary_thumbnail.dart';
import 'package:chat_baby_time/screens/tutorial_screen.dart';
import 'package:chat_baby_time/models/baby_record.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static void _showShareSheet(BuildContext context, RecordService recordService) {
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
                  '공유하기',
                  style: TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),
                _buildShareTile(
                  icon: Icons.text_snippet_outlined,
                  label: '오늘 기록 요약 공유',
                  subtitle: '오늘의 수유·기저귀·수면 요약을 텍스트로 보냅니다',
                  onTap: () {
                    Navigator.pop(ctx);
                    _shareTodaySummary(context, recordService);
                  },
                ),
                const SizedBox(height: 12),
                _buildShareTile(
                  icon: Icons.table_chart_outlined,
                  label: '전체 기록 CSV 내보내기',
                  subtitle: '모든 기록을 CSV 파일로 저장합니다',
                  onTap: () {
                    Navigator.pop(ctx);
                    _shareAllCsv(context, recordService);
                  },
                ),
                const SizedBox(height: 12),
                _buildShareTile(
                  icon: Icons.backup_outlined,
                  label: 'JSON 백업 보내기',
                  subtitle: '전체 데이터를 백업 파일로 공유합니다',
                  onTap: () {
                    Navigator.pop(ctx);
                    _shareBackupJson(context, recordService);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Widget _buildShareTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
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
              Icon(Icons.chevron_right_rounded, color: AppTheme.onSurfaceVariant, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  static Future<void> _shareTodaySummary(
      BuildContext context, RecordService recordService) async {
    final profile = recordService.profile;
    final babyName = profile?.name ?? '아기';
    final now = DateTime.now();
    final dateStr = DateFormat('yyyy년 M월 d일').format(now);
    final today = recordService.todayRecords;

    final counts = recordService.todayCategoryCounts;
    final buffer = StringBuffer();
    buffer.writeln('📋 $babyName의 오늘 기록 ($dateStr)');
    buffer.writeln();
    buffer.writeln(
        '🍼 수유 ${counts[RecordCategory.feeding] ?? 0}회 · '
        '🧷 기저귀 ${counts[RecordCategory.diaper] ?? 0}회 · '
        '😴 수면 ${counts[RecordCategory.sleep] ?? 0}회');

    if (today.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('상세:');
      for (final r in today) {
        final time = DateFormat('HH:mm').format(r.timestamp);
        buffer.writeln('  $time ${r.categoryEmoji} ${r.summary}');
      }
    }

    final lastFeeding = recordService.lastFeedingRecord;
    if (lastFeeding != null) {
      final diff = now.difference(lastFeeding.timestamp);
      buffer.writeln();
      if (diff.inMinutes < 60) {
        buffer.writeln('⏱ 마지막 수유: ${diff.inMinutes}분 전');
      } else {
        buffer.writeln('⏱ 마지막 수유: ${diff.inHours}시간 ${diff.inMinutes % 60}분 전');
      }
    }

    buffer.writeln();
    buffer.writeln('— 아기톡톡 앱에서 기록');

    await SharePlus.instance.share(ShareParams(text: buffer.toString()));
  }

  static Future<void> _shareAllCsv(
      BuildContext context, RecordService recordService) async {
    final records = recordService.records;
    if (records.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('내보낼 기록이 없습니다'),
            backgroundColor: AppTheme.surfaceContainerHigh,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('날짜,시간,카테고리,요약,양(ml),시간(분),메모');
    for (final r in records) {
      final date = DateFormat('yyyy-MM-dd').format(r.timestamp);
      final time = DateFormat('HH:mm').format(r.timestamp);
      final cat = r.categoryName;
      final summary = r.summary.replaceAll(',', ' ');
      final memo = (r.memo ?? '').replaceAll(',', ' ');
      buffer.writeln(
          '$date,$time,$cat,$summary,${r.amountMl ?? ''},${r.durationMinutes ?? ''},$memo');
    }

    final dir = await getTemporaryDirectory();
    final fileName =
        '아기톡톡_전체기록_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(buffer.toString());

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: '아기톡톡 전체 기록 데이터',
      ),
    );
  }

  static Future<void> _shareBackupJson(
      BuildContext context, RecordService recordService) async {
    final json = recordService.exportBackupJsonString();
    if (json == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('백업 생성에 실패했습니다'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
      return;
    }

    final dir = await getTemporaryDirectory();
    final name =
        'chatbabytime_backup_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.json';
    final file = File('${dir.path}/$name');
    await file.writeAsString(json);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        subject: '아기톡톡 백업',
        text: '아기톡톡 데이터 백업 파일입니다.',
      ),
    );
  }

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

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // 도구 모음
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('도구 모음', style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.w700, color: AppTheme.primary)),
                      const SizedBox(height: 12),
                      _ToolsGrid(),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 24)),

              // 가족 공유 (설정 탭에서 바로 진입)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '가족 공유',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Consumer<FamilyService>(
                        builder: (context, familyService, _) {
                          final isInFamily = familyService.isInFamily;
                          final memberCount =
                              familyService.familyGroup?.members.length ?? 0;
                          return Material(
                            color: AppTheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(16),
                            child: ListTile(
                              leading: Icon(
                                isInFamily
                                    ? Icons.family_restroom
                                    : Icons.group_add_outlined,
                                color: isInFamily
                                    ? AppTheme.primary
                                    : AppTheme.onSurfaceVariant,
                              ),
                              title: Text(
                                  isInFamily ? '가족 공유 중' : '가족 공유 설정'),
                              subtitle: Text(
                                isInFamily
                                    ? '${memberCount}명이 함께 기록하고 있어요'
                                    : '초대 코드로 엄마·아빠가 함께 기록해요',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey[600]),
                              ),
                              trailing: const Icon(
                                  Icons.chevron_right_rounded),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const FamilyScreen()),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 20)),

              // 내 정보
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Material(
                    color: AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    child: ListTile(
                      leading: Icon(Icons.person_outline_rounded, color: AppTheme.primary),
                      title: const Text('내 정보'),
                      subtitle: Text(
                        '아이 관리 · 가족 역할 · ${recordService.allProfiles.length}명의 아이',
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MyInfoScreen()),
                      ),
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

              // 공유하기
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Material(
                    color: AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    child: ListTile(
                      leading: Icon(Icons.ios_share_rounded, color: AppTheme.primary),
                      title: const Text('공유하기'),
                      subtitle: const Text('오늘 기록 요약 · 데이터 내보내기'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onTap: () => _showShareSheet(context, recordService),
                    ),
                  ),
                ),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 12)),

              // 알림 및 백업
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

              // 홈 화면 위젯
              if (Platform.isAndroid) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 12)),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: _HomeWidgetCard(),
                  ),
                ),
              ],

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
    final profileCount = context.watch<RecordService>().allProfiles.length;

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
              GestureDetector(
                onTap: profileCount > 1
                    ? () => _showProfileSwitcher(context)
                    : null,
                child: Stack(
                  children: [
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
                    if (profileCount > 1)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppTheme.surfaceContainer, width: 2),
                          ),
                          child: Center(
                            child: Icon(
                              Icons.swap_horiz_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
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

  void _showProfileSwitcher(BuildContext context) {
    final recordService = context.read<RecordService>();
    final profiles = recordService.allProfiles;
    final activeId = recordService.activeProfileId;

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
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '아이 전환',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(height: 16),
                ...profiles.map((p) {
                  final isActive = p.profileId == activeId;
                  final genderEmoji = p.gender == 'M'
                      ? '👦'
                      : p.gender == 'F'
                          ? '👧'
                          : '👶';
                  return ListTile(
                    leading: Text(genderEmoji,
                        style: const TextStyle(fontSize: 24)),
                    title: Text(
                      p.name,
                      style: TextStyle(
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive
                            ? AppTheme.primary
                            : AppTheme.textPrimary,
                      ),
                    ),
                    subtitle: Text(p.ageText,
                        style: TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                    trailing: isActive
                        ? Icon(Icons.check_circle,
                            color: AppTheme.primary, size: 22)
                        : null,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    onTap: () {
                      Navigator.pop(ctx);
                      if (!isActive) {
                        recordService.switchProfile(p.profileId);
                      }
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
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

/// Tools grid for additional features
class _ToolsGrid extends StatelessWidget {
  const _ToolsGrid();

  @override
  Widget build(BuildContext context) {
    final tools = [
      _ToolItem(emoji: '⏱️', label: '타이머', subtitle: '수유·수면 실시간 측정',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TimerScreen()))),
      _ToolItem(emoji: '🎵', label: '자장가', subtitle: '백색소음·자장가',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LullabyScreen()))),
      _ToolItem(emoji: '💉', label: '예방접종', subtitle: '국가 접종 스케줄',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VaccinationScreen()))),
      _ToolItem(emoji: '🌙', label: '수면 예측', subtitle: '최적 수면 시간',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SleepPredictionScreen()))),
      _ToolItem(emoji: '👩‍⚕️', label: '엄마 건강', subtitle: '기분·수분·수면 기록',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MomHealthScreen()))),
      _ToolItem(emoji: '🥄', label: '이유식 가이드', subtitle: '단계별 식단 안내',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BabyFoodGuideScreen()))),
      _ToolItem(emoji: '🏫', label: '어린이집', subtitle: '선생님과 기록 공유',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DaycareScreen()))),
      _ToolItem(emoji: '📄', label: 'PDF 리포트', subtitle: '성장 보고서 내보내기',
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PdfReportScreen()))),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 8,
        childAspectRatio: 0.75,
      ),
      itemCount: tools.length,
      itemBuilder: (context, index) => tools[index],
    );
  }
}

class _ToolItem extends StatelessWidget {
  final String emoji;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  const _ToolItem({required this.emoji, required this.label, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary), textAlign: TextAlign.center),
          Text(subtitle, style: TextStyle(fontSize: 9, color: AppTheme.textSecondary),
            textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
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

/// 홈 화면 위젯 추가 카드
class _HomeWidgetCard extends StatefulWidget {
  const _HomeWidgetCard();

  @override
  State<_HomeWidgetCard> createState() => _HomeWidgetCardState();
}

class _HomeWidgetCardState extends State<_HomeWidgetCard> {
  bool? _pinSupported;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _checkPinSupport();
  }

  Future<void> _checkPinSupport() async {
    final ok = await BabyTimeHomeWidget.isPinSupported();
    if (mounted) setState(() => _pinSupported = ok);
  }

  Future<void> _onPin() async {
    setState(() => _busy = true);
    try {
      await BabyTimeHomeWidget.requestPin();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.widgets_outlined, color: AppTheme.primary, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '홈 화면 위젯',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '앱을 열지 않고 수유·기저귀·수면을 바로 기록해요',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '홈 화면 빈 곳을 길게 누른 뒤 「위젯」에서 아기톡톡을 찾아 추가하거나, 아래 버튼으로 바로 고정할 수 있어요.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                  ),
            ),
            if (_pinSupported == true) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _onPin,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_to_home_screen_rounded),
                  label: Text(_busy ? '요청 중…' : '홈 화면에 위젯 추가'),
                ),
              ),
            ],
          ],
        ),
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
