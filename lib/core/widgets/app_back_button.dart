import 'package:flutter/material.dart';

import 'app_top_action.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton(
      {super.key, this.label = 'Back', this.onPressed, this.enabled = true});

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;

  static double leadingWidth(BuildContext context, String label) {
    final painter = TextPainter(
      text: TextSpan(
          text: label,
          style:
              DefaultTextStyle.of(context).style.merge(AppTopAction.textStyle)),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout();
    final width = painter.width + 56; // Pill padding and toolbar insets.
    painter.dispose();
    return width < 96 ? 96 : width;
  }

  @override
  Widget build(BuildContext context) => Align(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: 1,
        heightFactor: 1,
        child: AppTopAction(
          label: label,
          onTap:
              !enabled ? null : onPressed ?? () => Navigator.maybePop(context),
        ),
      );
}
