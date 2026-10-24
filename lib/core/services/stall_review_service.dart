import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stall_review.dart';

class StallReviewService {
  StallReviewService({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;
  final FirebaseFirestore _db;
  DocumentReference<Map<String, dynamic>> _review(
    String vendorId,
    String customerId,
  ) => _db
      .collection('stallReviews')
      .doc(vendorId)
      .collection('entries')
      .doc(customerId);

  Stream<List<StallReview>> watchReviews(String vendorId) => _db
      .collection('stallReviews')
      .doc(vendorId)
      .collection('entries')
      .snapshots()
      .map((snapshot) {
        final reviews = snapshot.docs
            .map((doc) => StallReview.fromMap(doc.data(), doc.id))
            .toList();
        reviews.sort(
          (a, b) =>
              (b.postedAt ?? DateTime(0)).compareTo(a.postedAt ?? DateTime(0)),
        );
        return reviews;
      });

  Future<void> saveReview(
    String vendorId,
    String customerId,
    String customerName,
    int rating,
    String text,
    List<String> photoUrls, {
    String customerAvatarUrl = '',
  }) async {
    if (rating < 1 ||
        rating > 5 ||
        photoUrls.length > 5 ||
        text.trim().length > 1000) {
      throw ArgumentError('Invalid review');
    }
    final ref = _review(vendorId, customerId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final old = snapshot.data();
      final name = customerName.trim().isEmpty
          ? 'Customer'
          : customerName.trim();
      // Merge only customer fields. A concurrent owner reply is never replaced.
      transaction.set(ref, {
        'customerId': customerId,
        'customerName': name.length > 80 ? name.substring(0, 80) : name,
        'customerAvatarUrl':
            customerAvatarUrl.startsWith('https://') &&
                customerAvatarUrl.length <= 2048
            ? customerAvatarUrl
            : '',
        'rating': rating,
        'text': text.trim(),
        'photoUrls': photoUrls,
        'createdAt':
            old?['createdAt'] ??
            old?['updatedAt'] ??
            FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'edited': snapshot.exists,
      }, SetOptions(merge: true));
    });
  }

  Future<void> saveVendorReply(
    String vendorId,
    StallReview review,
    String text,
  ) async {
    final reply = text.trim();
    if (reply.isEmpty || reply.length > 1000) {
      throw ArgumentError('Enter a reply between 1 and 1,000 characters.');
    }
    final ref = _review(vendorId, review.customerId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) throw StateError('This review was deleted.');
      final data = snapshot.data()!;
      final old = data['vendorReply'] is Map
          ? data['vendorReply'] as Map
          : null;
      // Record the version visible in the editor. If the customer edited while
      // the editor was open, the updated-after-reply indicator remains visible.
      transaction.update(ref, {
        'vendorReply': {
          'text': reply,
          'createdAt': old?['createdAt'] ?? FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'edited': old != null,
          'reviewUpdatedAt': review.updatedAt == null
              ? data['updatedAt']
              : Timestamp.fromDate(review.updatedAt!),
        },
      });
    });
  }

  Future<void> deleteVendorReply(String vendorId, String customerId) => _review(
    vendorId,
    customerId,
  ).update({'vendorReply': FieldValue.delete()});

  // The single reply belongs to the same document and disappears atomically.
  Future<void> deleteReview(String vendorId, String customerId) =>
      _review(vendorId, customerId).delete();
}
