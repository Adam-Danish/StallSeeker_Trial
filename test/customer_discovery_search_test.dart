import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/models/dish_search_entry.dart';
import 'package:stallseeker/core/models/menu_item_model.dart';
import 'package:stallseeker/core/models/vendor_model.dart';
import 'package:stallseeker/features/customer/home/discovery_search_filters.dart';
import 'package:stallseeker/features/customer/home/price_range_picker.dart';

VendorModel vendor(String id, String name, {String category = 'Malay Food'}) =>
    VendorModel(
      vendorId: id,
      stallName: name,
      description: '',
      category: category,
      openingHours: '',
      latitude: 3.1,
      longitude: 101.7,
    );

DishSearchEntry dish(String vendorId, String name, double price,
        {bool priceIsKnown = true}) =>
    DishSearchEntry(
      vendorId: vendorId,
      item: MenuItemModel(itemId: name, name: name, price: price),
      priceIsKnown: priceIsKnown,
    );

void main() {
  group('price filtering', () {
    test('includes both boundaries and supports either open end', () {
      const range = MenuPriceRange(minimum: 5, maximum: 10);
      expect(range.contains(dish('a', 'Lower', 5)), isTrue);
      expect(range.contains(dish('a', 'Upper', 10)), isTrue);
      expect(range.contains(dish('a', 'Low', 4.99)), isFalse);
      expect(range.contains(dish('a', 'High', 10.01)), isFalse);
      expect(const MenuPriceRange(minimum: 5).contains(dish('a', 'High', 100)),
          isTrue);
      expect(const MenuPriceRange(maximum: 10).contains(dish('a', 'Low', 0)),
          isTrue);
    });

    test('missing or invalid prices cannot masquerade as free menu items', () {
      const range = MenuPriceRange(minimum: 0, maximum: 0);
      expect(range.contains(dish('a', 'Actual free item', 0)), isTrue);
      expect(
          range.contains(dish('a', 'No saved price', 0, priceIsKnown: false)),
          isFalse);
      expect(range.contains(dish('a', 'Negative', -1)), isFalse);
      expect(range.contains(dish('a', 'Invalid', double.nan)), isFalse);
      expect(range.contains(dish('a', 'Infinite', double.infinity)), isFalse);
    });

    test('a cheap unrelated dish cannot qualify an expensive dish search', () {
      final seller = vendor('a', 'Warung A');
      final menu = [dish('a', 'Nasi lemak', 12), dish('a', 'Teh ais', 3)];
      const range = MenuPriceRange(maximum: 5);
      expect(
          vendorMatchesQueryAndPrice(
              vendor: seller, dishes: menu, query: 'nasi', priceRange: range),
          isFalse);
      expect(
          vendorMatchesQueryAndPrice(
              vendor: seller, dishes: menu, query: 'warung', priceRange: range),
          isTrue);
      expect(
          vendorMatchesQueryAndPrice(
              vendor: seller, dishes: menu, query: 'malay', priceRange: range),
          isTrue);
      expect(
          vendorMatchesQueryAndPrice(
              vendor: seller, dishes: menu, query: 'nasi'),
          isTrue);
      expect(
          vendorMatchesQueryAndPrice(
              vendor: seller, dishes: const [], query: '', priceRange: range),
          isFalse);
    });
  });

  group('live search suggestions', () {
    test('prefix matches outrank contains/history and labels are distinct', () {
      final suggestions = buildDiscoverySuggestions(
        query: '  NASI  ',
        vendors: [vendor('a', 'Nasi Corner')],
        dishes: [
          dish('a', 'Nasi lemak', 5),
          dish('a', '  NASI   lemak  ', 7),
          dish('a', 'Special nasi goreng', 6),
        ],
        categories: const ['Malay Food'],
        recentSearches: const ['My nasi spot', 'nasi lemak'],
      );
      expect(suggestions.map((item) => item.label), [
        'Nasi lemak',
        'Nasi Corner',
        'Special nasi goreng',
        'My nasi spot',
      ]);
      expect(suggestions.first.kind, DiscoverySuggestionKind.dish);
      expect(suggestions.first.isRecent, isTrue);
    });

    test('keeps dish, stall, category and history suggestions within budget',
        () {
      final suggestions = buildDiscoverySuggestions(
        query: 'burger',
        vendors: [vendor('a', 'Burger Corner', category: 'Burger')],
        dishes: [
          dish('a', 'Burger ayam', 5),
          dish('a', 'Burger premium', 20),
          dish('orphan', 'Burger elsewhere', 4),
        ],
        categories: const ['Burger', 'Malay Food'],
        recentSearches: const ['Burger favourite'],
        priceRange: const MenuPriceRange(maximum: 10),
      );
      expect(suggestions.map((item) => item.label), [
        'Burger',
        'Burger ayam',
        'Burger Corner',
        'Burger favourite',
      ]);
      // Exact category matches appear first even before dish prefix matches.
    });

    test('empty input keeps history order and filters duplicates', () {
      final suggestions = buildDiscoverySuggestions(
        query: '',
        vendors: const [],
        dishes: const [],
        categories: const [],
        recentSearches: const ['Nasi lemak', 'burger', ' NASI  LEMAK '],
      );
      expect(suggestions.map((item) => item.label), ['Nasi lemak', 'burger']);
    });
  });

  testWidgets(
      'price picker validates reversed bounds and applies exact amounts',
      (tester) async {
    MenuPriceRange? selected;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () async {
              selected = await showPriceRangePicker(context);
            },
            child: const Text('Choose price'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Choose price'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, '10');
    await tester.enterText(find.byType(TextFormField).last, '5');
    await tester.tap(find.text('Apply price range'));
    await tester.pumpAndSettle();
    expect(find.text('Must be at least the minimum'), findsOneWidget);
    expect(selected, isNull);
    await tester.enterText(find.byType(TextFormField).last, '12.50');
    await tester.tap(find.text('Apply price range'));
    await tester.pumpAndSettle();
    expect(selected?.minimum, 10);
    expect(selected?.maximum, 12.5);

    await tester.tap(find.text('Choose price'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(selected?.isActive, isFalse);
  });
}
