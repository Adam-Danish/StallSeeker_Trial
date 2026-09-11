import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/auth_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _authService = AuthService();
  final _codeController = TextEditingController();
  bool _isSending = false;
  bool _isVerifying = false;
  bool _messageIsError = false;
  String? _message;

  String get _email => FirebaseAuth.instance.currentUser?.email ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendCode());
  }

  Future<void> _sendCode() async {
    if (_isSending || _email.isEmpty) {
      return;
    }
    setState(() {
      _isSending = true;
      _message = null;
    });
    final error = await _authService.requestEmailVerificationCode();
    if (!mounted) {
      return;
    }
    setState(() {
      _isSending = false;
      _messageIsError = error != null;
      _message = error ?? 'A six-digit code was sent to $_email.';
    });
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() {
        _message = 'Enter the complete six-digit code.';
        _messageIsError = true;
      });
      return;
    }
    setState(() {
      _isVerifying = true;
      _message = null;
    });
    final error = await _authService.confirmEmailVerificationCode(code: code);
    if (!mounted) {
      return;
    }
    setState(() {
      _isVerifying = false;
      _messageIsError = error != null;
      _message = error ?? 'Email verified successfully.';
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
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
                        'Enter the code sent to $_email. The code expires in 10 minutes.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade700)),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _codeController,
                      enabled: !_isVerifying,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 10),
                      decoration: const InputDecoration(
                          labelText: 'Verification code',
                          counterText: '',
                          border: OutlineInputBorder()),
                      onSubmitted: (_) => _verifyCode(),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 12),
                      Text(_message!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _messageIsError
                                  ? Colors.red
                                  : Colors.green.shade700)),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _isVerifying ? null : _verifyCode,
                      child: _isVerifying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Verify Email'),
                    ),
                    TextButton(
                      onPressed: _isSending ? null : _sendCode,
                      child:
                          Text(_isSending ? 'Sending code...' : 'Resend code'),
                    ),
                    TextButton(
                      onPressed: _isVerifying ? null : _authService.signOut,
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
