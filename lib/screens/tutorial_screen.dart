import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chat_baby_time/utils/app_theme.dart';

/// 튜토리얼 온보딩 화면
/// PageView 기반 4단계 가이드 — 최초 실행 시 자동 표시, 완료 후 자동 저장
class TutorialScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const TutorialScreen({super.key, required this.onComplete});

  /// SharedPreferences 키
  static const String _prefKey = 'tutorial_completed';

  /// 튜토리얼을 이미 완료했는지 확인
  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_prefKey) ?? false);
  }

  /// 튜토리얼 완료 상태 저장
  static Future<void> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
  }

  /// 튜토리얼 완료 상태 초기화 (다시 보기 직전에 호출 — 완료 시 [markCompleted]로 다시 저장됨)
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKey);
  }

  /// 프로필·설정 등에서 풀스크린 튜토리얼 열기 (끝나면 현재 화면으로 복귀)
  static Future<void> openAgain(BuildContext context) async {
    await reset();
    if (!context.mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => TutorialScreen(
          onComplete: () => Navigator.of(ctx).pop(),
        ),
      ),
    );
  }

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_TutorialPageData> _pages = [
    _TutorialPageData(
      imagePath: 'assets/images/onboarding_welcome.png',
      title: '말 한마디로 끝나는 육아 기록',
      subtitle: '"분유 120ml 먹었어", "이유식 80g 먹었어"처럼\n자연스럽게 말하면 자동으로 기록됩니다',
      iconData: Icons.chat_bubble_outline_rounded,
      gradientColors: [Color(0xFFFFE0E0), Color(0xFFFF9B9B)],
    ),
    _TutorialPageData(
      imagePath: 'assets/images/onboarding_feature.png',
      title: '버튼으로도 툭툭 기록',
      subtitle: '채팅·기록 화면 아래에서 종류를 고른 뒤\n모유(분)·분유(ml)·이유식·간식(g)·수면(분)·기저귀·건강(체온·약)까지 단계로 고르고\n프리셋에 없으면 「직접 입력」으로 숫자·이름을 넣을 수 있어요\n마지막에 시간만 고르면 돼요',
      iconData: Icons.touch_app_rounded,
      gradientColors: [Color(0xFFFFF0E5), Color(0xFFF4A460)],
    ),
    _TutorialPageData(
      imagePath: 'assets/images/onboarding_feature.png',
      title: '음성으로도 간편하게',
      subtitle: '마이크 버튼을 누르고 말하면\n음성 인식으로 바로 기록할 수 있어요',
      iconData: Icons.mic_rounded,
      gradientColors: [Color(0xFFE8E8FF), Color(0xFFB4B4FF)],
    ),
    _TutorialPageData(
      imagePath: 'assets/images/tab_statistics.png',
      title: '패턴과 통계를 한눈에',
      subtitle: '수유, 수면, 기저귀 패턴을\n차트와 타임라인으로 확인하세요',
      iconData: Icons.insights_rounded,
      gradientColors: [Color(0xFFFFF0DD), Color(0xFFFFDEB4)],
    ),
    _TutorialPageData(
      imagePath: 'assets/images/onboarding_feature.png',
      title: '기록을 공유하세요',
      subtitle: '설정 탭의 공유하기 또는 패턴 화면에서\n오늘 요약·CSV·백업 파일을\n가족이나 소아과 선생님에게 보낼 수 있어요',
      iconData: Icons.ios_share_rounded,
      gradientColors: [Color(0xFFE0F7FA), Color(0xFF80DEEA)],
    ),
    _TutorialPageData(
      imagePath: 'assets/images/onboarding_feature.png',
      title: '홈 위젯으로 더 빠르게',
      subtitle: '설정 탭에서 홈 위젯을 추가하면\n앱을 열지 않고 수유·기저귀·수면을\n한 번의 탭으로 바로 기록할 수 있어요',
      iconData: Icons.widgets_rounded,
      gradientColors: [Color(0xFFE8F5E9), Color(0xFF81C784)],
    ),
  ];

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeTutorial();
    }
  }

  void _completeTutorial() async {
    await TutorialScreen.markCompleted();
    widget.onComplete();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip 버튼
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 8),
                child: TextButton(
                  onPressed: _completeTutorial,
                  child: const Text(
                    '건너뛰기',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),

            // 페이지 뷰
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index], isSmallScreen);
                },
              ),
            ),

            // 페이지 인디케이터
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (index) {
                  final isActive = _currentPage == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppTheme.primary
                          : AppTheme.primary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 24),

            // 다음/시작 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(
                    _currentPage == _pages.length - 1 ? '시작하기' : '다음',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_TutorialPageData data, bool isSmallScreen) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 이미지
          Container(
            width: isSmallScreen ? 180 : 240,
            height: isSmallScreen ? 180 : 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  data.gradientColors[0].withValues(alpha: 0.3),
                  data.gradientColors[1].withValues(alpha: 0.15),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ClipOval(
                child: Image.asset(
                  data.imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Icon(
                    data.iconData,
                    size: isSmallScreen ? 64 : 80,
                    color: data.gradientColors[1],
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: isSmallScreen ? 24 : 40),

          // 아이콘 배지
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: data.gradientColors[0].withValues(alpha: 0.4),
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.iconData,
              color: data.gradientColors[1],
              size: 24,
            ),
          ),

          const SizedBox(height: 16),

          // 타이틀
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 12),

          // 서브타이틀
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: AppTheme.textSecondary,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// 튜토리얼 페이지 데이터 모델
class _TutorialPageData {
  final String imagePath;
  final String title;
  final String subtitle;
  final IconData iconData;
  final List<Color> gradientColors;

  const _TutorialPageData({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.iconData,
    required this.gradientColors,
  });
}
