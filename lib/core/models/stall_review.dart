import 'package:cloud_firestore/cloud_firestore.dart';

DateTime? _date(Object? value) => value is Timestamp ? value.toDate() : null;

class VendorReviewReply {
  const VendorReviewReply({
    required this.text,
    this.createdAt,
    this.updatedAt,
    this.reviewUpdatedAt,
    this.edited = false,
  });
  final String text;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? reviewUpdatedAt;
  final bool edited;
  factory VendorReviewReply.fromMap(Map<String, dynamic> map) =>
      VendorReviewReply(
        text: map['text'] is String ? map['text'] as String : '',
        createdAt: _date(map['createdAt']),
        updatedAt: _date(map['updatedAt']),
        reviewUpdatedAt: _date(map['reviewUpdatedAt']),
        edited: map['edited'] == true,
      );
}

class StallReview {
  const StallReview({
    required this.customerId,
    required this.customerName,
    required this.rating,
    required this.text,
    required this.photoUrls,
    this.customerAvatarUrl = '',
    this.createdAt,
    this.updatedAt,
    this.edited = false,
    this.vendorReply,
  });
  final String customerId;
  final String customerName;
  final String customerAvatarUrl;
  final int rating;
  final String text;
  final List<String> photoUrls;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool edited;
  final VendorReviewReply? vendorReply;
  bool get hasReply => vendorReply?.text.trim().isNotEmpty == true;
  DateTime? get postedAt => createdAt ?? updatedAt;
  bool get updatedAfterReply {
    final answeredVersion =
        vendorReply?.reviewUpdatedAt ?? vendorReply?.updatedAt;
    return hasReply &&
        updatedAt != null &&
        answeredVersion != null &&
        updatedAt!.isAfter(answeredVersion);
  }

  factory StallReview.fromMap(Map<String, dynamic> map, String id) =>
      StallReview(
        customerId: id,
        customerName: map['customerName'] is String &&
                (map['customerName'] as String).trim().isNotEmpty
            ? map['customerName'] as String
            : 'Customer',
        customerAvatarUrl: map['customerAvatarUrl'] is String
            ? map['customerAvatarUrl'] as String
            : '',
        rating: map['rating'] is int ? (map['rating'] as int).clamp(1, 5) : 1,
        text: map['text'] is String ? map['text'] as String : '',
        photoUrls: map['photoUrls'] is List
            ? (map['photoUrls'] as List).whereType<String>().take(5).toList()
            : const [],
        createdAt: _date(map['createdAt']),
        updatedAt: _date(map['updatedAt']),
        edited: map['edited'] == true,
        vendorReply: map['vendorReply'] is Map
            ? VendorReviewReply.fromMap(
                Map<String, dynamic>.from(map['vendorReply'] as Map),
              )
            : null,
      );
}

class StallReviewSummary {
  StallReviewSummary(List<StallReview> reviews)
      : total = reviews.length,
        unanswered = reviews.where((review) => !review.hasReply).length,
        updated = reviews.where((review) => review.updatedAfterReply).length,
        average = reviews.isEmpty
            ? null
            : reviews.fold<int>(0, (total, review) => total + review.rating) /
                reviews.length;
  final int total;
  final int unanswered;
  final int updated;
  final double? average;
}
