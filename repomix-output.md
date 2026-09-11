This file is a merged representation of a subset of the codebase, containing specifically included files, combined into a single document by Repomix.

# File Summary

## Purpose
This file contains a packed representation of a subset of the repository's contents that is considered the most important context.
It is designed to be easily consumable by AI systems for analysis, code review,
or other automated processes.

## File Format
The content is organized as follows:
1. This summary section
2. Repository information
3. Directory structure
4. Repository files (if enabled)
5. Multiple file entries, each consisting of:
  a. A header with the file path (## File: path/to/file)
  b. The full contents of the file in a code block

## Usage Guidelines
- This file should be treated as read-only. Any changes should be made to the
  original repository files, not this packed version.
- When processing this file, use the file path to distinguish
  between different files in the repository.
- Be aware that this file may contain sensitive information. Handle it with
  the same level of security as you would the original repository.

## Notes
- Some files may have been excluded based on .gitignore rules and Repomix's configuration
- Binary files are not included in this packed representation. Please refer to the Repository Structure section for a complete list of file paths, including binary files
- Only files matching these patterns are included: **/*.dart
- Files matching patterns in .gitignore are excluded
- Files matching default ignore patterns are excluded
- Files are sorted by Git change count (files with more changes are at the bottom)

# Directory Structure
````
lib/
  core/
    constants/
      app_colors.dart
      firestore_collections.dart
    models/
      menu_item_model.dart
      notification_model.dart
      user_model.dart
      vendor_model.dart
    services/
      auth_service.dart
      follow_service.dart
      menu_service.dart
      notification_history_service.dart
      notification_service.dart
      storage_service.dart
      vendor_location_service.dart
      vendor_service.dart
    theme/
      app_theme.dart
  features/
    auth/
      screens/
        change_email_screen.dart
        email_verification_screen.dart
        forgot_password_screen.dart
        login_screen.dart
        register_screen.dart
        welcome_screen.dart
      auth_wrapper.dart
    customer/
      following/
        customer_following_screen.dart
      home/
        customer_home_screen.dart
      notifications/
        customer_notifications_screen.dart
      profile/
        customer_profile_screen.dart
      vendor_details/
        vendor_details_screen.dart
    shared/
      about_screen.dart
      account_ui.dart
      change_password_screen.dart
      delete_account_screen.dart
      edit_profile_screen.dart
      faq_screen.dart
      legal_screen.dart
      logout_helper.dart
      manual_location_dialog.dart
      notification_settings_screen.dart
      personal_information_screen.dart
      profile_page.dart
    splash/
      splash_screen.dart
    vendor/
      dashboard/
        vendor_dashboard_screen.dart
      menu/
        vendor_menu_screen.dart
      profile/
        edit_stall_screen.dart
        vendor_profile_screen.dart
      vendor_main_screen.dart
  firebase_options.dart
  main.dart
````

# Files

## File: lib/features/auth/screens/change_email_screen.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/auth_service.dart';

class ChangeEmailScreen extends StatefulWidget {
  const ChangeEmailScreen({super.key});

  @override
  State<ChangeEmailScreen> createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  bool _codeSent = false;
  bool _isBusy = false;

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isBusy = true);
    final error = await _authService.requestEmailVerificationCode(
        newEmail: _emailController.text.trim());
    if (!mounted) {
      return;
    }
    setState(() {
      _isBusy = false;
      if (error == null) {
        _codeSent = true;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ??
          'Verification code sent to ${_emailController.text.trim()}.'),
      backgroundColor: error == null ? Colors.green : Colors.red,
    ));
  }

  Future<void> _confirmCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter the complete six-digit code.')));
      return;
    }
    setState(() => _isBusy = true);
    final error = await _authService.confirmEmailVerificationCode(
        code: code, newEmail: _emailController.text.trim());
    if (!mounted) {
      return;
    }
    setState(() => _isBusy = false);
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Email changed and verified successfully.'),
          backgroundColor: Colors.green));
      Navigator.pop(context, true);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Change Email')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                      'We will send a six-digit verification code to your new email address. Your email changes only after the correct code is entered.'),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    readOnly: _codeSent,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                        labelText: 'New email', border: OutlineInputBorder()),
                    validator: (value) {
                      final email = value?.trim() ?? '';
                      return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                              .hasMatch(email)
                          ? null
                          : 'Enter a valid email address';
                    },
                  ),
                  const SizedBox(height: 16),
                  if (_codeSent) ...[
                    TextField(
                      controller: _codeController,
                      enabled: !_isBusy,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                          labelText: 'Verification code',
                          counterText: '',
                          border: OutlineInputBorder()),
                      onSubmitted: (_) => _confirmCode(),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _isBusy ? null : _confirmCode,
                      child: _isBusy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Verify and Change Email'),
                    ),
                    TextButton(
                        onPressed: _isBusy ? null : _sendCode,
                        child: const Text('Resend code')),
                  ] else
                    FilledButton(
                      onPressed: _isBusy ? null : _sendCode,
                      child: _isBusy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Send Verification Code'),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
}
````

## File: lib/features/auth/screens/email_verification_screen.dart
````dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/services/auth_service.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final _authService = AuthService();
  final _codeController = TextEditingController();
  bool _isSending = false;
  bool _isVerifying = false;
  bool _messageIsError = false;
  String? _message;

  String get _email => FirebaseAuth.instance.currentUser?.email ?? '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendCode());
  }

  Future<void> _sendCode() async {
    if (_isSending || _email.isEmpty) {
      return;
    }
    setState(() {
      _isSending = true;
      _message = null;
    });
    final error = await _authService.requestEmailVerificationCode();
    if (!mounted) {
      return;
    }
    setState(() {
      _isSending = false;
      _messageIsError = error != null;
      _message = error ?? 'A six-digit code was sent to $_email.';
    });
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() {
        _message = 'Enter the complete six-digit code.';
        _messageIsError = true;
      });
      return;
    }
    setState(() {
      _isVerifying = true;
      _message = null;
    });
    final error = await _authService.confirmEmailVerificationCode(code: code);
    if (!mounted) {
      return;
    }
    setState(() {
      _isVerifying = false;
      _messageIsError = error != null;
      _message = error ?? 'Email verified successfully.';
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.mark_email_unread_outlined,
                        size: 72, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(height: 20),
                    Text('Verify your email',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(
                        'Enter the code sent to $_email. The code expires in 10 minutes.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade700)),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _codeController,
                      enabled: !_isVerifying,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 10),
                      decoration: const InputDecoration(
                          labelText: 'Verification code',
                          counterText: '',
                          border: OutlineInputBorder()),
                      onSubmitted: (_) => _verifyCode(),
                    ),
                    if (_message != null) ...[
                      const SizedBox(height: 12),
                      Text(_message!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _messageIsError
                                  ? Colors.red
                                  : Colors.green.shade700)),
                    ],
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: _isVerifying ? null : _verifyCode,
                      child: _isVerifying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Verify Email'),
                    ),
                    TextButton(
                      onPressed: _isSending ? null : _sendCode,
                      child:
                          Text(_isSending ? 'Sending code...' : 'Resend code'),
                    ),
                    TextButton(
                      onPressed: _isVerifying ? null : _authService.signOut,
                      child: const Text('Use a different account'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
````

## File: lib/features/shared/manual_location_dialog.dart
````dart
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

Future<LatLng?> showManualLocationDialog(
  BuildContext context, {
  LatLng? initialLocation,
  String title = 'Enter Location Manually',
}) async {
  final placeController = TextEditingController();
  String? errorText;
  bool isSearching = false;

  final result = await showDialog<LatLng>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) {
        Future<void> search() async {
          final query = placeController.text.trim();
          if (query.isEmpty) {
            setDialogState(
                () => errorText = 'Enter a kawasan, daerah, state, or city.');
            return;
          }
          setDialogState(() {
            isSearching = true;
            errorText = null;
          });
          try {
            // Bias towards Malaysia so short names like "Skudai" or "Bangsar"
            // resolve correctly instead of matching a place overseas.
            final query2 = query.toLowerCase().contains('malaysia')
                ? query
                : '$query, Malaysia';
            final locations = await Geocoding()
                .locationFromAddress(query2)
                .timeout(const Duration(seconds: 10));
            if (locations.isEmpty) {
              setDialogState(() {
                isSearching = false;
                errorText = 'Could not find that place. Try a different name.';
              });
              return;
            }
            final match = locations.first;
            if (!dialogContext.mounted) {
              return;
            }
            Navigator.pop(
                dialogContext, LatLng(match.latitude, match.longitude));
          } catch (_) {
            setDialogState(() {
              isSearching = false;
              errorText =
                  'Could not find that place. Check your connection and try again.';
            });
          }
        }

        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Text(
                  'Enter a kawasan, daerah, state, or city — e.g. "Bukit Bintang" or "Johor Bahru".'),
              const SizedBox(height: 16),
              TextField(
                controller: placeController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                enabled: !isSearching,
                onSubmitted: (_) => search(),
                decoration: const InputDecoration(
                  labelText: 'Kawasan, daerah, state, or city',
                  border: OutlineInputBorder(),
                ),
              ),
              if (errorText != null) ...[
                const SizedBox(height: 10),
                Text(errorText!, style: const TextStyle(color: Colors.red)),
              ],
            ]),
          ),
          actions: [
            TextButton(
                onPressed:
                    isSearching ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel')),
            FilledButton(
              onPressed: isSearching ? null : search,
              child: isSearching
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Use Location'),
            ),
          ],
        );
      },
    ),
  );

  placeController.dispose();
  return result;
}
````

## File: lib/core/models/notification_model.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  const NotificationModel({required this.id, required this.vendorId,
    required this.title, required this.body, required this.createdAt,
    required this.isRead});

  final String id;
  final String vendorId;
  final String title;
  final String body;
  final DateTime? createdAt;
  final bool isRead;

  factory NotificationModel.fromMap(Map<String, dynamic> data, String id) {
    final time = data['createdAt'];
    return NotificationModel(
      id: id,
      vendorId: data['vendorId'] is String ? data['vendorId'] as String : '',
      title: data['title'] is String ? data['title'] as String : 'Stall update',
      body: data['body'] is String ? data['body'] as String : '',
      createdAt: time is Timestamp ? time.toDate() : null,
      isRead: data['isRead'] == true,
    );
  }
}
````

## File: lib/core/services/follow_service.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FollowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _followsRef => _firestore.collection('follows');

  // Combining customerId + vendorId into one predictable document ID
  // means a customer can never accidentally follow the same vendor
  // twice -- the second "follow" would just overwrite the same document.
  String _followId(String customerId, String vendorId) =>
      '${customerId}_$vendorId';

  Future<void> followVendor(String customerId, String vendorId) async {
    await _followsRef.doc(_followId(customerId, vendorId)).set({
      'customerId': customerId,
      'vendorId': vendorId,
      'followedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unfollowVendor(String customerId, String vendorId) async {
    await _followsRef.doc(_followId(customerId, vendorId)).delete();
  }

  // Live stream of whether this customer currently follows this vendor.
  // Used to show the correct Follow/Unfollow button state, and keeps it
  // in sync automatically if changed from another device.
  Stream<bool> isFollowing(String customerId, String vendorId) {
    return _followsRef
        .doc(_followId(customerId, vendorId))
        .snapshots()
        .map((doc) => doc.exists);
  }

  // Live stream of vendor IDs this customer follows -- used by the
  // Following tab to build its list.
  Stream<List<String>> getFollowedVendorIds(String customerId) {
    return _followsRef
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc['vendorId'] as String).toList());
  }
}
````

## File: lib/core/services/notification_history_service.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_model.dart';

/// The server creates history records. Clients can read their own records
/// and mark them read, but cannot invent or edit alert content.
class NotificationHistoryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _inbox(String uid) =>
      _db.collection('users').doc(uid).collection('notifications');

  Stream<List<NotificationModel>> watch(String uid, {int limit = 50}) =>
      _inbox(uid).orderBy('createdAt', descending: true).limit(limit).snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => NotificationModel.fromMap(doc.data(), doc.id)).toList());

  // Cap the badge query; the UI displays 99+ rather than a misleading exact count.
  Stream<int> watchUnreadCount(String uid) => _inbox(uid)
      .where('isRead', isEqualTo: false).limit(100).snapshots()
      .map((snapshot) => snapshot.docs.length);

  Future<void> markRead(String uid, String notificationId) async {
    _requireOwner(uid);
    await _inbox(uid).doc(notificationId).update({'isRead': true})
        .timeout(const Duration(seconds: 10));
  }

  /// Marks only the records the screen displayed. A new alert arriving during
  /// this operation remains unread, and writes stay below the batch limit.
  Future<void> markDisplayedRead(String uid, Iterable<NotificationModel> items) async {
    _requireOwner(uid);
    final ids = items.where((item) => !item.isRead).map((item) => item.id).toSet().toList();
    for (var start = 0; start < ids.length; start += 400) {
      _requireOwner(uid);
      final batch = _db.batch();
      for (final id in ids.skip(start).take(400)) {
        batch.update(_inbox(uid).doc(id), {'isRead': true});
      }
      await batch.commit().timeout(const Duration(seconds: 10));
    }
  }

  void _requireOwner(String uid) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous || user.uid != uid) {
      throw StateError('Sign in to read your notifications.');
    }
  }
}
````

## File: lib/core/services/vendor_location_service.dart
````dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Foreground-only sampling. Native background permissions/services are not
/// present in the supplied source export. Never claims background tracking.
class VendorLocationService extends ChangeNotifier {
  VendorLocationService._();
  static final instance = VendorLocationService._();
  Timer? _timer;
  Future<void>? _pending;
  String? _vendorId;
  int _generation = 0;
  String? error;
  bool get isSharing => _vendorId != null;

  Future<void> _operations = Future<void>.value();
  int _request = 0;

  Future<void> start(String vendorId) {
    final request = ++_request;
    _operations = _operations.catchError((Object _) {}).then((_) async {
      await _pause();
      if (request != _request || FirebaseAuth.instance.currentUser?.uid != vendorId) { return; }
      _vendorId = vendorId;
      error = null;
      final generation = ++_generation;
      notifyListeners();
      await _sample(vendorId, generation);
    });
    return _operations;
  }

  Future<void> pause() {
    ++_request;
    ++_generation;
    _timer?.cancel();
    _operations = _operations.catchError((Object _) {}).then((_) => _pause());
    return _operations;
  }

  Future<void> _sample(String vendorId, int generation) async {
    if (generation != _generation) { return; }
    final work = _writePosition(vendorId, generation);
    _pending = work;
    await work;
    if (generation != _generation) { return; }
    _pending = null;
    _timer = Timer(const Duration(seconds: 15), () {
      unawaited(_sample(vendorId, generation));
    });
  }

  Future<void> _writePosition(String vendorId, int generation) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 12));
      if (generation != _generation || FirebaseAuth.instance.currentUser?.uid != vendorId) { return; }
      final ref = FirebaseFirestore.instance.collection('vendors').doc(vendorId);
      // Do not reopen a stall closed by another screen/device.
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final doc = await tx.get(ref);
        if (generation != _generation || doc.data()?['isOpen'] != true) { return; }
        tx.update(ref, {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'locationUpdatedAt': FieldValue.serverTimestamp(),
          'locationSharingActive': true,
        });
      }).timeout(const Duration(seconds: 8));
      if (generation == _generation) { error = null; }
    } catch (_) {
      if (generation == _generation) {
        error = 'Location could not update. Check GPS and your connection.';
      }
    }
    if (generation == _generation) { notifyListeners(); }
  }

  Future<void> _pause() async {
    ++_generation;
    _timer?.cancel();
    _timer = null;
    final id = _vendorId;
    _vendorId = null;
    final pending = _pending;
    _pending = null;
    // Finish an in-flight transaction before writing the paused state.
    if (pending != null) { await pending; }
    if (id != null && FirebaseAuth.instance.currentUser?.uid == id) {
      try {
        await FirebaseFirestore.instance.collection('vendors').doc(id).update({
          'locationSharingActive': false,
        }).timeout(const Duration(seconds: 5));
      } catch (_) {
        // Customers also expire old timestamps if this device is offline/killed.
      }
    }
    notifyListeners();
  }
}
````

## File: lib/features/auth/screens/forgot_password_screen.dart
````dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/services/auth_service.dart';
import '../../shared/account_ui.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialEmail = ''});
  final String initialEmail;
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.initialEmail);
  Timer? _timer;
  int _seconds = 0;
  bool _busy = false;
  bool _sent = false;
  String? _error;
  String _sentTo = '';
  @override
  void dispose() { _timer?.cancel(); _email.dispose(); super.dispose(); }

  Future<void> _send() async {
    if (_busy || _seconds > 0) { return; }
    if (!_sent && !_form.currentState!.validate()) { return; }
    FocusScope.of(context).unfocus();
    final address = _email.text.trim();
    setState(() { _busy = true; _error = null; });
    final error = await AuthService().resetPassword(email: address);
    if (!mounted) { return; }
    setState(() {
      _busy = false; _error = error;
      if (error == null) { _sent = true; _sentTo = address; _seconds = 60; }
    });
    if (error == null) {
      _timer?.cancel();
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) { timer.cancel(); return; }
        setState(() { if (_seconds > 0) { _seconds--; } });
        if (_seconds == 0) { timer.cancel(); }
      });
    }
  }

  @override
  Widget build(BuildContext context) => AccountLayout(title: 'Forgot password', busy: _busy,
    children: [
      const SizedBox(height: 24),
      AccountIntro(icon: _sent ? Icons.mark_email_read_outlined : Icons.lock_reset_rounded,
        title: _sent ? 'Check your email' : 'Reset your password',
        body: _sent
          ? 'If an account uses $_sentTo, you will receive a link to reset its password.'
          : 'Enter the email address linked to your account. We will send you a reset link.'),
      if (!_sent) ...[
        Form(key: _form, child: TextFormField(controller: _email, enabled: !_busy,
          keyboardType: TextInputType.emailAddress, textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.email], autocorrect: false,
          decoration: accountField('Email address'),
          validator: (v) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch((v ?? '').trim())
            ? null : 'Enter a valid email address.',
          onFieldSubmitted: (_) => _send())),
        const SizedBox(height: 24), AccountError(_error),
        AccountButton(label: _seconds > 0 ? 'Send again in ${_seconds}s' : 'Send reset link',
          busy: _busy, onPressed: _seconds > 0 ? null : _send),
        const SizedBox(height: 20),
        const Text('Signed up with Google? Use Continue with Google to sign in.',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: Color(0xFF707078), height: 1.5)),
      ] else ...[
        const Text('Open the email and follow the link to choose a new password. Check Spam or Junk if it is missing.',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Color(0xFF707078), height: 1.5)),
        const SizedBox(height: 28), AccountError(_error),
        AccountButton(label: 'Done', onPressed: _busy ? null : () => Navigator.pop(context)),
        const SizedBox(height: 12),
        TextButton(onPressed: _busy || _seconds > 0 ? null : _send,
          child: Text(_busy ? 'Sending…' : _seconds > 0 ? 'Resend in ${_seconds}s' : 'Resend email')),
        TextButton(onPressed: _busy ? null : () => setState(() { _sent = false; _error = null; }),
          child: const Text('Use another email')),
      ],
    ]);
}
````

## File: lib/features/shared/about_screen.dart
````dart
import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About StallSeeker')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: const Icon(Icons.storefront, size: 40),
                ),
                const SizedBox(height: 12),
                const Text(
                  'StallSeeker',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'StallSeeker connects food stall vendors with nearby customers. '
            'Vendors can share their live location, opening hours, and menu '
            'availability, while customers can discover open stalls nearby, '
            'view menus in real time, and follow their favorite stalls.',
            style: TextStyle(height: 1.5),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          const Text(
            'This app was developed as a Final Year Project.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
````

## File: lib/features/shared/account_ui.dart
````dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Shared spacing, fields and actions for account pages.
class AccountLayout extends StatelessWidget {
  const AccountLayout({super.key, required this.title, required this.children,
    this.busy = false, this.background = Colors.white});
  final String title;
  final List<Widget> children;
  final bool busy;
  final Color background;

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !busy,
    child: Scaffold(
      backgroundColor: background,
      appBar: AppBar(title: Text(title), centerTitle: true,
        backgroundColor: Colors.white, surfaceTintColor: Colors.transparent,
        elevation: 0, scrolledUnderElevation: 0,
        titleTextStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500,
          color: AppColors.textDark, letterSpacing: 0),
        leading: BackButton(onPressed: busy ? () {} : () => Navigator.maybePop(context))),
      body: SafeArea(top: false, child: Align(alignment: Alignment.topCenter,
        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: children)))),
    ),
  );
}

class AccountIntro extends StatelessWidget {
  const AccountIntro({super.key, required this.icon, required this.title, required this.body});
  final IconData icon;
  final String title;
  final String body;
  @override
  Widget build(BuildContext context) => Column(children: [
    Container(width: 64, height: 64,
      decoration: const BoxDecoration(color: Color(0xFFFFF0E9), shape: BoxShape.circle),
      child: Icon(icon, color: AppColors.primary, size: 30)),
    const SizedBox(height: 24),
    Text(title, textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, letterSpacing: -.3)),
    const SizedBox(height: 10),
    Text(body, textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 15, height: 1.5, color: Color(0xFF707078))),
    const SizedBox(height: 32),
  ]);
}

InputDecoration accountField(String label, {Widget? suffix, String? helper}) => InputDecoration(
  labelText: label, helperText: helper, helperMaxLines: 3, errorMaxLines: 3,
  suffixIcon: suffix, filled: true, fillColor: const Color(0xFFF5F5F7),
  labelStyle: const TextStyle(color: Color(0xFF707078), fontSize: 14),
  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20),
    borderSide: const BorderSide(color: AppColors.primary)),
  errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20),
    borderSide: const BorderSide(color: Color(0xFFB3261E))),
  focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20),
    borderSide: const BorderSide(color: Color(0xFFB3261E), width: 1.5)),
);

class AccountButton extends StatelessWidget {
  const AccountButton({super.key, required this.label, this.onPressed, this.busy = false,
    this.color = AppColors.primary});
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(width: double.infinity,
    child: FilledButton(onPressed: busy ? null : onPressed,
      style: FilledButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        minimumSize: const Size(48, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
      child: busy ? const SizedBox(width: 22, height: 22,
        child: CircularProgressIndicator(strokeWidth: 2))
        : Text(label, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))));
}

class AccountError extends StatelessWidget {
  const AccountError(this.message, {super.key});
  final String? message;
  @override
  Widget build(BuildContext context) => message == null ? const SizedBox.shrink()
    : Padding(padding: const EdgeInsets.only(bottom: 16),
        child: Semantics(liveRegion: true, child: Text(message!,
          style: const TextStyle(color: Color(0xFFB3261E), height: 1.4))));
}
````

## File: lib/features/shared/change_password_screen.dart
````dart
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
````

## File: lib/features/shared/delete_account_screen.dart
````dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/services/auth_service.dart';
import 'account_ui.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});
  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _auth = AuthService();
  final _confirmation = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  bool _hidePassword = true;
  String? _error;

  bool get _usesPassword => FirebaseAuth.instance.currentUser?.providerData
      .any((provider) => provider.providerId == 'password') ?? false;

  Future<void> _delete() async {
    if (_confirmation.text.trim().toUpperCase() != 'DELETE') {
      setState(() => _error = 'Type DELETE to confirm.'); return;
    }
    if (_usesPassword && _password.text.isEmpty) {
      setState(() => _error = 'Enter your current password.'); return;
    }
    setState(() { _busy = true; _error = null; });
    final error = await _auth.deleteAccount(currentPassword: _usesPassword ? _password.text : null);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    } else {
      setState(() { _busy = false; _error = error; });
    }
  }

  @override
  void dispose() { _confirmation.dispose(); _password.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AccountLayout(
    title: 'Delete account', busy: _busy,
    children: [
      const AccountIntro(icon: Icons.delete_outline_rounded, title: 'Delete your account?',
        body: 'This permanently removes your profile, follows, notification history and vendor data. This cannot be undone.'),
      TextField(controller: _confirmation, enabled: !_busy,
        textCapitalization: TextCapitalization.characters,
        decoration: accountField('Type DELETE to confirm')),
      if (_usesPassword) ...[
        const SizedBox(height: 14),
        TextField(controller: _password, enabled: !_busy, obscureText: _hidePassword,
          decoration: accountField('Current password', suffix: IconButton(
            onPressed: _busy ? null : () => setState(() => _hidePassword = !_hidePassword),
            icon: Icon(_hidePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined)))),
      ],
      const SizedBox(height: 16),
      AccountError(_error),
      AccountButton(label: 'Delete account permanently', busy: _busy,
        color: const Color(0xFFB3261E), onPressed: _delete),
      const SizedBox(height: 12),
      TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancel')),
    ],
  );
}
````

## File: lib/features/shared/edit_profile_screen.dart
````dart
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
````

## File: lib/features/shared/legal_screen.dart
````dart
import 'package:flutter/material.dart';
import 'account_ui.dart';

enum LegalPage { privacy, terms }

class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.page});
  final LegalPage page;

  @override
  Widget build(BuildContext context) {
    final privacy = page == LegalPage.privacy;
    return AccountLayout(
      title: privacy ? 'Privacy Policy' : 'Terms of Use',
      background: const Color(0xFFF2F2F7),
      children: [
        Container(padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(privacy ? 'Your privacy at StallSeeker' : 'Using StallSeeker',
              style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w600, letterSpacing: -.3)),
            const SizedBox(height: 8),
            const Text('Last updated: 6 September 2026',
              style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93))),
            const SizedBox(height: 24),
            ...(privacy ? _privacySections : _termSections).map((section) => Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(section.key, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                const SizedBox(height: 7),
                Text(section.value, style: const TextStyle(fontSize: 15, height: 1.55,
                  color: Color(0xFF52525A))),
              ]))),
          ])),
      ],
    );
  }

  static const _privacySections = <MapEntry<String, String>>[
    MapEntry('Information we collect', 'We store your name, email address, account type, followed stalls, notification history and device notification token. Vendors may share their stall details and live location while using the service.'),
    MapEntry('How we use it', 'We use this information to run your account, show nearby stalls, save favourites, send stall updates and keep the service secure.'),
    MapEntry('Location', 'Customer location is used to show nearby stalls. Vendor location may be shown to customers when the stall is active. StallSeeker does not need location when these features are not being used.'),
    MapEntry('Sharing and storage', 'Account and app data are stored using Firebase services. We do not sell personal information. Data may be processed by service providers needed to operate the app.'),
    MapEntry('Your choices', 'You can turn off alerts in Notification settings, remove phone permissions in device settings, or delete your StallSeeker account from the Profile page.'),
    MapEntry('Data deletion', 'Deleting your account removes your account and related StallSeeker data. Some security or legal records may be kept only when required by law.'),
    MapEntry('Contact', 'For privacy questions, contact the StallSeeker team at support@stallseeker.my.'),
  ];

  static const _termSections = <MapEntry<String, String>>[
    MapEntry('Service purpose', 'StallSeeker helps customers find food stalls and helps vendors share their status, menu and location.'),
    MapEntry('Account responsibility', 'Use correct information, protect your password and do not use another person’s account. You are responsible for activity under your account.'),
    MapEntry('Vendor information', 'Vendors are responsible for keeping their location, opening status, menu, prices and stock information accurate.'),
    MapEntry('Acceptable use', 'Do not misuse the service, post harmful or false content, interfere with the app, scrape private data or break applicable laws.'),
    MapEntry('Availability', 'Stall locations, stock and opening status can change. StallSeeker cannot guarantee that every listing or live update is always correct or available.'),
    MapEntry('Account action', 'We may limit or remove accounts that abuse the service or put other users at risk. You may delete your account from the Profile page.'),
    MapEntry('Changes and contact', 'These terms may change as the service develops. For questions, contact support@stallseeker.my.'),
  ];
}
````

## File: lib/features/shared/notification_settings_screen.dart
````dart
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
````

## File: lib/features/shared/personal_information_screen.dart
````dart
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
````

## File: lib/core/constants/firestore_collections.dart
````dart
class FirestoreCollections {
  static const String users = 'users';
  static const String vendors = 'vendors';
  static const String menus = 'menus';
  static const String follows = 'follows';
}
````

## File: lib/core/models/menu_item_model.dart
````dart
class MenuItemModel {
  final String itemId;
  final String name;
  final double price;
  final String
      status; // 'available' (Green), 'low_stock' (Yellow), 'out_of_stock' (Red)
  final String imageUrl;

  MenuItemModel({
    required this.itemId,
    required this.name,
    required this.price,
    this.status = 'available',
    this.imageUrl = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'name': name,
      'price': price,
      'status': status,
      'imageUrl': imageUrl,
    };
  }

  factory MenuItemModel.fromMap(Map<String, dynamic> map, String id) {
    return MenuItemModel(
      itemId: id,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'available',
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}
````

## File: lib/core/models/user_model.dart
````dart
class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String role; // 'customer' or 'vendor'
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    required this.createdAt,
  });

  // Convert Firestore Document to UserModel Object
  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      uid: docId,
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      role: map['role'] ?? 'customer',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  // Convert UserModel Object to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'role': role,
      'createdAt': createdAt,
    };
  }
}
````

## File: lib/core/services/storage_service.dart
````dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Opens the gallery picker. Returns null if the vendor backed out
  // without choosing anything.
  Future<File?> pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 80,
    );
    if (picked == null) { return null; }
    return File(picked.path);
  }

  // Uploads a stall's cover photo. Always uses the same file name per
  // vendor, so re-uploading overwrites the old photo instead of leaving
  // unused files in Storage.
  Future<String> uploadStallImage(String vendorId, File imageFile) async {
    final ref = _storage.ref().child('stall_images/$vendorId.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  // Uploads a photo for one menu item. Named by itemId so each dish has
  // its own file, and re-uploading a photo for the same dish overwrites it.
  Future<String> uploadMenuItemImage(
    String vendorId,
    String itemId,
    File imageFile,
  ) async {
    final ref = _storage.ref().child('menu_images/$vendorId/$itemId.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }
}
````

## File: lib/features/customer/notifications/customer_notifications_screen.dart
````dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/notification_history_service.dart';
import '../../../core/services/vendor_service.dart';
import '../../auth/screens/login_screen.dart';
import '../vendor_details/vendor_details_screen.dart';

class CustomerNotificationsScreen extends StatefulWidget {
  const CustomerNotificationsScreen({super.key});
  @override
  State<CustomerNotificationsScreen> createState() => _CustomerNotificationsScreenState();
}

class _CustomerNotificationsScreenState extends State<CustomerNotificationsScreen> {
  final _history = NotificationHistoryService();
  final _vendors = VendorService();
  final _uid = FirebaseAuth.instance.currentUser?.uid;
  late Stream<List<NotificationModel>> _stream;
  final Set<String> _opening = {};
  int _limit = 50;
  bool _marking = false;
  bool _onlyUnread = false;

  @override
  void initState() { super.initState(); _listen(); }

  void _listen() {
    final uid = _uid;
    _stream = uid == null || FirebaseAuth.instance.currentUser?.isAnonymous == true
        ? Stream.value(<NotificationModel>[])
        : _history.watch(uid, limit: _limit);
  }

  void _message(String message) {
    if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message))); }
  }

  Future<void> _open(NotificationModel item) async {
    final uid = _uid;
    if (uid == null || _opening.contains(item.id)) { return; }
    setState(() => _opening.add(item.id));
    try {
      if (!item.isRead) {
        try { await _history.markRead(uid, item.id); }
        catch (_) { _message('Could not mark this alert as read.'); }
      }
      if (item.vendorId.isEmpty) { _message('This alert has no stall link.'); return; }
      final vendor = await _vendors.getVendorProfile(item.vendorId)
          .timeout(const Duration(seconds: 10));
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != uid) { return; }
      if (vendor == null) { _message('This stall is unavailable or could not be loaded.'); return; }
      await Navigator.push(context, MaterialPageRoute(builder: (_) => VendorDetailsScreen(vendor: vendor)));
    } catch (_) {
      _message('Could not open the stall. Please retry.');
    } finally {
      if (mounted) { setState(() => _opening.remove(item.id)); }
    }
  }

  Future<void> _markRead(List<NotificationModel> items) async {
    final uid = _uid;
    if (uid == null || _marking) { return; }
    setState(() => _marking = true);
    try { await _history.markDisplayedRead(uid, items); }
    catch (_) { _message('Could not mark alerts as read. Please retry.'); }
    finally { if (mounted) { setState(() => _marking = false); } }
  }

  String _date(DateTime? value) {
    if (value == null) { return 'Date unavailable'; }
    final local = value.toLocal();
    final time = TimeOfDay.fromDateTime(local).format(context);
    return '${local.day}/${local.month}/${local.year} · $time';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      return _empty('Your stall updates, in one place',
        'Sign in and follow stalls to keep their updates here.', action: TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
          child: const Text('Sign in')));
    }
    return ColoredBox(color: const Color(0xFFF2F2F7), child: StreamBuilder<List<NotificationModel>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _errorState(snapshot.error!);
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snapshot.data ?? [];
        final visible = _onlyUnread ? all.where((item) => !item.isRead).toList() : all;
        return RefreshIndicator(onRefresh: () async { setState(_listen); }, child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28), children: [
            Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8, runSpacing: 4, children: [
                CupertinoSlidingSegmentedControl<bool>(
                  groupValue: _onlyUnread,
                  children: const {
                    false: Padding(padding: EdgeInsets.symmetric(horizontal: 18), child: Text('All')),
                    true: Padding(padding: EdgeInsets.symmetric(horizontal: 18), child: Text('Unread')),
                  },
                  onValueChanged: (value) {
                    if (value != null) { setState(() => _onlyUnread = value); }
                  },
                ),
                TextButton(onPressed: _marking || !all.any((item) => !item.isRead) ? null : () => _markRead(all),
                  child: Text(_marking ? 'Updating…' : 'Mark shown as read')),
              ]),
            const Padding(padding: EdgeInsets.fromLTRB(8, 16, 8, 12),
              child: Text('STALL UPDATES', style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)))),
            if (visible.isEmpty) Padding(padding: const EdgeInsets.all(32), child: Column(children: [
              const Icon(Icons.notifications_none_rounded, size: 42, color: Color(0xFF8E8E93)),
              const SizedBox(height: 12),
              Text(_onlyUnread ? 'No unread updates in this list' : 'No notifications yet',
                textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text('When a stall you follow opens, its new update will appear here.',
                textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF8E8E93))),
            ]))
            else Container(clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                for (var i = 0; i < visible.length; i++) ...[
                  if (i > 0) const Divider(height: .5, thickness: .5, color: Color(0xFFE5E5EA)),
                  _tile(visible[i]),
                ],
              ])),
            if (all.length >= _limit) Padding(padding: const EdgeInsets.only(top: 12),
              child: TextButton(onPressed: () => setState(() { _limit += 50; _listen(); }),
                child: const Text('Load older updates'))),
          ],
        ));
      },
    ));
  }

  Widget _tile(NotificationModel item) => Material(
    color: item.isRead ? Colors.white : const Color(0xFFFFFAF6),
    child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      leading: Icon(Icons.storefront_outlined,
        color: item.isRead ? const Color(0xFF8E8E93) : const Color(0xFFFF6E41)),
      title: Text(item.title, style: TextStyle(fontSize: 17, letterSpacing: 0,
        fontWeight: item.isRead ? FontWeight.w400 : FontWeight.w500)),
      subtitle: Padding(padding: const EdgeInsets.only(top: 5), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (item.body.isNotEmpty) Text(item.body, style: const TextStyle(fontSize: 14, letterSpacing: 0)),
          const SizedBox(height: 5),
          Text(_date(item.createdAt), style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
        ])),
      trailing: _opening.contains(item.id)
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(item.isRead ? Icons.chevron_right : Icons.circle,
              size: item.isRead ? 20 : 8, color: item.isRead ? const Color(0xFFAEAEB2) : const Color(0xFFFF6E41)),
      onTap: () => _open(item),
    ),
  );

  Widget _errorState(Object error) {
    final code = error is FirebaseException ? error.code : 'unknown';
    // Preserve the real error in the debug console instead of blaming Wi-Fi.
    debugPrint('Notification history [$code]: $error');
    String title;
    String body;
    switch (code) {
      case 'permission-denied':
        title = 'Notification access is blocked';
        body = 'Your account cannot read notification history yet. Please contact support.';
        break;
      case 'unauthenticated':
        title = 'Please sign in again';
        body = 'Your session has expired. Sign out and sign in to load your updates.';
        break;
      case 'unavailable':
      case 'deadline-exceeded':
        title = 'Cannot reach notifications';
        body = 'Check your connection, then try again.';
        break;
      case 'failed-precondition':
        title = 'Notifications are not ready';
        body = 'Notification history needs a service update. Please contact support.';
        break;
      default:
        title = 'Could not load notifications';
        body = 'Try again. If this continues, share the error code with support.';
    }
    return _empty(title, body, action: Column(mainAxisSize: MainAxisSize.min, children: [
      TextButton(onPressed: () => setState(_listen), child: const Text('Retry')),
      SelectableText('Error: $code', textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
    ]));
  }

  Widget _empty(String title, String body, {Widget? action}) => Center(child: Padding(
    padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.notifications_none_rounded, size: 44, color: Color(0xFF8E8E93)),
      const SizedBox(height: 16), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8), Text(body, textAlign: TextAlign.center),
      if (action != null) action,
    ]),
  ));
}
````

## File: lib/features/splash/splash_screen.dart
````dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../auth/auth_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AuthWrapper()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.storefront, size: 72, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'StallSeeker',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w500,
                color: Colors.white,
                fontFamily: 'Poppins', // Added Poppins font
              ),
            ),
          ],
        ),
      ),
    );
  }
}
````

## File: lib/firebase_options.dart
````dart
// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBPTOZDnYDXxe9VNSzYLXPvso5nIiHTsPc',
    appId: '1:793011933510:web:e9cb5587fb777961911547',
    messagingSenderId: '793011933510',
    projectId: 'stallseeker-c2ffe',
    authDomain: 'stallseeker-c2ffe.firebaseapp.com',
    storageBucket: 'stallseeker-c2ffe.firebasestorage.app',
    measurementId: 'G-KEBYKY2P8P',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBzTEscU-ljvVtKgSVFs-KN3J3BtDre2Cs',
    appId: '1:793011933510:android:7127576788f40c81911547',
    messagingSenderId: '793011933510',
    projectId: 'stallseeker-c2ffe',
    storageBucket: 'stallseeker-c2ffe.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCrE5vzUXqYDTN5UQrbVKzx8LBwiA18mrc',
    appId: '1:793011933510:ios:29aa93bdf1ed90e6911547',
    messagingSenderId: '793011933510',
    projectId: 'stallseeker-c2ffe',
    storageBucket: 'stallseeker-c2ffe.firebasestorage.app',
    iosClientId: '793011933510-gphe3f510j5v4u555g4uo4ls5bm7bnsm.apps.googleusercontent.com',
    iosBundleId: 'com.example.stallseeker',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCrE5vzUXqYDTN5UQrbVKzx8LBwiA18mrc',
    appId: '1:793011933510:ios:29aa93bdf1ed90e6911547',
    messagingSenderId: '793011933510',
    projectId: 'stallseeker-c2ffe',
    storageBucket: 'stallseeker-c2ffe.firebasestorage.app',
    iosClientId: '793011933510-gphe3f510j5v4u555g4uo4ls5bm7bnsm.apps.googleusercontent.com',
    iosBundleId: 'com.example.stallseeker',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBPTOZDnYDXxe9VNSzYLXPvso5nIiHTsPc',
    appId: '1:793011933510:web:b99eecd2060151e1911547',
    messagingSenderId: '793011933510',
    projectId: 'stallseeker-c2ffe',
    authDomain: 'stallseeker-c2ffe.firebaseapp.com',
    storageBucket: 'stallseeker-c2ffe.firebasestorage.app',
    measurementId: 'G-QFFLHPN0GT',
  );
}
````

## File: lib/core/services/vendor_service.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/vendor_model.dart';

class VendorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _vendorsRef => _firestore.collection('vendors');

  Future<VendorModel?> getVendorProfile(String vendorId) async {
    try {
      DocumentSnapshot doc = await _vendorsRef.doc(vendorId).get();
      if (doc.exists && doc.data() != null) {
        return VendorModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching vendor profile: $e');
      return null;
    }
  }

  Future<void> saveVendorProfile(VendorModel vendor) async {
    try {
      await _vendorsRef.doc(vendor.vendorId).set(
            vendor.toProfileMap(),
            SetOptions(merge: true),
          );
    } catch (e) {
      debugPrint('Error saving vendor profile: $e');
      rethrow;
    }
  }

  Future<void> toggleStallStatus(String vendorId, bool isOpen) async {
    try {
      await _vendorsRef.doc(vendorId).set({
        'vendorId': vendorId,
        'isOpen': isOpen,
        if (!isOpen) 'locationSharingActive': false,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error toggling stall status: $e');
      rethrow;
    }
  }

  Future<void> updateVendorLocation(
    String vendorId,
    double latitude,
    double longitude,
    {bool sharingActive = true}
  ) async {
    try {
      await _vendorsRef.doc(vendorId).set({
        'vendorId': vendorId,
        'latitude': latitude,
        'longitude': longitude,
        'locationUpdatedAt': FieldValue.serverTimestamp(),
        'locationSharingActive': sharingActive,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating vendor location: $e');
      rethrow;
    }
  }

  Stream<VendorModel?> watchVendorProfile(String vendorId) {
    return _vendorsRef.doc(vendorId).snapshots().map((doc) =>
        doc.exists && doc.data() != null
            ? VendorModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)
            : null);
  }

  Stream<List<VendorModel>> getOpenVendors() {
    return _vendorsRef.where('isOpen', isEqualTo: true).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) =>
                VendorModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<VendorModel>> getAllVendors() {
    return _vendorsRef.snapshots().map((snapshot) => snapshot.docs
        .map((doc) =>
            VendorModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }
}
````

## File: lib/features/shared/faq_screen.dart
````dart
import 'package:flutter/material.dart';
import 'account_ui.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key, required this.isVendor});
  final bool isVendor;
  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqEntry {
  const _FaqEntry(this.group, this.question, this.answer);
  final String group;
  final String question;
  final String answer;
}

class _FaqScreenState extends State<FaqScreen> {
  final _search = TextEditingController();
  String _query = '';
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  static const _customer = [
    _FaqEntry('FINDING STALLS', 'How do I find stalls near me?',
      'Open Discover to see the map. Allow location access to find your area, or move the map yourself. Search by stall name or food category.'),
    _FaqEntry('FINDING STALLS', 'Why can’t I see a stall on the map?',
      'The stall may be closed, outside the area shown, or hidden by a filter. Clear your filters and zoom out. Vendors need to share a valid location.'),
    _FaqEntry('FINDING STALLS', 'Where can I see the menu and stock?',
      'Open a stall’s details to see its menu and available stock. Stock is updated by the vendor, so check with them if you need to be certain.'),
    _FaqEntry('FOLLOWING & UPDATES', 'How do I follow or unfollow a stall?',
      'Sign in and open the stall’s details. Tap the follow or heart button. Your saved stalls appear in Following. Tap the button again to unfollow.'),
    _FaqEntry('FOLLOWING & UPDATES', 'Where are my past notifications?',
      'Open Notifications for saved stall-opening updates. Use All or Unread to filter the list. Older pushes sent before history was enabled are not added automatically.'),
    _FaqEntry('FOLLOWING & UPDATES', 'Why am I not getting alerts?',
      'Check that you follow the stall, are signed in, and have allowed notifications in your phone settings. Alerts are sent when a stall changes from closed to open. Your phone or network may delay delivery.'),
  ];
  static const _vendor = [
    _FaqEntry('YOUR STALL', 'How do I mark my stall as open?',
      'Use the stall status switch on your Dashboard. Allow location access and turn on your phone’s location services so customers can find you.'),
    _FaqEntry('YOUR STALL', 'Why is my stall missing from the map?',
      'Check that your stall is open and its location has updated. Customers may also need to clear filters or move the map to your area.'),
    _FaqEntry('MENU & STOCK', 'How do I update my menu and stock?',
      'Open Manage Menu & Stock from the Dashboard. Edit a dish’s details or change its stock status. Keep this updated when items sell out.'),
    _FaqEntry('MENU & STOCK', 'How do I change my stall photo?',
      'Open Profile, then My stall to edit your stall details and photo. Menu item photos can be changed in Manage Menu & Stock.'),
    _FaqEntry('STALL UPDATES', 'When are followers notified?',
      'An opening update is created when your stall changes from closed to open. Changing a price or moving your location alone does not create an opening alert. Push delivery depends on customer settings and connectivity.'),
  ];
  static const _account = [
    _FaqEntry('ACCOUNT', 'How do I change my name?',
      'Open Profile and tap Edit Profile. Enter your full name and save. Your avatar uses your account photo when available, or the first word of your name.'),
    _FaqEntry('ACCOUNT', 'I forgot my password. What should I do?',
      'Tap Forgot Password on Sign In and enter your account email. Follow the link in the email to set a new password. If you signed up with Google, use Continue with Google.'),
    _FaqEntry('ACCOUNT', 'Why is the reset email missing?',
      'Check the email address and look in Spam or Junk. If you requested the email and recognise the sender, mark it as not spam. Wait for the resend countdown before requesting another link.'),
    _FaqEntry('ACCOUNT', 'Will logging out delete my account?',
      'No. Logging out ends your session on this device. Your account and saved follows stay available when you sign in again.'),
  ];

  @override
  Widget build(BuildContext context) {
    final all = [...(widget.isVendor ? _vendor : _customer), ..._account];
    final entries = all.where((e) => '${e.question} ${e.answer}'.toLowerCase().contains(_query)).toList();
    final groups = entries.map((e) => e.group).toSet();
    return AccountLayout(title: 'Help & FAQ', background: const Color(0xFFF2F2F7), children: [
      const Text('How can we help?', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      const Text('Find quick answers about your account and stalls.',
        style: TextStyle(fontSize: 14, color: Color(0xFF707078), height: 1.5)),
      const SizedBox(height: 20),
      TextField(controller: _search, onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
        decoration: accountField('Search questions', suffix: _query.isEmpty
          ? const Icon(Icons.search_rounded) : IconButton(tooltip: 'Clear search',
            onPressed: () { _search.clear(); setState(() => _query = ''); },
            icon: const Icon(Icons.close_rounded)))),
      const SizedBox(height: 28),
      if (entries.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 32),
        child: Text('No matching answers. Try a different word.', textAlign: TextAlign.center)),
      for (final group in groups) ...[
        Padding(padding: const EdgeInsets.only(left: 4, bottom: 10), child: Text(group,
          style: const TextStyle(fontSize: 12, color: Color(0xFF707078)))),
        _group(entries.where((e) => e.group == group).toList()),
        const SizedBox(height: 26),
      ],
    ]);
  }

  Widget _group(List<_FaqEntry> entries) => Material(color: Colors.white,
    borderRadius: BorderRadius.circular(16), clipBehavior: Clip.antiAlias,
    child: Column(children: [
      for (var i = 0; i < entries.length; i++) ...[
        if (i > 0) const Divider(height: .5, thickness: .5, color: Color(0xFFE5E5EA)),
        ExpansionTile(key: PageStorageKey(entries[i].question),
          tilePadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          shape: const Border(), collapsedShape: const Border(),
          backgroundColor: Colors.white, collapsedBackgroundColor: Colors.white,
          iconColor: const Color(0xFFFF6E41), collapsedIconColor: const Color(0xFF8E8E93),
          title: Text(entries[i].question, style: const TextStyle(fontSize: 15,
            fontWeight: FontWeight.w500, color: Color(0xFF222222), height: 1.4)),
          childrenPadding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: [Align(alignment: Alignment.centerLeft, child: Text(entries[i].answer,
            style: const TextStyle(fontSize: 14, height: 1.6, color: Color(0xFF707078))))]),
      ],
    ]));
}
````

## File: lib/features/shared/logout_helper.dart
````dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/auth_service.dart';
import 'account_ui.dart';

Future<void> confirmAndLogout(BuildContext context, AuthService authService) async {
  final navigator = Navigator.of(context, rootNavigator: true);
  final signedOut = await showDialog<bool>(context: context, barrierDismissible: false,
    builder: (_) => _LogoutDialog(authService: authService));
  if (signedOut == true && navigator.mounted) {
    navigator.popUntil((route) => route.isFirst);
  }
}

class _LogoutDialog extends StatefulWidget {
  const _LogoutDialog({required this.authService});
  final AuthService authService;
  @override
  State<_LogoutDialog> createState() => _LogoutDialogState();
}

class _LogoutDialogState extends State<_LogoutDialog> {
  bool _busy = false;
  String? _error;
  late final bool _guest = FirebaseAuth.instance.currentUser?.isAnonymous ?? true;

  Future<void> _logout() async {
    if (_busy) { return; }
    setState(() { _busy = true; _error = null; });
    try {
      await widget.authService.signOut();
      if (mounted) { Navigator.pop(context, true); }
    } catch (_) {
      if (mounted) { setState(() {
        _busy = false;
        _error = 'Could not finish logging out. Please try again.';
      }); }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(canPop: !_busy,
    child: Dialog(backgroundColor: Colors.white, surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 56, height: 56,
              decoration: const BoxDecoration(color: Color(0xFFFFF0E9), shape: BoxShape.circle),
              child: const Icon(Icons.logout_rounded, color: Color(0xFFFF6E41), size: 26)),
            const SizedBox(height: 20),
            Text(_guest ? 'Leave guest mode?' : 'Log out?',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Text(_guest ? 'You can browse again or sign in to your account.'
              : 'Your account details will stay saved. You can sign in again anytime.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF707078), height: 1.5)),
            const SizedBox(height: 24), AccountError(_error),
            AccountButton(label: _guest ? 'Leave guest mode' : 'Log out', busy: _busy,
              onPressed: _logout, color: const Color(0xFFB3261E)),
            const SizedBox(height: 8),
            TextButton(onPressed: _busy ? null : () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF55555D)))),
          ])))));
}
````

## File: lib/features/shared/profile_page.dart
````dart
import 'package:flutter/material.dart';

/// Grouped settings layout inspired by the supplied references.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.name, required this.email,
    this.photoUrl, required this.isVendor, required this.isGuest,
    required this.canChangePassword, required this.location,
    required this.isLoadingLocation, required this.onRefresh,
    required this.onLocation, required this.onEdit, required this.onPassword,
    required this.onEmail,
    required this.onFaq, required this.onAbout, required this.onLogout,
    required this.onSignIn, required this.onNotificationSettings,
    required this.onPrivacyPolicy, required this.onTerms,
    required this.onDeleteAccount, this.onEditStall, this.onPersonalInformation});

  final String name;
  final String email;
  final String? photoUrl;
  final bool isVendor;
  final bool isGuest;
  final bool canChangePassword;
  final String location;
  final bool isLoadingLocation;
  final Future<void> Function() onRefresh;
  final VoidCallback onLocation;
  final VoidCallback onEdit;
  final VoidCallback onPassword;
  final VoidCallback onEmail;
  final VoidCallback onFaq;
  final VoidCallback onAbout;
  final VoidCallback onLogout;
  final VoidCallback onSignIn;
  final VoidCallback onNotificationSettings;
  final VoidCallback onPrivacyPolicy;
  final VoidCallback onTerms;
  final VoidCallback onDeleteAccount;
  final VoidCallback? onEditStall;
  final VoidCallback? onPersonalInformation;

  static const _background = Color(0xFFF2F2F7);
  static const _muted = Color(0xFF8E8E93);
  static const _divider = Color(0xFFE5E5EA);

  // The avatar must never receive the full display name.
  String get _firstWord {
    final words = name.trim().split(RegExp(r'\s+')).where((word) => word.isNotEmpty);
    return words.isEmpty ? 'Guest' : words.first;
  }

  Widget _fallbackPhoto() => Container(color: const Color(0xFFFFE8DB), alignment: Alignment.center,
    padding: const EdgeInsets.all(9),
    child: FittedBox(fit: BoxFit.scaleDown, child: Text(_firstWord,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFFC64B22)))));

  Widget _avatar() => ClipOval(child: SizedBox(width: 64, height: 64,
    child: photoUrl == null || photoUrl!.trim().isEmpty ? _fallbackPhoto()
        : Image.network(photoUrl!, fit: BoxFit.cover,
            loadingBuilder: (_, child, progress) => progress == null ? child : _fallbackPhoto(),
            errorBuilder: (_, __, ___) => _fallbackPhoto())));

  Widget _group(String label, List<Widget> rows) => Padding(padding: const EdgeInsets.only(top: 28),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
        child: Text(label, style: const TextStyle(color: _muted, fontSize: 12, fontWeight: FontWeight.w400))),
      Container(clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          for (var index = 0; index < rows.length; index++) ...[
            if (index > 0) const Divider(height: .5, thickness: .5, color: _divider),
            rows[index],
          ],
        ])),
    ]));

  Widget _row(IconData icon, String label, VoidCallback onTap, {String? subtitle, Widget? trailing}) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    leading: Icon(icon, color: _muted, size: 24),
    title: Text(label, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w400, letterSpacing: 0)),
    subtitle: subtitle == null ? null : Padding(padding: const EdgeInsets.only(top: 3),
      child: Text(subtitle, style: const TextStyle(fontSize: 14, color: _muted, letterSpacing: 0))),
    trailing: trailing ?? const Icon(Icons.chevron_right, color: Color(0xFFAEAEB2), size: 22),
    onTap: onTap,
  );

  @override
  Widget build(BuildContext context) => ColoredBox(color: _background,
    child: RefreshIndicator(onRefresh: onRefresh, child: ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 40), children: [
        Container(padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            _avatar(), const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, letterSpacing: 0)),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(fontSize: 14, color: _muted, letterSpacing: 0)),
              ],
              const SizedBox(height: 8),
              TextButton(onPressed: isGuest ? onSignIn : onEdit,
                style: TextButton.styleFrom(backgroundColor: _background, foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text(isGuest ? 'Sign in' : 'Edit Profile', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, letterSpacing: 0))),
            ])),
            const SizedBox(width: 4),
            IconButton(tooltip: isGuest ? 'Sign in' : 'Edit profile',
              onPressed: isGuest ? onSignIn : onEdit,
              icon: const Icon(Icons.chevron_right, color: Color(0xFFAEAEB2)),
              constraints: const BoxConstraints(minWidth: 28, minHeight: 48), padding: EdgeInsets.zero),
          ])),
        _group('LOCATION', [
          _row(Icons.location_on_outlined, 'Current location', onLocation, subtitle: location,
            trailing: isLoadingLocation
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.chevron_right, color: Color(0xFFAEAEB2))),
        ]),
        if (!isGuest) _group(isVendor ? 'ACCOUNT & STALL' : 'ACCOUNT', [
          _row(Icons.person_outline_rounded, 'Personal information', onPersonalInformation ?? onEdit),
          if (isVendor && onEditStall != null) _row(Icons.storefront_outlined, 'My stall', onEditStall!),
          _row(Icons.alternate_email_rounded, 'Change email', onEmail),
          if (canChangePassword) _row(Icons.lock_outline_rounded, 'Change password', onPassword),
          if (!isVendor) _row(Icons.notifications_none_rounded, 'Notification settings', onNotificationSettings),
        ]),
        _group('ABOUT', [
          _row(Icons.help_outline_rounded, 'Help & FAQ', onFaq),
          _row(Icons.info_outline_rounded, 'About StallSeeker', onAbout),
          _row(Icons.privacy_tip_outlined, 'Privacy policy', onPrivacyPolicy),
          _row(Icons.description_outlined, 'Terms of use', onTerms),
        ]),
        if (!isGuest) _group('ACCOUNT ACTIONS', [
          _row(Icons.delete_outline_rounded, 'Delete account', onDeleteAccount,
            trailing: const Icon(Icons.chevron_right, color: Color(0xFFB3261E), size: 22)),
        ]),
        const SizedBox(height: 28),
        Container(clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
          child: _row(Icons.logout_rounded, isGuest ? 'Leave guest mode' : 'Logout', onLogout,
            trailing: const SizedBox.shrink())),
        const SizedBox(height: 36),
        const Icon(Icons.storefront_outlined, size: 32, color: Color(0xFFAEAEB2)),
        const SizedBox(height: 8),
        const Text('StallSeeker', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: _muted, letterSpacing: 0)),
      ],
    )),
  );
}
````

## File: lib/core/models/vendor_model.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';

class VendorModel {
  final String vendorId;
  final String stallName;
  final String description;
  final String category;
  final String openingHours;
  final bool isOpen;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final DateTime? locationUpdatedAt;
  final bool locationSharingActive;

  bool get hasValidLocation => latitude.isFinite && longitude.isFinite &&
      latitude.abs() <= 90 && longitude.abs() <= 180 &&
      !(latitude == 0 && longitude == 0);

  bool get hasFreshLocation {
    final updated = locationUpdatedAt;
    if (!locationSharingActive || updated == null) { return false; }
    final age = DateTime.now().difference(updated);
    return !age.isNegative && age < const Duration(minutes: 2);
  }


  VendorModel({
    required this.vendorId,
    required this.stallName,
    required this.description,
    required this.category,
    required this.openingHours,
    this.isOpen = false,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.imageUrl = '',
    this.locationUpdatedAt,
    this.locationSharingActive = false,
  });

  /// Editable information only. Operational state belongs to the selling session.
  Map<String, dynamic> toProfileMap() => {
    'vendorId': vendorId,
    'stallName': stallName,
    'description': description,
    'category': category,
    'openingHours': openingHours,
    'imageUrl': imageUrl,
  };

  // Convert VendorModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'vendorId': vendorId,
      'stallName': stallName,
      'description': description,
      'category': category,
      'openingHours': openingHours,
      'isOpen': isOpen,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
    };
  }

  // Create VendorModel from Firestore Document Snapshot
  factory VendorModel.fromMap(Map<String, dynamic> map, String documentId) {
    return VendorModel(
      vendorId: documentId,
      stallName: map['stallName'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      openingHours: map['openingHours'] ?? '',
      isOpen: map['isOpen'] ?? false,
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      locationUpdatedAt: (map['locationUpdatedAt'] as Timestamp?)?.toDate(),
      locationSharingActive: map['locationSharingActive'] == true,
    );
  }

  // CopyWith method for easy state updates
  VendorModel copyWith({
    String? stallName,
    String? description,
    String? category,
    String? openingHours,
    bool? isOpen,
    double? latitude,
    double? longitude,
    String? imageUrl,
  }) {
    return VendorModel(
      vendorId: vendorId,
      stallName: stallName ?? this.stallName,
      description: description ?? this.description,
      category: category ?? this.category,
      openingHours: openingHours ?? this.openingHours,
      isOpen: isOpen ?? this.isOpen,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
      locationUpdatedAt: locationUpdatedAt,
      locationSharingActive: locationSharingActive,
    );
  }
}
````

## File: lib/core/services/notification_service.dart
````dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/vendor_model.dart';
import 'vendor_service.dart';
import '../../features/customer/vendor_details/vendor_details_screen.dart';

// Runs in its own isolate when a push arrives while the app is backgrounded
// or fully closed. Android shows the system notification on its own from
// the message's payload -- this only needs to exist so FCM has something
// to call.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final VendorService _vendorService = VendorService();

  static const _channel = AndroidNotificationChannel(
    'stallseeker_channel',
    'StallSeeker Notifications',
    description: 'Notifies you when a followed vendor starts selling.',
    importance: Importance.high,
  );

  GlobalKey<NavigatorState>? _navigatorKey;
  bool _initialized = false;
  StreamSubscription<String>? _tokenSubscription;
  String? _syncedUid;
  String? _configuredUid;
  String? _configuredRole;
  String? _pendingVendorId;
  bool _navigationReady = false;
  Future<void> _tokenWork = Future<void>.value();

  Future<void> _queueTokenSave(String uid, String token) {
    _tokenWork = _tokenWork.catchError((Object _) {}).then((_) async {
      if (_syncedUid == uid && FirebaseAuth.instance.currentUser?.uid == uid) {
        await _saveToken(uid, token);
      }
    });
    return _tokenWork;
  }

  void setNavigationReady(bool ready) {
    _navigationReady = ready;
    if (ready && _pendingVendorId != null) {
      final id = _pendingVendorId!;
      _pendingVendorId = null;
      unawaited(_openVendorDetails(id));
    }
  }


  // One-time setup: creates the notification channel and wires up listeners
  // for taps in every app state. Permission is requested only after the
  // signed-in account is confirmed to be a customer.
  // (foreground, background, terminated). Safe to call more than once.
  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    if (_initialized) { return; }

    _navigatorKey = navigatorKey;

    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        final vendorId = response.payload;
        if (vendorId != null) { _openVendorDetails(vendorId); }
      },
    );

    _initialized = true;

    // FCM does not show a system notification by itself while the app is
    // in the foreground, so display one manually using the same channel.
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      final vendorId = message.data['vendorId'];
      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          payload: vendorId,
        );
      }
    });

    // App was backgrounded and the user tapped the notification.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final vendorId = message.data['vendorId'];
      if (vendorId != null) { _openVendorDetails(vendorId); }
    });

    // App was fully closed and got launched by tapping the notification.
    final initialMessage = await _messaging.getInitialMessage();
    final vendorId = initialMessage?.data['vendorId'];
    if (vendorId != null) { _openVendorDetails(vendorId); }
  }

  Future<void> configureForRole(String role) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) { return; }
    if (_configuredUid == user.uid && _configuredRole == role) { return; }
    _configuredUid = user.uid;
    _configuredRole = role;

    if (role != 'customer') {
      _syncedUid = null;
      await _tokenSubscription?.cancel();
      _tokenSubscription = null;
      await _tokenWork.timeout(const Duration(seconds: 5)).catchError((Object _) {});
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid)
            .set({'fcmToken': FieldValue.delete()}, SetOptions(merge: true));
        await _messaging.deleteToken().timeout(const Duration(seconds: 5));
        await _localNotifications.cancelAll();
      } catch (_) {
        debugPrint('Could not disable vendor notifications.');
        _configuredUid = null;
        _configuredRole = null;
      }
      return;
    }

    try {
      if (!await isEnabledForCurrentUser()) {
        await _removeCurrentDeviceToken(user);
        return;
      }
      final settings = await _messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        await _removeCurrentDeviceToken(user);
        return;
      }
      _syncedUid = null;
      await syncTokenForCurrentUser(skipPreferenceCheck: true);
    } catch (_) {
      debugPrint('Could not configure customer notifications.');
      _configuredUid = null;
      _configuredRole = null;
    }
  }

  // Fetches this device's FCM token and saves it on a customer account,
  // and keeps it updated if it ever rotates.
  Future<void> syncTokenForCurrentUser({bool skipPreferenceCheck = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous || _syncedUid == user.uid) { return; }
    if (_configuredRole != null && _configuredRole != 'customer') { return; }
    if (!skipPreferenceCheck && !await isEnabledForCurrentUser()) {
      await _removeCurrentDeviceToken(user);
      return;
    }
    _syncedUid = user.uid;
    await _tokenSubscription?.cancel();
    _tokenSubscription = _messaging.onTokenRefresh.listen((token) {
      final uid = _syncedUid;
      if (uid != null) { unawaited(_queueTokenSave(uid, token).catchError((Object e) {
        debugPrint('Could not refresh notification registration.');
      })); }
    });
    try {
      final token = await _messaging.getToken().timeout(const Duration(seconds: 5));
      if (token != null) { await _queueTokenSave(user.uid, token); }
    } catch (_) {
      _syncedUid = null;
      debugPrint('Notification registration unavailable.');
    }
  }

  Future<bool> isEnabledForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) { return false; }
    final profile = await FirebaseFirestore.instance
        .collection('users').doc(user.uid).get();
    return profile.data()?['notificationsEnabled'] != false;
  }

  Future<String?> setEnabledForCurrentUser(bool enabled) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) { return 'Sign in to manage notifications.'; }
    if (_configuredRole != 'customer') {
      return 'Notifications are only available for customer accounts.';
    }
    try {
      if (enabled) {
        final settings = await _messaging.requestPermission();
        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          return 'Notifications are blocked in your phone settings.';
        }
      }
      await FirebaseFirestore.instance.collection('users').doc(user.uid)
          .set({
            'notificationsEnabled': enabled,
            if (!enabled) 'fcmToken': FieldValue.delete(),
          }, SetOptions(merge: true));
      if (enabled) {
        _syncedUid = null;
        await syncTokenForCurrentUser(skipPreferenceCheck: true);
      } else {
        await _removeCurrentDeviceToken(user);
        await _localNotifications.cancelAll();
      }
      return null;
    } catch (_) {
      return 'Could not update notification settings. Please try again.';
    }
  }

  Future<void> _removeCurrentDeviceToken(User user) async {
    _syncedUid = null;
    await _tokenSubscription?.cancel();
    _tokenSubscription = null;
    await _tokenWork.timeout(const Duration(seconds: 5)).catchError((Object _) {});
    try {
      final token = await _messaging.getToken().timeout(const Duration(seconds: 5));
      if (token != null) {
        final ref = FirebaseFirestore.instance.collection('users').doc(user.uid);
        await FirebaseFirestore.instance.runTransaction((tx) async {
          final doc = await tx.get(ref);
          if (doc.data()?['fcmToken'] == token) {
            tx.update(ref, {'fcmToken': FieldValue.delete()});
          }
        }).timeout(const Duration(seconds: 5));
      }
    } finally {
      await _messaging.deleteToken().timeout(const Duration(seconds: 5)).catchError((Object _) {});
    }
  }

  Future<void> clearCurrentDevice() async {
    _navigationReady = false;
    _pendingVendorId = null;
    _configuredUid = null;
    _configuredRole = null;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) { return; }
    try {
      await _removeCurrentDeviceToken(user);
    } catch (_) {
      debugPrint('Could not remove notification registration.');
    } finally {
      await _localNotifications.cancelAll();
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .set({'fcmToken': token}, SetOptions(merge: true)).timeout(const Duration(seconds: 5));
  }

  Future<void> _openVendorDetails(String vendorId) async {
    final navState = _navigatorKey?.currentState;
    if (!_navigationReady || navState == null) {
      _pendingVendorId = vendorId;
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final VendorModel? vendor = await _vendorService.getVendorProfile(vendorId);
    if (vendor == null || !_navigationReady ||
        FirebaseAuth.instance.currentUser?.uid != uid) { return; }

    navState.push(
      MaterialPageRoute(builder: (_) => VendorDetailsScreen(vendor: vendor)),
    );
  }
}
````

## File: lib/features/customer/vendor_details/vendor_details_screen.dart
````dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/models/menu_item_model.dart';
import '../../../core/services/menu_service.dart';
import '../../../core/services/follow_service.dart';
import '../../../core/services/vendor_service.dart';
import '../../auth/screens/login_screen.dart';

class VendorDetailsScreen extends StatefulWidget {
  final VendorModel vendor;

  const VendorDetailsScreen({super.key, required this.vendor});

  @override
  State<VendorDetailsScreen> createState() => _VendorDetailsScreenState();
}

class _VendorDetailsScreenState extends State<VendorDetailsScreen> {
  final _menuService = MenuService();
  final _followService = FollowService();
  final _vendorService = VendorService();

  // Local copy of the vendor, refreshable independently of the
  // instance passed in -- the one passed in is a snapshot from
  // whenever the customer tapped the marker/card, and doesn't update
  // on its own if the vendor changes their status while this screen
  // is open.
  late VendorModel _vendor;
  bool _isRefreshing = false;
  String? _vendorError;
  bool _vendorDeleted = false;
  bool _isFollowSaving = false;
  StreamSubscription<VendorModel?>? _vendorSub;
  Timer? _freshnessTimer;
  late Stream<List<MenuItemModel>> _menuStream;

  // Local follow state, kept in sync with Firestore via a listener but
  // updated OPTIMISTICALLY (immediately, before the write completes)
  // when the user taps the heart -- this is what makes the icon flip
  // instantly instead of waiting on a round-trip.
  bool _isFollowing = false;
  StreamSubscription<bool>? _followSub;

  @override
  void initState() {
    super.initState();
    _vendor = widget.vendor;
    _menuStream = _menuService.getMenuItems(_vendor.vendorId);
    _vendorSub = _vendorService.watchVendorProfile(_vendor.vendorId).listen(
      (vendor) {
        if (!mounted) { return; }
        setState(() {
          _vendorDeleted = vendor == null;
          if (vendor != null) { _vendor = vendor; }
          _vendorError = null;
        });
      },
      onError: (Object error) {
        if (mounted) { setState(() => _vendorError = 'Could not update this stall. Showing last known details.'); }
      },
    );
    _freshnessTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) { setState(() {}); }
    });

    final customerId = FirebaseAuth.instance.currentUser?.uid;
    if (customerId != null) {
      _followSub = _followService
          .isFollowing(customerId, _vendor.vendorId)
          .listen((value) {
        if (mounted) { setState(() => _isFollowing = value); }
      });
    }
  }

  @override
  void dispose() {
    _followSub?.cancel();
    _vendorSub?.cancel();
    _freshnessTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshVendor() async {
    setState(() => _isRefreshing = true);
    final updated = await _vendorService.getVendorProfile(_vendor.vendorId);
    if (mounted) {
      setState(() {
        if (updated != null) { _vendor = updated; }
        _isRefreshing = false;
      });
    }
  }

  Future<void> _toggleFollow(String customerId) async {
    if (_isFollowSaving) { return; }
    _isFollowSaving = true;
    final wasFollowing = _isFollowing;
    // Flip immediately -- don't wait for Firestore to confirm. If the
    // write fails for some reason, it gets reverted in the catch below.
    setState(() => _isFollowing = !wasFollowing);

    try {
      if (wasFollowing) {
        await _followService.unfollowVendor(customerId, _vendor.vendorId);
      } else {
        await _followService.followVendor(customerId, _vendor.vendorId);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isFollowing = wasFollowing);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update following. Please retry.')),
        );
      }
    } finally {
      if (mounted) { setState(() => _isFollowSaving = false); }
    }
  }

  Future<void> _openNavigation() async {
    final coordinates = '${_vendor.latitude},${_vendor.longitude}';
    final isApplePlatform = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final googleMapsUri = isApplePlatform
        ? Uri.parse('comgooglemaps://?daddr=$coordinates&directionsmode=driving')
        : Uri.parse('google.navigation:q=$coordinates&mode=d');
    final wazeUri = Uri.parse('waze://?ll=$coordinates&navigate=yes');
    final browserUri = Uri.https(
      'www.google.com', '/maps/dir/', {'api': '1', 'destination': coordinates},
    );
    var googleMapsAvailable = false;
    var wazeAvailable = false;
    if (!kIsWeb) {
      try {
        googleMapsAvailable = await canLaunchUrl(googleMapsUri);
        wazeAvailable = await canLaunchUrl(wazeUri);
      } catch (_) {
        // The browser fallback remains available when app detection fails.
      }
    }
    if (!mounted) { return; }

    Future<void> launchNavigation(Uri uri) async {
      Navigator.pop(context);
      var launched = false;
      try { launched = await launchUrl(uri, mode: LaunchMode.externalApplication); }
      catch (_) { launched = false; }
      if (!launched && mounted) { ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open that navigation app.'))); }
    }

    await showModalBottomSheet<void>(context: context, showDragHandle: true,
      builder: (sheetContext) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(title: const Text('Choose navigation app'),
          subtitle: Text(_vendor.stallName.isEmpty ? 'Stall location' : _vendor.stallName)),
        if (googleMapsAvailable) ListTile(leading: const Icon(Icons.map_outlined),
          title: const Text('Google Maps'), onTap: () => launchNavigation(googleMapsUri)),
        if (wazeAvailable) ListTile(leading: const Icon(Icons.navigation_outlined),
          title: const Text('Waze'), onTap: () => launchNavigation(wazeUri)),
        ListTile(leading: const Icon(Icons.open_in_browser),
          title: const Text('Google Maps in browser'), onTap: () => launchNavigation(browserUri)),
        if (!googleMapsAvailable && !wazeAvailable) const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text('Google Maps and Waze were not detected. Browser directions are still available.',
            style: TextStyle(color: Colors.grey))),
      ])));
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create an Account'),
        content: const Text(
          'Following vendors requires an account. Log in or register to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Log In'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'available':
        return const Color(0xFF15803D);
      case 'low_stock':
        return const Color(0xFF92400E);
      case 'out_of_stock':
        return const Color(0xFFB42318);
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'available':
        return 'Available';
      case 'low_stock':
        return 'Low Stock';
      case 'out_of_stock':
        return 'Sold out';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final customerId = currentUser?.uid;
    final isGuest = currentUser?.isAnonymous ?? true;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Stall details'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh stall status',
            onPressed: _isRefreshing ? null : _refreshVendor,
          ),
          if (customerId != null)
            isGuest
                ? IconButton(
                    icon: const Icon(Icons.favorite_border),
                    tooltip: 'Follow',
                    onPressed: () => _showLoginRequiredDialog(context),
                  )
                : IconButton(
                    icon: Icon(
                      _isFollowing ? Icons.favorite : Icons.favorite_border,
                      color: _isFollowing ? Colors.red : null,
                    ),
                    tooltip: _isFollowing ? 'Unfollow' : 'Follow',
                    onPressed: _isFollowSaving || _vendorDeleted ? null : () => _toggleFollow(customerId),
                  ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: !_vendorDeleted && _vendor.hasValidLocation ? _openNavigation : null,
          icon: const Icon(Icons.directions),
          label: const Text('Get directions'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          if (_vendorDeleted || _vendorError != null)
            Padding(padding: const EdgeInsets.only(bottom: 12),
              child: Text(_vendorDeleted ? 'This stall is no longer available.' : _vendorError!)),
          ClipRRect(borderRadius: BorderRadius.circular(24),
            child: AspectRatio(aspectRatio: 1.8,
              child: _vendor.imageUrl.isNotEmpty
                  ? Image.network(_vendor.imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _photoPlaceholder())
                  : _photoPlaceholder())),
          const SizedBox(height: 20),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _badge(_vendor.isOpen ? 'Open now' : 'Closed',
                _vendor.isOpen ? const Color(0xFF15803D) : const Color(0xFFB42318), Icons.circle),
            if (_vendor.category.isNotEmpty)
              _badge(_vendor.category, const Color(0xFF64748B), Icons.restaurant_outlined),
          ]),
          const SizedBox(height: 12),
          Text(_vendor.stallName.isEmpty ? 'Unnamed stall' : _vendor.stallName,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
              height: 1.2, color: Color(0xFF17202D))),
          if (_vendor.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(_vendor.description,
              style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF64748B))),
          ],
          const SizedBox(height: 18),
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE9ECF0))),
            child: Column(children: [
              _info(Icons.schedule_rounded, 'Opening hours',
                _vendor.openingHours.isEmpty ? 'Not provided by this vendor' : _vendor.openingHours),
              const Divider(height: 24, indent: 36),
              _info(Icons.location_on_outlined, _vendor.hasFreshLocation ? 'Location updated recently' : 'Last known location',
                _vendor.hasFreshLocation ? 'The vendor is sharing their location.'
                    : 'This location may be outdated. Check before travelling.'),
            ])),
          const SizedBox(height: 26),
          const Text('On the menu', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF17202D))),
          const SizedBox(height: 4),
          const Text('Availability is updated by the vendor', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 14),
          StreamBuilder<List<MenuItemModel>>(
            stream: _menuStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(padding: const EdgeInsets.all(20), child: Column(children: [
                  const Text('Could not load the menu.'),
                  TextButton(onPressed: () => setState(() => _menuStream = _menuService.getMenuItems(_vendor.vendorId)),
                    child: const Text('Retry')),
                ]));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Padding(padding: EdgeInsets.all(24), child: Text('The vendor has not added a menu yet.'));
              }
              return Column(children: items.map(_menuCard).toList());
            },
          ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder() => Container(color: const Color(0xFFFFF0E7),
    alignment: Alignment.center,
    child: const Icon(Icons.storefront_rounded, size: 60, color: Color(0xFFC64B22)));

  Widget _badge(String text, Color color, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: color.withValues(alpha: .08), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color), const SizedBox(width: 5),
      Flexible(child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color))),
    ]),
  );

  Widget _info(IconData icon, String title, String detail) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, color: const Color(0xFF64748B), size: 21), const SizedBox(width: 14),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF17202D))),
      const SizedBox(height: 4),
      Text(detail, style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF64748B))),
    ])),
  ]);

  Widget _menuCard(MenuItemModel item) => Container(
    margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE9ECF0))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(borderRadius: BorderRadius.circular(14),
        child: SizedBox(width: 68, height: 68,
          child: item.imageUrl.isEmpty ? _photoPlaceholder()
              : Image.network(item.imageUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _photoPlaceholder()))),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF17202D))),
        const SizedBox(height: 4),
        Text('RM ${item.price.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFC64B22))),
        const SizedBox(height: 8),
        _badge(_statusLabel(item.status), _statusColor(item.status), Icons.circle),
      ])),
    ]),
  );
}
````

## File: lib/features/vendor/profile/edit_stall_screen.dart
````dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/vendor_service.dart';
import '../../../core/services/storage_service.dart';

class EditStallScreen extends StatefulWidget {
  const EditStallScreen({super.key});

  @override
  State<EditStallScreen> createState() => _EditStallScreenState();
}

class _EditStallScreenState extends State<EditStallScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vendorService = VendorService();
  final _storageService = StorageService();
  final _auth = FirebaseAuth.instance;

  final _stallNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _openingHoursController = TextEditingController();

  String _selectedCategory = 'Beverages';
  final List<String> _categories = [
    'Beverages',
    'Snacks & Desserts',
    'Malay Food',
    'Chinese Food',
    'Indian Food',
    'Western',
    'Noodles',
  ];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isOpen = false;

  // Existing photo URL loaded from Firestore, and a newly picked local
  // file (not yet uploaded) if the vendor chose a new photo this session.
  String _existingImageUrl = '';
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    _loadExistingVendorData();
  }

  // Fetch vendor info from Firestore to pre-fill the form
  Future<void> _loadExistingVendorData() async {
    final user = _auth.currentUser;
    if (user != null) {
      VendorModel? vendor = await _vendorService.getVendorProfile(user.uid);
      if (vendor != null) {
        _stallNameController.text = vendor.stallName;
        _descriptionController.text = vendor.description;
        _openingHoursController.text = vendor.openingHours;
        _isOpen = vendor.isOpen;
        _existingImageUrl = vendor.imageUrl;
        if (_categories.contains(vendor.category)) {
          _selectedCategory = vendor.category;
        }
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    final file = await _storageService.pickImage();
    if (file != null) {
      setState(() {
        _pickedImage = file;
      });
    }
  }

  // Save updated stall profile to Firestore
  Future<void> _saveStallProfile() async {
    if (!_formKey.currentState!.validate()) { return; }

    final user = _auth.currentUser;
    if (user == null) { return; }

    setState(() {
      _isSaving = true;
    });

    try {
      // Only upload if the vendor picked a new photo this session.
      // Otherwise keep whatever URL was already saved.
      String imageUrl = _existingImageUrl;
      if (_pickedImage != null) {
        imageUrl =
            await _storageService.uploadStallImage(user.uid, _pickedImage!);
      }

      final vendor = VendorModel(
        vendorId: user.uid,
        stallName: _stallNameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        openingHours: _openingHoursController.text.trim(),
        isOpen: _isOpen,
        imageUrl: imageUrl,
      );

      await _vendorService.saveVendorProfile(vendor);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stall profile saved successfully!')),
        );
        Navigator.pop(context); // Return to Dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _stallNameController.dispose();
    _descriptionController.dispose();
    _openingHoursController.dispose();
    super.dispose();
  }

  Widget _buildImagePicker() {
    Widget imageContent;
    if (_pickedImage != null) {
      imageContent = Image.file(_pickedImage!, fit: BoxFit.cover);
    } else if (_existingImageUrl.isNotEmpty) {
      imageContent = Image.network(
        _existingImageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.storefront, size: 48, color: Colors.grey),
      );
    } else {
      imageContent = const Icon(Icons.storefront, size: 48, color: Colors.grey);
    }

    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageContent,
          ),
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Stall Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Stall Photo
                    _buildImagePicker(),
                    const SizedBox(height: 16),

                    // Stall Name
                    TextFormField(
                      controller: _stallNameController,
                      decoration: const InputDecoration(
                        labelText: 'Stall Name',
                        hintText: 'e.g. Uncle John Drink Stall',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Enter stall name'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Food Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCategory = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe your food/drinks offered...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Enter description'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Operating Hours
                    TextFormField(
                      controller: _openingHoursController,
                      decoration: const InputDecoration(
                        labelText: 'Opening Hours',
                        hintText: 'e.g. 8:00 AM - 5:00 PM',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Enter opening hours'
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveStallProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator()
                          : const Text(
                              'Save Changes',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
````

## File: lib/core/constants/app_colors.dart
````dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color primary =
      Color(0xFFFF6E41); // Deep Orange / Food Stall theme
  static const Color primaryLight = Color(0xFFFF8142);

  // New design system
  static const Color background = Color(0xFFF2F2F7); // Grouped page background
  static const Color cardColor = Color(0xFFFFFFFF); // Pure White
  static const Color textDark = Color(0xFF222222); // Dark Charcoal
  static const Color textMuted = Color(0xFF9A9A9E); // Muted Gray

  // Status Colors
  static const Color openGreen = Color(0xFF2E7D32);
  static const Color closedRed = Color(0xFFC62828);
  static const Color limitedYellow = Color(0xFFF57F17);
}
````

## File: lib/core/services/menu_service.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item_model.dart';

class MenuService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream menu items for a specific vendor
  Stream<List<MenuItemModel>> getMenuItems(String vendorId) {
    return _db
        .collection('vendors')
        .doc(vendorId)
        .collection('menu')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MenuItemModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Generates a new, unused document ID for a menu item before it exists.
  // Needed when a photo has to be uploaded (and named after the item's ID)
  // before the item document itself is written.
  String newMenuItemId(String vendorId) {
    return _db.collection('vendors').doc(vendorId).collection('menu').doc().id;
  }

  // Add new menu item. Pass itemId (from newMenuItemId) when a photo was
  // uploaded ahead of time so the item is saved under that same ID.
  Future<void> addMenuItem(
    String vendorId,
    String name,
    double price, {
    String? itemId,
    String? imageUrl,
  }) async {
    if (name.trim().isEmpty || !price.isFinite || price <= 0) { throw ArgumentError('Invalid dish'); }
    final docRef = itemId != null
        ? _db.collection('vendors').doc(vendorId).collection('menu').doc(itemId)
        : _db.collection('vendors').doc(vendorId).collection('menu').doc();

    final newItem = MenuItemModel(
      itemId: docRef.id,
      name: name,
      price: price,
      status: 'available',
      imageUrl: imageUrl ?? '',
    );

    await docRef.set(newItem.toMap()).timeout(const Duration(seconds: 15));
  }

  // Edit an existing item's name, price, and (optionally) photo, without
  // touching its current status. Pass imageUrl only if a new photo was
  // uploaded -- omit it to keep whatever photo the item already has.
  Future<void> updateMenuItem(
    String vendorId,
    String itemId,
    String name,
    double price, {
    String? imageUrl,
  }) async {
    if (name.trim().isEmpty || !price.isFinite || price <= 0) { throw ArgumentError('Invalid dish'); }
    final data = <String, dynamic>{
      'name': name,
      'price': price,
    };
    if (imageUrl != null) {
      data['imageUrl'] = imageUrl;
    }

    await _db
        .collection('vendors')
        .doc(vendorId)
        .collection('menu')
        .doc(itemId)
        .update(data).timeout(const Duration(seconds: 15));
  }

  // Quick Traffic Light Status Update
  Future<void> updateItemStatus(
      String vendorId, String itemId, String newStatus) async {
    if (!{'available', 'low_stock', 'out_of_stock'}.contains(newStatus)) { throw ArgumentError('Invalid status'); }
    await _db
        .collection('vendors')
        .doc(vendorId)
        .collection('menu')
        .doc(itemId)
        .update({'status': newStatus, 'statusUpdatedAt': FieldValue.serverTimestamp()}).timeout(const Duration(seconds: 15));
  }

  // Delete item
  Future<void> deleteMenuItem(String vendorId, String itemId) async {
    await _db
        .collection('vendors')
        .doc(vendorId)
        .collection('menu')
        .doc(itemId)
        .delete().timeout(const Duration(seconds: 15));
  }
}
````

## File: lib/core/theme/app_theme.dart
````dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary).copyWith(
        primary: AppColors.primary,
        surface: Colors.white,
        onSurface: AppColors.textDark,
      ),
      // Use the platform sans-serif consistently, without per-page Poppins overrides.
      textTheme: Typography.material2021().black.apply(
        bodyColor: AppColors.textDark, displayColor: AppColors.textDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w500,
          color: AppColors.textDark, letterSpacing: 0),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFE5E5EA), thickness: .5),
      useMaterial3: true,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      )),
      elevatedButtonTheme: ElevatedButtonThemeData(style: ElevatedButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      )),
      scaffoldBackgroundColor: AppColors.background,
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(TextStyle(
          fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0,
          color: AppColors.textDark)),
        iconTheme: WidgetStatePropertyAll(IconThemeData(color: AppColors.textDark, size: 25)),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 72.0,
      ),
      // Root-cause fix for cards looking peach/tinted instead of pure
      // white: Material 3 automatically tints elevated surfaces with a
      // primary-colored overlay (surfaceTintColor) the higher their
      // elevation is -- since every Card in the app uses elevation,
      // they were all picking up a warm/orange cast from the primary
      // color even though color: null was meant to just mean "white".
      // Setting surfaceTintColor: Colors.transparent here disables
      // that overlay app-wide, so every Card renders true
      // AppColors.cardColor regardless of elevation.
      cardTheme: const CardThemeData(
        color: AppColors.cardColor,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }
}
````

## File: lib/features/customer/following/customer_following_screen.dart
````dart
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/vendor_service.dart';
import '../../../core/services/follow_service.dart';
import '../../auth/screens/login_screen.dart';
import '../vendor_details/vendor_details_screen.dart';

class CustomerFollowingScreen extends StatefulWidget {
  const CustomerFollowingScreen({super.key});
  @override
  State<CustomerFollowingScreen> createState() => _CustomerFollowingScreenState();
}

class _CustomerFollowingScreenState extends State<CustomerFollowingScreen> {
  final _follows = FollowService();
  final _vendors = VendorService();
  final _profiles = <String, VendorModel>{};
  final _subscriptions = <String, StreamSubscription<VendorModel?>>{};
  final _pending = <String>{};
  final _failed = <String>{};
  StreamSubscription<List<String>>? _followSubscription;
  bool _loading = true;
  bool _loadFailed = false;
  bool _openOnly = false;
  bool _ascending = true;
  int _generation = 0;
  bool _restarting = false;

  @override
  void initState() { super.initState(); _listen(); }

  @override
  void dispose() {
    ++_generation;
    _followSubscription?.cancel();
    for (final sub in _subscriptions.values) { sub.cancel(); }
    super.dispose();
  }

  Future<void> _listen() async {
    if (_restarting) { return; }
    _restarting = true;
    try {
    final generation = ++_generation;
    await _followSubscription?.cancel();
    for (final sub in _subscriptions.values) { await sub.cancel(); }
    _subscriptions.clear();
    _pending.clear();
    _failed.clear();
    _profiles.clear();
    if (!mounted || generation != _generation) { return; }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) { setState(() => _loading = false); return; }
    setState(() { _loading = true; _loadFailed = false; });
    _followSubscription = _follows.getFollowedVendorIds(user.uid).listen((ids) {
      if (!mounted || generation != _generation) { return; }
      final active = ids.toSet();
      for (final id in _subscriptions.keys.toList()) {
        if (!active.contains(id)) {
          _subscriptions.remove(id)?.cancel();
          _profiles.remove(id);
          _pending.remove(id);
          _failed.remove(id);
        }
      }
      setState(() { _loading = false; _loadFailed = false; });
      for (final id in active) {
        if (_subscriptions.containsKey(id)) { continue; }
        _pending.add(id);
        _subscriptions[id] = _vendors.watchVendorProfile(id).listen((vendor) {
          if (!mounted || generation != _generation || !_subscriptions.containsKey(id)) { return; }
          setState(() {
            _pending.remove(id);
            _failed.remove(id);
            if (vendor == null) { _profiles.remove(id); } else { _profiles[id] = vendor; }
          });
        }, onError: (Object error) {
          if (!mounted || generation != _generation || !_subscriptions.containsKey(id)) { return; }
          setState(() { _pending.remove(id); _failed.add(id); _profiles.remove(id); });
        });
      }
    }, onError: (Object error) {
      if (mounted && generation == _generation) {
        setState(() { _loading = false; _loadFailed = true; });
      }
    });
    } finally { _restarting = false; }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final guest = user == null || user.isAnonymous;
    final sorted = _profiles.values.toList()..sort((a, b) {
      final comparison = a.stallName.toLowerCase().compareTo(b.stallName.toLowerCase());
      return _ascending ? comparison : -comparison;
    });
    final open = sorted.where((vendor) => vendor.isOpen).toList();
    final closed = sorted.where((vendor) => !vendor.isOpen).toList();
    return ColoredBox(color: const Color(0xFFF2F2F7), child: SafeArea(top: false, bottom: false,
      child: RefreshIndicator(onRefresh: _listen, child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28), children: [
          Row(children: [
            IconButton(tooltip: _ascending ? 'Sort Z to A' : 'Sort A to Z',
              onPressed: () => setState(() => _ascending = !_ascending),
              icon: const Icon(Icons.sort_by_alpha_rounded, color: Color(0xFFFF6E41))),
            Expanded(child: Center(child: CupertinoSlidingSegmentedControl<bool>(
              groupValue: _openOnly,
              children: const {
                false: Padding(padding: EdgeInsets.symmetric(horizontal: 14), child: Text('All stalls')),
                true: Padding(padding: EdgeInsets.symmetric(horizontal: 14), child: Text('Open now')),
              },
              onValueChanged: (value) { if (value != null) { setState(() => _openOnly = value); } },
            ))),
            IconButton(tooltip: 'Refresh followed stalls', onPressed: _listen,
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFFFF6E41))),
          ]),
          const SizedBox(height: 24),
          if (guest) _notice('Keep your favourite stalls here',
            'Sign in, then tap Follow on a stall.', action: TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: const Text('Sign in')))
          else if (_loading || (_pending.isNotEmpty && sorted.isEmpty))
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (_loadFailed) _notice('Could not load followed stalls', 'Check your connection and retry.',
            action: TextButton(onPressed: _listen, child: const Text('Retry')))
          else ...[
            if (_failed.isNotEmpty) _notice('Some stalls could not load', 'Pull down to retry.'),
            if (open.isNotEmpty) _group('OPEN NOW', open),
            if (!_openOnly && closed.isNotEmpty) _group('CLOSED', closed),
            if (_openOnly && open.isEmpty) _notice('No followed stalls are open', 'Check again later, or switch to All stalls.'),
            if (!_openOnly && sorted.isEmpty && _failed.isEmpty)
              _notice('No followed stalls yet', 'Find a stall on the map and tap Follow to save it here.'),
          ],
        ],
      )),
    ));
  }

  Widget _group(String label, List<VendorModel> vendors) => Padding(
    padding: const EdgeInsets.only(bottom: 30), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Text('$label · ${vendors.length}', style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)))),
      Container(clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          for (var index = 0; index < vendors.length; index++) ...[
            if (index > 0) const Divider(height: .5, thickness: .5, color: Color(0xFFE5E5EA)),
            _stallRow(vendors[index]),
          ],
        ])),
    ]),
  );

  Widget _stallRow(VendorModel vendor) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    leading: Icon(Icons.storefront_outlined, size: 24,
      color: vendor.isOpen ? const Color(0xFFFF6E41) : const Color(0xFF8E8E93)),
    title: Text(vendor.stallName.isEmpty ? 'Unnamed stall' : vendor.stallName,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w400, letterSpacing: 0)),
    subtitle: Padding(padding: const EdgeInsets.only(top: 4),
      child: Text(vendor.category, style: const TextStyle(fontSize: 14, color: Color(0xFF8E8E93), letterSpacing: 0))),
    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(vendor.isOpen ? 'Open' : 'Closed', style: TextStyle(fontSize: 12,
        color: vendor.isOpen ? const Color(0xFF15803D) : const Color(0xFF8E8E93))),
      const SizedBox(width: 6), const Icon(Icons.chevron_right, color: Color(0xFFAEAEB2), size: 20),
    ]),
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VendorDetailsScreen(vendor: vendor))),
  );

  Widget _notice(String title, String body, {Widget? action}) => Padding(
    padding: const EdgeInsets.all(24), child: Column(children: [
      Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8), Text(body, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF8E8E93))),
      if (action != null) action,
    ]),
  );
}
````

## File: lib/features/vendor/vendor_main_screen.dart
````dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dashboard/vendor_dashboard_screen.dart';
import 'profile/vendor_profile_screen.dart';

class VendorMainScreen extends StatefulWidget {
  const VendorMainScreen({super.key});

  @override
  State<VendorMainScreen> createState() => _VendorMainScreenState();
}

class _VendorMainScreenState extends State<VendorMainScreen> {
  int _selectedIndex = 0;

  static const _titles = ['Vendor Dashboard', 'Profile'];

  // Key to call dashboard refresh method
  final _dashboardKey = GlobalKey<VendorDashboardScreenState>();

  void _refreshDashboard() {
    _dashboardKey.currentState?.fetchVendorDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          // Refresh button only on Dashboard
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              tooltip: 'Refresh',
              onPressed: _refreshDashboard,
            ),

        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          VendorDashboardScreen(key: _dashboardKey),
          const VendorProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: Color(0xFFFF6E41)),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFFFF6E41)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
````

## File: lib/features/auth/screens/register_screen.dart
````dart
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
      Navigator.of(context).popUntil((route) => route.isFirst);
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
````

## File: lib/features/auth/screens/welcome_screen.dart
````dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import 'login_screen.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _auth = AuthService();
  bool _busy = false;
  bool _loginOpen = false;

  Future<void> _google() async {
    setState(() => _busy = true);
    final error = await _auth.signInWithGoogle();
    if (!mounted) { return; }
    setState(() => _busy = false);
    if (error != null && error != 'cancelled') { _showError(error); }
  }

  Future<void> _guest() async {
    if (_busy) { return; }
    setState(() => _busy = true);
    final error = await _auth.signInAsGuest();
    if (!mounted) { return; }
    setState(() => _busy = false);
    if (error != null) { _showError(error); }
  }

  void _showError(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: const Color(0xFFB3261E)));

  Future<void> _openLogin() async {
    setState(() => _loginOpen = true);
    await showLoginSheet(context);
    if (mounted) { setState(() => _loginOpen = false); }
  }

  Widget _button({required Widget icon, required String label, required Color color,
    required Color textColor, required VoidCallback? onPressed}) => SizedBox(
    height: 58,
    child: FilledButton(onPressed: onPressed,
      style: FilledButton.styleFrom(backgroundColor: color, foregroundColor: textColor,
        disabledBackgroundColor: color.withValues(alpha: .65),
        disabledForegroundColor: textColor.withValues(alpha: .88),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        icon, const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ])),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF18181A),
    body: Stack(children: [
      Positioned.fill(child: ColoredBox(color: Colors.white,
        child: SafeArea(bottom: false, child: Stack(children: [
          if (!_loginOpen) Positioned(top: 12, right: 18, child: IconButton(
            tooltip: 'Continue as guest', onPressed: _busy ? null : _guest,
            style: IconButton.styleFrom(backgroundColor: const Color(0xFFEAEAEC)),
            icon: const Icon(Icons.close_rounded, color: Color(0xFF73737A)))),
          Center(child: Transform.translate(offset: const Offset(0, 26),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('StallSeeker', style: TextStyle(fontSize: 34,
                  fontWeight: FontWeight.w700, color: AppColors.textDark, letterSpacing: -1.1)),
                const SizedBox(width: 8),
                Container(width: 34, height: 34,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.storefront_rounded, size: 21, color: Colors.white)),
              ]),
              const SizedBox(height: 12),
              const Text('Find nearby food stalls, live.',
                style: TextStyle(fontSize: 15, color: Color(0xFF77777E))),
            ]))),
        ])))),
      Positioned(left: 0, right: 0, bottom: 0, child: Container(
        padding: EdgeInsets.fromLTRB(24, 28, 24, MediaQuery.paddingOf(context).bottom + 20),
        decoration: const BoxDecoration(color: Color(0xFF18181A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(40))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _button(icon: Image.asset('assets/google_logo.png', width: 21, height: 21),
            label: 'Continue with Google', color: Colors.white, textColor: Colors.black,
            onPressed: _busy ? null : _google),
          const SizedBox(height: 12),
          _button(icon: const Icon(Icons.mail_outline_rounded, size: 22),
            label: 'Log in or sign up', color: const Color(0xFF2D2D30), textColor: Colors.white,
            onPressed: _busy ? null : _openLogin),
          if (_busy) ...[
            const SizedBox(height: 16),
            const SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
          ],
        ]))),
    ]),
  );
}
````

## File: lib/features/vendor/menu/vendor_menu_screen.dart
````dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/menu_item_model.dart';
import '../../../core/services/menu_service.dart';
import '../../../core/services/storage_service.dart';

class VendorMenuScreen extends StatefulWidget {
  const VendorMenuScreen({super.key});
  @override
  State<VendorMenuScreen> createState() => _VendorMenuScreenState();
}

class _VendorMenuScreenState extends State<VendorMenuScreen> {
  final _menu = MenuService();
  final _storage = StorageService();
  final _busyItems = <String>{};
  late Stream<List<MenuItemModel>> _items;
  final _uid = FirebaseAuth.instance.currentUser?.uid;
  static const _statuses = {
    'available': ('Available', Colors.green),
    'low_stock': ('Low stock', Colors.orange),
    'out_of_stock': ('Sold out', Colors.red),
  };

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _items = _uid == null ? Stream.value(<MenuItemModel>[]) : _menu.getMenuItems(_uid);
  }

  void _error(String message) {
    if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message))); }
  }

  Future<void> _status(MenuItemModel item, String status) async {
    if (_uid == null || _busyItems.contains(item.itemId) || item.status == status) { return; }
    setState(() => _busyItems.add(item.itemId));
    try {
      await _menu.updateItemStatus(_uid, item.itemId, status);
    } catch (_) {
      _error('Could not update stock. Please retry.');
    } finally {
      if (mounted) { setState(() => _busyItems.remove(item.itemId)); }
    }
  }

  Future<void> _delete(MenuItemModel item) async {
    if (_uid == null || _busyItems.contains(item.itemId)) { return; }
    final confirmed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      title: const Text('Delete dish?'),
      content: Text('Delete ${item.name} from your menu? This cannot be undone.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
      ],
    ));
    if (confirmed != true || !mounted) { return; }
    setState(() => _busyItems.add(item.itemId));
    try { await _menu.deleteMenuItem(_uid, item.itemId); }
    catch (_) { _error('Could not delete this dish. Please retry.'); }
    finally { if (mounted) { setState(() => _busyItems.remove(item.itemId)); } }
  }

  Future<void> _edit([MenuItemModel? item]) async {
    if (_uid == null) { return; }
    await showModalBottomSheet<void>(
      context: context, isScrollControlled: true, useSafeArea: true,
      isDismissible: false, enableDrag: false,
      builder: (_) => _MenuEditor(uid: _uid, item: item, menu: _menu, storage: _storage),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Menu & stock')),
    floatingActionButton: _uid == null ? null : FloatingActionButton.extended(
      onPressed: _edit, icon: const Icon(Icons.add), label: const Text('Add dish')),
    body: StreamBuilder<List<MenuItemModel>>(stream: _items, builder: (context, snapshot) {
      if (snapshot.hasError) { return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('Could not load your menu.'),
        TextButton(onPressed: () => setState(_reload), child: const Text('Retry')),
      ])); }
      if (snapshot.connectionState == ConnectionState.waiting) { return const Center(child: CircularProgressIndicator()); }
      final items = snapshot.data ?? [];
      if (items.isEmpty) { return const Center(child: Text('Your menu is empty.\nTap Add dish to get started.', textAlign: TextAlign.center)); }
      return ListView.builder(padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final busy = _busyItems.contains(item.itemId);
          return Card(margin: const EdgeInsets.only(bottom: 12), child: Padding(
            padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: 56, height: 56,
                  child: item.imageUrl.isEmpty ? const Icon(Icons.restaurant, size: 32)
                      : Image.network(item.imageUrl, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.restaurant, size: 32)))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                  Text('RM ${item.price.toStringAsFixed(2)}'),
                ])),
                PopupMenuButton<String>(enabled: !busy, tooltip: 'Dish options', onSelected: (value) {
                  if (value == 'edit') { _edit(item); } else { _delete(item); }
                }, itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit dish')),
                  PopupMenuItem(value: 'delete', child: Text('Delete dish')),
                ]),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 8, runSpacing: 4, children: _statuses.entries.map((entry) => ChoiceChip(
                label: Text(entry.value.$1),
                avatar: Icon(Icons.circle, size: 12, color: entry.value.$2),
                selected: item.status == entry.key,
                onSelected: busy ? null : (_) => _status(item, entry.key),
              )).toList()),
              if (busy) const LinearProgressIndicator(),
            ]),
          ));
        });
    }),
  );
}

class _MenuEditor extends StatefulWidget {
  const _MenuEditor({required this.uid, required this.item, required this.menu, required this.storage});
  final String uid;
  final MenuItemModel? item;
  final MenuService menu;
  final StorageService storage;
  @override
  State<_MenuEditor> createState() => _MenuEditorState();
}

class _MenuEditorState extends State<_MenuEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final String _itemId;
  File? _image;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.item?.name ?? '');
    _price = TextEditingController(text: widget.item?.price.toStringAsFixed(2) ?? '');
    // Reuse the same ID on retries so an uncertain network result cannot duplicate a dish.
    _itemId = widget.item?.itemId ?? widget.menu.newMenuItemId(widget.uid);
  }
  @override
  void dispose() { _name.dispose(); _price.dispose(); super.dispose(); }

  Future<void> _pick() async {
    try {
      final image = await widget.storage.pickImage();
      if (mounted && image != null) { setState(() => _image = image); }
    } catch (_) {
      if (mounted) { setState(() => _error = 'Could not open your photos. Please retry.'); }
    }
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) { return; }
    setState(() { _saving = true; _error = null; });
    try {
      String? imageUrl;
      if (_image != null) { imageUrl = await widget.storage.uploadMenuItemImage(widget.uid, _itemId, _image!); }
      if (widget.item == null) {
        await widget.menu.addMenuItem(widget.uid, _name.text.trim(), double.parse(_price.text.trim()),
            itemId: _itemId, imageUrl: imageUrl);
      } else {
        await widget.menu.updateMenuItem(widget.uid, _itemId, _name.text.trim(), double.parse(_price.text.trim()), imageUrl: imageUrl);
      }
      if (mounted) {
        setState(() => _saving = false);
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) { setState(() { _saving = false; _error = 'Could not save this dish. Your changes are still here. Please retry.'; }); }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: SingleChildScrollView(padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Form(key: _form, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(widget.item == null ? 'Add dish' : 'Edit dish', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        if (_image != null) ClipRRect(borderRadius: BorderRadius.circular(12),
            child: Image.file(_image!, height: 140, fit: BoxFit.cover))
        else if (widget.item?.imageUrl.isNotEmpty == true)
          Image.network(widget.item!.imageUrl, height: 140, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.restaurant)),
        TextButton.icon(onPressed: _saving ? null : _pick, icon: const Icon(Icons.add_a_photo_outlined), label: const Text('Choose photo')),
        TextFormField(controller: _name, enabled: !_saving, maxLength: 80,
          decoration: const InputDecoration(labelText: 'Dish name'),
          validator: (value) => value == null || value.trim().isEmpty ? 'Enter a dish name.' : null),
        const SizedBox(height: 12),
        TextFormField(controller: _price, enabled: !_saving,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Price', prefixText: 'RM '),
          validator: (value) {
            final text = value?.trim() ?? '';
            final price = double.tryParse(text);
            if (price == null || !price.isFinite || price <= 0 || !RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(text)) {
              return 'Enter a positive price with up to 2 decimal places.';
            }
            return null;
          }),
        if (_error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        const SizedBox(height: 20),
        FilledButton(onPressed: _saving ? null : _save,
          child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save dish')),
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
      ])),
    ),
  );
}
````

## File: lib/features/vendor/profile/vendor_profile_screen.dart
````dart
import 'edit_stall_screen.dart';
import '../../shared/profile_page.dart';
import '../../shared/edit_profile_screen.dart';
import '../../shared/personal_information_screen.dart';
import '../../shared/change_password_screen.dart';
import '../../shared/notification_settings_screen.dart';
import '../../shared/legal_screen.dart';
import '../../shared/delete_account_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/change_email_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../shared/faq_screen.dart';
import '../../shared/about_screen.dart';
import '../../shared/logout_helper.dart';

class VendorProfileScreen extends StatefulWidget {
  const VendorProfileScreen({super.key});

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  final _authService = AuthService();
  final _geocoding = Geocoding();

  UserModel? _userModel;
  bool _isLoading = true;

  // Current Location section state -- shows the vendor's live GPS
  // position (turned into a readable address via reverse geocoding),
  // same pattern as the customer profile screen.
  String _locationText = 'Tap to find your current area';
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await _authService.getUserData(user.uid);
      if (mounted) {
        setState(() {
          _userModel = userData;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadLocation() async {
    if (!mounted || _isLoadingLocation) { return; }
    setState(() => _isLoadingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) { return; }
      if (!serviceEnabled) {
        setState(() {
          _locationText = 'Location services are turned off.';
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!mounted) { return; }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locationText = 'Location permission not granted.';
          _isLoadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 12));

      final placemarks = await _geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 8));
      final address =
          _formatPlacemark(placemarks.isNotEmpty ? placemarks.first : null);

      if (mounted) {
        setState(() {
          _locationText = address;
          _isLoadingLocation = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationText = 'Unable to fetch location.';
          _isLoadingLocation = false;
        });
      }
    }
  }

  String _formatPlacemark(Placemark? p) {
    if (p == null) { return 'Location unavailable'; }
    final parts = [p.subLocality, p.locality, p.administrativeArea]
        .where((s) => s != null && s.isNotEmpty)
        .toList();
    return parts.isEmpty ? 'Location unavailable' : parts.join(', ');
  }

  Future<void> _editProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => EditProfileScreen(
        name: _userModel?.fullName ?? user?.displayName ?? '',
        email: _userModel?.email ?? user?.email ?? '')));
    if (saved == true && mounted) {
      await _loadUserData();
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.'))); }
    }
  }

  Future<void> _personalInformation() async {
    final user = FirebaseAuth.instance.currentUser;
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => PersonalInformationScreen(
        name: _userModel?.fullName ?? user?.displayName ?? '',
        email: _userModel?.email ?? user?.email ?? '',
        isVendor: true)));
    if (mounted) { await _loadUserData(); }
  }

  void _changePassword() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChangePasswordScreen(
        email: _userModel?.email ?? FirebaseAuth.instance.currentUser?.email ?? '')));
  }

  Future<void> _changeEmail() async {
    final changed = await Navigator.push<bool>(context,
      MaterialPageRoute(builder: (_) => const ChangeEmailScreen()));
    if (changed == true && mounted) { await _loadUserData(); }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) { return const Center(child: CircularProgressIndicator()); }
    final user = FirebaseAuth.instance.currentUser;
    final guest = user?.isAnonymous ?? true;
    final name = guest ? 'Guest' : _userModel?.fullName.isNotEmpty == true
        ? _userModel!.fullName : user?.displayName ?? 'Your profile';
    return ProfilePage(
      name: name, email: guest ? '' : _userModel?.email ?? user?.email ?? '',
      photoUrl: guest ? null : user?.photoURL,
      isVendor: true, isGuest: guest,
      canChangePassword: user?.providerData.any((provider) => provider.providerId == 'password') ?? false,
      location: _locationText, isLoadingLocation: _isLoadingLocation,
      onRefresh: _loadUserData,
      onLocation: _loadLocation,
      onEdit: _editProfile,
      onPersonalInformation: _personalInformation,
      onPassword: _changePassword,
      onEmail: _changeEmail,
      onFaq: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const FaqScreen(isVendor: true))),
      onAbout: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
      onNotificationSettings: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
      onPrivacyPolicy: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const LegalScreen(page: LegalPage.privacy))),
      onTerms: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const LegalScreen(page: LegalPage.terms))),
      onDeleteAccount: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const DeleteAccountScreen())),
      onLogout: () => confirmAndLogout(context, _authService),
      onSignIn: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
      onEditStall: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditStallScreen())),
    );
  }
}
````

## File: lib/features/vendor/dashboard/vendor_dashboard_screen.dart
````dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/vendor_service.dart';
import '../../../core/services/vendor_location_service.dart';
import '../profile/edit_stall_screen.dart';
import '../menu/vendor_menu_screen.dart';
import '../../shared/manual_location_dialog.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});
  @override
  VendorDashboardScreenState createState() => VendorDashboardScreenState();
}

class VendorDashboardScreenState extends State<VendorDashboardScreen>
    with WidgetsBindingObserver {
  final _vendorService = VendorService();
  final _location = VendorLocationService.instance;
  StreamSubscription<VendorModel?>? _subscription;
  VendorModel? _vendor;
  bool _loading = true;
  bool _saving = false;
  bool _foreground = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _location.addListener(_locationChanged);
    fetchVendorDetails();
  }

  void _locationChanged() {
    if (mounted) { setState(() {}); }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      unawaited(_location.pause());
    }
    // Resuming is explicit: avoids restarting sharing after logout or a
    // permission dialog, and makes foreground-only behaviour visible.
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _location.removeListener(_locationChanged);
    _subscription?.cancel();
    unawaited(_location.pause());
    super.dispose();
  }

  Future<void> fetchVendorDetails() async {
    await _subscription?.cancel();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || !mounted) { return; }
    setState(() { _loading = true; _error = null; });
    _subscription = _vendorService.watchVendorProfile(uid).listen((vendor) {
      if (!mounted) { return; }
      setState(() { _vendor = vendor; _loading = false; _error = null; });
      if (vendor?.isOpen != true && _location.isSharing) { unawaited(_location.pause()); }
    }, onError: (Object error) {
      if (mounted) { setState(() {
        _loading = false;
        _error = 'Could not load your stall. Check your connection and retry.';
      }); }
    });
  }

  Future<Position> _position() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Turn on GPS before sharing your location.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) { permission = await Geolocator.requestPermission(); }
    if (permission == LocationPermission.deniedForever) {
      throw StateError('Allow location access in your phone settings.');
    }
    if (permission == LocationPermission.denied) { throw StateError('Location permission is required.'); }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).timeout(const Duration(seconds: 12));
  }

  Future<void> _toggle(bool open) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (_saving || uid == null) { return; }
    if (open && (_vendor?.stallName.trim().isEmpty ?? true)) {
      _message('Set up your stall name before opening.');
      return;
    }
    if (open) {
      final agreed = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Open stall and share location?'),
        content: const Text('Your location updates while StallSeeker is open. Sharing pauses when you leave the app or lock your phone. Customers will see the last known location.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Open stall')),
        ],
      ));
      if (agreed != true || !mounted) { return; }
    }
    setState(() => _saving = true);
    try {
      if (open) {
        double? latitude;
        double? longitude;
        var manualLocation = false;
        try {
          final position = await _position();
          latitude = position.latitude;
          longitude = position.longitude;
        } catch (_) {
          if (!mounted) { return; }
          final existing = _vendor?.hasValidLocation == true
              ? LatLng(_vendor!.latitude, _vendor!.longitude) : null;
          final location = await showManualLocationDialog(context,
            initialLocation: existing,
            title: 'Set Stall Location Manually');
          if (location == null || !mounted) { return; }
          latitude = location.latitude;
          longitude = location.longitude;
          manualLocation = true;
        }
        if (!mounted || FirebaseAuth.instance.currentUser?.uid != uid) { return; }
        await _vendorService.updateVendorLocation(uid, latitude, longitude,
          sharingActive: !manualLocation);
        await _vendorService.toggleStallStatus(uid, true);
        if (!manualLocation && mounted && _foreground) { await _location.start(uid); }
        if (manualLocation) {
          _message('Your stall is open using the manually entered location.');
        }
      } else {
        await _location.pause();
        await _vendorService.toggleStallStatus(uid, false);
      }
      if (!open) { _message('Your stall is closed.'); }
      if (open && _location.isSharing) { _message('Your stall is open.'); }
    } catch (_) {
      _message('Could not update your stall. Check GPS, location permission, and connection, then retry.');
    } finally {
      if (mounted) { setState(() => _saving = false); }
    }
  }

  Future<void> _resume() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _saving) { return; }
    setState(() => _saving = true);
    try {
      await _position();
      if (mounted && _foreground && FirebaseAuth.instance.currentUser?.uid == uid) {
        await _location.start(uid);
      }
    } catch (_) {
      _message('Could not share location. Check GPS and location permission.');
    } finally {
      if (mounted) { setState(() => _saving = false); }
    }
  }

  void _message(String text) {
    if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text))); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) { return const Center(child: CircularProgressIndicator()); }
    if (_error != null) { return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Text(_error!, textAlign: TextAlign.center),
      TextButton(onPressed: fetchVendorDetails, child: const Text('Retry')),
    ])); }
    final open = _vendor?.isOpen ?? false;
    return RefreshIndicator(
      onRefresh: fetchVendorDetails,
      child: ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(16), children: [
        Text(_vendor?.stallName.isNotEmpty == true ? _vendor!.stallName : 'Set up your stall',
            style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SwitchListTile(contentPadding: EdgeInsets.zero,
            title: Text(open ? 'Stall open' : 'Stall closed'),
            subtitle: const Text('Control whether customers can find you on the live map'),
            value: open, onChanged: _saving ? null : _toggle),
          if (_saving) const LinearProgressIndicator(),
          const Divider(),
          Text(!open ? 'Location sharing off'
              : _location.error ?? (_location.isSharing ? 'Location sharing active while the app is open' : 'Location sharing paused')),
          if (open && !_location.isSharing)
            TextButton.icon(onPressed: _saving ? null : _resume,
                icon: const Icon(Icons.my_location), label: const Text('Resume sharing')),
        ]))),
        const SizedBox(height: 16),
        FilledButton.icon(onPressed: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const VendorMenuScreen())),
            icon: const Icon(Icons.restaurant_menu), label: const Text('Manage menu & stock')),
        const SizedBox(height: 16),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Stall information', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(_vendor?.category ?? 'Choose a food category'),
          Text(_vendor?.openingHours ?? 'Add your opening hours'),
          const SizedBox(height: 8),
          Text(_vendor?.description ?? 'Tell customers what you sell.'),
          TextButton.icon(onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const EditStallScreen())),
              icon: const Icon(Icons.edit_outlined), label: const Text('Edit stall')),
        ]))),
      ]),
    );
  }
}
````

## File: lib/core/services/auth_service.dart
````dart
import 'notification_service.dart';
import 'vendor_location_service.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';
import '../constants/firestore_collections.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static bool _googleSignInReady = false;

  // google_sign_in v7 requires an explicit initialize() call, exactly
  // once, before authenticate()/signOut() are used. Cheap to call
  // repeatedly since it's guarded by the flag below.
  Future<void> _ensureGoogleSignInReady() async {
    if (_googleSignInReady) { return; }
    await _googleSignIn.initialize(
      serverClientId:
          '793011933510-ljrpbsf089fjdmjk58tfo7o1dmg1bmov.apps.googleusercontent.com',
    );
    _googleSignInReady = true;
  }

  // Stream of auth state changes (logged in / logged out)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current Firebase user
  User? get currentUser => _auth.currentUser;

  // Register user with Email, Password, Name & Role
  Future<String?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (credential.user != null) {
        UserModel newUser = UserModel(
          uid: credential.user!.uid,
          email: email.trim(),
          fullName: fullName.trim(),
          role: role,
          createdAt: DateTime.now(),
        );

        await _firestore
            .collection(FirestoreCollections.users)
            .doc(credential.user!.uid)
            .set({...newUser.toMap(), 'emailVerified': false});

        return null;
      }
      return "User creation failed.";
    } on FirebaseAuthException catch (e) {
      return e.message ?? "An authentication error occurred.";
    } catch (e) {
      return e.toString();
    }
  }

  // Login user with Email & Password
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "An authentication error occurred.";
    } catch (e) {
      return e.toString();
    }
  }

  // Google sign-in. Offered as a quick customer entry point -- a
  // brand-new Google user is created as role 'customer' automatically,
  // using their Google account's display name as fullName. Vendors
  // still register with email/password since a stall account needs the
  // role picker anyway.
  //
  // A 25-second timeout is applied to the account picker step. Without
  // this, a misconfigured SHA-1 fingerprint (the most common cause of
  // this failing) makes the picker hang indefinitely with no error and
  // no way forward for the user -- the timeout turns that into a clear
  // message instead of a frozen screen.
  Future<String?> signInWithGoogle() async {
    try {
      await _ensureGoogleSignInReady();

      final GoogleSignInAccount googleUser = await _googleSignIn
          .authenticate()
          .timeout(const Duration(seconds: 25));

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth
          .signInWithCredential(credential)
          .timeout(const Duration(seconds: 25));
      final user = userCredential.user;

      if (user != null &&
          (userCredential.additionalUserInfo?.isNewUser ?? false)) {
        final newUser = UserModel(
          uid: user.uid,
          email: user.email ?? '',
          fullName: user.displayName ?? '',
          role: 'customer',
          createdAt: DateTime.now(),
        );
        await _firestore
            .collection(FirestoreCollections.users)
            .doc(user.uid)
            .set({...newUser.toMap(), 'emailVerified': true});
      }

      return null;
    } on TimeoutException {
      return "Google sign-in timed out. Check your connection and try again, "
          "or sign in with email.";
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return "cancelled"; // user closed the picker without choosing
      }
      return e.description ?? "Google sign-in failed.";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        return "An account already exists with this email. Log in with your email and password instead.";
      }
      return e.message ?? "Google sign-in failed.";
    } catch (e) {
      return e.toString();
    }
  }

  // Guest mode: signs in anonymously so a customer can browse without
  // creating an account. Anonymous users skip the Firestore users/
  // document entirely (see AuthWrapper) and can't follow vendors --
  // following requires converting to a real account.
  Future<String?> signInAsGuest() async {
    try {
      await _auth.signInAnonymously();
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Could not start guest session.";
    } catch (e) {
      return e.toString();
    }
  }

  // Fetch current user's data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching user data: $e");
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await VendorLocationService.instance.pause();
    try {
      await NotificationService.instance.clearCurrentDevice();
    } catch (_) {
      debugPrint('Notification cleanup could not finish.');
    }
    try {
      if (_googleSignInReady) { await _googleSignIn.signOut(); }
    } finally {
      await _auth.signOut();
    }
  }

  Future<String?> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return null;
    } on FirebaseAuthException catch (e) {
      // Give the same result for unknown accounts to avoid exposing sign-ups.
      if (e.code == 'user-not-found') { return null; }
      if (e.code == 'invalid-email') { return 'Enter a valid email address.'; }
      if (e.code == 'too-many-requests') { return 'Too many requests. Please wait and try again.'; }
      if (e.code == 'network-request-failed') { return 'Could not connect. Check your network and retry.'; }
      return 'Could not send the reset link. Please try again.';
    } catch (_) {
      return 'Could not send the reset link. Please try again.';
    }
  }

  Future<String?> requestEmailVerificationCode({String? newEmail}) async {
    try {
      final callable = FirebaseFunctions.instance
          .httpsCallable('requestEmailVerificationCode');
      await callable.call(<String, dynamic>{
        'purpose': newEmail == null ? 'registration' : 'email_change',
        if (newEmail != null) 'newEmail': newEmail.trim(),
      });
      return null;
    } on FirebaseFunctionsException catch (e) {
      return e.message ?? 'Could not send the verification code.';
    } catch (_) {
      return 'Could not send the verification code. Please try again.';
    }
  }

  Future<String?> confirmEmailVerificationCode({
    required String code,
    String? newEmail,
  }) async {
    try {
      final callable = FirebaseFunctions.instance
          .httpsCallable('confirmEmailVerificationCode');
      await callable.call(<String, dynamic>{
        'purpose': newEmail == null ? 'registration' : 'email_change',
        'code': code.trim(),
        if (newEmail != null) 'newEmail': newEmail.trim(),
      });
      await _auth.currentUser?.reload();
      await _auth.currentUser?.getIdToken(true);
      return null;
    } on FirebaseFunctionsException catch (e) {
      return e.message ?? 'The verification code could not be confirmed.';
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'The account could not be refreshed.';
    } catch (_) {
      return 'The verification code could not be confirmed. Please try again.';
    }
  }

  Future<String?> changePassword(String newPassword, {String? currentPassword}) async {
    try {
      final user = _auth.currentUser;
      if (user == null) { return "No user is currently logged in."; }
      if (currentPassword != null) {
        if (user.email == null || !user.providerData.any((p) => p.providerId == 'password')) {
          return 'Manage your password with your sign-in provider.';
        }
        final credential = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
        await user.reauthenticateWithCredential(credential);
      }
      await user.updatePassword(newPassword);
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Your current password is incorrect. Please try again.';
      }
      if (e.code == 'too-many-requests') { return 'Too many attempts. Please wait and try again.'; }
      if (e.code == 'network-request-failed') { return 'Could not connect. Check your network and retry.'; }
      if (e.code == 'requires-recent-login') {
        return "For security, please log out and log back in before changing your password.";
      }
      return e.message ?? "Could not change password.";
    } catch (_) {
      return 'Could not update your password. Please try again.';
    }
  }

  Future<String?> updateFullName(String uid, String newName) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.isAnonymous || user.uid != uid) { return 'Please sign in to edit your profile.'; }
      final name = newName.trim();
      if (name.isEmpty || name.length > 80) { return 'Enter a name between 1 and 80 characters.'; }
      await _firestore
          .collection(FirestoreCollections.users)
          .doc(uid)
          .update({'fullName': name});
      // Firestore is the app's profile source. Sync Auth's display name as well.
      try { await user.updateDisplayName(name); }
      catch (_) { debugPrint('Profile saved; Auth display-name sync is unavailable.'); }
      return null;
    } catch (_) {
      return 'Could not save your profile. Please try again.';
    }
  }

  Future<String?> deleteAccount({String? currentPassword}) async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) { return 'Sign in before deleting your account.'; }
    try {
      final providers = user.providerData.map((provider) => provider.providerId).toSet();
      if (providers.contains('password')) {
        if (currentPassword == null || currentPassword.isEmpty || user.email == null) {
          return 'Enter your current password.';
        }
        await user.reauthenticateWithCredential(EmailAuthProvider.credential(
          email: user.email!, password: currentPassword));
      } else if (providers.contains('google.com')) {
        await _ensureGoogleSignInReady();
        final googleUser = await _googleSignIn.authenticate();
        final googleAuth = googleUser.authentication;
        await user.reauthenticateWithCredential(
          GoogleAuthProvider.credential(idToken: googleAuth.idToken));
      } else {
        return 'Log out, sign in again, then retry account deletion.';
      }

      await NotificationService.instance.clearCurrentDevice();
      await FirebaseFunctions.instance.httpsCallable('deleteAccount').call();
      await _auth.signOut();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Your current password is incorrect.';
      }
      if (e.code == 'requires-recent-login') {
        return 'Log out, sign in again, then retry account deletion.';
      }
      return e.message ?? 'Could not verify your account.';
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'unauthenticated') { return 'Your session expired. Sign in and try again.'; }
      if (e.code == 'failed-precondition') {
        return 'Confirm your sign-in, then retry account deletion.';
      }
      return 'Could not finish account deletion. Please retry.';
    } catch (_) {
      return 'Could not delete your account. Please try again.';
    }
  }
}
````

## File: lib/features/auth/screens/login_screen.dart
````dart
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/auth_service.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart';

Future<void> showLoginSheet(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: false,
      isDismissible: true,
      enableDrag: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: .28),
      builder: (sheetContext) => AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: .90,
          minChildSize: .55,
          maxChildSize: .96,
          snap: true,
          snapSizes: const [.55, .90],
          builder: (_, controller) => LoginScreen(
            embeddedInSheet: true,
            scrollController: controller,
          ),
        ),
      ),
    );

class LoginScreen extends StatefulWidget {
  const LoginScreen(
      {super.key, this.embeddedInSheet = false, this.scrollController});
  final bool embeddedInSheet;
  final ScrollController? scrollController;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  StreamSubscription<User?>? _authSub;
  bool _busy = false;
  bool _hidePassword = true;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null &&
          !user.isAnonymous &&
          user.emailVerified &&
          mounted &&
          Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _busy = true);
    final error =
        await _auth.login(email: _email.text.trim(), password: _password.text);
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (error != null) {
      _showError(error);
    } else if (FirebaseAuth.instance.currentUser?.emailVerified == false) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  Future<void> _google() async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    final error = await _auth.signInWithGoogle();
    if (!mounted) {
      return;
    }
    setState(() => _busy = false);
    if (error != null && error != 'cancelled') {
      _showError(error);
    }
  }

  void _close() {
    if (!_busy) {
      Navigator.maybePop(context);
    }
  }

  void _showError(String message) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message), backgroundColor: const Color(0xFFB3261E)));

  @override
  void dispose() {
    _authSub?.cancel();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  InputDecoration _field(String label, {Widget? suffix}) => InputDecoration(
        labelText: label,
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFD5D5D8))),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFD5D5D8))),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: const BorderSide(color: Color(0xFFB3261E))),
      );

  Widget _divider() => const Row(children: [
        Expanded(child: Divider(color: Color(0xFFE3E3E5))),
        Padding(
            padding: EdgeInsets.symmetric(horizontal: 14),
            child: Text('OR',
                style: TextStyle(fontSize: 13, color: Color(0xFF77777E)))),
        Expanded(child: Divider(color: Color(0xFFE3E3E5))),
      ]);

  Widget _panel(BuildContext context) => Material(
        color: Colors.white,
        borderRadius: widget.embeddedInSheet
            ? const BorderRadius.vertical(top: Radius.circular(28))
            : BorderRadius.zero,
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          if (widget.embeddedInSheet) ...[
            const SizedBox(height: 10),
            Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                    color: const Color(0xFFD2D2D5),
                    borderRadius: BorderRadius.circular(3))),
          ],
          Expanded(
              child: SingleChildScrollView(
            controller: widget.scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.fromLTRB(24, widget.embeddedInSheet ? 6 : 18,
                24, MediaQuery.paddingOf(context).bottom + 28),
            child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                            tooltip: 'Close',
                            onPressed: _busy ? null : _close,
                            style: IconButton.styleFrom(
                                backgroundColor: const Color(0xFFEAEAEC)),
                            icon: const Icon(Icons.close_rounded,
                                color: Color(0xFF73737A)))),
                    const Icon(Icons.storefront_rounded,
                        size: 42, color: AppColors.primary),
                    const SizedBox(height: 10),
                    const Text('Log in or sign up',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -.4)),
                    const SizedBox(height: 8),
                    const Text(
                        'Follow favourite stalls and receive live updates.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 15,
                            height: 1.4,
                            color: Color(0xFF707078))),
                    const SizedBox(height: 28),
                    TextFormField(
                        controller: _email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.email],
                        decoration: _field('Email address'),
                        validator: (value) =>
                            value == null || !value.trim().contains('@')
                                ? 'Enter a valid email address.'
                                : null),
                    const SizedBox(height: 12),
                    TextFormField(
                        controller: _password,
                        obscureText: _hidePassword,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.password],
                        onFieldSubmitted: (_) => _login(),
                        decoration: _field('Password',
                            suffix: IconButton(
                                onPressed: () => setState(
                                    () => _hidePassword = !_hidePassword),
                                icon: Icon(_hidePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined))),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter your password.'
                            : null),
                    Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                            onPressed: _busy
                                ? null
                                : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ForgotPasswordScreen(
                                            initialEmail: _email.text.trim()))),
                            child: const Text('Forgot password?',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600)))),
                    SizedBox(
                        height: 56,
                        child: FilledButton(
                            onPressed: _busy ? null : _login,
                            style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28))),
                            child: _busy
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                        color: Colors.white, strokeWidth: 2))
                                : const Text('Continue',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600)))),
                    const SizedBox(height: 22),
                    _divider(),
                    const SizedBox(height: 18),
                    SizedBox(
                        height: 56,
                        child: OutlinedButton(
                            onPressed: _busy ? null : _google,
                            style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.black,
                                side:
                                    const BorderSide(color: Color(0xFFD5D5D8)),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(28))),
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset('assets/google_logo.png',
                                      width: 21, height: 21),
                                  const SizedBox(width: 12),
                                  const Text('Continue with Google',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600)),
                                ]))),
                    const SizedBox(height: 16),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Text("Don't have an account? ",
                          style: TextStyle(color: Color(0xFF707078))),
                      TextButton(
                          onPressed: _busy
                              ? null
                              : () => Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const RegisterScreen())),
                          child: const Text('Sign up',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600))),
                    ]),
                  ],
                )),
          )),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    if (widget.embeddedInSheet) {
      return _panel(context);
    }
    return Scaffold(
        backgroundColor: Colors.white, body: SafeArea(child: _panel(context)));
  }
}
````

## File: lib/features/auth/auth_wrapper.dart
````dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stallseeker/features/auth/screens/welcome_screen.dart';
import 'package:stallseeker/features/vendor/vendor_main_screen.dart';
import 'package:stallseeker/features/customer/home/customer_home_screen.dart';
import 'package:stallseeker/core/services/notification_service.dart';
import 'package:stallseeker/core/services/auth_service.dart';
import 'package:stallseeker/features/auth/screens/email_verification_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final _authStream = FirebaseAuth.instance.userChanges();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(stream: _authStream, builder: (context, snapshot) {
      if (snapshot.hasError) { return const _AccountRecovery(message: 'Could not check your session. Please sign in again.'); }
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final user = snapshot.data;
      if (user == null) { return const WelcomeScreen(); }
      if (user.isAnonymous) { return const CustomerHomeScreen(); }
      if (!user.emailVerified) { return const EmailVerificationScreen(); }
      return _AccountGate(key: ValueKey(user.uid), user: user);
    });
  }
}

class _AccountGate extends StatefulWidget {
  const _AccountGate({super.key, required this.user});
  final User user;
  @override
  State<_AccountGate> createState() => _AccountGateState();
}

class _AccountGateState extends State<_AccountGate> {
  late Stream<DocumentSnapshot<Map<String, dynamic>>> _profile;
  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    _profile = FirebaseFirestore.instance.collection('users').doc(widget.user.uid).snapshots();
  }

  @override
  void dispose() {
    NotificationService.instance.setNavigationReady(false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _profile,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final role = snapshot.data?.data()?['role'];
        if (snapshot.hasError || !snapshot.hasData || !snapshot.data!.exists ||
            (role != 'vendor' && role != 'customer')) {
          NotificationService.instance.setNavigationReady(false);
          return _AccountRecovery(
            message: snapshot.hasError
                ? 'Could not load your account. Check your connection and retry.'
                : 'Your account setup is incomplete. Retry, or sign out and contact support.',
            retry: () => setState(_listen),
          );
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            NotificationService.instance.setNavigationReady(role == 'customer');
            unawaited(NotificationService.instance.configureForRole(role));
          }
        });
        return role == 'vendor' ? const VendorMainScreen() : const CustomerHomeScreen();
      },
    );
  }
}

class _AccountRecovery extends StatelessWidget {
  const _AccountRecovery({required this.message, this.retry});
  final String message;
  final VoidCallback? retry;
  @override
  Widget build(BuildContext context) => Scaffold(body: Center(child: Padding(
    padding: const EdgeInsets.all(24),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.cloud_off_outlined, size: 40),
      const SizedBox(height: 16),
      Text(message, textAlign: TextAlign.center),
      if (retry != null) TextButton(onPressed: retry, child: const Text('Retry')),
      TextButton(onPressed: () async {
        try { await AuthService().signOut(); }
        catch (_) {
          if (context.mounted) { ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not sign out. Please retry.'))); }
        }
      }, child: const Text('Sign out')),
    ]),
  )));
}
````

## File: lib/features/customer/profile/customer_profile_screen.dart
````dart
import '../../shared/profile_page.dart';
import '../../shared/edit_profile_screen.dart';
import '../../shared/personal_information_screen.dart';
import '../../shared/change_password_screen.dart';
import '../../shared/notification_settings_screen.dart';
import '../../shared/legal_screen.dart';
import '../../shared/delete_account_screen.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/change_email_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';
import '../../shared/faq_screen.dart';
import '../../shared/about_screen.dart';
import '../../shared/logout_helper.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  final _authService = AuthService();
  final _geocoding = Geocoding();

  UserModel? _userModel;
  bool _isLoading = true;

  String _locationText = 'Tap to find your current area';
  bool _isLoadingLocation = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userData = await _authService.getUserData(user.uid);
      if (mounted) {
        setState(() {
          _userModel = userData;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadLocation() async {
    if (!mounted || _isLoadingLocation) { return; }
    setState(() => _isLoadingLocation = true);

    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!mounted) { return; }
      if (!serviceEnabled) {
        setState(() {
          _locationText = 'Location services are turned off.';
          _isLoadingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (!mounted) { return; }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locationText = 'Location permission not granted.';
          _isLoadingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 12));

      // FIXED: use _geocoding.placemarkFromCoordinates
      final placemarks = await _geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 8));
      final address =
          _formatPlacemark(placemarks.isNotEmpty ? placemarks.first : null);

      if (mounted) {
        setState(() {
          _locationText = address;
          _isLoadingLocation = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationText = 'Unable to fetch location.';
          _isLoadingLocation = false;
        });
      }
    }
  }

  String _formatPlacemark(Placemark? p) {
    if (p == null) { return 'Location unavailable'; }
    final parts = [p.subLocality, p.locality, p.administrativeArea]
        .where((s) => s != null && s.isNotEmpty)
        .toList();
    return parts.isEmpty ? 'Location unavailable' : parts.join(', ');
  }

  Future<void> _editProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    final saved = await Navigator.push<bool>(context, MaterialPageRoute(
      builder: (_) => EditProfileScreen(
        name: _userModel?.fullName ?? user?.displayName ?? '',
        email: _userModel?.email ?? user?.email ?? '')));
    if (saved == true && mounted) {
      await _loadUserData();
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated.'))); }
    }
  }

  Future<void> _personalInformation() async {
    final user = FirebaseAuth.instance.currentUser;
    await Navigator.push(context, MaterialPageRoute(
      builder: (_) => PersonalInformationScreen(
        name: _userModel?.fullName ?? user?.displayName ?? '',
        email: _userModel?.email ?? user?.email ?? '',
        isVendor: false)));
    if (mounted) { await _loadUserData(); }
  }

  void _changePassword() {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => ChangePasswordScreen(
        email: _userModel?.email ?? FirebaseAuth.instance.currentUser?.email ?? '')));
  }

  Future<void> _changeEmail() async {
    final changed = await Navigator.push<bool>(context,
      MaterialPageRoute(builder: (_) => const ChangeEmailScreen()));
    if (changed == true && mounted) { await _loadUserData(); }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) { return const Center(child: CircularProgressIndicator()); }
    final user = FirebaseAuth.instance.currentUser;
    final guest = user?.isAnonymous ?? true;
    final name = guest ? 'Guest' : _userModel?.fullName.isNotEmpty == true
        ? _userModel!.fullName : user?.displayName ?? 'Your profile';
    return ProfilePage(
      name: name, email: guest ? '' : _userModel?.email ?? user?.email ?? '',
      photoUrl: guest ? null : user?.photoURL,
      isVendor: false, isGuest: guest,
      canChangePassword: user?.providerData.any((provider) => provider.providerId == 'password') ?? false,
      location: _locationText, isLoadingLocation: _isLoadingLocation,
      onRefresh: _loadUserData,
      onLocation: _loadLocation,
      onEdit: _editProfile,
      onPersonalInformation: _personalInformation,
      onPassword: _changePassword,
      onEmail: _changeEmail,
      onFaq: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const FaqScreen(isVendor: false))),
      onAbout: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
      onNotificationSettings: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
      onPrivacyPolicy: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const LegalScreen(page: LegalPage.privacy))),
      onTerms: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const LegalScreen(page: LegalPage.terms))),
      onDeleteAccount: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const DeleteAccountScreen())),
      onLogout: () => confirmAndLogout(context, _authService),
      onSignIn: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
      
    );
  }
}
````

## File: lib/main.dart
````dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';
import 'features/splash/splash_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The app's background is light (white/cream), so the status bar's
  // time/battery/signal icons need to render dark to stay visible --
  // otherwise they default to light and blend into the light
  // background, becoming nearly invisible. Set globally here so it
  // applies even on screens that override AppBar styling directly.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
  );

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    runApp(MaterialApp(
        home: Scaffold(
            body: Center(
                child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text(
            'StallSeeker could not start. Check your connection and retry.'),
        TextButton(onPressed: main, child: const Text('Retry')),
      ]),
    )))));
    return;
  }

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  runApp(const StallSeekerApp());
  unawaited(NotificationService.instance
      .initialize(navigatorKey)
      .catchError((Object error) {
    debugPrint('Notifications are currently unavailable.');
  }));
}

class StallSeekerApp extends StatelessWidget {
  const StallSeekerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'StallSeeker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
````

## File: lib/features/customer/home/customer_home_screen.dart
````dart
import '../../../core/services/notification_history_service.dart';
import '../notifications/customer_notifications_screen.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/vendor_service.dart';
import '../following/customer_following_screen.dart';
import '../profile/customer_profile_screen.dart';
import '../vendor_details/vendor_details_screen.dart';
import '../../shared/manual_location_dialog.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _vendorService = VendorService();
  final _authService = AuthService();
  final _searchController = TextEditingController();
  Stream<int>? _unreadCount;

  int _selectedIndex = 0;
  String _searchQuery = '';
  GoogleMapController? _mapController;
  LatLng? _customerPosition;
  bool _usesManualLocation = false;
  double _searchRadiusKm = 5;

  // NEW: Track the visible map area to filter vendors
  LatLngBounds? _visibleBounds;

  final List<String> _tabTitles = ['Home', 'Following', 'Notifications', 'Profile'];
  String _greeting = 'Welcome!';

  String? _selectedVendorId;
  bool _isLocatingCustomer = true;
  bool _locationPermissionGranted = false;
  String? _locationError;
  String? _category;
  Timer? _freshnessTimer;
  late Stream<List<VendorModel>> _vendors;
  final ScrollController _stallScrollController = ScrollController();
  List<VendorModel> _visibleVendors = [];
  double _cardExtent = 288;
  int _cameraRequest = 0;

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(3.1390, 101.6869),
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();
    _vendors = _vendorService.getAllVendors();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      _unreadCount = NotificationHistoryService().watchUnreadCount(user.uid);
    }
    _getCustomerLocation();
    _loadGreeting();
    _freshnessTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) { setState(() {}); }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    _stallScrollController.dispose();
    _freshnessTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadGreeting() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { return; }

    if (user.isAnonymous) {
      if (mounted) { setState(() => _greeting = 'Welcome, Guest'); }
      return;
    }

    final userData = await _authService.getUserData(user.uid);
    final name = userData?.fullName;
    if (mounted) {
      setState(() {
        _greeting =
            (name != null && name.isNotEmpty) ? 'Welcome, $name' : 'Welcome!';
      });
    }
  }

  bool _locationRequestActive = false;

  Future<void> _getCustomerLocation() async {
    if (_isLocatingCustomer && _locationRequestActive) { return; }
    _locationRequestActive = true;
    if (mounted) { setState(() { _isLocatingCustomer = true; _locationError = null; _locationPermissionGranted = false; }); }
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { throw StateError('Turn on GPS, or browse the map manually.'); }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError(permission == LocationPermission.deniedForever
            ? 'Allow location access in phone settings, or browse manually.'
            : 'Location access denied. You can still browse the map.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 12));
      if (!mounted) { return; }

      setState(() {
        _customerPosition = LatLng(position.latitude, position.longitude);
        _locationPermissionGranted = true;
        _usesManualLocation = false;
        _locationError = null;
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_customerPosition!, 15),
      );
    } catch (error) {
      if (mounted) { setState(() {
        _locationError = error is StateError ? error.message.toString()
            : 'Could not find your location. Retry or browse the map manually.';
      }); }
    } finally {
      _locationRequestActive = false;
      if (mounted) {
        setState(() => _isLocatingCustomer = false);
      }
    }
  }

  Future<void> _enterCustomerLocationManually() async {
    final location = await showManualLocationDialog(context,
      initialLocation: _customerPosition ?? _defaultPosition.target,
      title: 'Set Search Location');
    if (location == null || !mounted) { return; }
    setState(() {
      _customerPosition = location;
      _usesManualLocation = true;
      _locationPermissionGranted = false;
      _locationError = null;
    });
    await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(location, 13.5));
  }

  void _expandSearchArea() {
    const radii = [5.0, 10.0, 25.0, 50.0];
    final index = radii.indexOf(_searchRadiusKm);
    if (index < 0 || index == radii.length - 1) { return; }
    setState(() => _searchRadiusKm = radii[index + 1]);
    final zoom = switch (_searchRadiusKm) {
      <= 10 => 12.5,
      <= 25 => 11.0,
      _ => 10.0,
    };
    final position = _customerPosition;
    if (position != null) {
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, zoom));
    }
  }

  Future<void> _selectVendor(VendorModel vendor) async {
    if (!vendor.hasValidLocation) { return; }
    FocusScope.of(context).unfocus();
    final request = ++_cameraRequest;
    setState(() => _selectedVendorId = vendor.vendorId);
    _revealSelectedCard();
    final controller = _mapController;
    if (controller == null) { return; }
    try {
      final currentZoom = await controller.getZoomLevel();
      if (!mounted || request != _cameraRequest) { return; }
      // A modest zoom-in with a useful street-level ceiling. Repeated taps
      // keep the same useful view, instead of zooming further on every tap.
      final targetZoom = currentZoom < 16 ? 16.0 : currentZoom.clamp(16.0, 17.5).toDouble();
      await controller.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(vendor.latitude, vendor.longitude), targetZoom,
      ));
    } catch (_) {
      // A controller may be disposed while the user changes screens.
    }
  }

  void _revealSelectedCard() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_stallScrollController.hasClients) { return; }
      final index = _visibleVendors.indexWhere((v) => v.vendorId == _selectedVendorId);
      if (index < 0) { return; }
      final offset = (index * _cardExtent).clamp(
        0.0, _stallScrollController.position.maxScrollExtent,
      ).toDouble();
      _stallScrollController.animateTo(offset,
        duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
    });
  }

  // NEW: Update the visible bounds whenever the map stops moving
  void _updateVisibleBounds() async {
    if (_mapController == null) { return; }
    try {
      final bounds = await _mapController!.getVisibleRegion();
      if (mounted) {
        setState(() => _visibleBounds = bounds);
        _revealSelectedCard();
      }
    } catch (_) {
      // Controller may have been disposed during navigation.
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) { return '${meters.toStringAsFixed(0)} m away'; }
    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? _greeting : _tabTitles[_selectedIndex],
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              tooltip: 'Refresh',
              onPressed: _getCustomerLocation,
            ),

        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildMapTab(),
          const CustomerFollowingScreen(),
          const CustomerNotificationsScreen(),
          const CustomerProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: Color(0xFFFF6E41)),
            label: 'Discover',
          ),
          const NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite, color: Color(0xFFFF6E41)),
            label: 'Following',
          ),
          NavigationDestination(
            icon: _notificationIcon(false),
            selectedIcon: _notificationIcon(true),
            label: 'Notifications',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFFFF6E41)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _notificationIcon(bool selected) => StreamBuilder<int>(
    stream: _unreadCount,
    builder: (context, snapshot) {
      final count = snapshot.data ?? 0;
      return Badge(
        isLabelVisible: count > 0,
        label: Text(count >= 100 ? '99+' : '$count'),
        child: Icon(selected ? Icons.notifications : Icons.notifications_none_rounded,
          color: selected ? const Color(0xFFFF6E41) : null),
      );
    },
  );

  Widget _buildMapTab() {
    return StreamBuilder<List<VendorModel>>(
      stream: _vendors,
      builder: (context, snapshot) {
        final allVendors = (snapshot.data ?? []).where((v) => v.hasValidLocation &&
            (_category == null || v.category == _category)).toList();

        final query = _searchQuery.trim().toLowerCase();
        final matchingVendors = allVendors.where((vendor) {
          final nameMatches = vendor.stallName.toLowerCase().contains(query);
          final categoryMatches = vendor.category.toLowerCase().contains(query);
          if (query.isEmpty) { return vendor.isOpen; }
          if (vendor.isOpen) { return nameMatches || categoryMatches; }
          return nameMatches;
        });
        final filteredVendors = matchingVendors.where((vendor) {
          final position = _customerPosition;
          if (position == null) { return true; }
          return Geolocator.distanceBetween(position.latitude, position.longitude,
                vendor.latitude, vendor.longitude) <= _searchRadiusKm * 1000;
        }).toList();

        // NEW: Filter to only vendors that are physically inside the current map view
        var onScreenVendors = List<VendorModel>.from(filteredVendors);

        if (_visibleBounds != null) {
          final southWest = _visibleBounds!.southwest;
          final northEast = _visibleBounds!.northeast;

          onScreenVendors = onScreenVendors.where((v) {
            return v.latitude >= southWest.latitude &&
                v.latitude <= northEast.latitude &&
                v.longitude >= southWest.longitude &&
                v.longitude <= northEast.longitude;
          }).toList();
        }

        // Sort by distance for easier viewing
        onScreenVendors.sort((a, b) {
          if (_customerPosition == null) { return 0; }
          final distA = Geolocator.distanceBetween(
            _customerPosition!.latitude,
            _customerPosition!.longitude,
            a.latitude,
            a.longitude,
          );
          final distB = Geolocator.distanceBetween(
            _customerPosition!.latitude,
            _customerPosition!.longitude,
            b.latitude,
            b.longitude,
          );
          return distA.compareTo(distB);
        });

        _visibleVendors = onScreenVendors;

        final markers = filteredVendors
            .map(
              (v) => Marker(
                markerId: MarkerId(v.vendorId),
                position: LatLng(v.latitude, v.longitude),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  v.vendorId == _selectedVendorId
                      ? BitmapDescriptor.hueOrange
                      : BitmapDescriptor.hueRed,
                ),
                infoWindow: InfoWindow(
                  title: v.stallName,
                  snippet: '${v.category} · ${v.isOpen ? "Open" : "Closed"}',
                  onTap: () => _openVendorDetails(v),
                ),
                consumeTapEvents: true,
                onTap: () => _selectVendor(v),
              ),
            )
            .toSet();

        if (_usesManualLocation && _customerPosition != null) {
          markers.add(Marker(markerId: const MarkerId('customer_manual_location'),
            position: _customerPosition!,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            infoWindow: const InfoWindow(title: 'Your search location')));
        }

        return LayoutBuilder(builder: (context, constraints) {
          // The panel is a sibling below the map, never an overlay. It cannot
          // grow to obscure the map, even after tapping or scrolling a stall.
          final shortViewport = constraints.maxHeight < 400;
          final panelHeight = shortViewport ? 52.0
              : (constraints.maxHeight * .34).clamp(168.0, 180.0).toDouble();
          final cardWidth = (constraints.maxWidth - 48).clamp(220.0, 340.0).toDouble();
          _cardExtent = cardWidth + 12;
          return Column(children: [
            Expanded(child: Stack(children: [
              Positioned.fill(child: GoogleMap(
                initialCameraPosition: _defaultPosition,
                markers: markers,
                myLocationEnabled: _locationPermissionGranted,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: true,
                padding: const EdgeInsets.fromLTRB(12, 76, 12, 12),
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (_customerPosition != null) {
                    controller.animateCamera(CameraUpdate.newLatLngZoom(_customerPosition!, 15));
                  }
                  _updateVisibleBounds();
                },
                onCameraIdle: _updateVisibleBounds,
                onTap: (_) {
                  FocusScope.of(context).unfocus();
                },
              )),
              Positioned(top: 12, left: 12, right: 12,
                child: Material(elevation: 3, shadowColor: const Color(0x22000000),
                  color: Colors.white, borderRadius: BorderRadius.circular(18),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() { _searchQuery = value; _selectedVendorId = null; }),
                    decoration: InputDecoration(
                      hintText: 'Find a stall or food category',
                      hintStyle: const TextStyle(fontSize: 13),
                      border: InputBorder.none, enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      prefixIcon: PopupMenuButton<String>(
                        tooltip: 'Filter category', icon: Icon(Icons.tune_rounded,
                          color: _category == null ? AppColors.textDark : AppColors.primary),
                        onSelected: (value) => setState(() {
                          _category = value == 'All' ? null : value;
                          _selectedVendorId = null;
                        }),
                        itemBuilder: (_) => ['All', 'Beverages', 'Snacks & Desserts', 'Malay Food', 'Chinese Food', 'Indian Food', 'Western', 'Noodles']
                            .map((value) => PopupMenuItem(value: value, child: Text(value))).toList(),
                      ),
                      suffixIcon: _searchQuery.isEmpty ? const Icon(Icons.search_rounded)
                          : IconButton(tooltip: 'Clear search', icon: const Icon(Icons.close_rounded),
                              onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); }),
                    ),
                  ),
                )),
              if (_customerPosition != null)
                Positioned(top: 76, left: 12, child: ActionChip(
                  avatar: const Icon(Icons.radar, size: 18),
                  label: Text(_searchRadiusKm < 50
                      ? '${_searchRadiusKm.toStringAsFixed(0)} km · Expand area'
                      : '50 km search area'),
                  onPressed: _searchRadiusKm < 50 ? _expandSearchArea : null)),
              if (_locationError != null)
                Positioned(top: _customerPosition == null ? 76 : 126, left: 12, right: 68,
                  child: Material(color: Colors.white, borderRadius: BorderRadius.circular(12),
                    child: Padding(padding: const EdgeInsets.all(10),
                      child: Row(children: [
                        Expanded(child: Text(_locationError!, maxLines: 3,
                          overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))),
                        TextButton(onPressed: _enterCustomerLocationManually,
                          child: const Text('Enter manually')),
                      ]),
                    ),
                  ))
              else if (!shortViewport && (_isLocatingCustomer || _category != null))
                Positioned(top: _customerPosition == null ? 76 : 126, left: 12, right: 68,
                  child: Material(color: Colors.white, borderRadius: BorderRadius.circular(12),
                    child: Padding(padding: const EdgeInsets.all(10),
                      child: Text(_isLocatingCustomer ? 'Finding your location…' : 'Category: $_category',
                        maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12))))),
              Positioned(right: 12, bottom: 12,
                child: FloatingActionButton.small(
                  heroTag: 'recenter_button', tooltip: 'My location',
                  backgroundColor: Colors.white, foregroundColor: AppColors.textDark,
                  onPressed: _getCustomerLocation,
                  child: _isLocatingCustomer
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location_rounded),
                )),
            ])),
            SizedBox(height: panelHeight, child: Material(color: Colors.white,
              child: Column(children: [
                SizedBox(height: 44, child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: Row(children: [
                    Expanded(child: Text(snapshot.hasError ? 'Could not load stalls'
                        : snapshot.connectionState == ConnectionState.waiting ? 'Finding stalls…'
                        : query.isEmpty ? '${onScreenVendors.length} open stalls in this area'
                            : '${onScreenVendors.length} matching stalls in this area',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                    TextButton(onPressed: snapshot.hasError
                        ? () => setState(() => _vendors = _vendorService.getAllVendors())
                        : onScreenVendors.isEmpty ? null : () => _showAllStalls(onScreenVendors),
                      child: Text(snapshot.hasError ? 'Retry' : 'View all')),
                  ]),
                )),
                if (!shortViewport) Expanded(child: snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : onScreenVendors.isEmpty
                        ? Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(snapshot.hasError ? 'Check your connection and retry.'
                                : _customerPosition != null && _searchRadiusKm < 50
                                    ? 'No stalls found within ${_searchRadiusKm.toStringAsFixed(0)} km. Try Expand area.'
                                    : 'Move the map, zoom out, or clear your filters.', textAlign: TextAlign.center,
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13))))
                        : ListView.builder(
                            controller: _stallScrollController,
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.fromLTRB(16, 0, 4, 10),
                            itemCount: onScreenVendors.length,
                            itemExtent: _cardExtent,
                            itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _stallCard(onScreenVendors[index]),
                            ),
                          )),
              ]),
            )),
          ]);
        });
      },
    );
  }

  String? _distanceTo(VendorModel vendor) {
    final position = _customerPosition;
    if (position == null) { return null; }
    return _formatDistance(Geolocator.distanceBetween(
      position.latitude, position.longitude, vendor.latitude, vendor.longitude));
  }

  Widget _stallPhoto(VendorModel vendor, {double size = 48}) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Container(width: size, height: size, color: const Color(0xFFFFF0E9),
      child: vendor.imageUrl.isEmpty ? const Icon(Icons.storefront_rounded, color: AppColors.primary)
          : Image.network(vendor.imageUrl, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.storefront_rounded, color: AppColors.primary))),
  );

  Widget _stallCard(VendorModel vendor) {
    final selected = vendor.vendorId == _selectedVendorId;
    return Material(
      color: selected ? const Color(0xFFFFF8F3) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? AppColors.primary : const Color(0xFFE5E7EB), width: selected ? 1.5 : 1)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: () => _selectVendor(vendor),
        child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(12, 10, 8, 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _stallPhoto(vendor), const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(vendor.stallName, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text([vendor.category, vendor.isOpen ? 'Open' : 'Closed',
                  if (_distanceTo(vendor) != null) _distanceTo(vendor)!].join(' · '),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ])),
              if (selected) const Padding(padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18)),
            ]),
            Row(children: [
              Icon(vendor.hasFreshLocation ? Icons.circle : Icons.history_rounded,
                size: 10, color: vendor.hasFreshLocation ? const Color(0xFF15803D) : const Color(0xFF92400E)),
              const SizedBox(width: 5),
              Expanded(child: Text(vendor.hasFreshLocation ? 'Location updated' : 'Last known location',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)))),
              TextButton(onPressed: () => _openVendorDetails(vendor),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact),
                child: const Text('View stall', style: TextStyle(fontSize: 11))),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _showAllStalls(List<VendorModel> vendors) async {
    FocusScope.of(context).unfocus();
    final selected = await showModalBottomSheet<VendorModel>(
      context: context, isScrollControlled: true, useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SizedBox(height: MediaQuery.of(context).size.height * .6,
        child: Column(children: [
          ListTile(title: const Text('Stalls in this area', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Choose a stall to find it on the map'),
            trailing: IconButton(tooltip: 'Close list', icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))),
          const Divider(height: 1),
          Expanded(child: ListView.separated(itemCount: vendors.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 80),
            itemBuilder: (context, index) {
              final vendor = vendors[index];
              return ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: _stallPhoto(vendor), title: Text(vendor.stallName),
                subtitle: Text([vendor.category, vendor.isOpen ? 'Open' : 'Closed',
                  if (_distanceTo(vendor) != null) _distanceTo(vendor)!].join(' · ')),
                trailing: const Icon(Icons.near_me_outlined, color: AppColors.primary),
                onTap: () => Navigator.pop(context, vendor));
            },
          )),
        ]),
      ),
    );
    if (mounted && selected != null) { await _selectVendor(selected); }
  }

  void _openVendorDetails(VendorModel vendor) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VendorDetailsScreen(vendor: vendor)),
    );
  }
}
````
