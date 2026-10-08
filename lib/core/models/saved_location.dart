import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/place_search_service.dart';

class SavedLocation {
  const SavedLocation({
    required this.id,
    required this.name,
    required this.address,
    required this.coordinates,
    required this.isHome,
  });

  final String id;
  final String name;
  final String address;
  final LatLng coordinates;
  final bool isHome;

  LocationSelection get selection =>
      LocationSelection(coordinates: coordinates, label: '$name · $address');

  Map<String, dynamic> toMap() => {
        'name': name,
        'address': address,
        'latitude': coordinates.latitude,
        'longitude': coordinates.longitude,
        'isHome': isHome,
      };

  static SavedLocation? fromMap(String id, Map<String, dynamic> map) {
    final latitude = map['latitude'];
    final longitude = map['longitude'];
    final name = map['name'];
    final address = map['address'];
    if (id.isEmpty ||
        id == '.' ||
        id == '..' ||
        id.contains('/') ||
        id.length > 128 ||
        latitude is! num ||
        longitude is! num ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180 ||
        name is! String ||
        name.trim().isEmpty ||
        name.length > 60 ||
        address is! String ||
        address.trim().isEmpty ||
        address.length > 500 ||
        map['isHome'] is! bool ||
        (id == 'home') != map['isHome'] ||
        (map['isHome'] == true && name != 'Home')) {
      return null;
    }
    return SavedLocation(
        id: id,
        name: name,
        address: address,
        coordinates: LatLng(latitude.toDouble(), longitude.toDouble()),
        isHome: map['isHome'] as bool);
  }
}
