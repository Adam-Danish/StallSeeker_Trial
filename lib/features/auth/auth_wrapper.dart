import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/welcome_screen.dart';
import '../vendor/vendor_main_screen.dart';
import '../customer/home/customer_home_screen.dart';
import '../../core/services/notification_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;

          // Guests (anonymous sign-in) skip the Firestore role lookup
          // entirely and go straight to the customer experience --
          // there's no users/ document for them since they haven't
          // created a real account.
          if (user.isAnonymous) {
            return const CustomerHomeScreen();
          }

          NotificationService.instance.syncTokenForCurrentUser();

          // Live listener (.snapshots()), not a one-time .get(). This
          // matters for brand-new Google sign-ins: Firebase Auth's
          // state updates immediately, but the user's Firestore profile
          // document gets created a moment later by signInWithGoogle().
          // A one-time .get() can run in that gap, find nothing, and
          // (since it never checks again) get stuck showing
          // WelcomeScreen forever even after the document exists. A
          // live stream instead automatically re-fires and routes
          // correctly the instant the document appears.
          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .snapshots(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>?;
                final String role = userData?['role'] ?? 'customer';

                if (role == 'vendor') {
                  return const VendorMainScreen();
                } else {
                  return const CustomerHomeScreen();
                }
              }

              // Document doesn't exist yet -- show a brief loading
              // state instead of WelcomeScreen while we wait for it to
              // be created. If the document genuinely never gets
              // created (e.g. signup failed), the user is still signed
              // in at this point, so falling through to WelcomeScreen
              // (which offers sign-in options again) would be
              // confusing; a spinner is a more honest "still working
              // on it" state for the brief moment this normally takes.
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            },
          );
        }

        return const WelcomeScreen();
      },
    );
  }
}
