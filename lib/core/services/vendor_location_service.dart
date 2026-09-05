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
