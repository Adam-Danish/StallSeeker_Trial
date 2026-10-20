import 'package:flutter/foundation.dart';
import 'package:flutter_google_places_sdk/flutter_google_places_sdk.dart'
    hide LatLng;
import 'package:google_maps_flutter/google_maps_flutter.dart';

class LocationSelection {
  const LocationSelection({
    required this.coordinates,
    required this.label,
  });

  final LatLng coordinates;
  final String label;
}

class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.primaryText,
    required this.secondaryText,
    required this.fullText,
    this.coordinates,
  });

  final String placeId;
  final String primaryText;
  final String secondaryText;
  final String fullText;
  final LatLng? coordinates;
}

class PlaceSearchService {
  PlaceSearchService({FlutterGooglePlacesSdk? places})
      : _places = places ??
            FlutterGooglePlacesSdk(
              'AIzaSyDV0UDXXVwuXQw3dVAb8RHmcql3bTlysNE',
              useNewApi: true,
            );

  final FlutterGooglePlacesSdk _places;

  void dispose() {}

  Future<List<PlaceSuggestion>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.length < 2) return [];

    try {
      final response = await _places.findAutocompletePredictions(
        trimmed,
        countries: ['my'],
      ).timeout(const Duration(seconds: 12));

      return response.predictions.map((prediction) {
        return PlaceSuggestion(
          placeId: prediction.placeId,
          primaryText: prediction.primaryText,
          secondaryText: prediction.secondaryText,
          fullText: prediction.fullText,
        );
      }).toList();
    } catch (error, stackTrace) {
      debugPrint('Google Places search failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<LatLng?> getCoordinates(String placeId) async {
    if (placeId.isEmpty) return null;

    try {
      final response = await _places.fetchPlace(
        placeId,
        fields: [PlaceField.Location],
      ).timeout(const Duration(seconds: 12));

      final coordinates = response.place?.latLng;

      if (coordinates == null) return null;

      return LatLng(coordinates.lat, coordinates.lng);
    } catch (error, stackTrace) {
      debugPrint('Google Places details failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }
}
