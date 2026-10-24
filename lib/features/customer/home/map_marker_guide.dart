import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

/// Matches the search pin and selected/unselected stall pins on the home map.
class MapMarkerGuide extends StatelessWidget {
  const MapMarkerGuide({super.key});

  static const _entries = [
    ('Search location', Color(0xFF0080FF)),
    ('Other stalls', Color(0xFFFF0000)),
    ('Selected stall', Color(0xFFFF8000)),
  ];
  static const _style = TextStyle(fontSize: 11, color: AppColors.textMuted);

  // The map results panel reserves its own height. Measure the same labels so
  // the guide can wrap without taking space away from the stall cards.
  static double heightFor(BuildContext context, double panelWidth) {
    final available = math.max(1.0, panelWidth - 32);
    var runWidth = 0.0;
    var runs = 1;
    var lineHeight = 18.0;
    for (final entry in _entries) {
      final painter = TextPainter(
          text: TextSpan(
              text: entry.$1,
              style: DefaultTextStyle.of(context).style.merge(_style)),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context))
        ..layout(maxWidth: math.max(1.0, available - 24));
      final itemWidth = painter.width + 22;
      lineHeight = math.max(lineHeight, painter.height);
      if (runWidth > 0 && runWidth + 12 + itemWidth > available) {
        runs++;
        runWidth = itemWidth;
      } else {
        runWidth += (runWidth == 0 ? 0 : 12) + itemWidth;
      }
      painter.dispose();
    }
    return (lineHeight * runs + (runs - 1) * 6 + 16).ceilToDouble();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                for (final entry in _entries)
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.location_on, size: 18, color: entry.$2),
                      const SizedBox(width: 4),
                      Flexible(child: Text(entry.$1, style: _style)),
                    ]),
                  ),
              ],
            ),
          ),
        ),
      );
}
