import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';

Future<void> confirmAndLogout(
  BuildContext context,
  AuthService authService,
) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final signedOut = await showCupertinoModalPopup<bool>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    barrierColor: Colors.black45,
    builder: (_) => _LogoutSheet(authService: authService),
  );
  if (signedOut == true && navigator.mounted) {
    navigator.popUntil((route) => route.isFirst);
  }
}

class _LogoutSheet extends StatefulWidget {
  const _LogoutSheet({required this.authService});

  final AuthService authService;

  @override
  State<_LogoutSheet> createState() => _LogoutSheetState();
}

class _LogoutSheetState extends State<_LogoutSheet> {
  bool _busy = false;
  String? _error;
  late final bool _guest =
      FirebaseAuth.instance.currentUser?.isAnonymous ?? true;

  Future<void> _logout() async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.authService.signOut();
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'Could not finish logging out. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_busy,
        child: CupertinoTheme(
          data: const CupertinoThemeData(primaryColor: AppColors.primary),
          child: CupertinoActionSheet(
            title: Text(_guest ? 'Leave Guest Mode?' : 'Log Out?'),
            message: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_guest
                    ? 'You can continue browsing or sign in at any time.'
                    : 'Are you sure you want to log out of StallSeeker?'),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!,
                      style: const TextStyle(color: CupertinoColors.systemRed)),
                ],
              ],
            ),
            actions: [
              CupertinoActionSheetAction(
                isDestructiveAction: true,
                onPressed: _busy ? () {} : _logout,
                child: _busy
                    ? const CupertinoActivityIndicator()
                    : Text(_guest ? 'Leave Guest Mode' : 'Log Out'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: _busy ? () {} : () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
          ),
        ),
      );
}
