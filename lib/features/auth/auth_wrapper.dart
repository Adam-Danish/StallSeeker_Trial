import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stallseeker/core/models/user_model.dart';
import 'package:stallseeker/core/services/auth_service.dart';
import 'package:stallseeker/features/auth/screens/login_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return StreamBuilder<User?>(
      stream: authService.authStateChanges,
      builder: (context, snapshot) {
        // If checking auth state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If user is logged in
        if (snapshot.hasData && snapshot.data != null) {
          return FutureBuilder<UserModel?>(
            future: authService.getUserData(snapshot.data!.uid),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              final userModel = userSnapshot.data;

              if (userModel != null && userModel.role == 'vendor') {
                return Scaffold(
                  appBar: AppBar(
                    title: const Text('Vendor Dashboard'),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.logout),
                        onPressed: () => authService.signOut(),
                      )
                    ],
                  ),
                  body: Center(
                      child: Text('Welcome, Vendor ${userModel.fullName}!')),
                );
              }

              // Default: Customer Home
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Customer Home'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () => authService.signOut(),
                    )
                  ],
                ),
                body: Center(
                  child:
                      Text('Welcome, Customer ${userModel?.fullName ?? ''}!'),
                ),
              );
            },
          );
        }

        // If not logged in
        return const LoginScreen();
      },
    );
  }
}
