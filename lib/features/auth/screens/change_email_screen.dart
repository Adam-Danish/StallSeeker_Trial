import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/auth_service.dart';

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeSent = false;
  bool _isBusy = false;

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isBusy = true);
    final error = await _authService.requestEmailVerificationCode(
        newEmail: _emailController.text.trim());
    if (!mounted) {
      return;
    }
    setState(() {
      _isBusy = false;
      if (error == null) {
        _codeSent = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ??
          'Verification code sent to ${_emailController.text.trim()}.'),
      backgroundColor: error == null ? Colors.green : Colors.red,
    ));
  }

  Future<void> _confirmCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter the complete six-digit code.')));
      return;
    }
    setState(() => _isBusy = true);
    final error = await _authService.confirmEmailVerificationCode(
        code: code, newEmail: _emailController.text.trim());
    if (!mounted) {
      return;
    }
    setState(() => _isBusy = false);
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Email changed and verified successfully.'),
          backgroundColor: Colors.green));
      Navigator.pop(context, true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
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
                  const Text(
                      'We will send a six-digit verification code to your new email address. Your email changes only after the correct code is entered.'),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    readOnly: _codeSent,
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
                  if (_codeSent) ...[
                    TextField(
                      controller: _codeController,
                      enabled: !_isBusy,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                          labelText: 'Verification code',
                          counterText: '',
                          border: OutlineInputBorder()),
                      onSubmitted: (_) => _confirmCode(),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _isBusy ? null : _confirmCode,
                      child: _isBusy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Verify and Change Email'),
                    ),
                    TextButton(
                        onPressed: _isBusy ? null : _sendCode,
                        child: const Text('Resend code')),
                  ] else
                    FilledButton(
                      onPressed: _isBusy ? null : _sendCode,
                      child: _isBusy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Send Verification Code'),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
}
