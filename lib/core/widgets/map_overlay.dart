import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';

/// Let Flutter controls above an HTML map receive browser mouse/touch events.
Widget interceptMapOverlay(Widget overlay) {
  if (!kIsWeb) return overlay;
  if (overlay is Positioned && overlay.child is! GoogleMap) {
    return Positioned(
      key: overlay.key,
      left: overlay.left,
      top: overlay.top,
      right: overlay.right,
      bottom: overlay.bottom,
      width: overlay.width,
      height: overlay.height,
      child: PointerInterceptor(child: overlay.child),
    );
  }
  if (overlay is AnimatedPositioned) {
    return AnimatedPositioned(
      key: overlay.key,
      duration: overlay.duration,
      curve: overlay.curve,
      onEnd: overlay.onEnd,
      left: overlay.left,
      top: overlay.top,
      right: overlay.right,
      bottom: overlay.bottom,
      width: overlay.width,
      height: overlay.height,
      child: PointerInterceptor(child: overlay.child),
    );
  }
  return overlay;
}
