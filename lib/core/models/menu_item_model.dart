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
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String description;
  final String portionSize;
  final List<String> ingredients;

  MenuItemModel({
    required this.itemId,
    required this.name,
    required this.price,
    this.status = 'available',
    this.imageUrl = '',
    this.section = 'Main menu',
    this.statusUpdatedAt,
    this.createdAt,
    this.updatedAt,
    this.description = '',
    this.portionSize = '',
    this.ingredients = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'name': name,
      'price': price,
      'status': status,
      'imageUrl': imageUrl,
      'section': section,
      'description': description,
      'portionSize': portionSize,
      'ingredients': ingredients,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      'statusUpdatedAt': statusUpdatedAt == null
          ? FieldValue.serverTimestamp()
          : Timestamp.fromDate(statusUpdatedAt!),
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
          ? map['section'] as String
          : 'Main menu',
      statusUpdatedAt: (map['statusUpdatedAt'] as Timestamp?)?.toDate(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      description: map['description'] as String? ?? '',
      portionSize: map['portionSize'] as String? ?? '',
      ingredients: map['ingredients'] is List
          ? (map['ingredients'] as List).whereType<String>().toList()
          : const [],
    );
  }
}
