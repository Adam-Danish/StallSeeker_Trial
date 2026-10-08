import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_location.dart';

class SavedLocationService {
  SavedLocationService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  static const _guestKey = 'guest_saved_locations_v1';
  bool get _isGuest =>
      _auth.currentUser == null || _auth.currentUser!.isAnonymous;

  CollectionReference<Map<String, dynamic>> get _locations => _db
      .collection('users')
      .doc(_auth.currentUser!.uid)
      .collection('savedLocations');

  Future<List<SavedLocation>> load() async {
    final List<SavedLocation> locations;
    if (_isGuest) {
      final prefs = await SharedPreferences.getInstance();
      final byId = <String, SavedLocation>{};
      for (final value in prefs.getStringList(_guestKey) ?? <String>[]) {
        try {
          final map = jsonDecode(value) as Map<String, dynamic>;
          final location = SavedLocation.fromMap(map['id'] as String, map);
          if (location != null) byId[location.id] = location;
        } catch (_) {
          // Ignore an invalid legacy pin without hiding other saved places.
        }
      }
      locations = byId.values.toList();
    } else {
      final snapshot =
          await _locations.get().timeout(const Duration(seconds: 12));
      locations = snapshot.docs
          .map((doc) => SavedLocation.fromMap(doc.id, doc.data()))
          .whereType<SavedLocation>()
          .toList();
    }
    locations.sort((a, b) => a.isHome != b.isHome
        ? (a.isHome ? -1 : 1)
        : a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return locations;
  }

  Future<void> save(
      {required String name,
      required String address,
      required LatLng coordinates,
      required bool isHome,
      String? id}) async {
    final locationId = isHome ? 'home' : id ?? _db.collection('_ids').doc().id;
    final location = SavedLocation.fromMap(locationId, {
      'name': isHome ? 'Home' : name.trim(),
      'address': address.trim(),
      'latitude': coordinates.latitude,
      'longitude': coordinates.longitude,
      'isHome': isHome,
    });
    if (location == null) {
      throw ArgumentError('Enter a valid name and map pin.');
    }
    if (_isGuest) {
      final saved = await load();
      saved.removeWhere((pin) => pin.id == location.id);
      saved.add(location);
      await _writeGuest(saved);
    } else {
      await _locations.doc(location.id).set({
        ...location.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 12));
    }
  }

  Future<void> delete(String id) async {
    if (_isGuest) {
      final saved = await load();
      saved.removeWhere((pin) => pin.id == id);
      await _writeGuest(saved);
    } else {
      await _locations.doc(id).delete().timeout(const Duration(seconds: 12));
    }
  }

  Future<void> _writeGuest(List<SavedLocation> locations) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setStringList(
        _guestKey,
        locations
            .map((location) =>
                jsonEncode({'id': location.id, ...location.toMap()}))
            .toList());
    if (!saved) throw StateError('Could not save the pin on this device.');
  }
}
