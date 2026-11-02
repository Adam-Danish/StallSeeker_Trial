import 'dart:ui' show Size;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Uses the full map rectangle, independently of camera padding, tilt, or bearing.
/// The 28 logical-pixel radius matches the centered 56px stall marker.
bool stallMarkerIntersectsViewport({
  required ScreenCoordinate coordinate,
  required Size viewport,
  double pixelsPerLogicalPixel = 1,
  double markerRadius = 28,
}) {
  if (viewport.isEmpty || pixelsPerLogicalPixel <= 0 || markerRadius < 0) {
    return false;
  }
  final x = coordinate.x / pixelsPerLogicalPixel;
  final y = coordinate.y / pixelsPerLogicalPixel;
  final dx = x - x.clamp(0.0, viewport.width);
  final dy = y - y.clamp(0.0, viewport.height);
  return dx * dx + dy * dy <= markerRadius * markerRadius;
}
