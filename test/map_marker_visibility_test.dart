import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:stallseeker/features/customer/home/map_marker_visibility.dart';

void main() {
  const viewport = Size(1000, 700);
  bool visible(int x, int y, {double scale = 1}) =>
      stallMarkerIntersectsViewport(
        coordinate: ScreenCoordinate(x: x, y: y),
        viewport: viewport,
        pixelsPerLogicalPixel: scale,
      );

  test('keeps markers in the top and bottom padded areas', () {
    expect(visible(500, 80), isTrue);
    expect(visible(500, 620), isTrue);
  });

  test('includes partially visible centered marker icons on every edge', () {
    expect(visible(-20, 350), isTrue);
    expect(visible(1020, 350), isTrue);
    expect(visible(500, -20), isTrue);
    expect(visible(500, 720), isTrue);
  });

  test('excludes marker icons completely outside the map', () {
    expect(visible(-29, 350), isFalse);
    expect(visible(1029, 350), isFalse);
    expect(visible(500, -29), isFalse);
    expect(visible(500, 729), isFalse);
    expect(visible(-25, -25), isFalse);
  });

  test('normalizes Android screen pixels before checking visibility', () {
    expect(visible(1500, 1860, scale: 3), isTrue);
    expect(visible(3060, 1050, scale: 3), isTrue);
    expect(visible(3090, 1050, scale: 3), isFalse);
  });

  test('does not report an unlaid-out map as visible', () {
    expect(
      stallMarkerIntersectsViewport(
        coordinate: const ScreenCoordinate(x: 0, y: 0),
        viewport: Size.zero,
      ),
      isFalse,
    );
  });
}
