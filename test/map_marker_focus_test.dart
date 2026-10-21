import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:stallseeker/core/models/vendor_model.dart';
import 'package:stallseeker/features/customer/home/map_marker_focus.dart';

void main() {
  final bounds = LatLngBounds(
    southwest: const LatLng(3.10, 101.65),
    northeast: const LatLng(3.18, 101.73),
  );
  final nearby = VendorModel(
    vendorId: 'nearby',
    stallName: 'Nearby stall',
    description: '',
    category: 'Drinks',
    openingHours: '',
    latitude: 3.1405,
    longitude: 101.6865,
  );
  final distant = VendorModel(
    vendorId: 'distant',
    stallName: 'Distant stall',
    description: '',
    category: 'Drinks',
    openingHours: '',
    latitude: 3.16,
    longitude: 101.71,
  );

  test('selects the nearest stall when the map settles over its marker', () {
    final focused = stallNearMapCenter(
      center: const LatLng(3.14, 101.686),
      bounds: bounds,
      vendors: [distant, nearby],
    );
    expect(focused?.vendorId, 'nearby');
  });

  test('does not select a stall away from the map center', () {
    final focused = stallNearMapCenter(
      center: const LatLng(3.14, 101.686),
      bounds: bounds,
      vendors: [distant],
    );
    expect(focused, isNull);
  });
}
