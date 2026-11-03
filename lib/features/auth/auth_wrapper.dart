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

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authStream = FirebaseAuth.instance.userChanges();
  bool _guestAccessGranted = false;

  void _grantGuestAccess() {
    if (!mounted) return;
    setState(() => _guestAccessGranted = true);
  }

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
          if (user == null || (user.isAnonymous && !_guestAccessGranted)) {
            return WelcomeScreen(onGuestAccessGranted: _grantGuestAccess);
          }
          if (user.isAnonymous) {
            return const CustomerHomeScreen();
          }
          if (!user.emailVerified) {
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
  late Future<void> _session;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listen();
  }

  void _listen() {
    NotificationService.instance.setNavigationReady(false);
    _session = AuthService().validateCurrentSession();
    _profile = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .snapshots();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) setState(_listen);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationService.instance.setNavigationReady(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _session,
      builder: (context, session) {
        if (session.connectionState != ConnectionState.done) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        if (session.hasError) {
          return _AccountRecovery(
            message:
                'Could not check your session. Check your connection and retry.',
            retry: () => setState(_listen),
          );
        }
        if (FirebaseAuth.instance.currentUser == null) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _profile,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }
            final role = snapshot.data?.data()?['role'];
            if (snapshot.hasError ||
                !snapshot.hasData ||
                !snapshot.data!.exists ||
                (role != 'vendor' && role != 'customer')) {
              NotificationService.instance.setNavigationReady(false);
              return _AccountRecovery(
                message: snapshot.hasError
                    ? 'Could not load your account. Check your connection and retry.'
                    : 'This account is no longer available. Sign out to register a new account, or contact support.',
                retry: snapshot.hasError ? () => setState(_listen) : null,
              );
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                NotificationService.instance.setNavigationReady(true);
                unawaited(NotificationService.instance.configureForRole(role));
              }
            });
            return role == 'vendor'
                ? const VendorMainScreen()
                : const CustomerHomeScreen();
          },
        );
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
