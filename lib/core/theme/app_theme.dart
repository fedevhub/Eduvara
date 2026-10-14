import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import 'text_theme.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineMedium: AppTextTheme.title,
        titleLarge: AppTextTheme.heading,
        bodyMedium: AppTextTheme.body,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        foregroundColor: AppColors.text,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        indicatorColor: const Color(0xFFDDF7E8),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: states.contains(WidgetState.selected)
                ? const Color(0xFF15803D)
                : AppColors.textMuted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? const Color(0xFF15803D)
                : AppColors.text,
          ),
        ),
      ),
    );
  }
}
