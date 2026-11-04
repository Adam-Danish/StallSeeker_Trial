import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/models/vendor_model.dart';
import 'package:stallseeker/core/services/moderation_service.dart';
import 'package:stallseeker/features/shared/moderation_screen.dart';

void main() {
  test('legacy vendors are active and suspension survives profile drafts', () {
    final legacy =
        VendorModel.fromMap({'stallName': 'Stall', 'isOpen': true}, 'vendor');
    expect(legacy.isSuspended, isFalse);
    final suspended = VendorModel.fromMap(
        {'stallName': 'Stall', 'isOpen': true, 'listingStatus': 'suspended'},
        'vendor');
    expect(suspended.isOpenNow, isFalse);
    expect(suspended.copyWith(stallName: 'Updated').isSuspended, isTrue);
    expect(suspended.toProfileMap().containsKey('listingStatus'), isFalse);
    expect(suspended.toMap().containsKey('listingStatus'), isFalse);
  });
  test('deadlines display Malaysia time independently of the device timezone',
      () {
    expect(
        moderationTime(DateTime.utc(2026, 11, 4, 3, 5)), '4/11/2026 11:05 MYT');
  });
  for (final width in [360.0, 1200.0]) {
    testWidgets('warning response is readable at width $width with large text',
        (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final record = ModerationRecord('case-a', {
        'stallName': 'Test stall',
        'vendorId': 'vendor',
        'status': 'suspended',
        'createdAt': Timestamp.fromDate(DateTime.now()),
        'dueAt': Timestamp.fromDate(
            DateTime.now().subtract(const Duration(hours: 1))),
        'summaries': [
          {
            'reason': 'wrong_location',
            'details': 'The stall was not at its listed location.'
          }
        ],
        'adminReason': 'Please update the stall pin.',
      });
      await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!),
          home: Scaffold(
              body: SingleChildScrollView(
                  child:
                      ModerationRecordCard(record: record, isVendor: true)))));
      expect(find.text('SUSPENDED'), findsOneWidget);
      expect(find.textContaining('existing orders'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Submit correction or dispute'));
      await tester.tap(find.text('Submit correction or dispute'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Submit for review'));
      await tester.tap(find.text('Submit for review'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a response.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('customer report status displays the admin decision',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: ModerationRecordCard(
                record: const ModerationRecord('report-a', {
                  'stallName': 'Test stall',
                  'status': 'rejected',
                  'reason': 'menu_prices',
                  'details': 'The price was different.',
                  'adminReason': 'The menu had already been corrected.'
                }),
                isVendor: false))));
    expect(find.text('REJECTED'), findsOneWidget);
    expect(find.textContaining('already been corrected'), findsOneWidget);
    expect(find.text('Submit correction or dispute'), findsNothing);
  });
}
