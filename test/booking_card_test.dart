import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/models/demo_order.dart';
import 'package:stallseeker/features/shared/booking_detail_screen.dart';

void main() {
  for (final isVendor in [false, true]) {
    testWidgets('special instructions appear for vendor=$isVendor',
        (tester) async {
      final booking = DemoOrder.fromMap(const {
        'id': 'with-instructions',
        'customerName': 'Aina',
        'stallName': 'Nasi Stall',
        'specialInstructions': 'Less spicy, please\nNo onions.',
      });
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Column(children: [
            BookingSummaryCard(
                booking: booking, isVendor: isVendor, onTap: () {}),
            BookingSpecialInstructionsCard(
                instructions: booking.specialInstructions),
          ]),
        ),
      ));
      expect(find.text('Special instructions: Less spicy, please\nNo onions.'),
          findsOneWidget);
      expect(find.text('Less spicy, please\nNo onions.'), findsOneWidget);
      expect(find.text('Requests are subject to vendor acceptance.'),
          findsOneWidget);
    });
  }

  testWidgets(
      'simultaneous bookings show separate progress and open separately',
      (tester) async {
    final opened = <String>[];
    DemoOrder booking(String id, String status, bool unseen) => DemoOrder(
          id: id,
          customerId: 'customer',
          vendorId: 'vendor',
          customerName: 'Customer',
          stallName: 'Stall $id',
          status: status,
          items: const [],
          totalCents: 1200,
          createdAt: DateTime(2026, 10, 8),
          customerUnseenReady: unseen,
        );

    final preparing = booking('first', 'preparing', false);
    final ready = booking('second', 'ready', true);
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Column(children: [
      BookingSummaryCard(
          booking: preparing,
          isVendor: false,
          onTap: () => opened.add('first')),
      BookingProgress(booking: preparing, compact: true),
      BookingSummaryCard(
          booking: ready, isVendor: false, onTap: () => opened.add('second')),
      BookingProgress(booking: ready, compact: true),
    ]))));

    expect(find.text('Preparing'), findsOneWidget);
    expect(find.text('Ready for collection'), findsOneWidget);
    expect(find.bySemanticsLabel('Booking stage 3 of 5'), findsOneWidget);
    expect(find.bySemanticsLabel('Booking stage 4 of 5'), findsOneWidget);
    expect(find.byType(CircleAvatar), findsOneWidget);
    await tester.tap(find.text('Stall second'));
    expect(opened, ['second']);
  });
}
