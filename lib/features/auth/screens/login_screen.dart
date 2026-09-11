import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

Future<void> showLoginSheet(BuildContext context) {
  final media = MediaQuery.of(context);
  final useDialog = media.size.shortestSide >= 600;

  if (useDialog) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: .32),
      builder: (dialogContext) {
        final dialogMedia = MediaQuery.of(dialogContext);
        final availableHeight = dialogMedia.size.height -
            dialogMedia.padding.vertical -
            dialogMedia.viewInsets.bottom -
            64;
        final dialogHeight = availableHeight.clamp(480.0, 660.0).toDouble();

        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: SizedBox(
            width: 520,
            height: dialogHeight,
            child: const LoginScreen(embeddedInDialog: true),
          ),
        );
      },
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: false,
    isDismissible: true,
    enableDrag: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: .28),
    builder: (sheetContext) => AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: .90,
        minChildSize: .55,
        maxChildSize: .96,
        snap: true,
        snapSizes: const [.55, .90],
        builder: (_, controller) => LoginScreen(
          embeddedInSheet: true,
          scrollController: controller,
        ),
      ),
    ),
  );
}

class LoginScreen extends StatefulWidget {
  const LoginScreen(
      {super.key,
      this.embeddedInSheet = false,
      this.embeddedInDialog = false,
      this.scrollController})
      : assert(!(embeddedInSheet && embeddedInDialog));
  final bool embeddedInSheet;
  final bool embeddedInDialog;
  final ScrollController? scrollController;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  StreamSubscription<User?>? _authSub;
  bool _busy = false;
  bool _hidePassword = true;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null &&
          !user.isAnonymous &&
          mounted &&
          Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _busy = true);
    final error =
        await _auth.login(email: _email.text.trim(), password: _password.text);
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (error != null) {
      _showError(error);
    }
  }

  Future<void> _google() async {
    if (_busy) {
      return;
    }
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

  void _close() {
    if (!_busy) {
      Navigator.maybePop(context);
    }
  }

  void _showError(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message), backgroundColor: const Color(0xFFB3261E)));

  @override
  void dispose() {
    _authSub?.cancel();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  InputDecoration _field(String label, {Widget? suffix}) => InputDecoration(
        labelText: label,
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFD5D5D8))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFD5D5D8))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFB3261E))),
      );

  Widget _divider() => const Row(children: [
        Expanded(child: Divider(color: Color(0xFFE3E3E5))),
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Text('OR',
                style: TextStyle(fontSize: 13, color: Color(0xFF77777E)))),
        Expanded(child: Divider(color: Color(0xFFE3E3E5))),
      ]);

  Widget _panel(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: widget.embeddedInDialog
            ? BorderRadius.circular(28)
            : widget.embeddedInSheet
                ? const BorderRadius.vertical(top: Radius.circular(28))
                : BorderRadius.zero,
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          if (widget.embeddedInSheet) ...[
            const SizedBox(height: 10),
            Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                    color: const Color(0xFFD2D2D5),
                    borderRadius: BorderRadius.circular(3))),
          ],
          Expanded(
              child: SingleChildScrollView(
            controller: widget.scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(
                24,
                widget.embeddedInSheet ? 6 : 18,
                24,
                widget.embeddedInDialog
                    ? 24
                    : MediaQuery.paddingOf(context).bottom + 28),
            child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                            tooltip: 'Close',
                            onPressed: _busy ? null : _close,
                            style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFEAEAEC)),
                            icon: const Icon(Icons.close_rounded,
                                color: Color(0xFF73737A)))),
                    Center(
                        child: Image.asset('assets/app_logo.png',
                            width: 54, height: 54)),
                    const SizedBox(height: 10),
                    const Text('Log in or sign up',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -.4)),
                    const SizedBox(height: 8),
                    const Text(
                        'Follow favourite stalls and receive live updates.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            color: Color(0xFF707078))),
                    const SizedBox(height: 28),
                    TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: _field('Email address'),
                        validator: (value) =>
                            value == null || !value.trim().contains('@')
                                ? 'Enter a valid email address.'
                                : null),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _password,
                        obscureText: _hidePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _login(),
                        decoration: _field('Password',
                            suffix: IconButton(
                                onPressed: () => setState(
                                    () => _hidePassword = !_hidePassword),
                                icon: Icon(_hidePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined))),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter your password.'
                            : null),
                    Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                            onPressed: _busy
                                ? null
                                : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ForgotPasswordScreen(
                                            initialEmail: _email.text.trim()))),
                            child: const Text('Forgot password?',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600)))),
                    SizedBox(
                        height: 56,
                        child: FilledButton(
                            onPressed: _busy ? null : _login,
                            style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28))),
                            child: _busy
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Text('Continue',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)))),
                    const SizedBox(height: 22),
                    _divider(),
                    const SizedBox(height: 18),
                    SizedBox(
                        height: 56,
                        child: OutlinedButton(
                            onPressed: _busy ? null : _google,
                            style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black,
                                side:
                                    const BorderSide(color: Color(0xFFD5D5D8)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28))),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset('assets/google_logo.png',
                                      width: 21, height: 21),
                                  const SizedBox(width: 12),
                                  const Text('Continue with Google',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                                ]))),
                    const SizedBox(height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text("Don't have an account? ",
                          style: TextStyle(color: Color(0xFF707078))),
                      TextButton(
                          onPressed: _busy
                              ? null
                              : () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const RegisterScreen())),
                          child: const Text('Sign up',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600))),
                    ]),
                  ],
                )),
          )),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    if (widget.embeddedInSheet || widget.embeddedInDialog) {
      return _panel(context);
    }
    return Scaffold(
        backgroundColor: Colors.white, body: SafeArea(child: _panel(context)));
  }
}
