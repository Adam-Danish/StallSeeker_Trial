import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import 'account_ui.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});
  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _auth = AuthService();
  final _confirmation = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _hidePassword = true;
  String? _error;

  bool get _usesPassword => FirebaseAuth.instance.currentUser?.providerData
      .any((provider) => provider.providerId == 'password') ?? false;

  Future<void> _delete() async {
    if (_confirmation.text.trim().toUpperCase() != 'DELETE') {
      setState(() => _error = 'Type DELETE to confirm.'); return;
    }
    if (_usesPassword && _password.text.isEmpty) {
      setState(() => _error = 'Enter your current password.'); return;
    }
    setState(() { _busy = true; _error = null; });
    final error = await _auth.deleteAccount(currentPassword: _usesPassword ? _password.text : null);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      setState(() { _busy = false; _error = error; });
    }
  }

  @override
  void dispose() { _confirmation.dispose(); _password.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AccountLayout(
    title: 'Delete account', busy: _busy,
    children: [
      const AccountIntro(icon: Icons.delete_outline_rounded, title: 'Delete your account?',
        body: 'This permanently removes your profile, follows, notification history and vendor data. This cannot be undone.'),
      TextField(controller: _confirmation, enabled: !_busy,
        textCapitalization: TextCapitalization.characters,
        decoration: accountField('Type DELETE to confirm')),
      if (_usesPassword) ...[
        const SizedBox(height: 14),
        TextField(controller: _password, enabled: !_busy, obscureText: _hidePassword,
          decoration: accountField('Current password', suffix: IconButton(
            onPressed: _busy ? null : () => setState(() => _hidePassword = !_hidePassword),
            icon: Icon(_hidePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined)))),
      ],
      const SizedBox(height: 16),
      AccountError(_error),
      AccountButton(label: 'Delete account permanently', busy: _busy,
        color: const Color(0xFFB3261E), onPressed: _delete),
      const SizedBox(height: 12),
      TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancel')),
    ],
  );
}
