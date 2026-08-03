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

  // Add new menu item
  Future<void> addMenuItem(String vendorId, String name, double price) async {
    final docRef =
        _db.collection('vendors').doc(vendorId).collection('menu').doc();

    final newItem = MenuItemModel(
      itemId: docRef.id,
      name: name,
      price: price,
      status: 'available',
    );

    await docRef.set(newItem.toMap());
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
