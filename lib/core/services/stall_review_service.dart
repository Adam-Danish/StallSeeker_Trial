import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/stall_review.dart';

class StallReviewService {
  final _db = FirebaseFirestore.instance;

  Stream<List<StallReview>> watchReviews(String vendorId) => _db
      .collection('stallReviews').doc(vendorId).collection('entries')
      .snapshots().map((snapshot) {
        final reviews = snapshot.docs
            .map((doc) => StallReview.fromMap(doc.data(), doc.id)).toList();
        reviews.sort((a, b) => (b.updatedAt ?? DateTime(0))
            .compareTo(a.updatedAt ?? DateTime(0)));
        return reviews;
      });

  Future<void> saveReview(String vendorId, String customerId,
      String customerName, int rating, String text, List<String> photoUrls) async {
    if (rating < 1 || rating > 5 || photoUrls.length > 5 || text.length > 1000) {
      throw ArgumentError('Invalid review');
    }
    await _db.collection('stallReviews').doc(vendorId).collection('entries')
        .doc(customerId).set({
      'customerId': customerId,
      'customerName': customerName.trim().isEmpty ? 'Customer' : customerName.trim(),
      'rating': rating,
      'text': text.trim(),
      'photoUrls': photoUrls,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
