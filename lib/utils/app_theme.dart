import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 아기톡톡 앱 테마 - Pastel Nursery Design System
/// 부드러운 파스텔 톤의 아기자기한 라이트 테마
class AppTheme {
  // ===== Pastel Nursery Color Palette =====

  // Primary: 코랄 핑크 계열 (따뜻하고 부드러운 메인 컬러)
  static const Color primary = Color(0xFFFF9B9B);
  static const Color primaryContainer = Color(0xFFFFE0E0);
  static const Color primaryFixed = Color(0xFFFFCDCD);
  static const Color primaryFixedDim = Color(0xFFFF8A8A);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF5D2020);
  static const Color onPrimaryFixed = Color(0xFF3B1010);
  static const Color onPrimaryFixedVariant = Color(0xFF7A3030);
  static const Color inversePrimary = Color(0xFFFF6B6B);

  // Secondary: 베이비 블루 계열 (보조 컬러, 수면/차분한 느낌)
  static const Color secondary = Color(0xFFB4E4FF);
  static const Color secondaryContainer = Color(0xFFDDF3FF);
  static const Color secondaryFixed = Color(0xFFE8F6FF);
  static const Color secondaryFixedDim = Color(0xFF8AD4FF);
  static const Color onSecondary = Color(0xFF1A3A4A);
  static const Color onSecondaryContainer = Color(0xFF2A4F5F);
  static const Color onSecondaryFixed = Color(0xFF0D2A38);
  static const Color onSecondaryFixedVariant = Color(0xFF3A6070);

  // Tertiary: 피치/살구 계열 (따뜻한 강조 컬러)
  static const Color tertiary = Color(0xFFFFDEB4);
  static const Color tertiaryContainer = Color(0xFFFFF0DD);
  static const Color tertiaryFixed = Color(0xFFFFE8CC);
  static const Color tertiaryFixedDim = Color(0xFFFFC98A);
  static const Color onTertiary = Color(0xFF4A3520);
  static const Color onTertiaryContainer = Color(0xFF5A4030);
  static const Color onTertiaryFixed = Color(0xFF2D1F10);
  static const Color onTertiaryFixedVariant = Color(0xFF6A5040);

  // Error
  static const Color error = Color(0xFFE57373);
  static const Color errorContainer = Color(0xFFFFE0E0);
  static const Color onError = Color(0xFFFFFFFF);
  static const Color onErrorContainer = Color(0xFF5D2020);

  // Background / Surface: 웜 크림 계열
  static const Color background = Color(0xFFFFF8F0);
  static const Color onBackground = Color(0xFF5D4037);

  static const Color surface = Color(0xFFFFF8F0);
  static const Color surfaceDim = Color(0xFFF5EDE5);
  static const Color surfaceBright = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFFFF5EC);
  static const Color surfaceContainer = Color(0xFFFFF0E5);
  static const Color surfaceContainerHigh = Color(0xFFFFEBDD);
  static const Color surfaceContainerHighest = Color(0xFFFFE5D5);
  static const Color surfaceVariant = Color(0xFFF5E6D8);
  static const Color onSurface = Color(0xFF5D4037);
  static const Color onSurfaceVariant = Color(0xFF8D7B70);
  static const Color inverseSurface = Color(0xFF5D4037);
  static const Color inverseOnSurface = Color(0xFFFFF8F0);
  static const Color surfaceTint = Color(0xFFFF9B9B);

  static const Color outline = Color(0xFFD4C4B8);
  static const Color outlineVariant = Color(0xFFE8DCD2);

  // Gradient
  static const Color primaryGradientStart = Color(0xFFFFE0E0);
  static const Color primaryGradientEnd = Color(0xFFFFB4B4);

  // ===== 카테고리 색상 (파스텔 버전) =====
  static const Color feedingColor = Color(0xFFFF9B9B);     // 코랄 핑크
  static const Color sleepColor = Color(0xFFB4B4FF);       // 라벤더
  static const Color diaperColor = Color(0xFFFFD268);       // 옐로우
  static const Color healthColor = Color(0xFF98D8B0);       // 민트 그린
  static const Color milestoneColor = Color(0xFFFFB74D);    // 오렌지
  static const Color babyfoodColor = Color(0xFFF4A460);     // 샌디 브라운
  static const Color snackColor = Color(0xFFE091D3);        // 라이트 퍼플 핑크
  static const Color otherColor = Color(0xFFBDBDBD);        // 그레이

  // 카테고리 연한 배경색 (카드 아이콘 배경용)
  static const Color feedingBg = Color(0xFFFFE5E5);
  static const Color sleepBg = Color(0xFFE8E8FF);
  static const Color diaperBg = Color(0xFFFFF3D6);
  static const Color healthBg = Color(0xFFDFF5E8);
  static const Color milestoneBg = Color(0xFFFFF0DD);
  static const Color babyfoodBg = Color(0xFFFFF0E0);
  static const Color snackBg = Color(0xFFFCE4F6);
  static const Color otherBg = Color(0xFFF0F0F0);

  // Legacy compatibility aliases
  static const Color textPrimary = Color(0xFF5D4037);
  static const Color textSecondary = Color(0xFF8D7B70);
  static const Color textHint = Color(0xFFB0A098);
  static const Color success = Color(0xFF81C784);
  static const Color accent = Color(0xFFFFDEB4);

  // 스와이프 액션 색상
  static const Color editAction = Color(0xFF81C784);
  static const Color copyAction = Color(0xFF64B5F6);
  static const Color deleteAction = Color(0xFFE57373);

  // 카테고리별 색상 가져오기 (편의 메서드)
  static Color categoryColor(dynamic category) {
    switch (category.toString().split('.').last) {
      case 'feeding':
        return feedingColor;
      case 'sleep':
        return sleepColor;
      case 'diaper':
        return diaperColor;
      case 'health':
        return healthColor;
      case 'milestone':
        return milestoneColor;
      case 'babyfood':
        return babyfoodColor;
      case 'snack':
        return snackColor;
      default:
        return otherColor;
    }
  }

  static Color categoryBg(dynamic category) {
    switch (category.toString().split('.').last) {
      case 'feeding':
        return feedingBg;
      case 'sleep':
        return sleepBg;
      case 'diaper':
        return diaperBg;
      case 'health':
        return healthBg;
      case 'milestone':
        return milestoneBg;
      case 'babyfood':
        return babyfoodBg;
      case 'snack':
        return snackBg;
      default:
        return otherBg;
    }
  }

  // ===== 공통 장식 =====

  /// 부드러운 카드 그림자
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: const Color(0xFF5D4037).withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  /// 카드 데코레이션 (파스텔 카드)
  static BoxDecoration cardDecoration({Color? color}) => BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: softShadow,
      );

  static ThemeData get theme => ThemeData(
        useMaterial3: true,
        fontFamily: 'NotoSansKR',
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: primary,
          onPrimary: onPrimary,
          primaryContainer: primaryContainer,
          onPrimaryContainer: onPrimaryContainer,
          secondary: secondary,
          onSecondary: onSecondary,
          secondaryContainer: secondaryContainer,
          onSecondaryContainer: onSecondaryContainer,
          tertiary: tertiary,
          onTertiary: onTertiary,
          tertiaryContainer: tertiaryContainer,
          onTertiaryContainer: onTertiaryContainer,
          error: error,
          onError: onError,
          errorContainer: errorContainer,
          onErrorContainer: onErrorContainer,
          surface: surface,
          onSurface: onSurface,
          surfaceContainerHighest: surfaceContainerHighest,
          outline: outline,
          outlineVariant: outlineVariant,
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          foregroundColor: textPrimary,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarBrightness: Brightness.light,
            statusBarIconBrightness: Brightness.dark,
            statusBarColor: Colors.transparent,
          ),
          titleTextStyle: TextStyle(
            color: textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            fontFamily: 'NotoSansKR',
            letterSpacing: -0.5,
          ),
          iconTheme: IconThemeData(color: textPrimary),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: textPrimary,
          contentTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            fontFamily: 'NotoSansKR',
          ),
          actionTextColor: primaryContainer,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: primary,
          unselectedItemColor: textHint,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: outlineVariant.withOpacity(0.6),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: primary.withOpacity(0.6),
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
          hintStyle: TextStyle(color: textHint.withOpacity(0.8)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 14,
            ),
            elevation: 0,
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w800,
            fontFamily: 'NotoSansKR',
            color: textPrimary,
            letterSpacing: -1.5,
          ),
          displayMedium: TextStyle(
            fontSize: 45,
            fontWeight: FontWeight.w700,
            fontFamily: 'NotoSansKR',
            color: textPrimary,
            letterSpacing: -1.0,
          ),
          displaySmall: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w700,
            fontFamily: 'NotoSansKR',
            color: textPrimary,
            letterSpacing: -0.5,
          ),
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            fontFamily: 'NotoSansKR',
            color: textPrimary,
            letterSpacing: -0.5,
          ),
          headlineMedium: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            fontFamily: 'NotoSansKR',
            color: textPrimary,
          ),
          headlineSmall: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            fontFamily: 'NotoSansKR',
            color: textPrimary,
          ),
          titleLarge: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            fontFamily: 'NotoSansKR',
            color: textPrimary,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'NotoSansKR',
            color: textPrimary,
          ),
          titleSmall: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            fontFamily: 'NotoSansKR',
            color: textPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            fontFamily: 'NotoSansKR',
            color: textPrimary,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            fontFamily: 'NotoSansKR',
            color: textPrimary,
          ),
          bodySmall: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            fontFamily: 'NotoSansKR',
            color: textSecondary,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            fontFamily: 'NotoSansKR',
            color: textPrimary,
            letterSpacing: 0.5,
          ),
          labelMedium: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            fontFamily: 'NotoSansKR',
            color: textSecondary,
            letterSpacing: 0.5,
          ),
          labelSmall: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            fontFamily: 'NotoSansKR',
            color: textHint,
            letterSpacing: 0.8,
          ),
        ),
      );
}
