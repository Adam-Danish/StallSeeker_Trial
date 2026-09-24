import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen>
    with WidgetsBindingObserver {
  final _authService = AuthService();
  bool _isSending = false;
  bool _isChecking = false;
  bool _messageIsError = false;
  String? _message;
  Timer? _cooldownTimer;
  int _resendSeconds = 0;

  String get _email => FirebaseAuth.instance.currentUser?.email ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendLink());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && !_isSending && !_isChecking) {
      _checkVerification(quiet: true);
    }
  }

  Future<void> _sendLink() async {
    if (!mounted || _isSending || _isChecking || _resendSeconds > 0) return;
    setState(() {
      _isSending = true;
      _message = null;
    });
    final error = await _authService.sendEmailVerificationLink();
    if (!mounted) return;
    setState(() {
      _isSending = false;
      _messageIsError = error != null;
      _message = error ?? 'Verification email sent to $_email.';
      if (error == null) _resendSeconds = 60;
    });
    if (error == null) _startCooldown();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _resendSeconds--);
      if (_resendSeconds <= 0) timer.cancel();
    });
  }

  Future<void> _checkVerification({bool quiet = false}) async {
    if (_isChecking || _isSending) return;
    setState(() {
      _isChecking = true;
      if (!quiet) _message = null;
    });
    final error = await _authService.refreshEmailVerification();
    if (!mounted) return;
    setState(() {
      _isChecking = false;
      if (!quiet || error == null) {
        _messageIsError = error != null;
        _message = error ?? 'Email verified successfully.';
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cooldownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.mark_email_unread_outlined,
                        size: 72, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 20),
                    Text('Verify your email',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                      'We sent a verification link to $_email. Open the email, tap the link, then return here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 16),
                      Text(_message!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _messageIsError
                                  ? Colors.red
                                  : Colors.green.shade700)),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _isChecking || _isSending
                          ? null
                          : () => _checkVerification(),
                      icon: _isChecking
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.refresh),
                      label: Text(_isChecking
                          ? 'Checking…'
                          : 'I Have Verified My Email'),
                    ),
                    TextButton(
                      onPressed: _isSending || _isChecking || _resendSeconds > 0
                          ? null
                          : _sendLink,
                      child: Text(_isSending
                          ? 'Sending email…'
                          : _resendSeconds > 0
                              ? 'Resend in ${_resendSeconds}s'
                              : 'Resend verification email'),
                    ),
                    TextButton(
                      onPressed: _isChecking ? null : _authService.signOut,
                      child: const Text('Use a different account'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
