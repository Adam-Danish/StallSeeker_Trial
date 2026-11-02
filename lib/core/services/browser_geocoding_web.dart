import 'dart:js_interop';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'place_search_service.dart';

@JS('google.maps.Geocoder')
extension type _Geocoder._(JSObject _) implements JSObject {
  external _Geocoder();
  external JSPromise<_GeocodeResponse> geocode(JSObject request);
}

extension type _GeocodeResponse._(JSObject _) implements JSObject {
  external JSArray<_GeocodeResult> get results;
}

extension type _GeocodeResult._(JSObject _) implements JSObject {
  @JS('formatted_address')
  external String get formattedAddress;
  @JS('place_id')
  external String get placeId;
  external _Geometry get geometry;
}

extension type _Geometry._(JSObject _) implements JSObject {
  external _LatLng get location;
}

extension type _LatLng._(JSObject _) implements JSObject {
  external double lat();
  external double lng();
}

@JS('google.maps.places.Place')
extension type _Place._(JSObject _) implements JSObject {
  external _Place(JSObject options);
  external JSPromise<JSObject> fetchFields(JSObject request);
  external _LatLng? get location;
}

Future<LatLng?> findBrowserPlaceCoordinates(String placeId) async {
  final place = _Place({'id': placeId}.jsify()! as JSObject);
  await place
      .fetchFields({
        'fields': ['location']
      }.jsify()! as JSObject)
      .toDart
      .timeout(const Duration(seconds: 12));
  final location = place.location;
  return location == null ? null : LatLng(location.lat(), location.lng());
}

Future<List<_GeocodeResult>> _geocode(Map<String, Object> request) async {
  final response = await _Geocoder()
      .geocode(request.jsify()! as JSObject)
      .toDart
      .timeout(const Duration(seconds: 12));
  return response.results.toDart;
}

Future<String> describeBrowserLocation(LatLng coordinates) async {
  final results = await _geocode({
    'location': {'lat': coordinates.latitude, 'lng': coordinates.longitude},
    'region': 'my',
  });
  return results.isEmpty ? 'Selected location' : results.first.formattedAddress;
}

Future<List<PlaceSuggestion>> findBrowserAddresses(String query) async {
  final results = await _geocode({'address': query, 'region': 'my'});
  return results
      .take(3)
      .map((result) => PlaceSuggestion(
            placeId: result.placeId,
            primaryText: result.formattedAddress.split(',').first,
            secondaryText: result.formattedAddress,
            fullText: result.formattedAddress,
            coordinates: LatLng(
                result.geometry.location.lat(), result.geometry.location.lng()),
          ))
      .toList();
}
