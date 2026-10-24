import '../../../core/models/vendor_model.dart';
import '../../../core/models/stall_schedule.dart';
import '../../../core/utils/vendor_phone.dart';

/// A detached profile snapshot; operational state comes from the loaded stall.
VendorModel buildStallProfileDraft({
  required VendorModel original,
  required String name,
  required String description,
  required String phone,
  required String legacyHours,
  required Iterable<String> categories,
  required Map<int, List<StallHoursInterval>> hours,
  required List<TemporaryClosure> closures,
  String? imageUrl,
}) {
  final selected = categories.toList();
  return original.copyWith(
    stallName: name.trim(),
    description: description.trim(),
    phoneNumber: normalizeVendorPhone(phone) ?? phone.trim(),
    category: selected.isEmpty ? '' : selected.first,
    categories: selected,
    openingHours: legacyHours.trim(),
    imageUrl: imageUrl,
    weeklyHours: {
      for (final entry in hours.entries) entry.key: [...entry.value]
    },
    temporaryClosures: [...closures],
  );
}
