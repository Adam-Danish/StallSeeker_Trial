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

          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get(),
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

              return const WelcomeScreen();
            },
          );
        }

        return const WelcomeScreen();
      },
    );
  }
}
