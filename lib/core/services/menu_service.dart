import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item_model.dart';

class MenuService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream menu items for a specific vendor
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

  // Generates a new, unused document ID for a menu item before it exists.
  // Needed when a photo has to be uploaded (and named after the item's ID)
  // before the item document itself is written.
  String newMenuItemId(String vendorId) {
    return _db.collection('vendors').doc(vendorId).collection('menu').doc().id;
  }

  // Add new menu item. Pass itemId (from newMenuItemId) when a photo was
  // uploaded ahead of time so the item is saved under that same ID.
  Future<void> addMenuItem(
    String vendorId,
    String name,
    double price, {
    String? itemId,
    String? imageUrl,
  }) async {
    final docRef = itemId != null
        ? _db.collection('vendors').doc(vendorId).collection('menu').doc(itemId)
        : _db.collection('vendors').doc(vendorId).collection('menu').doc();

    final newItem = MenuItemModel(
      itemId: docRef.id,
      name: name,
      price: price,
      status: 'available',
      imageUrl: imageUrl ?? '',
    );

    await docRef.set(newItem.toMap());
  }

  // Edit an existing item's name, price, and (optionally) photo, without
  // touching its current status. Pass imageUrl only if a new photo was
  // uploaded -- omit it to keep whatever photo the item already has.
  Future<void> updateMenuItem(
    String vendorId,
    String itemId,
    String name,
    double price, {
    String? imageUrl,
  }) async {
    final data = <String, dynamic>{
      'name': name,
      'price': price,
    };
    if (imageUrl != null) {
      data['imageUrl'] = imageUrl;
    }

    await _db
        .collection('vendors')
        .doc(vendorId)
        .collection('menu')
        .doc(itemId)
        .update(data);
  }

  // Quick Traffic Light Status Update
  Future<void> updateItemStatus(
      String vendorId, String itemId, String newStatus) async {
    await _db
        .collection('vendors')
        .doc(vendorId)
        .collection('menu')
        .doc(itemId)
        .update({'status': newStatus});
  }

  // Delete item
  Future<void> deleteMenuItem(String vendorId, String itemId) async {
    await _db
        .collection('vendors')
        .doc(vendorId)
        .collection('menu')
        .doc(itemId)
        .delete();
  }
}
