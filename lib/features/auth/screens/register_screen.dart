import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  String _role = 'customer';
  bool _busy = false;
  bool _hidePassword = true;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _busy = true);
    final error = await _auth.signUp(email: _email.text.trim(), password: _password.text,
      fullName: _name.text.trim(), role: _role);
    if (!mounted) return;
    setState(() => _busy = false);
    if (error == null) {
      Navigator.maybePop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error), backgroundColor: const Color(0xFFB3261E)));
    }
  }

  Future<void> _guest() async {
    if (_busy) return;
    if (FirebaseAuth.instance.currentUser?.isAnonymous == true) {
      Navigator.maybePop(context); return;
    }
    setState(() => _busy = true);
    final error = await _auth.signInAsGuest();
    if (!mounted) return;
    setState(() => _busy = false);
    if (error == null) {
      Navigator.maybePop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error), backgroundColor: const Color(0xFFB3261E)));
    }
  }

  InputDecoration _field(String label, {Widget? suffix}) => InputDecoration(
    labelText: label, suffixIcon: suffix, filled: true, fillColor: const Color(0xFFF5F5F7),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.4)),
    errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: Color(0xFFB3261E))),
  );

  @override
  void dispose() { _name.dispose(); _email.dispose(); _password.dispose(); _confirm.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: Colors.white,
    body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520),
      child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Align(alignment: Alignment.centerRight, child: IconButton(
            tooltip: 'Continue as guest', onPressed: _busy ? null : _guest,
            style: IconButton.styleFrom(backgroundColor: const Color(0xFFF0F0F2)),
            icon: const Icon(Icons.close_rounded, color: Color(0xFF6E6E73)))),
          const SizedBox(height: 18),
          const Icon(Icons.storefront_rounded, size: 46, color: AppColors.primary),
          const SizedBox(height: 14),
          const Text('Create your account', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 27, fontWeight: FontWeight.w600, letterSpacing: -.4)),
          const SizedBox(height: 7),
          const Text('Save favourite stalls and receive live updates.', textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, height: 1.4, color: Color(0xFF707078))),
          const SizedBox(height: 28),
          TextFormField(controller: _name, textInputAction: TextInputAction.next,
            decoration: _field('Full name'),
            validator: (v) => v == null || v.trim().isEmpty ? 'Enter your name.' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _email, keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next, decoration: _field('Email address'),
            validator: (v) => v == null || !v.trim().contains('@') ? 'Enter a valid email address.' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _password, obscureText: _hidePassword,
            textInputAction: TextInputAction.next,
            decoration: _field('Password', suffix: IconButton(
              onPressed: () => setState(() => _hidePassword = !_hidePassword),
              icon: Icon(_hidePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined))),
            validator: (v) => v == null || v.length < 6 ? 'Use at least 6 characters.' : null),
          const SizedBox(height: 12),
          TextFormField(controller: _confirm, obscureText: _hidePassword,
            textInputAction: TextInputAction.done, decoration: _field('Confirm password'),
            validator: (v) => v != _password.text ? 'Passwords do not match.' : null),
          const SizedBox(height: 18),
          const Text('Account type', style: TextStyle(fontSize: 13, color: Color(0xFF707078))),
          const SizedBox(height: 8),
          SegmentedButton<String>(segments: const [
            ButtonSegment(value: 'customer', icon: Icon(Icons.person_outline), label: Text('Customer')),
            ButtonSegment(value: 'vendor', icon: Icon(Icons.storefront_outlined), label: Text('Vendor')),
          ], selected: {_role}, onSelectionChanged: _busy ? null : (v) => setState(() => _role = v.first),
            style: ButtonStyle(shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))))),
          const SizedBox(height: 24),
          SizedBox(height: 56, child: FilledButton(onPressed: _busy ? null : _register,
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
            child: _busy ? const SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Create account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)))),
          const SizedBox(height: 18),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Text('Already have an account? ', style: TextStyle(color: Color(0xFF707078))),
            TextButton(onPressed: _busy ? null : () => Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: const Text('Sign in', style: TextStyle(color: AppColors.primary,
                fontWeight: FontWeight.w600))),
          ]),
        ]))),
    ))));
}
