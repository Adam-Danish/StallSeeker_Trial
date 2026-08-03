import 'package:cloud_firestore/cloud_firestore.dart';

class FollowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _followsRef => _firestore.collection('follows');

  // Combining customerId + vendorId into one predictable document ID
  // means a customer can never accidentally follow the same vendor
  // twice -- the second "follow" would just overwrite the same document.
  String _followId(String customerId, String vendorId) =>
      '${customerId}_$vendorId';

  Future<void> followVendor(String customerId, String vendorId) async {
    await _followsRef.doc(_followId(customerId, vendorId)).set({
      'customerId': customerId,
      'vendorId': vendorId,
      'followedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unfollowVendor(String customerId, String vendorId) async {
    await _followsRef.doc(_followId(customerId, vendorId)).delete();
  }

  // Live stream of whether this customer currently follows this vendor.
  // Used to show the correct Follow/Unfollow button state, and keeps it
  // in sync automatically if changed from another device.
  Stream<bool> isFollowing(String customerId, String vendorId) {
    return _followsRef
        .doc(_followId(customerId, vendorId))
        .snapshots()
        .map((doc) => doc.exists);
  }

  // Live stream of vendor IDs this customer follows -- used by the
  // Following tab to build its list.
  Stream<List<String>> getFollowedVendorIds(String customerId) {
    return _followsRef
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc['vendorId'] as String).toList());
  }
}
