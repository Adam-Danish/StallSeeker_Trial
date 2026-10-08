import 'menu_item_model.dart';

class DishSearchEntry {
  const DishSearchEntry({
    required this.vendorId,
    required this.item,
    this.priceIsKnown = true,
  });

  final String vendorId;
  final MenuItemModel item;
  // Older menu records may not contain a price. Their model fallback of zero
  // must not make them appear as free dishes in a price filter.
  final bool priceIsKnown;
}
