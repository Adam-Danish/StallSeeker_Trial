import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stallseeker/features/auth/screens/welcome_screen.dart';
import 'package:stallseeker/features/vendor/vendor_main_screen.dart';
import 'package:stallseeker/features/customer/home/customer_home_screen.dart';
import 'package:stallseeker/core/services/notification_service.dart';
import 'package:stallseeker/core/services/auth_service.dart';
import 'screens/email_verification_screen.dart';
import 'resume_navigation.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authStream = FirebaseAuth.instance.userChanges();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
        stream: _authStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _AccountRecovery(
                message: 'Could not check your session. Please sign in again.');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
                body: Center(child: CircularProgressIndicator()));
          }
          final user = snapshot.data;
          if (user == null) {
            resumeNavigation.clearSession();
            return const WelcomeScreen();
          }
          if (user.isAnonymous) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted &&
                  FirebaseAuth.instance.currentUser?.uid == user.uid) {
                resumeNavigation.restore(context, user.uid, 'guest');
              }
            });
            return CustomerHomeScreen(key: ValueKey(user.uid));
          }
          if (!user.emailVerified) {
            resumeNavigation.clearSession();
            NotificationService.instance.setNavigationReady(false);
            return EmailVerificationScreen(key: ValueKey('verify-${user.uid}'));
          }
          return _AccountGate(key: ValueKey(user.uid), user: user);
        });
  }
}

class _AccountGate extends StatefulWidget {
  const _AccountGate({super.key, required this.user});
  final User user;
  @override
  State<_AccountGate> createState() => _AccountGateState();
}

class _AccountGateState extends State<_AccountGate>
    with WidgetsBindingObserver {
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _profile;
  bool _sessionReady = false;
  bool _checkingSession = false;
  bool _sessionFailed = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService.instance.setNavigationReady(false);
    _profile = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .snapshots();
    unawaited(_validateSession());
  }

  Future<void> _validateSession() async {
    if (_checkingSession) return;
    _checkingSession = true;
    try {
      await AuthService().validateCurrentSession();
      if (!mounted ||
          FirebaseAuth.instance.currentUser?.uid != widget.user.uid) {
        return;
      }
      if (!_sessionReady || _sessionFailed) {
        setState(() {
          _sessionReady = true;
          _sessionFailed = false;
        });
      }
    } catch (_) {
      if (mounted && !_sessionReady) {
        NotificationService.instance.setNavigationReady(false);
        setState(() => _sessionFailed = true);
      }
    } finally {
      _checkingSession = false;
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_validateSession());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.instance.setNavigationReady(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _profile,
      builder: (context, snapshot) {
        if (_sessionFailed) {
          return _AccountRecovery(
            message:
                'Could not check your session. Check your connection and retry.',
            retry: _validateSession,
          );
        }
        if (!_sessionReady ||
            snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final role = snapshot.data?.data()?['role'];
        if (snapshot.hasError ||
            !snapshot.hasData ||
            !snapshot.data!.exists ||
            (role != 'vendor' && role != 'customer')) {
          NotificationService.instance.setNavigationReady(false);
          resumeNavigation.clearSession();
          return _AccountRecovery(
            message: snapshot.hasError
                ? 'Could not load your account. Check your connection and retry.'
                : 'This account is no longer available. Sign out to register a new account, or contact support.',
            retry: snapshot.hasError
                ? () => setState(() => _profile = FirebaseFirestore.instance
                    .collection('users')
                    .doc(widget.user.uid)
                    .snapshots())
                : null,
          );
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              FirebaseAuth.instance.currentUser?.uid == widget.user.uid) {
            resumeNavigation.restore(context, widget.user.uid, role as String);
            NotificationService.instance.setNavigationReady(true);
            unawaited(NotificationService.instance.configureForRole(role));
          }
        });
        return role == 'vendor'
            ? const VendorMainScreen()
            : const CustomerHomeScreen();
      },
    );
  }
}

class _AccountRecovery extends StatelessWidget {
  const _AccountRecovery({required this.message, this.retry});
  final String message;
  final VoidCallback? retry;
  @override
  Widget build(BuildContext context) => Scaffold(
          body: Center(
              child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_outlined, size: 40),
          const SizedBox(height: 16),
          Text(message, textAlign: TextAlign.center),
          if (retry != null)
            TextButton(onPressed: retry, child: const Text('Retry')),
          TextButton(
              onPressed: () async {
                try {
                  await AuthService().signOut();
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Could not sign out. Please retry.')));
                  }
                }
              },
              child: const Text('Sign out')),
        ]),
      )));
}
