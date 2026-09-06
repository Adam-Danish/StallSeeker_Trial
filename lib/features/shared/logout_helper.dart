import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/auth_service.dart';
import 'account_ui.dart';

Future<void> confirmAndLogout(BuildContext context, AuthService authService) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final signedOut = await showDialog<bool>(context: context, barrierDismissible: false,
    builder: (_) => _LogoutDialog(authService: authService));
  if (signedOut == true && navigator.mounted) {
    navigator.popUntil((route) => route.isFirst);
  }
}

class _LogoutDialog extends StatefulWidget {
  const _LogoutDialog({required this.authService});
  final AuthService authService;
  @override
  State<_LogoutDialog> createState() => _LogoutDialogState();
}

class _LogoutDialogState extends State<_LogoutDialog> {
  bool _busy = false;
  String? _error;
  late final bool _guest = FirebaseAuth.instance.currentUser?.isAnonymous ?? true;

  Future<void> _logout() async {
    if (_busy) { return; }
    setState(() { _busy = true; _error = null; });
    try {
      await widget.authService.signOut();
      if (mounted) { Navigator.pop(context, true); }
    } catch (_) {
      if (mounted) { setState(() {
        _busy = false;
        _error = 'Could not finish logging out. Please try again.';
      }); }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(canPop: !_busy,
    child: Dialog(backgroundColor: Colors.white, surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 56, height: 56,
              decoration: const BoxDecoration(color: Color(0xFFFFF0E9), shape: BoxShape.circle),
              child: const Icon(Icons.logout_rounded, color: Color(0xFFFF6E41), size: 26)),
            const SizedBox(height: 20),
            Text(_guest ? 'Leave guest mode?' : 'Log out?',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text(_guest ? 'You can browse again or sign in to your account.'
              : 'Your account details will stay saved. You can sign in again anytime.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF707078), height: 1.5)),
            const SizedBox(height: 24), AccountError(_error),
            AccountButton(label: _guest ? 'Leave guest mode' : 'Log out', busy: _busy,
              onPressed: _logout, color: const Color(0xFFB3261E)),
            const SizedBox(height: 8),
            TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF55555D)))),
          ])))));
}
