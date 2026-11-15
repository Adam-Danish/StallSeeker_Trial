import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stallseeker/features/auth/screens/welcome_screen.dart';
import 'package:stallseeker/features/vendor/vendor_main_screen.dart';
import 'package:stallseeker/features/customer/home/customer_home_screen.dart';
import 'package:stallseeker/core/services/notification_service.dart';
import 'package:stallseeker/core/services/auth_service.dart';
import '../../core/models/user_model.dart';
import '../../core/widgets/web_page_navigation.dart';
import '../shared/change_password_screen.dart';
import '../shared/edit_profile_screen.dart';
import '../shared/personal_information_screen.dart';
import 'screens/email_verification_screen.dart';
import 'resume_navigation.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key, this.initialUri});
  final Uri? initialUri;
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authStream = FirebaseAuth.instance.userChanges();
  bool _hadSession = false;

  void _showWelcomePath() {
    if (!kIsWeb || (!_hadSession && (widget.initialUri?.path ?? '/') != '/')) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && FirebaseAuth.instance.currentUser == null) {
        webPageNavigation.showShellPath(ModalRoute.of(context), '/');
      }
    });
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
          if (user == null) {
            resumeNavigation.clearSession();
            _showWelcomePath();
            return const WelcomeScreen();
          }
          _hadSession = true;
          if (user.isAnonymous) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted &&
                  FirebaseAuth.instance.currentUser?.uid == user.uid) {
                resumeNavigation.restore(context, user.uid, 'guest',
                    initialUri: widget.initialUri);
              }
            });
            return CustomerHomeScreen(
                key: ValueKey(user.uid), initialPath: widget.initialUri?.path);
          }
          if (!user.emailVerified) {
            resumeNavigation.clearSession();
            NotificationService.instance.setNavigationReady(false);
            return EmailVerificationScreen(key: ValueKey('verify-${user.uid}'));
          }
          return _AccountGate(
              key: ValueKey(user.uid),
              user: user,
              initialUri: widget.initialUri);
        });
  }
}

class _AccountGate extends StatefulWidget {
  const _AccountGate({super.key, required this.user, this.initialUri});
  final User user;
  final Uri? initialUri;
  @override
  State<_AccountGate> createState() => _AccountGateState();
}

class _AccountGateState extends State<_AccountGate>
    with WidgetsBindingObserver {
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _profile;
  bool _sessionReady = false;
  bool _checkingSession = false;
  bool _sessionFailed = false;

  Widget? _linkedAccountPage(Map<String, dynamic> data, String role) {
    final path = widget.initialUri?.path;
    if (path != '/edit-profile' &&
        path != '/personal-information' &&
        path != '/change-password') {
      return null;
    }
    final profile = UserModel.fromMap(data, widget.user.uid);
    final email = widget.user.email ?? profile.email;
    return switch (path) {
      '/edit-profile' => EditProfileScreen(
          name: profile.fullName,
          email: email,
          phoneNumber: profile.phoneNumber,
          editPhone: role == 'customer',
        ),
      '/personal-information' => PersonalInformationScreen(
          name: profile.fullName,
          email: email,
          phoneNumber: profile.phoneNumber,
          isVendor: role == 'vendor',
        ),
      _ => ChangePasswordScreen(email: email),
    };
  }

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
            final accountRole = role as String;
            resumeNavigation.restore(context, widget.user.uid, accountRole,
                initialUri: widget.initialUri,
                accountPage:
                    _linkedAccountPage(snapshot.data!.data()!, accountRole));
            NotificationService.instance.setNavigationReady(true);
            unawaited(NotificationService.instance.configureForRole(role));
          }
        });
        return role == 'vendor'
            ? VendorMainScreen(initialPath: widget.initialUri?.path)
            : CustomerHomeScreen(initialPath: widget.initialUri?.path);
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
