import 'menu_item_model.dart';

class DishSearchEntry {
  const DishSearchEntry({
    required this.vendorId,
    required this.item,
  });

  final String vendorId;
  final MenuItemModel item;
}
