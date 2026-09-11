import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
        primary: AppColors.primary,
        surface: Colors.white,
        onSurface: AppColors.textDark,
      ),
      // Use the platform sans-serif consistently, without per-page Poppins overrides.
      textTheme: Typography.material2021().black.apply(
            bodyColor: AppColors.textDark,
            displayColor: AppColors.textDark,
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
            letterSpacing: 0),
      ),
      dividerTheme:
          const DividerThemeData(color: Color(0xFFE5E5EA), thickness: .5),
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      )),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      )),
      scaffoldBackgroundColor: AppColors.background,
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
            color: AppColors.textDark)),
        iconTheme: WidgetStatePropertyAll(
            IconThemeData(color: AppColors.textDark, size: 25)),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 72.0,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.cardColor,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
