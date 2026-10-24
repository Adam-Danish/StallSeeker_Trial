import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:stallseeker/core/models/dish_search_entry.dart';
import 'package:stallseeker/core/models/menu_item_model.dart';
import 'package:stallseeker/core/models/vendor_model.dart';
import 'package:stallseeker/features/customer/home/discovery_options.dart';
import 'package:stallseeker/features/customer/home/discovery_search_filters.dart';

VendorModel vendor(String id, {DateTime? created, DateTime? updated}) =>
    VendorModel(
        vendorId: id,
        stallName: id,
        category: 'Burger',
        openingHours: '',
        description: '',
        latitude: id == 'a' ? 3.1 : 3.2,
        longitude: 101.7,
        createdAt: created,
        updatedAt: updated);

DishSearchEntry dish(String owner, String id, double price,
        {bool known = true, String status = 'available', DateTime? updated}) =>
    DishSearchEntry(
        vendorId: owner,
        priceIsKnown: known,
        item: MenuItemModel(
            itemId: id,
            name: id,
            price: price,
            status: status,
            statusUpdatedAt: updated));

void main() {
  test('legacy category records remain readable and multiple categories filter',
      () {
    final legacy = VendorModel.fromMap({'category': 'Burger'}, 'old');
    expect(legacy.allCategories, ['Burger']);
    final multiple = VendorModel.fromMap({
      'category': 'Burger',
      'categories': ['Burger', 'Beverages', 'Burger'],
    }, 'new');
    expect(multiple.allCategories, ['Burger', 'Beverages']);
    expect(multiple.hasCategory('Beverages'), isTrue);
    expect(multiple.toProfileMap()['categories'], ['Burger', 'Beverages']);
    expect(
        vendorMatchesQueryAndPrice(
            vendor: multiple, dishes: [], query: 'beverages'),
        isTrue);
    expect(multiple.copyWith(stallName: 'Renamed').allCategories,
        multiple.allCategories);
  });

  test('dish search handles alternatives, abbreviations and small misspellings',
      () {
    for (final pair in [
      ['burgre', 'Burger ayam'],
      ['burgr', 'Burger'],
      ['mee grg', 'Mi goreng'],
      ['banana fritters', 'Goreng pisang'],
      ['roti prata', 'Roti canai'],
      ['coconut rice', 'Nasi lemak'],
      ['char kway teow', 'Char kuey teow'],
    ]) {
      expect(discoveryMatches(pair[0], pair[1]), isTrue,
          reason: pair.toString());
    }
    expect(discoveryMatches('burger', 'Nasi lemak'), isFalse);
    expect(discoveryMatches('teh', 'mee'), isFalse);
    expect(discoverySearchScore('Burger', 'Burger'), 0);
    expect(discoverySearchScore('burgre', 'Burger'), greaterThan(0));
  });

  test('sorting uses real prices and ratings, with unknowns last', () {
    final vendors = [vendor('a'), vendor('b'), vendor('c')];
    final menus = {
      'a': [dish('a', 'Burger', 8)],
      'b': [dish('b', 'Burger', 5)],
      'c': [dish('c', 'Burger', 0, known: false)],
    };
    final ratings = {
      'a': const StallRatingSummary(4.8, 5),
      'b': const StallRatingSummary(4.1, 12),
      'c': const StallRatingSummary(0, 0)
    };
    List<String> sort(DiscoverySort option) => (vendors.toList()
          ..sort((a, b) => compareDiscoveryVendors(a, b,
              sort: option,
              center: const LatLng(3.1, 101.7),
              ratings: ratings,
              dishes: menus)))
        .map((v) => v.vendorId)
        .toList();
    expect(sort(DiscoverySort.price), ['b', 'a', 'c']);
    expect(sort(DiscoverySort.rating), ['a', 'b', 'c']);
    expect(sort(DiscoverySort.distance).first, 'a');
  });

  test('newest sorting does not invent dates for old profiles', () {
    final now = DateTime.utc(2026, 10, 24);
    final values = [
      vendor('unknown'),
      vendor('old', created: now.subtract(const Duration(days: 2))),
      vendor('new', created: now)
    ];
    values.sort((a, b) => compareDiscoveryVendors(a, b,
        sort: DiscoverySort.newest, center: null, ratings: {}, dishes: {}));
    expect(values.map((v) => v.vendorId), ['new', 'old', 'unknown']);
  });

  test('recent means profile or menu update within 24h, not live GPS', () {
    final now = DateTime.utc(2026, 10, 24, 10);
    final stall = VendorModel.fromMap(
        {'locationUpdatedAt': Timestamp.fromDate(now)}, 'a');
    expect(stallUpdatedRecently(stall, [], now: now), isFalse);
    expect(
        stallUpdatedRecently(
            stall,
            [
              dish('a', 'food', 5,
                  updated: now.subtract(const Duration(hours: 2)))
            ],
            now: now),
        isTrue);
    expect(
        stallUpdatedRecently(
            stall,
            [
              dish('a', 'food', 5,
                  updated: now.subtract(const Duration(hours: 25)))
            ],
            now: now),
        isFalse);
    expect(dishIsAvailable(dish('a', 'food', 5, status: 'low_stock')), isTrue);
    expect(
        dishIsAvailable(dish('a', 'food', 5, status: 'out_of_stock')), isFalse);
  });

  test('menu details round trip without requiring them on old dishes', () {
    final item = MenuItemModel(
        itemId: 'dish',
        name: 'Nasi Lemak',
        price: 6,
        description: 'Coconut rice',
        portionSize: '1 plate',
        ingredients: ['Rice', 'Peanuts']);
    final restored = MenuItemModel.fromMap({
      ...item.toMap(),
      'statusUpdatedAt': Timestamp.fromDate(DateTime.utc(2026, 10, 24)),
    }, 'dish');
    expect(restored.description, 'Coconut rice');
    expect(restored.portionSize, '1 plate');
    expect(restored.ingredients, ['Rice', 'Peanuts']);
    expect(
        MenuItemModel.fromMap({'name': 'Old dish', 'price': 5}, 'old')
            .ingredients,
        isEmpty);
  });
}
