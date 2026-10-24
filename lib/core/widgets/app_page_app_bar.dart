import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_back_button.dart';

/// Route-aware page headers consistently use the Edit Profile pill style.
class AppPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AppPageAppBar(
      {super.key,
      this.title,
      this.actions,
      this.bottom,
      this.centerTitle,
      this.backgroundColor,
      this.foregroundColor,
      this.surfaceTintColor,
      this.elevation,
      this.scrolledUnderElevation,
      this.systemOverlayStyle,
      this.titleTextStyle,
      this.onBack,
      this.backEnabled = true,
      this.backLabel = 'Back',
      this.showBackButton,
      this.toolbarHeight = 64});

  final Widget? title;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool? centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? surfaceTintColor;
  final double? elevation;
  final double? scrolledUnderElevation;
  final SystemUiOverlayStyle? systemOverlayStyle;
  final TextStyle? titleTextStyle;
  final VoidCallback? onBack;
  final bool backEnabled;
  final String backLabel;
  final bool? showBackButton;
  final double toolbarHeight;

  @override
  Size get preferredSize =>
      Size.fromHeight(toolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    final showBack = showBackButton ??
        (onBack != null ||
            (ModalRoute.of(context)?.impliesAppBarDismissal ?? false));
    return AppBar(
      automaticallyImplyLeading: false,
      leadingWidth:
          showBack ? AppBackButton.leadingWidth(context, backLabel) : null,
      leading: showBack
          ? Padding(
              padding: const EdgeInsetsDirectional.only(start: 16, end: 8),
              child: AppBackButton(
                  label: backLabel, onPressed: onBack, enabled: backEnabled),
            )
          : null,
      title: title,
      actions: actions,
      bottom: bottom,
      centerTitle: centerTitle,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      surfaceTintColor: surfaceTintColor,
      elevation: elevation,
      scrolledUnderElevation: scrolledUnderElevation,
      systemOverlayStyle: systemOverlayStyle,
      titleTextStyle: titleTextStyle,
      toolbarHeight: toolbarHeight,
    );
  }
}
