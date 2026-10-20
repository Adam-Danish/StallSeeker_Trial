import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/models/demo_order.dart';
import 'package:stallseeker/features/shared/demo_orders_screen.dart';

void main() {
  testWidgets('customer bookings only show Active and History', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: DemoOrdersScreen(
        isVendor: false,
        accountId: 'test-customer',
        liveBookings: Stream.value(<DemoOrder>[]),
      ),
    ));
    expect(find.text('Past demos'), findsNothing);
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(find.text('No bookings in this section yet.'), findsOneWidget);
    await tester.tap(find.text('Active'));
    await tester.pumpAndSettle();
    expect(find.text('No bookings in this section yet.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
