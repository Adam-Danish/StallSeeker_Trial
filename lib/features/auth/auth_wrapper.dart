import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stallseeker/features/auth/screens/welcome_screen.dart';
import 'package:stallseeker/features/vendor/vendor_main_screen.dart';
import 'package:stallseeker/features/customer/home/customer_home_screen.dart';
import 'package:stallseeker/core/services/notification_service.dart';
import 'package:stallseeker/core/services/auth_service.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authStream = FirebaseAuth.instance.authStateChanges();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(stream: _authStream, builder: (context, snapshot) {
      if (snapshot.hasError) { return const _AccountRecovery(message: 'Could not check your session. Please sign in again.'); }
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final user = snapshot.data;
      if (user == null) { return const WelcomeScreen(); }
      if (user.isAnonymous) { return const CustomerHomeScreen(); }
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

class _AccountGateState extends State<_AccountGate> {
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _profile;
  @override
  void initState() {
    super.initState();
    _listen();
    unawaited(NotificationService.instance.syncTokenForCurrentUser());
  }

  void _listen() {
    _profile = FirebaseFirestore.instance.collection('users').doc(widget.user.uid).snapshots();
  }

  @override
  void dispose() {
    NotificationService.instance.setNavigationReady(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final role = snapshot.data?.data()?['role'];
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists ||
            (role != 'vendor' && role != 'customer')) {
          NotificationService.instance.setNavigationReady(false);
          return _AccountRecovery(
            message: snapshot.hasError
                ? 'Could not load your account. Check your connection and retry.'
                : 'Your account setup is incomplete. Retry, or sign out and contact support.',
            retry: () => setState(_listen),
          );
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) { NotificationService.instance.setNavigationReady(role == 'customer'); }
        });
        return role == 'vendor' ? const VendorMainScreen() : const CustomerHomeScreen();
      },
    );
  }
}

class _AccountRecovery extends StatelessWidget {
  const _AccountRecovery({required this.message, this.retry});
  final String message;
  final VoidCallback? retry;
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.cloud_off_outlined, size: 40),
      const SizedBox(height: 16),
      Text(message, textAlign: TextAlign.center),
      if (retry != null) TextButton(onPressed: retry, child: const Text('Retry')),
      TextButton(onPressed: () async {
        try { await AuthService().signOut(); }
        catch (_) {
          if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not sign out. Please retry.'))); }
        }
      }, child: const Text('Sign out')),
    ]),
  )));
}
