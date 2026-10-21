import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/models/vendor_model.dart';

/// Finds a visible stall close to the center of the map after a user pan.
/// The threshold scales with zoom because it is a fraction of the viewport.
VendorModel? stallNearMapCenter({
  required LatLng center,
  required LatLngBounds bounds,
  required Iterable<VendorModel> vendors,
  double focusFraction = .15,
}) {
  final latitudeSpan = bounds.northeast.latitude - bounds.southwest.latitude;
  final longitudeSpan = bounds.northeast.longitude - bounds.southwest.longitude;
  if (latitudeSpan <= 0 || longitudeSpan <= 0 || focusFraction <= 0) {
    return null;
  }

  VendorModel? nearest;
  var nearestScore = 1.0;
  for (final vendor in vendors) {
    if (!vendor.hasValidLocation) continue;
    final latitudeOffset =
        (vendor.latitude - center.latitude) / (latitudeSpan * focusFraction);
    final longitudeOffset =
        (vendor.longitude - center.longitude) / (longitudeSpan * focusFraction);
    final score =
        latitudeOffset * latitudeOffset + longitudeOffset * longitudeOffset;
    if (score <= nearestScore) {
      nearest = vendor;
      nearestScore = score;
    }
  }
  return nearest;
}
