import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item_model.dart';

class MenuService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

// customer tengok menu vendor
  Stream<List<MenuItemModel>> getMenuItems(String vendorId) {
    return _db
        .collection('vendors')
        .doc(vendorId)
        .collection('menu')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MenuItemModel.fromMap(doc.data(), doc.id))
            .toList());
  }

// create id baru bila add menu baru
  String newMenuItemId(String vendorId) {
    return _db.collection('vendors').doc(vendorId).collection('menu').doc().id;
  }

// validate dan save menu
  Future<void> addMenuItem(
    String vendorId,
    String name,
    double price, {
    String? itemId,
    String? imageUrl,
    String section = 'Main menu',
  }) async {
    if (name.trim().isEmpty || !price.isFinite || price <= 0) { throw ArgumentError('Invalid dish'); }
    final docRef = itemId != null
        ? _db.collection('vendors').doc(vendorId).collection('menu').doc(itemId)
        : _db.collection('vendors').doc(vendorId).collection('menu').doc();

    final newItem = MenuItemModel(
      itemId: docRef.id,
      name: name,
      price: price,
      status: 'available',
      imageUrl: imageUrl ?? '',
      section: section,
    );

    await docRef.set(newItem.toMap()).timeout(const Duration(seconds: 15));
  }

// update menu item (name, price, image)
  Future<void> updateMenuItem(
    String vendorId,
    String itemId,
    String name,
    double price, {
    String? imageUrl,
    String section = 'Main menu',
  }) async {
    if (name.trim().isEmpty || !price.isFinite || price <= 0) { throw ArgumentError('Invalid dish'); }
    final data = <String, dynamic>{
      'name': name,
      'price': price,
      'section': section,
    };
    if (imageUrl != null) {
      data['imageUrl'] = imageUrl;
    }

    await _db
        .collection('vendors')
        .doc(vendorId)
        .collection('menu')
        .doc(itemId)
        .update(data).timeout(const Duration(seconds: 15));
  }
// change menu aiavlaibility
  Future<void> updateItemStatus(
      String vendorId, String itemId, String newStatus) async {
    if (!{'available', 'low_stock', 'out_of_stock'}.contains(newStatus)) { throw ArgumentError('Invalid status'); }
    await _db
        .collection('vendors')
        .doc(vendorId)
        .collection('menu')
        .doc(itemId)
        .update({'status': newStatus, 'statusUpdatedAt': FieldValue.serverTimestamp()}).timeout(const Duration(seconds: 15));
  }

  // Delete item
  Future<void> deleteMenuItem(String vendorId, String itemId) async {
    await _db
        .collection('vendors')
        .doc(vendorId)
        .collection('menu')
        .doc(itemId)
        .delete().timeout(const Duration(seconds: 15));
  }
}
