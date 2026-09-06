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
