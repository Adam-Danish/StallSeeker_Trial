import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/models/dish_search_entry.dart';
import '../../../core/models/vendor_model.dart';

enum DiscoverySort {
  distance('Distance: nearest first'),
  price('Price: low to high'),
  rating('Rating: highest first'),
  newest('Newest first'),
  updated('Recently updated');

  const DiscoverySort(this.label);
  final String label;
}

class StallRatingSummary {
  const StallRatingSummary(this.average, this.count);
  final double average;
  final int count;
}

/// Canonical phrases cover common Malaysian names and abbreviations.
String normalizeDishSearch(String value) {
  var text = value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
  text = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  const phrases = {
    'banana fritters': 'pisang goreng',
    'goreng pisang': 'pisang goreng',
    'coconut rice': 'nasi lemak',
    'nasi lmk': 'nasi lemak',
    'pulled tea': 'teh tarik',
    'roti prata': 'roti canai',
    'char kway teow': 'char kuey teow',
    'char koay teow': 'char kuey teow',
    'kueh teow': 'kuey teow',
  };
  for (final entry in phrases.entries) {
    text = text.replaceAll(RegExp('\\b${entry.key}\\b'), entry.value);
  }
  const words = {
    'mi': 'mee',
    'noodle': 'mee',
    'noodles': 'mee',
    'grg': 'goreng',
    'burgers': 'burger',
    'hamburger': 'burger',
    'chkn': 'ayam',
    'chicken': 'ayam',
  };
  return text.split(' ').map((word) => words[word] ?? word).join(' ');
}

int _editDistance(String a, String b) {
  if (a.length == b.length) {
    final differences = <int>[];
    for (var index = 0; index < a.length; index++) {
      if (a[index] != b[index]) differences.add(index);
    }
    if (differences.length == 2 &&
        differences.last == differences.first + 1 &&
        a[differences.first] == b[differences.last] &&
        a[differences.last] == b[differences.first]) {
      return 1;
    }
  }
  var previous = List.generate(b.length + 1, (index) => index);
  for (var row = 1; row <= a.length; row++) {
    final current = <int>[row];
    for (var column = 1; column <= b.length; column++) {
      current.add(math.min(math.min(current.last + 1, previous[column] + 1),
          previous[column - 1] + (a[row - 1] == b[column - 1] ? 0 : 1)));
    }
    previous = current;
  }
  return previous.last;
}

/// Null means no match. Smaller scores represent closer matches.
int? discoverySearchScore(String query, String value) {
  final needle = normalizeDishSearch(query);
  final text = normalizeDishSearch(value);
  if (needle.isEmpty || text.contains(needle)) return 0;
  final words = text.split(' ');
  var score = 0;
  for (final token in needle.split(' ')) {
    if (words.any((word) => word.startsWith(token))) continue;
    final tolerance = token.length >= 7
        ? 2
        : token.length >= 4
            ? 1
            : 0;
    if (tolerance == 0) return null;
    final matches = words.where((word) =>
        (word.length - token.length).abs() <= tolerance &&
        _editDistance(token, word) <= tolerance);
    if (matches.isEmpty) return null;
    score++;
  }
  return score;
}

bool discoveryMatches(String query, String value) =>
    discoverySearchScore(query, value) != null;

bool dishIsAvailable(DishSearchEntry dish) =>
    {'available', 'low_stock'}.contains(dish.item.status);

DateTime? latestStallUpdate(
    VendorModel vendor, Iterable<DishSearchEntry> dishes) {
  DateTime? latest = vendor.updatedAt;
  for (final dish in dishes) {
    for (final date in [dish.item.updatedAt, dish.item.statusUpdatedAt]) {
      if (date != null && (latest == null || date.isAfter(latest))) {
        latest = date;
      }
    }
  }
  // GPS refreshes do not count as menu/profile updates.
  return latest;
}

bool stallUpdatedRecently(VendorModel vendor, Iterable<DishSearchEntry> dishes,
    {DateTime? now}) {
  final updated = latestStallUpdate(vendor, dishes);
  if (updated == null) return false;
  final age = (now ?? DateTime.now()).difference(updated);
  return !age.isNegative && age <= const Duration(hours: 24);
}

int _ascending(num? a, num? b) {
  if (a == null) return b == null ? 0 : 1;
  if (b == null) return -1;
  return a.compareTo(b);
}

int _newest(DateTime? a, DateTime? b) => _ascending(
    a == null ? null : -a.millisecondsSinceEpoch,
    b == null ? null : -b.millisecondsSinceEpoch);

double? lowestDishPrice(Iterable<DishSearchEntry> dishes, String query) {
  final all = dishes.toList();
  final matches = query.trim().isEmpty
      ? all
      : all.where((dish) => discoveryMatches(query, dish.item.name)).toList();
  final priced = (matches.isEmpty ? all : matches).where((dish) =>
      dish.priceIsKnown && dish.item.price.isFinite && dish.item.price >= 0);
  if (priced.isEmpty) return null;
  return priced.map((dish) => dish.item.price).reduce(math.min);
}

int compareDiscoveryVendors(
  VendorModel a,
  VendorModel b, {
  required DiscoverySort sort,
  required LatLng? center,
  required Map<String, StallRatingSummary> ratings,
  required Map<String, List<DishSearchEntry>> dishes,
  String query = '',
}) {
  double? distance(VendorModel vendor) => center == null
      ? null
      : Geolocator.distanceBetween(
          center.latitude, center.longitude, vendor.latitude, vendor.longitude);
  double? rating(VendorModel vendor) {
    final summary = ratings[vendor.vendorId];
    return summary == null || summary.count == 0 ? null : -summary.average;
  }

  final left = dishes[a.vendorId] ?? const <DishSearchEntry>[];
  final right = dishes[b.vendorId] ?? const <DishSearchEntry>[];
  final order = switch (sort) {
    DiscoverySort.distance => _ascending(distance(a), distance(b)),
    DiscoverySort.price =>
      _ascending(lowestDishPrice(left, query), lowestDishPrice(right, query)),
    DiscoverySort.rating => _ascending(rating(a), rating(b)),
    DiscoverySort.newest => _newest(a.createdAt, b.createdAt),
    DiscoverySort.updated =>
      _newest(latestStallUpdate(a, left), latestStallUpdate(b, right)),
  };
  if (order != 0) return order;
  final name = a.stallName.toLowerCase().compareTo(b.stallName.toLowerCase());
  return name != 0 ? name : a.vendorId.compareTo(b.vendorId);
}

int compareDiscoveryDishes(
  DishSearchEntry a,
  DishSearchEntry b, {
  required DiscoverySort sort,
  required Map<String, VendorModel> vendors,
  required LatLng? center,
  required Map<String, StallRatingSummary> ratings,
  required Map<String, List<DishSearchEntry>> dishes,
  String query = '',
}) {
  final order = switch (sort) {
    DiscoverySort.price => _ascending(a.priceIsKnown ? a.item.price : null,
        b.priceIsKnown ? b.item.price : null),
    DiscoverySort.newest => _newest(a.item.createdAt, b.item.createdAt),
    DiscoverySort.updated => _newest(a.item.updatedAt ?? a.item.statusUpdatedAt,
        b.item.updatedAt ?? b.item.statusUpdatedAt),
    _ => compareDiscoveryVendors(vendors[a.vendorId]!, vendors[b.vendorId]!,
        sort: sort,
        center: center,
        ratings: ratings,
        dishes: dishes,
        query: query),
  };
  if (order != 0) return order;
  final relevance = (discoverySearchScore(query, a.item.name) ?? 999)
      .compareTo(discoverySearchScore(query, b.item.name) ?? 999);
  if (relevance != 0) return relevance;
  final name = a.item.name.toLowerCase().compareTo(b.item.name.toLowerCase());
  return name != 0
      ? name
      : '${a.vendorId}/${a.item.itemId}'
          .compareTo('${b.vendorId}/${b.item.itemId}');
}
