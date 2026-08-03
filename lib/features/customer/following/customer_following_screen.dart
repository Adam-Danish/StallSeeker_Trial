import 'package:flutter/material.dart';

/// Placeholder for now. Will be replaced with a real list once
/// the Follow/Unfollow feature (roadmap step 5) is built.
class CustomerFollowingScreen extends StatelessWidget {
  const CustomerFollowingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Text(
          'Followed vendors will appear here.\n(Coming soon)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
