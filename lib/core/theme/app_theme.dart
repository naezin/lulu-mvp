import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/design_system/lulu_radius.dart';

/// Lulu Theme - MVP-F (다태아 중심)
/// Midnight Blue theme optimized for late-night feeding & low-light usage
class AppTheme {
  // Midnight Blue - Primary Colors (Low-light optimized)
  static const Color midnightNavy = Color(0xFF0D1B2A);
  static const Color deepBlue = Color(0xFF1B263B);
  static const Color softBlue = Color(0xFF415A77);
  static const Color lavenderMist = Color(0xFF9D8CD6);
  static const Color lavenderGlow = Color(0xFFB4A5E6);
  static const Color primaryPurple = Color(0xFF9D8CD6);
  static const Color champagneGold = Color(0xFFD4AF6A);

  // Surface Colors
  static const Color surfaceDark = Color(0xFF0D1B2A);
  static const Color surfaceCard = Color(0xFF1B263B);
  static const Color surfaceElevated = Color(0xFF2A3F5F);

  // Text Colors (WCAG AAA compliant)
  static const Color textPrimary = Color(0xFFE9ECEF);
  static const Color textSecondary = Color(0xFFADB5BD);
  static const Color textTertiary = Color(0xFF6C757D);

  // Status Colors (Low-light optimized)
  static const Color successSoft = Color(0xFF5FB37B);
  static const Color warningSoft = Color(0xFFE8B87E);
  static const Color errorSoft = Color(0xFFE87878);
  static const Color infoSoft = Color(0xFF7BB8E8);

  // Sweet Spot Gauge Colors
  static const Color gaugeOptimal = Color(0xFF5FB37B);
  static const Color gaugeWarning = Color(0xFFE8B87E);
  static const Color gaugeCritical = Color(0xFFE87878);
  static const Color gaugeBackground = Color(0xFF2A3F5F);

  // Emergency Mode Colors
  static const Color emergencyRed = Color(0xFFFF6B6B);
  static const Color emergencyBackground = Color(0xFF2D1F1F);

  // Activity Colors (Records)
  static const Color sleepColor = Color(0xFF7BB8E8);
  static const Color feedingColor = Color(0xFFE8B87E);
  static const Color diaperColor = Color(0xFF9D8CD6);
  static const Color playColor = Color(0xFF5FB37B);
  static const Color healthColor = Color(0xFFE87878);

  // UI Element Colors
  static const Color glassBorder = Color(0xFF415A77);
  static const Color primaryDark = Color(0xFF0D1B2A);

  // Sweet Spot Constants
  static const int nightModeStartHour = 17;
  static const int nightModeEndHour = 6;

  // Sweet Spot State Colors (Day)
  static const Color sweetSpotTooEarly = Color(0xFF4A90E2);
  static const Color sweetSpotApproaching = Color(0xFFF5A623);
  static const Color sweetSpotOptimal = Color(0xFF7ED321);
  static const Color sweetSpotOvertired = Color(0xFFE87878);

  // Sweet Spot State Colors (Night - 30% darker)
  static const Color sweetSpotTooEarlyNight = Color(0xFF35679E);
  static const Color sweetSpotApproachingNight = Color(0xFFAB7418);
  static const Color sweetSpotOptimalNight = Color(0xFF4A7D21);
  static const Color sweetSpotOvertiredNight = Color(0xFFA35454);

  // Glassmorphism Colors
  static const Color glassBackground = Color(0x1AFFFFFF);
  static const Color glassBackgroundLight = Color(0x0DFFFFFF);
  static const Color glassBorderLight = Color(0x33FFFFFF);

  // MVP-F: 다태아 구분 색상 (Baby Avatar Colors)
  static const List<Color> babyAvatarColors = [
    Color(0xFF7EB8DA), // 하늘 (첫째)
    Color(0xFFE8B4CB), // 분홍 (둘째)
    Color(0xFFA8D5BA), // 민트 (셋째)
    Color(0xFFF5D6A8), // 살구 (넷째)
  ];

  /// Midnight Blue Theme (Default)
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: lavenderMist,
        onPrimary: midnightNavy,
        primaryContainer: softBlue,
        onPrimaryContainer: lavenderGlow,
        secondary: softBlue,
        tertiary: lavenderGlow,
        surface: surfaceDark,
        onSurface: textPrimary,
        surfaceContainerHighest: surfaceCard,
        error: errorSoft,
      ),
      scaffoldBackgroundColor: surfaceDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: 'SF Pro Display',
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuluRadius.xl),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: deepBlue,
        indicatorColor: lavenderMist.withValues(alpha: 0.2),
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: lavenderGlow,
              letterSpacing: -0.2,
            );
          }
          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: textSecondary,
            letterSpacing: -0.2,
          );
        }),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: deepBlue,
        modalBackgroundColor: deepBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: lavenderMist,
        foregroundColor: midnightNavy,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(LuluRadius.lg),
        ),
        extendedSizeConstraints: const BoxConstraints.tightFor(height: 56),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lavenderMist,
          foregroundColor: midnightNavy,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LuluRadius.md),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontFamily: 'SF Pro Display',
            letterSpacing: -0.4,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lavenderGlow,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(LuluRadius.sm),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LuluRadius.md),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LuluRadius.md),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LuluRadius.md),
          borderSide: const BorderSide(color: lavenderMist, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: const TextStyle(
          color: textTertiary,
          fontSize: 16,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: softBlue.withValues(alpha: 0.3),
        thickness: 1,
        space: 1,
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 34,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          fontFamily: 'SF Pro Display',
          letterSpacing: -0.8,
          height: 1.2,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
          fontFamily: 'SF Pro Display',
          letterSpacing: -0.6,
          height: 1.25,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontFamily: 'SF Pro Display',
          letterSpacing: -0.5,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontFamily: 'SF Pro Display',
          letterSpacing: -0.4,
        ),
        titleLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontFamily: 'SF Pro Text',
          letterSpacing: -0.3,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontFamily: 'SF Pro Text',
          letterSpacing: -0.3,
        ),
        bodyLarge: TextStyle(
          fontSize: 17,
          color: textPrimary,
          fontFamily: 'SF Pro Text',
          letterSpacing: -0.4,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          color: textSecondary,
          fontFamily: 'SF Pro Text',
          letterSpacing: -0.2,
          height: 1.4,
        ),
        bodySmall: TextStyle(
          fontSize: 13,
          color: textTertiary,
          fontFamily: 'SF Pro Text',
          letterSpacing: -0.1,
        ),
        labelLarge: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimary,
          fontFamily: 'SF Pro Text',
          letterSpacing: -0.4,
        ),
        labelMedium: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: textSecondary,
          fontFamily: 'SF Pro Text',
          letterSpacing: -0.2,
        ),
      ),
    );
  }

  /// Emergency Mode Theme (High Fever Detection)
  static ThemeData get emergencyTheme {
    return darkTheme.copyWith(
      scaffoldBackgroundColor: emergencyBackground,
      colorScheme: darkTheme.colorScheme.copyWith(
        primary: emergencyRed,
        surface: emergencyBackground,
        error: emergencyRed,
      ),
      appBarTheme: darkTheme.appBarTheme.copyWith(
        backgroundColor: emergencyBackground,
      ),
    );
  }
}
