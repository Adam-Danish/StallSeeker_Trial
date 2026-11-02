import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/constants/app_colors.dart';

IconData stallCategoryIcon(String category) => switch (category) {
      'Beverages' => Icons.local_drink_rounded,
      'Burger' => Icons.lunch_dining_rounded,
      'Snacks & Desserts' => Icons.icecream_rounded,
      'Noodles' => Icons.ramen_dining_rounded,
      'Goreng Pisang' => Icons.bakery_dining_rounded,
      _ => Icons.restaurant_rounded,
    };

/// Bounded cache: two marker states per category, rather than one per stall.
class StallMapMarkerCache {
  final _icons = <(String, bool), Future<BitmapDescriptor>>{};

  Future<BitmapDescriptor> icon(String category, {required bool selected}) =>
      _icons.putIfAbsent((category, selected), () => _draw(category, selected));

  Future<BitmapDescriptor> _draw(String category, bool selected) async {
    const scale = 3.0;
    const size = 56.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder)..scale(scale);
    const center = Offset(size / 2, size / 2);
    canvas.drawCircle(center, 26, Paint()..color = const Color(0x22000000));
    canvas.drawCircle(center, 24, Paint()..color = AppColors.cardColor);
    if (selected) {
      canvas.drawCircle(
          center,
          24,
          Paint()
            ..color = AppColors.primary
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2);
    }
    canvas.drawCircle(center, 20,
        Paint()..color = selected ? AppColors.primary : AppColors.cardColor);
    final glyph = stallCategoryIcon(category);
    final painter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(glyph.codePoint),
        style: TextStyle(
          fontSize: 24,
          fontFamily: glyph.fontFamily,
          package: glyph.fontPackage,
          color: selected ? AppColors.cardColor : AppColors.primary,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
        canvas, center - Offset(painter.width / 2, painter.height / 2));
    painter.dispose();
    final picture = recorder.endRecording();
    final image =
        await picture.toImage((size * scale).round(), (size * scale).round());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List(),
        imagePixelRatio: scale);
  }
}
