import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Shares an open vendor's location, including while the app is backgrounded.
/// Android keeps the stream alive with a visible foreground-service
/// notification; iOS uses the location background mode.
class VendorLocationService extends ChangeNotifier {
  VendorLocationService._();
  static final instance = VendorLocationService._();
  StreamSubscription<Position>? _positionSubscription;
  Future<void> _writes = Future<void>.value();
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
      if (request != _request ||
          FirebaseAuth.instance.currentUser?.uid != vendorId) {
        return;
      }
      _vendorId = vendorId;
      error = null;
      final generation = ++_generation;
      notifyListeners();
      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: _locationSettings(),
      ).listen(
        (position) => _queuePosition(vendorId, generation, position),
        onError: (Object _) {
          if (generation == _generation) {
            error = 'Location could not update. Check GPS and your connection.';
            notifyListeners();
          }
        },
      );
    });
    return _operations;
  }

  Future<void> pause() {
    ++_request;
    ++_generation;
    _operations = _operations.catchError((Object _) {}).then((_) => _pause());
    return _operations;
  }

  LocationSettings _locationSettings() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
        intervalDuration: const Duration(seconds: 15),
        foregroundNotificationConfig: const ForegroundNotificationConfig(
          notificationTitle: 'Stall location sharing is active',
          notificationText:
              'Customers can see your location while your stall is open.',
          notificationChannelName: 'Stall location sharing',
          enableWakeLock: true,
          setOngoing: true,
        ),
      );
    }
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      return AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.otherNavigation,
        distanceFilter: 0,
        pauseLocationUpdatesAutomatically: false,
        showBackgroundLocationIndicator: true,
        allowBackgroundLocationUpdates: true,
      );
    }
    return const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 0,
    );
  }

  void _queuePosition(String vendorId, int generation, Position position) {
    _writes = _writes.catchError((Object _) {}).then(
          (_) => _writePosition(vendorId, generation, position),
        );
  }

  Future<void> _writePosition(
      String vendorId, int generation, Position position) async {
    try {
      if (generation != _generation ||
          FirebaseAuth.instance.currentUser?.uid != vendorId) {
        return;
      }
      final ref =
          FirebaseFirestore.instance.collection('vendors').doc(vendorId);
      // Do not reopen a stall closed by another screen/device.
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final doc = await tx.get(ref);
        if (generation != _generation || doc.data()?['isOpen'] != true) {
          return;
        }
        tx.update(ref, {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'locationUpdatedAt': FieldValue.serverTimestamp(),
          'locationSharingActive': true,
        });
      }).timeout(const Duration(seconds: 8));
      if (generation == _generation) {
        error = null;
      }
    } catch (_) {
      if (generation == _generation) {
        error = 'Location could not update. Check GPS and your connection.';
      }
    }
    if (generation == _generation) {
      notifyListeners();
    }
  }

  Future<void> _pause() async {
    ++_generation;
    final subscription = _positionSubscription;
    _positionSubscription = null;
    await subscription?.cancel();
    final id = _vendorId;
    _vendorId = null;
    // Finish queued writes before writing the paused state.
    await _writes.catchError((Object _) {});
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
