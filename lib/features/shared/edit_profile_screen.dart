import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/auth_service.dart';
import 'account_ui.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.name, required this.email});
  final String name;
  final String email;
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  final _auth = AuthService();
  late final TextEditingController _name = TextEditingController(text: widget.name);
  bool _busy = false;
  String? _error;
  @override
  void dispose() { _name.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) { return; }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      setState(() => _error = 'Please sign in to edit your profile.'); return;
    }
    FocusScope.of(context).unfocus();
    setState(() { _busy = true; _error = null; });
    final error = await _auth.updateFullName(user.uid, _name.text.trim());
    if (!mounted) { return; }
    setState(() { _busy = false; _error = error; });
    if (error == null) { Navigator.pop(context, true); }
  }

  @override
  Widget build(BuildContext context) => AccountLayout(title: 'Edit profile', busy: _busy,
    children: [
      const AccountIntro(icon: Icons.person_outline_rounded, title: 'Make it yours',
        body: 'Keep your name up to date so your account feels like you.'),
      Form(key: _form, child: Column(children: [
        TextFormField(controller: _name, enabled: !_busy, maxLength: 80,
          textCapitalization: TextCapitalization.words,
          autofillHints: const [AutofillHints.name], textInputAction: TextInputAction.done,
          decoration: accountField('Full name'),
          validator: (value) => (value ?? '').trim().isEmpty ? 'Enter your name.' : null,
          onFieldSubmitted: (_) => _save()),
        const SizedBox(height: 12),
        TextFormField(initialValue: widget.email, readOnly: true,
          decoration: accountField('Email address', suffix: const Icon(Icons.lock_outline, size: 20),
            helper: 'This is the email linked to your sign-in account.')),
      ])),
      const SizedBox(height: 24), AccountError(_error),
      AccountButton(label: 'Save changes', busy: _busy, onPressed: _save),
    ]);
}
