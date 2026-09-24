import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen>
    with WidgetsBindingObserver {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _linkSent = false;
  bool _isBusy = false;
  Timer? _cooldownTimer;
  int _resendSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _linkSent && !_isBusy) {
      _checkNewEmail(quiet: true);
    }
  }

  Future<void> _sendLink() async {
    if (!_formKey.currentState!.validate() || _isBusy || _resendSeconds > 0) {
      return;
    }
    setState(() => _isBusy = true);
    final error = await _authService.sendEmailChangeLink(
      _emailController.text.trim(),
    );
    if (!mounted) return;
    setState(() {
      _isBusy = false;
      if (error == null) {
        _linkSent = true;
        _resendSeconds = 60;
      }
    });
    if (error == null) _startCooldown();
    _showMessage(
      error ?? 'Verification link sent to ${_emailController.text.trim()}.',
      error: error != null,
    );
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

  Future<void> _checkNewEmail({bool quiet = false}) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    final error = await _authService.refreshEmailChange(
      _emailController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isBusy = false);
    if (error == null) {
      _showMessage('Email changed and verified successfully.');
      Navigator.pop(context, true);
    } else if (!quiet) {
      _showMessage(error, error: true);
    }
  }

  void _showMessage(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error ? Colors.red : Colors.green,
    ));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cooldownTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Change Email')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(_linkSent
                      ? 'Open the verification link sent to your new email, then return here and confirm.'
                      : 'Firebase will send a verification link to your new email. Your address changes only after you open that link.'),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    readOnly: _linkSent,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                        labelText: 'New email', border: OutlineInputBorder()),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(email)
                          ? null
                          : 'Enter a valid email address';
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_linkSent) ...[
                    FilledButton.icon(
                      onPressed: _isBusy ? null : () => _checkNewEmail(),
                      icon: _isBusy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.refresh),
                      label: Text(_isBusy
                          ? 'Checking…'
                          : 'I Have Verified My New Email'),
                    ),
                    TextButton(
                      onPressed:
                          _isBusy || _resendSeconds > 0 ? null : _sendLink,
                      child: Text(_resendSeconds > 0
                          ? 'Resend in ${_resendSeconds}s'
                          : 'Resend verification email'),
                    ),
                  ] else
                    FilledButton(
                      onPressed: _isBusy ? null : _sendLink,
                      child: _isBusy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Send Verification Link'),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
}
