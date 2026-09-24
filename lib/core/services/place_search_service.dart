import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class LocationSelection {
  const LocationSelection({required this.coordinates, required this.label});
  final LatLng coordinates;
  final String label;
}

/// Nationwide autocomplete; location is a ranking hint, never a radius limit.
class PlaceSearchService {
  PlaceSearchService({http.Client? client}) : _client = client ?? http.Client();
  final http.Client _client;
  void dispose() => _client.close();

  Future<List<LocationSelection>> search(String query, {LatLng? origin}) async {
    if (query.trim().length < 3) return [];
    final results = <LocationSelection>[];
    final seen = <String>{};
    Object? failure;
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        final response = await _client
            .get(Uri.https('photon.komoot.io', '/api/', {
              'q': query.trim(),
              'countrycode': 'MY',
              'limit': '20',
              if (attempt == 0 && origin != null) ...{
                'lat': '${origin.latitude}',
                'lon': '${origin.longitude}',
                'location_bias_scale': '0.2',
              },
            }))
            .timeout(const Duration(seconds: 12));
        if (response.statusCode != 200) {
          throw http.ClientException(
              'Place search unavailable (${response.statusCode})');
        }
        for (final place in parsePlaces(jsonDecode(response.body))) {
          final key =
              '${place.label.toLowerCase()}|${place.coordinates.latitude.toStringAsFixed(5)}|${place.coordinates.longitude.toStringAsFixed(5)}';
          if (seen.add(key)) results.add(place);
        }
        if (results.length > 1) break;
      } catch (error) {
        failure = error;
      }
    }
    if (results.isEmpty && failure != null) throw failure;
    return results.take(15).toList();
  }

  static List<LocationSelection> parsePlaces(Object? body) {
    if (body is! Map || body['features'] is! List) return [];
    final results = <LocationSelection>[];
    for (final feature in body['features'] as List) {
      if (feature is! Map) continue;
      final properties = feature['properties'];
      final geometry = feature['geometry'];
      if (properties is! Map || geometry is! Map) continue;
      if (properties['countrycode']?.toString().toUpperCase() != 'MY') continue;
      final coords = geometry['coordinates'];
      if (coords is! List ||
          coords.length < 2 ||
          coords[0] is! num ||
          coords[1] is! num) {
        continue;
      }
      final lon = (coords[0] as num).toDouble();
      final lat = (coords[1] as num).toDouble();
      if (!lat.isFinite || !lon.isFinite || lat.abs() > 90 || lon.abs() > 180) {
        continue;
      }
      final parts = <String>[];
      final seen = <String>{};
      for (final key in [
        'name',
        'housenumber',
        'street',
        'district',
        'city',
        'county',
        'state',
        'postcode'
      ]) {
        final value = properties[key]?.toString().trim() ?? '';
        if (value.isNotEmpty && seen.add(value.toLowerCase())) parts.add(value);
      }
      if (parts.isNotEmpty) {
        results.add(LocationSelection(
            coordinates: LatLng(lat, lon),
            label: '${parts.join(', ')}, Malaysia'));
      }
    }
    return results;
  }
}
