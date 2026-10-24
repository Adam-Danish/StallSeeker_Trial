import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/services/auth_service.dart';
import 'edit_profile_screen.dart';
import 'profile_header.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({
    super.key,
    required this.name,
    required this.email,
    required this.isVendor,
  });

  final String name;
  final String email;
  final bool isVendor;

  @override
  State<PersonalInformationScreen> createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  late String _name = widget.name;

  Future<void> _edit() async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(name: _name, email: widget.email),
      ),
    );
    if (changed != true || !mounted) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final data = await AuthService().getUserData(uid);
    if (mounted) {
      setState(() => _name = data?.fullName ??
          FirebaseAuth.instance.currentUser?.displayName ??
          _name);
    }
  }

  Widget _detail(String label, String value, {bool accent = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 14, color: AppColors.textDark)),
            const SizedBox(height: 3),
            SelectableText(
              value.isEmpty ? 'Not available' : value,
              style: TextStyle(
                fontSize: 17,
                color: accent ? AppColors.primary : AppColors.textDark,
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final providers =
        user?.providerData.map((p) => p.providerId).toSet() ?? <String>{};
    final methods = providers
        .map((p) => p == 'google.com'
            ? 'Google'
            : p == 'password'
                ? 'Email and password'
                : p)
        .join(', ');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            SizedBox(
              height: 116,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  Positioned(
                    top: 12,
                    child: ProfileAvatar(
                        name: _name, photoUrl: user?.photoURL, size: 100),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: ProfileTopAction(
                      label: 'Back',
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: ProfileTopAction(label: 'Edit', onTap: _edit),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _name,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 28,
                height: 1.1,
                letterSpacing: -.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.isVendor ? 'Vendor account' : 'Customer account',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: AppColors.textMuted),
            ),
            const SizedBox(height: 46),
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _detail('name', _name),
                  const Divider(indent: 16, endIndent: 16, height: .5),
                  _detail('email', widget.email, accent: true),
                  const Divider(indent: 16, endIndent: 16, height: .5),
                  _detail(
                      'account type', widget.isVendor ? 'Vendor' : 'Customer'),
                  const Divider(indent: 16, endIndent: 16, height: .5),
                  _detail('sign-in method', methods),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
