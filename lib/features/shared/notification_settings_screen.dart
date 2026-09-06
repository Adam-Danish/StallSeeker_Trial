import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/notification_service.dart';
import 'account_ui.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});
  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  bool _enabled = true;
  bool _busy = true;
  AuthorizationStatus _systemStatus = AuthorizationStatus.notDetermined;
  String? _error;

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _load(); }

  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); super.dispose(); }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      if (mounted) {
        setState(() { _busy = false; _error = 'Sign in to manage notifications.'; });
      }
      return;
    }
    try {
      final values = await Future.wait([
        NotificationService.instance.isEnabledForCurrentUser(),
        FirebaseMessaging.instance.getNotificationSettings(),
      ]);
      if (mounted) {
        setState(() {
          _enabled = values[0] as bool;
          _systemStatus = (values[1] as NotificationSettings).authorizationStatus;
          _busy = false; _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() { _busy = false; _error = 'Could not load notification settings.'; });
      }
    }
  }

  Future<void> _toggle(bool value) async {
    setState(() { _busy = true; _error = null; });
    final error = await NotificationService.instance.setEnabledForCurrentUser(value);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (error == null) {
        _enabled = value;
      } else {
        _error = error;
      }
    });
    if (error == null) {
      await _load();
    }
  }

  String get _permissionText {
    if (_systemStatus == AuthorizationStatus.authorized) {
      return 'Allowed by this device';
    }
    if (_systemStatus == AuthorizationStatus.provisional) {
      return 'Quiet notifications allowed';
    }
    if (_systemStatus == AuthorizationStatus.denied) {
      return 'Blocked in phone settings';
    }
    return 'Permission not requested';
  }

  @override
  Widget build(BuildContext context) => AccountLayout(
    title: 'Notifications', busy: _busy,
    background: const Color(0xFFF2F2F7),
    children: [
      Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: SwitchListTile.adaptive(
          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          activeThumbColor: AppColors.primary,
          value: _enabled, onChanged: _busy ? null : _toggle,
          secondary: const Icon(Icons.notifications_active_outlined, color: AppColors.primary),
          title: const Text('Stall notifications', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
          subtitle: const Padding(padding: EdgeInsets.only(top: 4),
            child: Text('Get an alert when a followed stall opens.')),
        )),
      const SizedBox(height: 22),
      Container(padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          const Icon(Icons.phone_android_rounded, color: Color(0xFF8E8E93)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Device permission', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(_permissionText, style: const TextStyle(color: Color(0xFF707078))),
          ])),
        ])),
      if (_systemStatus == AuthorizationStatus.denied) ...[
        const SizedBox(height: 12),
        const Text('Allow notifications in your phone settings, then return to StallSeeker.',
          style: TextStyle(color: Color(0xFF707078), height: 1.4)),
      ],
      if (_error != null) ...[
        const SizedBox(height: 16),
        AccountError(_error),
      ],
      const SizedBox(height: 18),
      const Text('Notification history stays in the app even when alerts are turned off.',
        style: TextStyle(fontSize: 13, height: 1.45, color: Color(0xFF8E8E93))),
    ],
  );
}
