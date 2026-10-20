import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import 'account_ui.dart';
import 'profile_header.dart';

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
  late final TextEditingController _name =
      TextEditingController(text: widget.name);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_form.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      setState(() => _error = 'Please sign in to edit your profile.');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await _auth.updateFullName(user.uid, _name.text.trim());
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
    if (error == null) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_busy,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Form(
              key: _form,
              child: ListView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                children: [
                  SizedBox(
                    height: 116,
                    child: Stack(alignment: Alignment.topCenter, children: [
                      Positioned(
                        top: 12,
                        child: ProfileAvatar(
                          name: widget.name,
                          photoUrl: FirebaseAuth.instance.currentUser?.photoURL,
                          size: 100,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        child: ProfileTopAction(
                          label: 'Cancel',
                          onTap: _busy ? null : () => Navigator.pop(context),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: ProfileTopAction(
                          label: _busy ? 'Saving…' : 'Done',
                          onTap: _busy ? null : _save,
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 46),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    clipBehavior: Clip.antiAlias,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextFormField(
                        controller: _name,
                        enabled: !_busy,
                        maxLength: 80,
                        textCapitalization: TextCapitalization.words,
                        autofillHints: const [AutofillHints.name],
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          hintText: 'Full name',
                          counterText: '',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 19),
                        ),
                        style: const TextStyle(fontSize: 17),
                        validator: (value) => (value ?? '').trim().isEmpty
                            ? 'Enter your name.'
                            : null,
                        onFieldSubmitted: (_) => _save(),
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      'This name appears on your StallSeeker account.',
                      style:
                          TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Email address',
                              style: TextStyle(
                                  fontSize: 13, color: AppColors.textMuted)),
                          const SizedBox(height: 5),
                          Text(widget.email,
                              style: const TextStyle(fontSize: 17)),
                        ],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Text(
                      'Your sign-in email cannot be changed here.',
                      style:
                          TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 20),
                  AccountError(_error),
                ],
              ),
            ),
          ),
        ),
      );
}
