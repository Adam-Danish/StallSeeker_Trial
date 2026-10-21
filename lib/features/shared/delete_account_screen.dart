import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
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

  bool get _usesPassword =>
      FirebaseAuth.instance.currentUser?.providerData
          .any((provider) => provider.providerId == 'password') ??
      false;

  Future<void> _delete() async {
    if (_busy) return;
    if (_confirmation.text.trim().toUpperCase() != 'DELETE') {
      setState(() => _error = 'Type DELETE to confirm.');
      return;
    }
    if (_usesPassword && _password.text.isEmpty) {
      setState(() => _error = 'Enter your current password.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await _auth.deleteAccount(
      currentPassword: _usesPassword ? _password.text : null,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  void dispose() {
    _confirmation.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AccountLayout(
        title: 'Delete Account',
        busy: _busy,
        children: [
          Center(
            child: Container(
              width: 92,
              height: 92,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE9E7),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.delete_solid,
                color: AppColors.closedRed,
                size: 42,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Delete your account?',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your StallSeeker account and its data will be permanently removed.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 32),
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('What will be removed',
                      style:
                          TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  SizedBox(height: 10),
                  Text(
                    'Your profile, followed stalls and dishes, notification history, and any vendor stall data.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'This cannot be undone.',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.closedRed,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Padding(
            padding: EdgeInsets.only(left: 16, bottom: 10),
            child: Text(
              'CONFIRM DELETION',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
              ),
            ),
          ),
          TextField(
            controller: _confirmation,
            enabled: !_busy,
            textCapitalization: TextCapitalization.characters,
            textInputAction:
                _usesPassword ? TextInputAction.next : TextInputAction.done,
            onSubmitted: _usesPassword ? null : (_) => _delete(),
            decoration: accountField('Type DELETE to confirm'),
          ),
          if (_usesPassword) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _password,
              enabled: !_busy,
              obscureText: _hidePassword,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _delete(),
              decoration: accountField(
                'Current password',
                suffix: IconButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _hidePassword = !_hidePassword),
                  icon: Icon(_hidePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                ),
              ),
            ),
          ],
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 9, 16, 0),
            child: Text(
              'Type DELETE exactly to confirm this permanent action.',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
          ),
          const SizedBox(height: 22),
          AccountError(_error),
          AccountButton(
            label: 'Delete Account',
            busy: _busy,
            color: AppColors.closedRed,
            onPressed: _delete,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _busy ? null : () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.textDark,
                minimumSize: const Size.fromHeight(54),
                shape: const StadiumBorder(),
              ),
              child: const Text('Cancel'),
            ),
          ),
        ],
      );
}
