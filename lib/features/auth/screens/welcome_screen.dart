import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _continueWithGoogle() async {
    setState(() => _isLoading = true);
    final error = await _authService.signInWithGoogle();
    if (mounted) setState(() => _isLoading = false);

    // "cancelled" means the user just closed the Google picker --
    // not a real error, so nothing to show them.
    if (error != null && error != 'cancelled' && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
    // On success, AuthWrapper's auth-state stream swaps this screen
    // out automatically -- no manual navigation needed here.
  }

  Future<void> _continueAsGuest() async {
    setState(() => _isLoading = true);
    final error = await _authService.signInAsGuest();
    if (mounted) setState(() => _isLoading = false);

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.storefront, size: 64, color: AppColors.primary),
              const SizedBox(height: 12),
              const Text(
                'StallSeeker',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Find nearby food stalls, live.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _continueWithGoogle,
                icon: const Icon(Icons.login),
                label: const Text('Continue with Google'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _isLoading ? null : _continueAsGuest,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Continue as Guest'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                        );
                      },
                child: const Text('Log In with Email'),
              ),
              if (_isLoading) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
