import 'package:flutter/material.dart';
import 'package:chat_baby_time/utils/app_theme.dart';
import 'package:chat_baby_time/screens/tutorial_screen.dart';

/// 스플래시 화면 — 앱 로딩 시 미드저니 이미지와 앱 이름 표시
class SplashScreen extends StatefulWidget {
  final String nextRoute;

  const SplashScreen({super.key, required this.nextRoute});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<double> _scaleUp;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _scaleUp = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();

    // 2초 후 다음 화면으로
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) {
        _navigateNext();
      }
    });
  }

  void _navigateNext() async {
    // 프로필이 없으면 (신규 사용자) 튜토리얼 체크 후 프로필 설정으로
    // 프로필이 있으면 튜토리얼 체크 후 홈으로
    final shouldShowTutorial = await TutorialScreen.shouldShow();

    if (!mounted) return;

    if (shouldShowTutorial) {
      // 튜토리얼 표시 — nextRoute를 전달하여 TutorialScreen이 자체적으로 네비게이션
      final nextRoute = widget.nextRoute;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (ctx) => TutorialScreen(
            onComplete: () {
              Navigator.pushReplacementNamed(ctx, nextRoute);
            },
          ),
        ),
      );
    } else {
      Navigator.pushReplacementNamed(context, widget.nextRoute);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: ScaleTransition(
            scale: _scaleUp,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 미드저니 스플래시 이미지 (앱 아이콘 스타일 라운딩)
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(36),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(36),
                    child: Image.asset(
                      'assets/images/splash.png',
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
