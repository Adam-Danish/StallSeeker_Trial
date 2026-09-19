import 'package:cloud_firestore/cloud_firestore.dart';

class StallReview {
  const StallReview({required this.customerId, required this.customerName,
    required this.rating, required this.text, required this.photoUrls,
    this.updatedAt});

  final String customerId;
  final String customerName;
  final int rating;
  final String text;
  final List<String> photoUrls;
  final DateTime? updatedAt;

  factory StallReview.fromMap(Map<String, dynamic> map, String id) => StallReview(
    customerId: id,
    customerName: map['customerName'] is String ? map['customerName'] as String : 'Customer',
    rating: map['rating'] is int ? (map['rating'] as int).clamp(1, 5) : 1,
    text: map['text'] is String ? map['text'] as String : '',
    photoUrls: map['photoUrls'] is List
        ? (map['photoUrls'] as List).whereType<String>().take(5).toList() : const [],
    updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
  );
}
