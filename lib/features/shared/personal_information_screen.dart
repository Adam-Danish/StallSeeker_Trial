import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/auth_service.dart';
import 'account_ui.dart';
import 'edit_profile_screen.dart';

class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key, required this.name, required this.email,
    required this.isVendor});
  final String name;
  final String email;
  final bool isVendor;
  @override
  State<PersonalInformationScreen> createState() => _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  late String _name = widget.name;
  Future<void> _edit() async {
    final changed = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => EditProfileScreen(name: _name, email: widget.email)));
    if (changed != true || !mounted) { return; }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { return; }
    final data = await AuthService().getUserData(uid);
    if (mounted) { setState(() => _name = data?.fullName ?? FirebaseAuth.instance.currentUser?.displayName ?? _name); }
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.all(18), child: Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF707078))),
        const SizedBox(height: 6), SelectableText(value.isEmpty ? 'Not available' : value,
          style: const TextStyle(fontSize: 16, height: 1.4))]));

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final providers = user?.providerData.map((p) => p.providerId).toSet() ?? <String>{};
    final methods = providers.map((p) => p == 'google.com' ? 'Google' : p == 'password' ? 'Email and password' : p).join(', ');
    return AccountLayout(title: 'Personal information', background: const Color(0xFFF2F2F7),
      children: [
        const Text('YOUR ACCOUNT', style: TextStyle(fontSize: 12, color: Color(0xFF707078))),
        const SizedBox(height: 12),
        Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            _row('Full name', _name), const Divider(height: 1),
            _row('Email address', widget.email), const Divider(height: 1),
            _row('Account type', widget.isVendor ? 'Vendor' : 'Customer'), const Divider(height: 1),
            _row('Sign-in method', methods),
          ])),
        const SizedBox(height: 24),
        AccountButton(label: 'Edit profile', onPressed: _edit),
      ]);
  }
}
