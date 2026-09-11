import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key, this.onGuestAccessGranted});

  final VoidCallback? onGuestAccessGranted;

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _auth = AuthService();
  bool _busy = false;
  bool _loginOpen = false;

  Future<void> _google() async {
    setState(() => _busy = true);
    final error = await _auth.signInWithGoogle();
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (error != null && error != 'cancelled') {
      _showError(error);
    }
  }

  Future<void> _guest() async {
    if (_busy) {
      return;
    }

    if (_auth.currentUser?.isAnonymous == true) {
      widget.onGuestAccessGranted?.call();
      return;
    }

    setState(() => _busy = true);
    final error = await _auth.signInAsGuest();
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (error != null) {
      _showError(error);
      return;
    }

    widget.onGuestAccessGranted?.call();
  }

  void _showError(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message), backgroundColor: const Color(0xFFB3261E)));

  Future<void> _openLogin() async {
    setState(() => _loginOpen = true);
    await showLoginSheet(context);
    if (mounted) {
      setState(() => _loginOpen = false);
    }
  }

  Widget _button(
          {required Widget icon,
          required String label,
          required Color color,
          required Color textColor,
          required VoidCallback? onPressed}) =>
      SizedBox(
        height: 58,
        child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: textColor,
                disabledBackgroundColor: color.withValues(alpha: .65),
                disabledForegroundColor: textColor.withValues(alpha: .88),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              icon,
              const SizedBox(width: 12),
              Text(label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ])),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF18181A),
        body: Stack(children: [
          Positioned.fill(
              child: ColoredBox(
                  color: Colors.white,
                  child: SafeArea(
                      bottom: false,
                      child: Stack(children: [
                        if (!_loginOpen)
                          Positioned(
                              top: 12,
                              right: 18,
                              child: IconButton(
                                  tooltip: 'Continue as guest',
                                  onPressed: _busy ? null : _guest,
                                  style: IconButton.styleFrom(
                                      backgroundColor: const Color(0xFFEAEAEC)),
                                  icon: const Icon(Icons.close_rounded,
                                      color: Color(0xFF73737A)))),
                        Center(
                            child: Transform.translate(
                                offset: const Offset(0, -20),
                                child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset('assets/app_logo.png',
                                          width: 112, height: 112),
                                      const SizedBox(height: 18),
                                      const Text('StallSeeker',
                                          style: TextStyle(
                                              fontSize: 34,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.textDark,
                                              letterSpacing: -1.1)),
                                      const SizedBox(height: 12),
                                      const Text(
                                          'Find nearby food stalls, live.',
                                          style: TextStyle(
                                              fontSize: 15,
                                              color: Color(0xFF77777E))),
                                    ]))),
                      ])))),
          Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                  padding: EdgeInsets.fromLTRB(
                      24, 28, 24, MediaQuery.paddingOf(context).bottom + 20),
                  decoration: const BoxDecoration(
                      color: Color(0xFF18181A),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(40))),
                  child: Center(
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            _button(
                                icon: Image.asset('assets/google_logo.png',
                                    width: 21, height: 21),
                                label: 'Continue with Google',
                                color: Colors.white,
                                textColor: Colors.black,
                                onPressed: _busy ? null : _google),
                            const SizedBox(height: 12),
                            _button(
                                icon: const Icon(Icons.mail_outline_rounded,
                                    size: 22),
                                label: 'Log in or sign up',
                                color: const Color(0xFF2D2D30),
                                textColor: Colors.white,
                                onPressed: _busy ? null : _openLogin),
                            if (_busy) ...[
                              const SizedBox(height: 16),
                              const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary)),
                            ],
                          ]))))),
        ]),
      );
}
