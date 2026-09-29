import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  SearchHistoryService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  static const _guestKey = 'guest_search_history_v1';
  static const _limit = 10;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  bool get _usesLocalHistory {
    final user = _auth.currentUser;
    return user == null || user.isAnonymous;
  }

  Future<List<String>> loadRecent() async {
    if (_usesLocalHistory) {
      final preferences = await SharedPreferences.getInstance();
      return (preferences.getStringList(_guestKey) ?? const <String>[])
          .take(_limit)
          .toList();
    }

    final uid = _auth.currentUser!.uid;
    final snapshot = await _history(uid)
        .orderBy('searchedAt', descending: true)
        .limit(_limit)
        .get();
    return snapshot.docs
        .map((document) => document.data()['query'])
        .whereType<String>()
        .where((query) => query.trim().isNotEmpty)
        .toList();
  }

  Future<void> save(String rawQuery) async {
    final query = _clean(rawQuery);
    if (query.isEmpty) return;

    if (_usesLocalHistory) {
      final preferences = await SharedPreferences.getInstance();
      final recent = preferences.getStringList(_guestKey) ?? <String>[];
      final normalized = query.toLowerCase();
      recent.removeWhere((item) => item.toLowerCase() == normalized);
      recent.insert(0, query);
      await preferences.setStringList(_guestKey, recent.take(_limit).toList());
      return;
    }

    final uid = _auth.currentUser!.uid;
    await _history(uid).doc(_documentId(query)).set({
      'query': query,
      'normalizedQuery': query.toLowerCase(),
      'searchedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> remove(String rawQuery) async {
    final query = _clean(rawQuery);
    if (query.isEmpty) return;
    if (_usesLocalHistory) {
      final preferences = await SharedPreferences.getInstance();
      final recent = preferences.getStringList(_guestKey) ?? <String>[];
      recent.removeWhere((item) => item.toLowerCase() == query.toLowerCase());
      await preferences.setStringList(_guestKey, recent);
      return;
    }
    await _history(_auth.currentUser!.uid).doc(_documentId(query)).delete();
  }

  Future<void> clear() async {
    if (_usesLocalHistory) {
      final preferences = await SharedPreferences.getInstance();
      await preferences.remove(_guestKey);
      return;
    }
    final snapshot = await _history(_auth.currentUser!.uid).get();
    final batch = _db.batch();
    for (final document in snapshot.docs) {
      batch.delete(document.reference);
    }
    await batch.commit();
  }

  CollectionReference<Map<String, dynamic>> _history(String uid) =>
      _db.collection('users').doc(uid).collection('searchHistory');

  String _clean(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    return cleaned.length <= 100 ? cleaned : cleaned.substring(0, 100);
  }

  String _documentId(String query) =>
      base64Url.encode(utf8.encode(query.toLowerCase())).replaceAll('=', '');
}
