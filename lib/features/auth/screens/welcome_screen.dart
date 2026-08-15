import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import 'login_screen.dart';
import 'register_screen.dart';

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

    if (error != null && error != 'cancelled' && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error), backgroundColor: const Color(0xFFFF6B56)),
      );
    }
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

  void _goToRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  void _goToLogin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // App icon and title
              const Icon(
                Icons.storefront,
                size: 64,
                color: const Color(0xFFFF6E41),
              ),
              const SizedBox(height: 16),
              const Text(
                'StallSeeker',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Find nearby food stalls, live.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 40),

              // ---- Updated: Google button (Light Gray) ----
              _buildActionButton(
                icon: Image.asset('assets/google_logo.png', height: 20),
                label: 'Continue with Google',
                backgroundColor: const Color(0xFFF1F3F4), // Light gray
                foregroundColor: Colors.black, // Dark text
                onPressed: _isLoading ? null : _continueWithGoogle,
              ),
              const SizedBox(height: 10), // SPACING ANTARA BUTTON

              // ---- Updated: Email button (Coral/Orange) ----
              _buildActionButton(
                icon: const Icon(Icons.email_outlined, size: 24),
                label: 'Continue with Email',
                backgroundColor: const Color(0xFFFF6E41), // Vibrant coral
                foregroundColor: Colors.white, // White text
                onPressed: _isLoading ? null : _goToRegister,
              ),
              const SizedBox(height: 10),

              // ---- Updated: Guest button (Dark Black) ----
              _buildActionButton(
                icon: const Icon(Icons.person_outline, size: 24),
                label: 'Continue as Guest',
                backgroundColor: const Color(0xFF1C1C1E), // Dark gray/black
                foregroundColor: Colors.white, // White text
                onPressed: _isLoading ? null : _continueAsGuest,
              ),

              const SizedBox(height: 24),

              // "Already have an account? Sign In"
              Center(
                child: TextButton(
                  onPressed: _isLoading ? null : _goToLogin,
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                      children: const [
                        TextSpan(text: 'Already have an account? '),
                        TextSpan(
                          text: 'Sign In',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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

  // Reusable button – UPDATED to accept background and foreground colors
  Widget _buildActionButton({
    required Widget icon,
    required String label,
    required Color backgroundColor, // New argument
    required Color foregroundColor, // New argument
    VoidCallback? onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: backgroundColor, // The solid background color
        foregroundColor: foregroundColor, // Text & icon color
        side: BorderSide.none, // Removed the gray border entirely
        padding: const EdgeInsets.symmetric(vertical: 22),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50), // Kept your max roundness
        ),
        textStyle: const TextStyle(
            fontSize: 16, fontWeight: FontWeight.w500, fontFamily: 'Poppins'),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}
