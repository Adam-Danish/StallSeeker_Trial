class VendorModel {
  final String vendorId;
  final String stallName;
  final String description;
  final String category;
  final String openingHours;
  final bool isOpen;
  final double latitude;
  final double longitude;

  VendorModel({
    required this.vendorId,
    required this.stallName,
    required this.description,
    required this.category,
    required this.openingHours,
    this.isOpen = false,
    this.latitude = 0.0,
    this.longitude = 0.0,
  });

  // Convert VendorModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'vendorId': vendorId,
      'stallName': stallName,
      'description': description,
      'category': category,
      'openingHours': openingHours,
      'isOpen': isOpen,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  // Create VendorModel from Firestore Document Snapshot
  factory VendorModel.fromMap(Map<String, dynamic> map, String documentId) {
    return VendorModel(
      vendorId: documentId,
      stallName: map['stallName'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      openingHours: map['openingHours'] ?? '',
      isOpen: map['isOpen'] ?? false,
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
    );
  }

  // CopyWith method for easy state updates
  VendorModel copyWith({
    String? stallName,
    String? description,
    String? category,
    String? openingHours,
    bool? isOpen,
    double? latitude,
    double? longitude,
  }) {
    return VendorModel(
      vendorId: vendorId,
      stallName: stallName ?? this.stallName,
      description: description ?? this.description,
      category: category ?? this.category,
      openingHours: openingHours ?? this.openingHours,
      isOpen: isOpen ?? this.isOpen,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
