import 'package:flutter/material.dart';

/// Placeholder for now. Will be replaced with real profile editing,
/// change password, FAQ, and About screens in a later roadmap step.
class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Text(
          'Profile, Change Password, FAQ, and About\nwill appear here.\n(Coming soon)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
