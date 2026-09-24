import 'package:cloud_firestore/cloud_firestore.dart';
import 'stall_schedule.dart';

class VendorModel {
  // file ni represent 1 stall
  final String vendorId;
  final String stallName;
  final String description;
  final String category;
  final String openingHours;
  final bool isOpen;
  final double latitude;
  final double longitude;
  final String imageUrl;
  final String phoneNumber;
  final Map<int, List<StallHoursInterval>> weeklyHours;
  final List<TemporaryClosure> temporaryClosures;
  final DateTime? locationUpdatedAt;
  final bool locationSharingActive;

  bool get isTemporarilyClosed =>
      temporaryClosures.any((c) => c.contains(DateTime.now()));
  bool get isOpenNow => isOpen && !isTemporarilyClosed;
  bool isScheduledOpenAt(DateTime instant) =>
      isWithinStallSchedule(instant, weeklyHours, temporaryClosures);

  String get hoursToday {
    final day = malaysiaTime(DateTime.now()).weekday;
    if (weeklyHours.isEmpty) return openingHours;
    final intervals = weeklyHours[day] ?? [];
    if (intervals.isEmpty) return 'Closed today';
    return intervals
        .map((i) => '${formatStallTime(i.openMinute)} – '
            '${formatStallTime(i.closeMinute)}${i.closeMinute < i.openMinute ? ' (next day)' : ''}')
        .join(', ');
  }

  bool get hasValidLocation =>
      latitude.isFinite &&
      longitude.isFinite &&
      latitude.abs() <= 90 &&
      longitude.abs() <= 180 &&
      !(latitude == 0 && longitude == 0);

  bool get hasFreshLocation {
    // check kalau stall ada usable coordinates
    final updated = locationUpdatedAt;
    if (!locationSharingActive || updated == null) {
      return false;
    }
    final age = DateTime.now().difference(updated);
    return !age.isNegative && age < const Duration(minutes: 2);
  }

  // location update setiap 15sec, tapi kalau vendor punya gps fail/phone off lebih dua minit stall tutup

  VendorModel({
    required this.vendorId,
    required this.stallName,
    required this.description,
    required this.category,
    required this.openingHours,
    this.isOpen = false,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.imageUrl = '',
    this.phoneNumber = '',
    this.weeklyHours = const {},
    this.temporaryClosures = const [],
    this.locationUpdatedAt,
    this.locationSharingActive = false,
  });

  /// Editable information only. Operational state belongs to the selling session.
  Map<String, dynamic> toProfileMap() => {
        'vendorId': vendorId,
        'stallName': stallName,
        'description': description,
        'category': category,
        'openingHours': openingHours,
        'imageUrl': imageUrl,
        'phoneNumber': phoneNumber,
        'weeklyHours': serializeWeeklyHours(weeklyHours),
        'temporaryClosures': temporaryClosures.map((c) => c.toMap()).toList(),
      };

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
      'imageUrl': imageUrl,
      'phoneNumber': phoneNumber,
      'weeklyHours': serializeWeeklyHours(weeklyHours),
      'temporaryClosures': temporaryClosures.map((c) => c.toMap()).toList(),
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
      imageUrl: map['imageUrl'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      weeklyHours: parseWeeklyHours(map['weeklyHours']),
      temporaryClosures: (map['temporaryClosures'] is List
              ? map['temporaryClosures'] as List
              : const [])
          .map(TemporaryClosure.fromMap)
          .whereType<TemporaryClosure>()
          .toList(),
      locationUpdatedAt: (map['locationUpdatedAt'] as Timestamp?)?.toDate(),
      locationSharingActive: map['locationSharingActive'] == true,
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
    String? imageUrl,
    String? phoneNumber,
    Map<int, List<StallHoursInterval>>? weeklyHours,
    List<TemporaryClosure>? temporaryClosures,
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
      imageUrl: imageUrl ?? this.imageUrl,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      weeklyHours: weeklyHours ?? this.weeklyHours,
      temporaryClosures: temporaryClosures ?? this.temporaryClosures,
      locationUpdatedAt: locationUpdatedAt,
      locationSharingActive: locationSharingActive,
    );
  }
}
