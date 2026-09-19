import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/models/menu_item_model.dart';
import 'package:stallseeker/core/models/stall_schedule.dart';
import 'package:stallseeker/core/models/vendor_model.dart';
import 'package:stallseeker/core/utils/vendor_phone.dart';
import 'package:stallseeker/features/vendor/profile/stall_schedule_editor.dart';

void main() {
  group('vendor phone', () {
    test('normalizes common Malaysian mobile and landline formats', () {
      expect(normalizeVendorPhone('012-345 6789'), '+60123456789');
      expect(normalizeVendorPhone('+60 12 345 6789'), '+60123456789');
      expect(normalizeVendorPhone('03-1234 5678'), '+60312345678');
    });

    test('rejects blank, foreign and implausible numbers', () {
      expect(normalizeVendorPhone(''), isNull);
      expect(normalizeVendorPhone('+44 20 1234 5678'), isNull);
      expect(normalizeVendorPhone('01234'), isNull);
    });
  });

  group('structured hours and closures', () {
    test('round-trips weekday intervals and rejects invalid ranges', () {
      final hours = <int, List<StallHoursInterval>>{
        1: [const StallHoursInterval(9 * 60, 12 * 60),
            const StallHoursInterval(13 * 60, 17 * 60)],
        6: [const StallHoursInterval(20 * 60, 2 * 60)],
      };
      final parsed = parseWeeklyHours(serializeWeeklyHours(hours));
      expect(parsed[1]!.map((range) => range.openMinute), [540, 780]);
      expect(parsed[6]!.single.closeMinute, 120);
      expect(StallHoursInterval.fromMap({'open': 540, 'close': 540}), isNull);
      expect(StallHoursInterval.fromMap({'open': -1, 'close': 600}), isNull);
    });

    test('closure start is inclusive and end is exclusive', () {
      final start = DateTime.utc(2026, 9, 18, 2);
      final end = start.add(const Duration(hours: 3));
      final closure = TemporaryClosure(start, end);
      final parsed = TemporaryClosure.fromMap(closure.toMap())!;
      expect(parsed.contains(start), isTrue);
      expect(parsed.contains(end.subtract(const Duration(milliseconds: 1))),
          isTrue);
      expect(parsed.contains(end), isFalse);
      expect(TemporaryClosure.fromMap({
        'startAt': Timestamp.fromDate(end),
        'endAt': Timestamp.fromDate(start),
      }), isNull);
    });

    test('active closure hides an otherwise open stall', () {
      final now = DateTime.now();
      final vendor = VendorModel(
        vendorId: 'vendor-a', stallName: 'Test', description: '',
        category: 'Malay Food', openingHours: '', isOpen: true,
        temporaryClosures: [TemporaryClosure(
          now.subtract(const Duration(minutes: 1)),
          now.add(const Duration(minutes: 1)))],
      );
      expect(vendor.isTemporarilyClosed, isTrue);
      expect(vendor.isOpenNow, isFalse);
      expect(vendor.copyWith(temporaryClosures: []).isOpenNow, isTrue);
    });
  });

  test('old dishes get a section, and stock time comes from Firestore', () {
    final legacy = MenuItemModel.fromMap(
      {'name': 'Nasi lemak', 'price': 5.5, 'status': 'available'}, 'dish-1');
    expect(legacy.section, 'Main menu');
    expect(legacy.statusUpdatedAt, isNull);

    final updated = DateTime.utc(2026, 9, 18, 3);
    final current = MenuItemModel.fromMap({
      'name': 'Teh ais', 'price': 2,
      'section': 'Drinks', 'status': 'low_stock',
      'statusUpdatedAt': Timestamp.fromDate(updated),
    }, 'dish-2');
    expect(current.section, 'Drinks');
    expect(current.statusUpdatedAt!.toUtc(), updated);
  });

  testWidgets('vendor can toggle a day and add a second time period',
      (tester) async {
    var hours = <int, List<StallHoursInterval>>{};
    final closures = <TemporaryClosure>[];
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: StatefulBuilder(
      builder: (context, setState) => SingleChildScrollView(
        child: StallScheduleEditor(hours: hours, closures: closures,
          onChanged: (nextHours, _) => setState(() => hours = nextHours))),
    ))));

    await tester.tap(find.text('Monday').first);
    await tester.pump();
    expect(hours[1], hasLength(1));
    expect(hours[1]!.single.openMinute, 540);

    await tester.tap(find.text('Add time').first);
    await tester.pump();
    expect(hours[1], hasLength(2));

    await tester.tap(find.byTooltip('Remove time').first);
    await tester.pump();
    expect(hours[1], hasLength(1));
  });
}
