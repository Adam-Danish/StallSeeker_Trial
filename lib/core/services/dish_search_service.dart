import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/dish_search_entry.dart';
import '../models/menu_item_model.dart';

class DishSearchService {
  DishSearchService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Stream<List<DishSearchEntry>> watchAllDishes() {
    return _db.collectionGroup('menu').snapshots().map((snapshot) {
      final dishes = <DishSearchEntry>[];
      for (final document in snapshot.docs) {
        final vendorId = document.reference.parent.parent?.id;
        if (vendorId == null || vendorId.isEmpty) continue;
        dishes.add(DishSearchEntry(
          vendorId: vendorId,
          item: MenuItemModel.fromMap(document.data(), document.id),
        ));
      }
      dishes.sort((a, b) =>
          a.item.name.toLowerCase().compareTo(b.item.name.toLowerCase()));
      return dishes;
    });
  }
}
