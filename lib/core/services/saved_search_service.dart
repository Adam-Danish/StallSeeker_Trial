import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SavedDiscoverySearch {
  const SavedDiscoverySearch(
      {required this.id, required this.name, required this.filters});
  final String id;
  final String name;
  final Map<String, dynamic> filters;
}

/// Saved combinations belong to a signed-in customer; guests have no local fallback.
class SavedSearchService {
  SavedSearchService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  String _customerId() {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous || !user.emailVerified) {
      throw StateError(
          'Sign in with a verified customer account to save searches.');
    }
    return user.uid;
  }

  CollectionReference<Map<String, dynamic>> _collection(String uid) =>
      _db.collection('users').doc(uid).collection('savedSearches');

  Future<List<SavedDiscoverySearch>> load() async {
    final uid = _customerId();
    final snapshot =
        await _collection(uid).orderBy('savedAt', descending: true).get();
    if (_auth.currentUser?.uid != uid) throw StateError('Account changed.');
    return snapshot.docs
        .map((doc) => SavedDiscoverySearch(
            id: doc.id,
            name: doc.data()['name'] as String,
            filters: Map<String, dynamic>.from(doc.data()['filters'] as Map)))
        .toList();
  }

  Future<void> save(String name, Map<String, dynamic> filters) async {
    final uid = _customerId();
    final cleaned = name.trim();
    if (cleaned.isEmpty || cleaned.length > 80) {
      throw ArgumentError('Invalid search name.');
    }
    // Same combination updates its existing record rather than creating duplicates.
    final encoded =
        base64Url.encode(utf8.encode(jsonEncode(filters))).replaceAll('=', '');
    if (encoded.length > 1400) throw ArgumentError('Saved search is too long.');
    await _collection(uid).doc(encoded).set({
      'name': cleaned,
      'filters': filters,
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> remove(String id) => _collection(_customerId()).doc(id).delete();
}
