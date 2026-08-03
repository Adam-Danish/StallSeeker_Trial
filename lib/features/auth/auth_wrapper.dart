import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/login_screen.dart';
import '../vendor/dashboard/vendor_dashboard_screen.dart';
import '../customer/home/customer_home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Waiting for auth status
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. User is logged in
        if (snapshot.hasData && snapshot.data != null) {
          final String uid = snapshot.data!.uid;

          return FutureBuilder<DocumentSnapshot>(
            future:
                FirebaseFirestore.instance.collection('users').doc(uid).get(),
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
                  return const VendorDashboardScreen();
                } else {
                  return const CustomerHomeScreen();
                }
              }

              return const LoginScreen();
            },
          );
        }

        // 3. User is NOT logged in
        return const LoginScreen();
      },
    );
  }
}
