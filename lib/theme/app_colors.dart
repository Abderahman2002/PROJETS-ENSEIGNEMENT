import 'package:flutter/material.dart';

/// Mirrors app/src/main/java/com/example/ui/theme/Color.kt
class AppColors {
  AppColors._();

  static const Color primaryBlue = Color(0xFF3577B4);
  static const Color primaryBlueDark = Color(0xFF1E6091);
  static const Color primaryBlueLight = Color(0xFF4A90E2);
  static const Color accentCyan = Color(0xFF00ACC1);
  static const Color accentSky = Color(0xFFE3F2FD);
  static const Color iceBackground = Color(0xFFEBF5FC);
  static const Color surfaceCard = Color(0xFFFFFFFF);

  static const Color attendancePresent = Color(0xFF2E7D32);
  static const Color attendanceAbsent = Color(0xFFD32F2F);
  static const Color attendanceLate = Color(0xFFF57C00);

  static const Color skillMastered = Color(0xFF2E7D32);
  static const Color skillAcquiring = Color(0xFFFFA000);
  static const Color skillNotAcquired = Color(0xFFD32F2F);

  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color cardBorder = Color(0xFFE2E8F0);
  static const Color inputBackground = Color(0xFFF8FAFC);
}

/// Mirrors the `AppColorTheme` enum: multiple selectable color schemes.
class AppColorTheme {
  final String id;
  final String title;
  final String subtitle;
  final Color primaryColor;
  final Color primaryDark;
  final Color primaryLight;
  final Color accentContainer;
  final Color backgroundTint;

  const AppColorTheme({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.primaryColor,
    required this.primaryDark,
    required this.primaryLight,
    required this.accentContainer,
    required this.backgroundTint,
  });

  static const blue = AppColorTheme(
    id: 'blue',
    title: 'أزرق كلاسيكي',
    subtitle: 'اللون الرسمي الافتراضي',
    primaryColor: Color(0xFF3577B4),
    primaryDark: Color(0xFF1E6091),
    primaryLight: Color(0xFF4A90E2),
    accentContainer: Color(0xFFE3F2FD),
    backgroundTint: Color(0xFFEBF5FC),
  );

  static const emerald = AppColorTheme(
    id: 'emerald',
    title: 'أخضر زمردي',
    subtitle: 'أخضر تعليمي مريح للعين',
    primaryColor: Color(0xFF16A34A),
    primaryDark: Color(0xFF15803D),
    primaryLight: Color(0xFF22C55E),
    accentContainer: Color(0xFFDCFCE7),
    backgroundTint: Color(0xFFF0FDF4),
  );

  static const purple = AppColorTheme(
    id: 'purple',
    title: 'بنفسجي ملكي',
    subtitle: 'طابع راقٍ ومميز',
    primaryColor: Color(0xFF7C3AED),
    primaryDark: Color(0xFF6D28D9),
    primaryLight: Color(0xFF8B5CF6),
    accentContainer: Color(0xFFEDE9FE),
    backgroundTint: Color(0xFFFAF5FF),
  );

  static const teal = AppColorTheme(
    id: 'teal',
    title: 'تركوازي بحري',
    subtitle: 'أزرق بترولي هادئ',
    primaryColor: Color(0xFF0D9488),
    primaryDark: Color(0xFF0F766E),
    primaryLight: Color(0xFF14B8A6),
    accentContainer: Color(0xFFCCFBF1),
    backgroundTint: Color(0xFFF0FDFA),
  );

  static const amber = AppColorTheme(
    id: 'amber',
    title: 'كهرماني دافئ',
    subtitle: 'ذهبي برونزي جذاب',
    primaryColor: Color(0xFFD97706),
    primaryDark: Color(0xFFB45309),
    primaryLight: Color(0xFFF59E0B),
    accentContainer: Color(0xFFFEF3C7),
    backgroundTint: Color(0xFFFFFBEB),
  );

  static const ruby = AppColorTheme(
    id: 'ruby',
    title: 'قرمزي ياقوتي',
    subtitle: 'تدرج ياقوتي حيوي',
    primaryColor: Color(0xFFE11D48),
    primaryDark: Color(0xFFBE123C),
    primaryLight: Color(0xFFF43F5E),
    accentContainer: Color(0xFFFFE4E6),
    backgroundTint: Color(0xFFFFF1F2),
  );

  static const navy = AppColorTheme(
    id: 'navy',
    title: 'كحلي ليلي',
    subtitle: 'أزرق داكن فخم ووقور',
    primaryColor: Color(0xFF1E3A8A),
    primaryDark: Color(0xFF172554),
    primaryLight: Color(0xFF2563EB),
    accentContainer: Color(0xFFDBEAFE),
    backgroundTint: Color(0xFFEFF6FF),
  );

  static const List<AppColorTheme> all = [blue, emerald, purple, teal, amber, ruby, navy];

  static AppColorTheme fromId(String id) {
    return all.firstWhere((t) => t.id == id, orElse: () => blue);
  }
}
