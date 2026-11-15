import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/vendor_model.dart';

class VendorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _vendorsRef => _firestore.collection('vendors');

// read store id
  Future<VendorModel?> getVendorProfile(String vendorId) async {
    try {
      return await fetchVendorProfile(vendorId);
    } catch (e) {
      debugPrint('Error fetching vendor profile: $e');
      return null;
    }
  }

  Future<VendorModel?> fetchVendorProfile(String vendorId,
      {GetOptions? options}) async {
    final doc = await _vendorsRef.doc(vendorId).get(options);
    final data = doc.data() as Map<String, dynamic>?;
    return data == null ? null : VendorModel.fromMap(data, doc.id);
  }

// update stall infroamtion
  Future<void> saveVendorProfile(VendorModel vendor) async {
    try {
      final ref = _vendorsRef.doc(vendor.vendorId);
      await _firestore.runTransaction((transaction) async {
        final existing = await transaction.get(ref);
        final data = existing.data() as Map<String, dynamic>?;
        final firstProfile = !existing.exists ||
            (data?['stallName'] as String? ?? '').trim().isEmpty;
        transaction.set(
            ref,
            {
              ...vendor.toProfileMap(),
              'updatedAt': FieldValue.serverTimestamp(),
              if (firstProfile && data?['createdAt'] == null)
                'createdAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true));
      });
    } catch (e) {
      debugPrint('Error saving vendor profile: $e');
      rethrow;
    }
  }

// open/closed
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

// update location
  Future<void> updateVendorLocation(
      String vendorId, double latitude, double longitude,
      {bool sharingActive = true}) async {
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

  Future<void> setSelfCollectEnabled(String vendorId, bool enabled) =>
      _vendorsRef.doc(vendorId).update({'selfCollectEnabled': enabled});

  Stream<List<VendorModel>> getOpenVendors() {
    return _vendorsRef.where('isOpen', isEqualTo: true).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) =>
                VendorModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .where((vendor) => !vendor.isSuspended)
            .toList());
  }

  Stream<List<VendorModel>> getAllVendors() {
    return _vendorsRef.snapshots().map((snapshot) => snapshot.docs
        .map((doc) =>
            VendorModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .where((vendor) => !vendor.isSuspended)
        .toList());
  }
}
