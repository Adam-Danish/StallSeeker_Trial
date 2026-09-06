import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../shared/account_ui.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});
  final String initialEmail;
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  Timer? _timer;
  int _seconds = 0;
  bool _busy = false;
  bool _sent = false;
  String? _error;
  String _sentTo = '';
  @override
  void dispose() { _timer?.cancel(); _email.dispose(); super.dispose(); }

  Future<void> _send() async {
    if (_busy || _seconds > 0) { return; }
    if (!_sent && !_form.currentState!.validate()) { return; }
    FocusScope.of(context).unfocus();
    final address = _email.text.trim();
    setState(() { _busy = true; _error = null; });
    final error = await AuthService().resetPassword(email: address);
    if (!mounted) { return; }
    setState(() {
      _busy = false; _error = error;
      if (error == null) { _sent = true; _sentTo = address; _seconds = 60; }
    });
    if (error == null) {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) { timer.cancel(); return; }
        setState(() { if (_seconds > 0) { _seconds--; } });
        if (_seconds == 0) { timer.cancel(); }
      });
    }
  }

  @override
  Widget build(BuildContext context) => AccountLayout(title: 'Forgot password', busy: _busy,
    children: [
      const SizedBox(height: 24),
      AccountIntro(icon: _sent ? Icons.mark_email_read_outlined : Icons.lock_reset_rounded,
        title: _sent ? 'Check your email' : 'Reset your password',
        body: _sent
          ? 'If an account uses $_sentTo, you will receive a link to reset its password.'
          : 'Enter the email address linked to your account. We will send you a reset link.'),
      if (!_sent) ...[
        Form(key: _form, child: TextFormField(controller: _email, enabled: !_busy,
          keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email], autocorrect: false,
          decoration: accountField('Email address'),
          validator: (v) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch((v ?? '').trim())
            ? null : 'Enter a valid email address.',
          onFieldSubmitted: (_) => _send())),
        const SizedBox(height: 24), AccountError(_error),
        AccountButton(label: _seconds > 0 ? 'Send again in ${_seconds}s' : 'Send reset link',
          busy: _busy, onPressed: _seconds > 0 ? null : _send),
        const SizedBox(height: 20),
        const Text('Signed up with Google? Use Continue with Google to sign in.',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF707078), height: 1.5)),
      ] else ...[
        const Text('Open the email and follow the link to choose a new password. Check Spam or Junk if it is missing.',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Color(0xFF707078), height: 1.5)),
        const SizedBox(height: 28), AccountError(_error),
        AccountButton(label: 'Done', onPressed: _busy ? null : () => Navigator.pop(context)),
        const SizedBox(height: 12),
        TextButton(onPressed: _busy || _seconds > 0 ? null : _send,
          child: Text(_busy ? 'Sending…' : _seconds > 0 ? 'Resend in ${_seconds}s' : 'Resend email')),
        TextButton(onPressed: _busy ? null : () => setState(() { _sent = false; _error = null; }),
          child: const Text('Use another email')),
      ],
    ]);
}
