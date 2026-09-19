import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItemModel {
  final String itemId;
  final String name;
  final double price;
  final String
      status; // 'available' (Green), 'low_stock' (Yellow), 'out_of_stock' (Red)
  final String imageUrl;
  final String section;
  final DateTime? statusUpdatedAt;

  MenuItemModel({
    required this.itemId,
    required this.name,
    required this.price,
    this.status = 'available',
    this.imageUrl = '',
    this.section = 'Main menu',
    this.statusUpdatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'name': name,
      'price': price,
      'status': status,
      'imageUrl': imageUrl,
      'section': section,
      'statusUpdatedAt': statusUpdatedAt == null
          ? FieldValue.serverTimestamp() : Timestamp.fromDate(statusUpdatedAt!),
    };
  }

  factory MenuItemModel.fromMap(Map<String, dynamic> map, String id) {
    return MenuItemModel(
      itemId: id,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'available',
      imageUrl: map['imageUrl'] ?? '',
      section: (map['section'] as String?)?.trim().isNotEmpty == true
          ? map['section'] as String : 'Main menu',
      statusUpdatedAt: (map['statusUpdatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
