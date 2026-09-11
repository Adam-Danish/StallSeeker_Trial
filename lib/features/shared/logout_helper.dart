import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';

Future<void> confirmAndLogout(
  BuildContext context,
  AuthService authService,
) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final signedOut = await showModalBottomSheet<bool>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
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
        child: SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                14,
                24,
                MediaQuery.paddingOf(context).bottom + 24,
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8D8DC),
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 12),
                Row(children: [
                  IconButton(
                    tooltip: 'Close',
                    onPressed:
                        _busy ? null : () => Navigator.pop(context, false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                  Expanded(
                    child: Text(
                      _guest ? 'Leave Guest Mode' : 'Log Out',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ]),
                const Divider(height: 24),
                Container(
                  width: 58,
                  height: 58,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEEE8),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: AppColors.primary,
                    size: 27,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  _guest
                      ? 'Are you sure you want to leave guest mode?'
                      : 'Are you sure you want to log out?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _guest
                      ? 'You can continue browsing or sign in at any time.'
                      : 'Thank you for using StallSeeker. We hope to see you again soon.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: AppColors.textMuted,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Color(0xFFB3261E)),
                  ),
                ],
                const SizedBox(height: 26),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _busy ? null : () => Navigator.pop(context, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textDark,
                        side: const BorderSide(color: Color(0xFFE2E2E6)),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy ? null : _logout,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppColors.primary.withValues(alpha: .65),
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_guest ? 'Yes, Leave' : 'Yes, Log Out'),
                    ),
                  ),
                ]),
              ]),
            ),
          ),
        ),
      );
}
