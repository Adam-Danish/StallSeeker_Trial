import 'package:cloud_firestore/cloud_firestore.dart';

class DishFollowModel {
  const DishFollowModel(
      {required this.id,
      required this.vendorId,
      required this.itemId,
      this.followedAt});

  final String id;
  final String vendorId;
  final String itemId;
  final DateTime? followedAt;

  factory DishFollowModel.fromMap(Map<String, dynamic> data, String id) {
    final time = data['followedAt'];
    return DishFollowModel(
      id: id,
      vendorId: data['vendorId'] is String ? data['vendorId'] as String : '',
      itemId: data['itemId'] is String ? data['itemId'] as String : '',
      followedAt: time is Timestamp ? time.toDate() : null,
    );
  }
}
