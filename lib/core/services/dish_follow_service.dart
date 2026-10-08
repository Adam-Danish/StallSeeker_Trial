import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/dish_follow_model.dart';
import '../models/menu_item_model.dart';

/// Each customer's subscriptions live beneath their own user document.
/// The same stall/dish pair always uses the same ID, so following it twice
/// cannot create duplicate alerts.
class DishFollowService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _subscriptions(String uid) =>
      _db.collection('users').doc(uid).collection('dishFollows');

  String _id(String vendorId, String itemId) {
    for (final value in [vendorId, itemId]) {
      if (value.isEmpty ||
          value.length > 128 ||
          value.contains('/') ||
          value.contains(':')) {
        throw ArgumentError('Invalid stall or dish.');
      }
    }
    return '$vendorId:$itemId';
  }

  void _requireOwner(String uid) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous || user.uid != uid) {
      throw StateError('Sign in to follow dishes.');
    }
    if (!user.emailVerified) {
      throw StateError('Verify your email before following dishes.');
    }
  }

  Future<void> _requireCustomer(String uid) async {
    _requireOwner(uid);
    final profile = await _db
        .collection('users')
        .doc(uid)
        .get()
        .timeout(const Duration(seconds: 10));
    _requireOwner(uid);
    if (profile.data()?['role'] != 'customer') {
      throw StateError('Only customers can follow dishes.');
    }
  }

  Future<void> follow(String uid, String vendorId, String itemId) async {
    final id = _id(vendorId, itemId);
    await _requireCustomer(uid);
    final ref = _subscriptions(uid).doc(id);
    await _db.runTransaction((transaction) async {
      final existing = await transaction.get(ref);
      // Preserve the original follow time when a tap is repeated or a second
      // device follows the same dish while this device has stale state.
      if (!existing.exists) {
        transaction.set(ref, {
          'customerId': uid,
          'vendorId': vendorId,
          'itemId': itemId,
          'followedAt': FieldValue.serverTimestamp()
        });
      }
    }).timeout(const Duration(seconds: 10));
  }

  Future<void> unfollow(String uid, String vendorId, String itemId) async {
    await _requireCustomer(uid);
    await _subscriptions(uid)
        .doc(_id(vendorId, itemId))
        .delete()
        .timeout(const Duration(seconds: 10));
  }

  Stream<List<DishFollowModel>> watch(String uid, {String? vendorId}) {
    _requireOwner(uid);
    Query<Map<String, dynamic>> query = _subscriptions(uid);
    if (vendorId != null) query = query.where('vendorId', isEqualTo: vendorId);
    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => DishFollowModel.fromMap(doc.data(), doc.id))
        .where((item) => item.vendorId.isNotEmpty && item.itemId.isNotEmpty)
        .toList());
  }

  Stream<MenuItemModel?> watchDish(String vendorId, String itemId) => _db
      .collection('vendors')
      .doc(vendorId)
      .collection('menu')
      .doc(itemId)
      .snapshots()
      .map((doc) =>
          doc.exists ? MenuItemModel.fromMap(doc.data()!, doc.id) : null);
}
