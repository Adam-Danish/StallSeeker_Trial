import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  const NotificationModel({required this.id, required this.vendorId,
    required this.title, required this.body, required this.createdAt,
    required this.isRead});

  final String id;
  final String vendorId;
  final String title;
  final String body;
  final DateTime? createdAt;
  final bool isRead;

  factory NotificationModel.fromMap(Map<String, dynamic> data, String id) {
    final time = data['createdAt'];
    return NotificationModel(
      id: id,
      vendorId: data['vendorId'] is String ? data['vendorId'] as String : '',
      title: data['title'] is String ? data['title'] as String : 'Stall update',
      body: data['body'] is String ? data['body'] as String : '',
      createdAt: time is Timestamp ? time.toDate() : null,
      isRead: data['isRead'] == true,
    );
  }
}
