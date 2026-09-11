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
