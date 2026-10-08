import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/models/demo_order.dart';
import 'package:stallseeker/features/shared/booking_detail_screen.dart';

void main() {
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

    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Column(children: [
      BookingSummaryCard(
          booking: booking('first', 'preparing', false),
          isVendor: false,
          onTap: () => opened.add('first')),
      BookingSummaryCard(
          booking: booking('second', 'ready', true),
          isVendor: false,
          onTap: () => opened.add('second')),
    ]))));

    expect(find.text('Preparing'), findsOneWidget);
    expect(find.text('Ready for collection'), findsOneWidget);
    expect(find.byType(CircleAvatar), findsOneWidget);
    await tester.tap(find.text('Stall second'));
    expect(opened, ['second']);
  });
}
