import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:chat_baby_time/utils/app_theme.dart';
import 'package:chat_baby_time/screens/record_home_screen.dart';
import 'package:chat_baby_time/screens/pattern_screen.dart';
import 'package:chat_baby_time/screens/statistics_screen.dart';
import 'package:chat_baby_time/screens/profile_screen.dart';

/// 메인 네비게이션 화면
/// 파스텔 톤 Floating Bottom Navigation Bar
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const RecordHomeScreen(),
    const PatternScreen(),
    const StatisticsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF5D4037).withOpacity(0.08),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Row(
              children: [
                _buildNavItem(index: 0, icon: Icons.edit_calendar_rounded, label: '기록'),
                _buildNavItem(index: 1, icon: Icons.timeline_rounded, label: '패턴'),
                _buildNavItem(index: 2, icon: Icons.bar_chart_rounded, label: '통계'),
                _buildNavItem(index: 3, icon: Icons.settings_rounded, label: '설정'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setState(() => _currentIndex = index),
        child: SizedBox(
          height: 72,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: isSelected
                    ? BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFFFE0E0),  // 파스텔 핑크 그라디언트
                            Color(0xFFFF9B9B),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primary.withOpacity(0.25),
                            blurRadius: 12,
                          ),
                        ],
                      )
                    : null,
                child: Icon(
                  icon,
                  color: isSelected
                      ? Colors.white
                      : AppTheme.textHint,
                  size: 22,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AppTheme.primary
                      : AppTheme.textHint,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
