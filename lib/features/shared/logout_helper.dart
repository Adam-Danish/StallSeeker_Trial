import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';

// Shows a confirmation dialog before logging out. Used by every logout
// button in the app (customer AppBar icon, customer profile, vendor
// dashboard AppBar icon, vendor profile) so the confirmation behavior
// stays identical everywhere instead of being copy-pasted per screen.
Future<void> confirmAndLogout(
  BuildContext context,
  AuthService authService,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Log Out'),
      content: const Text('Are you sure you want to log out?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Log Out'),
        ),
      ],
    ),
  );

  if (confirmed == true) {
    try {
      await authService.signOut();
      if (context.mounted) { Navigator.of(context).popUntil((route) => route.isFirst); }
    } catch (_) {
      if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not finish logging out. Please retry.')),
      ); }
    }
  }
}
