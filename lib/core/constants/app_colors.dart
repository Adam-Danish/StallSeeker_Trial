import 'package:flutter/material.dart';

class AppColors {
  // Colors sampled from the StallSeeker logo.
  static const Color logoOrange = Color(0xFFFB8D24);
  static const Color logoRedOrange = Color(0xFFFA3A1E);

  // A darker orange for readable text and selected navigation icons.
  static const Color primary = Color(0xFFB83D11);
  static const Color primaryLight = logoOrange;

  static const LinearGradient logoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [logoOrange, logoRedOrange],
  );

  static const Color background = Color(0xFFFFF8F2);
  static const Color cardColor = Colors.white;

  // Keep this name because existing screens already use AppColors.mint.
  static const Color mint = Color(0xFFFFF0E5);

  static const Color border = Color(0xFFF0E1D6);
  static const Color textDark = Color(0xFF241E1B);
  static const Color textMuted = Color(0xFF7D706B);

  // Status colors retain their meanings.
  static const Color openGreen = Color(0xFF2E7D32);
  static const Color closedRed = Color(0xFFC62828);
  static const Color limitedYellow = Color(0xFFF57F17);
}
