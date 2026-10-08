import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/vendor_model.dart';
import 'vendor_service.dart';
import '../../features/customer/vendor_details/vendor_details_screen.dart';
import '../../features/shared/booking_detail_screen.dart';

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
    description: 'Stall, dish, and self-collect booking alerts.',
    importance: Importance.high,
  );

  GlobalKey<NavigatorState>? _navigatorKey;
  bool _initialized = false;
  StreamSubscription<String>? _tokenSubscription;
  String? _syncedUid;
  String? _configuredUid;
  String? _configuredRole;
  String? _pendingVendorId;
  String? _pendingItemId;
  String? _pendingBookingId;
  String? _pendingBookingRecipient;
  bool _pendingBookingVendor = false;
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
    if (ready && _pendingBookingId != null) {
      final id = _pendingBookingId!;
      final recipient = _pendingBookingRecipient;
      final isVendor = _pendingBookingVendor;
      _pendingBookingId = null;
      _pendingBookingRecipient = null;
      unawaited(_openBooking(id, recipientId: recipient, isVendor: isVendor));
    }
    if (ready && _pendingVendorId != null) {
      final id = _pendingVendorId!;
      final itemId = _pendingItemId;
      _pendingVendorId = null;
      _pendingItemId = null;
      unawaited(_openVendorDetails(id, itemId: itemId));
    }
  }

  // One-time setup: creates the notification channel and wires up listeners
  // for taps in every app state. Permission is requested only after the
  // signed-in account is confirmed.
  // (foreground, background, terminated). Safe to call more than once.
  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    if (_initialized) {
      return;
    }

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
        final payload = response.payload;
        if (payload != null) {
          _openPayload(payload);
        }
      },
    );

    _initialized = true;

    // FCM does not show a system notification by itself while the app is
    // in the foreground, so display one manually using the same channel.
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      final vendorId = message.data['vendorId'];
      final bookingId = message.data['bookingId'];
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
          payload: bookingId is String
              ? jsonEncode({
                  'bookingId': bookingId,
                  'recipientId': message.data['recipientId'],
                  'role': message.data['role'],
                })
              : vendorId == null
                  ? null
                  : jsonEncode({
                      'vendorId': vendorId,
                      if (message.data['itemId'] is String)
                        'itemId': message.data['itemId'],
                    }),
        );
      }
    });

    // App was backgrounded and the user tapped the notification.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      final bookingId = message.data['bookingId'];
      if (bookingId is String) {
        unawaited(_openBooking(bookingId,
            recipientId: message.data['recipientId'] as String?,
            isVendor: message.data['role'] == 'vendor'));
        return;
      }
      final vendorId = message.data['vendorId'];
      if (vendorId != null) {
        _openVendorDetails(vendorId,
            itemId: message.data['itemId'] is String
                ? message.data['itemId'] as String
                : null);
      }
    });

    // App was fully closed and got launched by tapping the notification.
    final initialMessage = await _messaging.getInitialMessage();
    final initialBookingId = initialMessage?.data['bookingId'];
    if (initialBookingId is String) {
      unawaited(_openBooking(initialBookingId,
          recipientId: initialMessage?.data['recipientId'] as String?,
          isVendor: initialMessage?.data['role'] == 'vendor'));
      return;
    }
    final vendorId = initialMessage?.data['vendorId'];
    if (vendorId != null) {
      _openVendorDetails(vendorId,
          itemId: initialMessage!.data['itemId'] is String
              ? initialMessage.data['itemId'] as String
              : null);
    }
  }

  Future<void> configureForRole(String role) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      return;
    }
    if (_configuredUid == user.uid && _configuredRole == role) {
      return;
    }
    _configuredUid = user.uid;
    _configuredRole = role;

    if (role != 'customer' && role != 'vendor') {
      _syncedUid = null;
      await _tokenSubscription?.cancel();
      _tokenSubscription = null;
      await _tokenWork
          .timeout(const Duration(seconds: 5))
          .catchError((Object _) {});
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({'fcmToken': FieldValue.delete()}, SetOptions(merge: true));
        await _messaging.deleteToken().timeout(const Duration(seconds: 5));
        await _localNotifications.cancelAll();
      } catch (_) {
        debugPrint('Could not disable notifications.');
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
      debugPrint('Could not configure notifications.');
      _configuredUid = null;
      _configuredRole = null;
    }
  }

  // Fetches this device's FCM token and saves it on the signed-in account,
  // and keeps it updated if it ever rotates.
  Future<void> syncTokenForCurrentUser(
      {bool skipPreferenceCheck = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous || _syncedUid == user.uid) {
      return;
    }
    if (_configuredRole != null &&
        _configuredRole != 'customer' &&
        _configuredRole != 'vendor') {
      return;
    }
    if (!skipPreferenceCheck && !await isEnabledForCurrentUser()) {
      await _removeCurrentDeviceToken(user);
      return;
    }
    _syncedUid = user.uid;
    await _tokenSubscription?.cancel();
    _tokenSubscription = _messaging.onTokenRefresh.listen((token) {
      final uid = _syncedUid;
      if (uid != null) {
        unawaited(_queueTokenSave(uid, token).catchError((Object e) {
          debugPrint('Could not refresh notification registration.');
        }));
      }
    });
    try {
      final token =
          await _messaging.getToken().timeout(const Duration(seconds: 5));
      if (token != null) {
        await _queueTokenSave(user.uid, token);
      }
    } catch (_) {
      _syncedUid = null;
      debugPrint('Notification registration unavailable.');
    }
  }

  Future<bool> isEnabledForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      return false;
    }
    final profile = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    return profile.data()?['notificationsEnabled'] != false;
  }

  Future<String?> setEnabledForCurrentUser(bool enabled) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      return 'Sign in to manage notifications.';
    }
    if (_configuredRole != 'customer' && _configuredRole != 'vendor') {
      return 'Sign in to manage notifications.';
    }
    try {
      if (enabled) {
        final settings = await _messaging.requestPermission();
        if (settings.authorizationStatus == AuthorizationStatus.denied) {
          return 'Notifications are blocked in your phone settings.';
        }
      }
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
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
    await _tokenWork
        .timeout(const Duration(seconds: 5))
        .catchError((Object _) {});
    try {
      final token =
          await _messaging.getToken().timeout(const Duration(seconds: 5));
      if (token != null) {
        final ref =
            FirebaseFirestore.instance.collection('users').doc(user.uid);
        await FirebaseFirestore.instance.runTransaction((tx) async {
          final doc = await tx.get(ref);
          if (doc.data()?['fcmToken'] == token) {
            tx.update(ref, {'fcmToken': FieldValue.delete()});
          }
        }).timeout(const Duration(seconds: 5));
      }
    } finally {
      await _messaging
          .deleteToken()
          .timeout(const Duration(seconds: 5))
          .catchError((Object _) {});
    }
  }

  Future<void> clearCurrentDevice() async {
    _navigationReady = false;
    _pendingVendorId = null;
    _pendingItemId = null;
    _pendingBookingId = null;
    _pendingBookingRecipient = null;
    _configuredUid = null;
    _configuredRole = null;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      return;
    }
    try {
      await _removeCurrentDeviceToken(user);
    } catch (_) {
      debugPrint('Could not remove notification registration.');
    } finally {
      await _localNotifications.cancelAll();
    }
  }

  Future<void> _saveToken(String uid, String token) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {'fcmToken': token},
        SetOptions(merge: true)).timeout(const Duration(seconds: 5));
  }

  void _openPayload(String payload) {
    try {
      final data = jsonDecode(payload);
      if (data is Map && data['bookingId'] is String) {
        unawaited(_openBooking(data['bookingId'] as String,
            recipientId: data['recipientId'] as String?,
            isVendor: data['role'] == 'vendor'));
        return;
      }
      if (data is Map && data['vendorId'] is String) {
        unawaited(_openVendorDetails(data['vendorId'] as String,
            itemId:
                data['itemId'] is String ? data['itemId'] as String : null));
        return;
      }
    } on FormatException {
      // Existing notifications used the plain vendor ID as their payload.
    }
    unawaited(_openVendorDetails(payload));
  }

  Future<void> _openVendorDetails(String vendorId, {String? itemId}) async {
    final navState = _navigatorKey?.currentState;
    if (!_navigationReady || navState == null) {
      _pendingVendorId = vendorId;
      _pendingItemId = itemId;
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final VendorModel? vendor = await _vendorService.getVendorProfile(vendorId);
    if (vendor == null ||
        !_navigationReady ||
        FirebaseAuth.instance.currentUser?.uid != uid) {
      return;
    }

    navState.push(
      MaterialPageRoute(
          builder: (_) =>
              VendorDetailsScreen(vendor: vendor, initialDishId: itemId)),
    );
  }

  Future<void> _openBooking(String bookingId,
      {String? recipientId, required bool isVendor}) async {
    final navState = _navigatorKey?.currentState;
    if (!_navigationReady || navState == null) {
      _pendingBookingId = bookingId;
      _pendingBookingRecipient = recipientId;
      _pendingBookingVendor = isVendor;
      return;
    }
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || (recipientId != null && uid != recipientId)) return;
    navState.push(MaterialPageRoute(
        builder: (_) =>
            BookingDetailScreen(bookingId: bookingId, isVendor: isVendor)));
  }
}
