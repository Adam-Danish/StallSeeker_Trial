import 'package:flutter/material.dart';

import 'app_back_button.dart';

/// Sheet dismissal stays at the top left, above the sheet's content.
class AppSheetHeader extends StatelessWidget {
  const AppSheetHeader(
      {super.key,
      required this.title,
      this.subtitle,
      this.onBack,
      this.backLabel = 'Close',
      this.padding = const EdgeInsets.fromLTRB(16, 12, 16, 12)});

  final Widget title;
  final Widget? subtitle;
  final VoidCallback? onBack;
  final String backLabel;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          AppBackButton(label: backLabel, onPressed: onBack),
          const SizedBox(height: 12),
          DefaultTextStyle.merge(
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w600),
            child: title,
          ),
          if (subtitle != null) ...[const SizedBox(height: 4), subtitle!],
        ]),
      );
}
