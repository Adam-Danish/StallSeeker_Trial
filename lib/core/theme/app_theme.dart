import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        height: 65.0,
      ),
      // Root-cause fix for cards looking peach/tinted instead of pure
      // white: Material 3 automatically tints elevated surfaces with a
      // primary-colored overlay (surfaceTintColor) the higher their
      // elevation is -- since every Card in the app uses elevation,
      // they were all picking up a warm/orange cast from the primary
      // color even though color: null was meant to just mean "white".
      // Setting surfaceTintColor: Colors.transparent here disables
      // that overlay app-wide, so every Card renders true
      // AppColors.cardColor regardless of elevation.
      cardTheme: const CardThemeData(
        color: AppColors.cardColor,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
