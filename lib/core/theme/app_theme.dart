import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2D336B); // Dark Navy Blue
  static const Color secondary = Color(0xFF7886C7); // Medium Blue-Purple
  static const Color tertiary = Color(0xFFA9B5DF); // Light Blue-Gray
  static const Color quaternary = Color(0xFFFFF2F2); // Very Light Pink

  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  static const Color cardBackground = Color(0xFFF8F9FC);
  static const Color text = Color(0xFF2D336B);
  static const Color textSecondary = Color(0xFF666666);
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Quicksand',
    colorScheme: ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      tertiary: AppColors.tertiary,
      background: AppColors.background,
      surface: AppColors.surface,
      onBackground: AppColors.text,
      onSurface: AppColors.text,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: AppColors.primary,
      error: const Color(0xFFD32F2F),
      onError: Colors.white,
    ),
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: AppColors.text,
        height: 1.3,
        fontFamily: 'Quicksand',
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.text,
        height: 1.3,
        fontFamily: 'Quicksand',
      ),
      titleLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
        height: 1.3,
        fontFamily: 'Quicksand',
      ),
      titleMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: AppColors.text,
        height: 1.3,
        fontFamily: 'Quicksand',
      ),
      bodyLarge: TextStyle(
        fontSize: 18,
        color: AppColors.text,
        height: 1.5,
        fontFamily: 'Quicksand',
      ),
      bodyMedium: TextStyle(
        fontSize: 16,
        color: AppColors.textSecondary,
        height: 1.5,
        fontFamily: 'Quicksand',
      ),
    ),
    cardTheme: CardTheme(
      color: AppColors.cardBackground,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      elevation: 0,
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      selectedLabelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
      unselectedLabelStyle: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      ),
    ),
  );
} 