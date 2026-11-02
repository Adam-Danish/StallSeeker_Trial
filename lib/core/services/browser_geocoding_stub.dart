import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'place_search_service.dart';

Future<String> describeBrowserLocation(LatLng coordinates) =>
    Future.error(UnsupportedError('Browser geocoding is web-only.'));

Future<List<PlaceSuggestion>> findBrowserAddresses(String query) =>
    Future.error(UnsupportedError('Browser geocoding is web-only.'));

Future<LatLng?> findBrowserPlaceCoordinates(String placeId) =>
    Future.error(UnsupportedError('Browser Places is web-only.'));
