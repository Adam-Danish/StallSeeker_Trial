import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import '../auth/screens/forgot_password_screen.dart';
import 'account_ui.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key, required this.email});
  final String email;
  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  final _hidden = [true, true, true];
  bool _busy = false;
  bool _saved = false;
  String? _error;
  @override
  void dispose() { _current.dispose(); _next.dispose(); _confirm.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) { return; }
    FocusScope.of(context).unfocus();
    setState(() { _busy = true; _error = null; });
    // Do not trim passwords: spaces may be intentional.
    final error = await AuthService().changePassword(_next.text, currentPassword: _current.text);
    if (!mounted) { return; }
    setState(() { _busy = false; _error = error; _saved = error == null; });
    if (_saved) { _current.clear(); _next.clear(); _confirm.clear(); }
  }

  Widget _field(String label, TextEditingController controller, int index,
      String? Function(String?) validator) => Padding(padding: const EdgeInsets.only(bottom: 18),
    child: TextFormField(controller: controller, enabled: !_busy, obscureText: _hidden[index],
      enableSuggestions: false, autocorrect: false,
      autofillHints: [index == 0 ? AutofillHints.password : AutofillHints.newPassword],
      textInputAction: index == 2 ? TextInputAction.done : TextInputAction.next,
      onFieldSubmitted: index == 2 ? (_) => _save() : null,
      validator: validator, decoration: accountField(label,
        suffix: IconButton(tooltip: _hidden[index] ? 'Show password' : 'Hide password',
          onPressed: () => setState(() => _hidden[index] = !_hidden[index]),
          icon: Icon(_hidden[index] ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 21, color: const Color(0xFF707078))))));

  @override
  Widget build(BuildContext context) => AccountLayout(title: 'Change password', busy: _busy,
    children: _saved ? [
      const SizedBox(height: 40),
      const AccountIntro(icon: Icons.check_rounded, title: 'Password changed',
        body: 'Your new password is ready. Use it the next time you sign in.'),
      AccountButton(label: 'Back to profile', onPressed: () => Navigator.pop(context)),
    ] : [
      const AccountIntro(icon: Icons.lock_outline_rounded, title: 'Choose a new password',
        body: 'Confirm your current password, then enter a new one.'),
      Form(key: _form, child: AutofillGroup(child: Column(children: [
        _field('Current password', _current, 0,
          (v) => (v ?? '').isEmpty ? 'Enter your current password.' : null),
        _field('New password', _next, 1, (v) {
          if ((v ?? '').length < 6) { return 'Use at least 6 characters.'; }
          if (v == _current.text) { return 'Choose a different password.'; }
          return null;
        }),
        _field('Confirm new password', _confirm, 2,
          (v) => v != _next.text ? 'Your passwords do not match.' : null),
      ]))),
      const Padding(padding: EdgeInsets.only(bottom: 20), child: Text(
        'Use a long, unique password. Your account may require extra characters.',
        style: TextStyle(fontSize: 13, color: Color(0xFF707078), height: 1.4))),
      AccountError(_error),
      AccountButton(label: 'Update password', busy: _busy, onPressed: _save),
      const SizedBox(height: 12),
      TextButton(onPressed: _busy ? null : () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ForgotPasswordScreen(initialEmail: widget.email))),
        child: const Text('Forgot your current password?')),
    ]);
}
