import '../../../core/models/dish_search_entry.dart';
import '../../../core/models/vendor_model.dart';

String normalizeDiscoveryQuery(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

class MenuPriceRange {
  const MenuPriceRange({this.minimum, this.maximum});

  final double? minimum;
  final double? maximum;

  bool get isActive => minimum != null || maximum != null;

  bool contains(DishSearchEntry dish) =>
      dish.priceIsKnown &&
      dish.item.price.isFinite &&
      dish.item.price >= 0 &&
      (minimum == null || dish.item.price >= minimum!) &&
      (maximum == null || dish.item.price <= maximum!);

  String get label {
    String amount(double value) => value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
    if (minimum != null && maximum != null) {
      return 'RM ${amount(minimum!)}–${amount(maximum!)}';
    }
    if (minimum != null) return 'RM ${amount(minimum!)}+';
    if (maximum != null) return 'Up to RM ${amount(maximum!)}';
    return 'Any price';
  }
}

/// For a dish query, the matching dish itself must meet the price range.
/// Stall/category queries can match any genuinely priced dish on that menu.
bool vendorMatchesQueryAndPrice({
  required VendorModel vendor,
  required Iterable<DishSearchEntry> dishes,
  required String query,
  MenuPriceRange? priceRange,
}) {
  final normalized = normalizeDiscoveryQuery(query);
  final vendorMatches =
      normalizeDiscoveryQuery(vendor.stallName).contains(normalized) ||
          normalizeDiscoveryQuery(vendor.category).contains(normalized);
  final matchingDishes = normalized.isEmpty
      ? dishes
      : dishes.where((dish) =>
          normalizeDiscoveryQuery(dish.item.name).contains(normalized));
  if (priceRange == null || !priceRange.isActive) {
    return normalized.isEmpty || vendorMatches || matchingDishes.isNotEmpty;
  }
  // Do not let a cheap unrelated menu item make an expensive dish match.
  if (matchingDishes.isNotEmpty) {
    return matchingDishes.any(priceRange.contains);
  }
  return vendorMatches && dishes.any(priceRange.contains);
}

enum DiscoverySuggestionKind { dish, stall, category, recent }

class DiscoverySuggestion {
  const DiscoverySuggestion({
    required this.label,
    required this.kind,
    this.isRecent = false,
  });

  final String label;
  final DiscoverySuggestionKind kind;
  final bool isRecent;

  String get detail => switch (kind) {
        DiscoverySuggestionKind.dish => 'Dish',
        DiscoverySuggestionKind.stall => 'Stall',
        DiscoverySuggestionKind.category => 'Category',
        DiscoverySuggestionKind.recent => 'Recent search',
      };
}

List<DiscoverySuggestion> buildDiscoverySuggestions({
  required String query,
  required Iterable<VendorModel> vendors,
  required Iterable<DishSearchEntry> dishes,
  required Iterable<String> categories,
  required List<String> recentSearches,
  MenuPriceRange? priceRange,
  int limit = 8,
}) {
  final typed = normalizeDiscoveryQuery(query);
  final recentKeys = recentSearches.map(normalizeDiscoveryQuery).toSet();
  final suggestions = <String, DiscoverySuggestion>{};

  void add(String rawLabel, DiscoverySuggestionKind kind) {
    final label = rawLabel.trim().replaceAll(RegExp(r'\s+'), ' ');
    final key = normalizeDiscoveryQuery(label);
    if (key.isEmpty || (typed.isNotEmpty && !key.contains(typed))) return;
    final current = suggestions[key];
    if (current == null || kind.index < current.kind.index) {
      suggestions[key] = DiscoverySuggestion(
        label: label,
        kind: kind,
        isRecent: recentKeys.contains(key),
      );
    }
  }

  for (final recent in recentSearches) {
    add(recent, DiscoverySuggestionKind.recent);
  }
  if (typed.isEmpty) return suggestions.values.take(limit).toList();

  final vendorById = {
    for (final vendor in vendors) vendor.vendorId: vendor,
  };
  final eligibleDishes = dishes.where((dish) =>
      vendorById.containsKey(dish.vendorId) &&
      (priceRange == null ||
          !priceRange.isActive ||
          priceRange.contains(dish)));
  final pricedVendorIds = eligibleDishes.map((dish) => dish.vendorId).toSet();
  final eligibleVendors = vendorById.values.where((vendor) =>
      priceRange == null ||
      !priceRange.isActive ||
      pricedVendorIds.contains(vendor.vendorId));

  for (final dish in eligibleDishes) {
    add(dish.item.name, DiscoverySuggestionKind.dish);
  }
  for (final vendor in eligibleVendors) {
    add(vendor.stallName, DiscoverySuggestionKind.stall);
  }
  final offeredCategories = eligibleVendors
      .map((vendor) => normalizeDiscoveryQuery(vendor.category))
      .toSet();
  for (final category in categories) {
    if (offeredCategories.contains(normalizeDiscoveryQuery(category))) {
      add(category, DiscoverySuggestionKind.category);
    }
  }

  int matchRank(String label) {
    final normalized = normalizeDiscoveryQuery(label);
    if (normalized == typed) return 0;
    if (normalized.startsWith(typed)) return 1;
    if (normalized.split(' ').any((word) => word.startsWith(typed))) return 2;
    return 3;
  }

  final ranked = suggestions.values.toList()
    ..sort((a, b) {
      final matchOrder = matchRank(a.label).compareTo(matchRank(b.label));
      if (matchOrder != 0) return matchOrder;
      final sourceOrder = a.kind.index.compareTo(b.kind.index);
      if (sourceOrder != 0) return sourceOrder;
      if (a.kind == DiscoverySuggestionKind.recent) {
        return recentSearches
            .indexWhere((value) =>
                normalizeDiscoveryQuery(value) ==
                normalizeDiscoveryQuery(a.label))
            .compareTo(recentSearches.indexWhere((value) =>
                normalizeDiscoveryQuery(value) ==
                normalizeDiscoveryQuery(b.label)));
      }
      return normalizeDiscoveryQuery(a.label)
          .compareTo(normalizeDiscoveryQuery(b.label));
    });
  return ranked.take(limit).toList();
}
