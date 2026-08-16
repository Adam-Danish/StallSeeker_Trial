import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6E41)),
      useMaterial3: true,
      scaffoldBackgroundColor: Colors.white,
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        height: 65.0,
      ),
    );
  }
}
