import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Shared spacing, fields and actions for account pages.
class AccountLayout extends StatelessWidget {
  const AccountLayout({super.key, required this.title, required this.children,
    this.busy = false, this.background = Colors.white});
  final String title;
  final List<Widget> children;
  final bool busy;
  final Color background;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      backgroundColor: background,
      appBar: AppBar(title: Text(title), centerTitle: true,
        backgroundColor: Colors.white, surfaceTintColor: Colors.transparent,
        elevation: 0, scrolledUnderElevation: 0,
        titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500,
          color: AppColors.textDark, letterSpacing: 0),
        leading: BackButton(onPressed: busy ? () {} : () => Navigator.maybePop(context))),
      body: SafeArea(top: false, child: Align(alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: children)))),
    ),
  );
}

class AccountIntro extends StatelessWidget {
  const AccountIntro({super.key, required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Column(children: [
    Container(width: 64, height: 64,
      decoration: const BoxDecoration(color: Color(0xFFFFF0E9), shape: BoxShape.circle),
      child: Icon(icon, color: AppColors.primary, size: 30)),
    const SizedBox(height: 24),
    Text(title, textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -.3)),
    const SizedBox(height: 10),
    Text(body, textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF707078))),
    const SizedBox(height: 32),
  ]);
}

InputDecoration accountField(String label, {Widget? suffix, String? helper}) => InputDecoration(
  labelText: label, helperText: helper, helperMaxLines: 3, errorMaxLines: 3,
  suffixIcon: suffix, filled: true, fillColor: const Color(0xFFF5F5F7),
  labelStyle: const TextStyle(color: Color(0xFF707078), fontSize: 14),
  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20),
    borderSide: const BorderSide(color: AppColors.primary)),
  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20),
    borderSide: const BorderSide(color: Color(0xFFB3261E))),
  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20),
    borderSide: const BorderSide(color: Color(0xFFB3261E), width: 1.5)),
);

class AccountButton extends StatelessWidget {
  const AccountButton({super.key, required this.label, this.onPressed, this.busy = false,
    this.color = AppColors.primary});
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(width: double.infinity,
    child: FilledButton(onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        minimumSize: const Size(48, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
      child: busy ? const SizedBox(width: 22, height: 22,
        child: CircularProgressIndicator(strokeWidth: 2))
        : Text(label, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))));
}

class AccountError extends StatelessWidget {
  const AccountError(this.message, {super.key});
  final String? message;
  @override
  Widget build(BuildContext context) => message == null ? const SizedBox.shrink()
    : Padding(padding: const EdgeInsets.only(bottom: 16),
        child: Semantics(liveRegion: true, child: Text(message!,
          style: const TextStyle(color: Color(0xFFB3261E), height: 1.4))));
}
