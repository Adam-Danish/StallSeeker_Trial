import 'dart:io';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/models/demo_order.dart';
import 'package:stallseeker/core/theme/app_theme.dart';
import 'package:stallseeker/features/shared/booking_payment_card.dart';
import 'package:stallseeker/features/shared/booking_receipt_screen.dart';
import 'package:stallseeker/features/vendor/dashboard/vendor_demo_sales.dart';

DemoOrder order(
        {String id = 'order',
        String vendorId = 'seller',
        String? mode = 'test',
        String? payment = 'awaiting_payment',
        bool checkoutFirst = false,
        bool vendorUnseenRequest = false,
        int refund = 0,
        DateTime? paidAt}) =>
    DemoOrder(
        id: id,
        customerId: 'buyer',
        vendorId: vendorId,
        customerName: 'Adam',
        stallName: 'Nasi Lemak Kak Ani',
        status: 'confirmed',
        items: const [],
        totalCents: 1250,
        createdAt: DateTime(2026, 10, 20),
        paymentMode: mode,
        checkoutFirst: checkoutFirst,
        vendorUnseenRequest: vendorUnseenRequest,
        paymentStatus: payment,
        paymentRefundedCents: refund,
        paymentExpiresAt: DateTime.now().add(const Duration(minutes: 5)),
        paymentPaidAt: paidAt);

Future<void> preview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('PAYMENT_PREVIEW')) return;
  final boundary = tester
      .renderObject<RenderRepaintBoundary>(find.byKey(const Key('preview')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('tmp/payment-previews').create(recursive: true);
    await File('tmp/payment-previews/$name.png')
        .writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

Widget app(Widget child) => MaterialApp(
    theme: AppTheme.lightTheme,
    home: RepaintBoundary(
        key: const Key('preview'),
        child: Scaffold(
            appBar: AppBar(
                title: const Text('StallSeeker',
                    style: TextStyle(fontFamily: 'Roboto'))),
            body: SingleChildScrollView(
                padding: const EdgeInsets.all(16), child: child))));

void main() {
  setUpAll(() async {
    if (!const bool.fromEnvironment('PAYMENT_PREVIEW')) return;
    const fontRoot = String.fromEnvironment('PREVIEW_FONT_ROOT');
    final bytes = await File('$fontRoot/roboto-regular.ttf').readAsBytes();
    for (final family in ['Roboto', 'Ahem']) {
      final font = FontLoader(family)
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      await font.load();
    }
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  test(
      'legacy records remain payable outside the app and test payment metadata survives round trips',
      () {
    final legacy = order(mode: null, payment: null);
    expect(legacy.canPrepare, isTrue);
    expect(legacy.hasTestPayment, isFalse);
    final paid = order(payment: 'paid', paidAt: DateTime.utc(2026, 10, 20));
    final decoded = DemoOrder.fromMap(paid.toMap()).withStatus('preparing');
    expect(decoded.paymentStatus, 'paid');
    expect(decoded.paymentPaidAt, paid.paymentPaidAt);
    expect(decoded.paymentMode, 'test');
    expect(order(checkoutFirst: true).toMap()['checkoutFirst'], isTrue);
    expect(DemoOrder.fromMap(order(checkoutFirst: true).toMap()).checkoutFirst,
        isTrue);
    expect(order().canPrepare, isFalse);
    expect(paid.canPrepare, isTrue);
  });

  test('customer may cancel a paid test booking until it is collected', () {
    final paid = order(payment: 'paid');
    for (final status in ['confirmed', 'preparing', 'ready']) {
      expect(paid.withStatus(status).canCustomerCancel, isTrue);
    }
    expect(paid.withStatus('collected').canCustomerCancel, isFalse);
    expect(order(mode: null).canCustomerCancel, isFalse);
    expect(bookingStatusLabel(order(checkoutFirst: true)), 'Awaiting payment');
    expect(bookingStatusLabel(order(checkoutFirst: true, payment: 'paid')),
        'Paid · awaiting preparation');
    expect(
        order(checkoutFirst: true, payment: 'paid', vendorUnseenRequest: true)
            .vendorNeedsAttention,
        isTrue);
    expect(
        order(
                checkoutFirst: true,
                payment: 'pending',
                vendorUnseenRequest: true)
            .vendorNeedsAttention,
        isFalse);
  });

  test('receipts require a recorded test payment and survive refunds', () {
    final paidAt = DateTime.utc(2026, 10, 20);
    expect(order(payment: 'pending').hasReceipt, isFalse);
    expect(order(payment: 'paid').hasReceipt, isFalse);
    expect(order(payment: 'paid', paidAt: paidAt).hasReceipt, isTrue);
    expect(
        order(mode: null, payment: 'paid', paidAt: paidAt).hasReceipt, isFalse);
    expect(order(payment: 'refunded', paidAt: paidAt, refund: 1250).hasReceipt,
        isTrue);
  });

  test(
      'demo sales exclude other stalls, old bookings, unpaid and refunded orders',
      () {
    final now =
        DateTime.utc(2026, 10, 19, 17); // 1am on 20 October in Malaysia.
    final result = DemoSalesSummary.fromOrders([
      order(payment: 'paid', paidAt: now),
      order(payment: 'paid', paidAt: now, refund: 250),
      order(payment: 'paid', paidAt: DateTime.utc(2026, 10, 19, 15)),
      order(vendorId: 'other', payment: 'paid', paidAt: now),
      order(mode: null, payment: 'paid', paidAt: now),
      order(payment: 'refunded', paidAt: now),
      order(payment: 'refund_pending', paidAt: now),
      order(payment: 'pending', paidAt: now),
    ], vendorId: 'seller', now: now);
    expect(result.todayCents, 2250);
    expect(result.totalCents, 3500);
    expect(result.paidOrders, 3);
  });

  testWidgets(
      'customer can pay only eligible bookings and sees payment information',
      (tester) async {
    tester.view.resetPhysicalSize();
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var tapped = 0;
    await tester.pumpWidget(app(BookingPaymentCard(
        booking: order(),
        isVendor: false,
        onPay: () => tapped++,
        onRefresh: () {})));
    await tester.pumpAndSettle();
    expect(find.text('Pay RM 12.50'), findsOneWidget);
    expect(find.text('Complete your payment securely with Stripe.'),
        findsOneWidget);
    expect(find.textContaining('TEST MODE'), findsNothing);
    await tester.tap(find.text('Pay RM 12.50'));
    expect(tapped, 1);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await preview(tester, 'customer-payment');

    await tester.pumpWidget(app(BookingPaymentCard(
        booking: order(payment: 'paid'),
        isVendor: false,
        onPay: () => tapped++)));
    expect(find.text('Pay RM 12.50'), findsNothing);
    expect(find.text('Paid'), findsOneWidget);
  });

  testWidgets('vendor and busy payment cards cannot launch checkout',
      (tester) async {
    await tester
        .pumpWidget(app(BookingPaymentCard(booking: order(), isVendor: true)));
    expect(find.text('Pay RM 12.50'), findsNothing);
    expect(find.textContaining('Preparation unlocks'), findsOneWidget);
    await tester.pumpWidget(app(BookingPaymentCard(
        booking: order(),
        isVendor: false,
        busy: true,
        onPay: () => fail('Must not start another payment'))));
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
  });

  testWidgets('customer can open a paid booking receipt with itemized amounts',
      (tester) async {
    final booking = DemoOrder(
      id: 'booking-123',
      customerId: 'buyer',
      vendorId: 'seller',
      customerName: 'Adam',
      stallName: 'Nasi Lemak Kak Ani',
      status: 'collected',
      items: const [
        DemoOrderItem(
            itemId: 'dish',
            name: 'Nasi Lemak',
            unitPriceCents: 625,
            quantity: 2),
      ],
      totalCents: 1250,
      createdAt: DateTime.utc(2026, 10, 20),
      paymentMode: 'test',
      paymentStatus: 'refunded',
      paymentReference: 'cs_test_123',
      paymentPaidAt: DateTime.utc(2026, 10, 20),
      paymentRefundedCents: 1250,
    );
    var opened = 0;
    await tester.pumpWidget(app(BookingPaymentCard(
      booking: booking,
      isVendor: false,
      onReceipt: () => opened++,
    )));
    expect(find.text('View receipt'), findsOneWidget);
    await tester.tap(find.text('View receipt'));
    expect(opened, 1);
    await tester.pumpWidget(app(BookingPaymentCard(
      booking: booking,
      isVendor: true,
      onReceipt: () => fail('Vendor should not see the customer receipt'),
    )));
    expect(find.text('View receipt'), findsNothing);
    await tester.pumpWidget(app(BookingPaymentCard(
      booking: order(payment: 'pending'),
      isVendor: false,
      onReceipt: () => fail('Unpaid booking should not have a receipt'),
    )));
    expect(find.text('View receipt'), findsNothing);

    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: BookingReceiptScreen(booking: booking)));
    expect(find.text('StallSeeker payment receipt'), findsOneWidget);
    expect(find.text('Nasi Lemak Kak Ani'), findsOneWidget);
    expect(find.text('2 × Nasi Lemak'), findsOneWidget);
    expect(find.text('RM 6.25 each'), findsOneWidget);
    expect(find.text('Amount paid'), findsOneWidget);
    expect(find.text('Refunded'), findsOneWidget);
    expect(find.text('Remaining paid'), findsOneWidget);
    expect(find.text('cs_test_123'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('PDF export disables repeated taps and shows retryable failure',
      (tester) async {
    final export = Completer<void>();
    var attempts = 0;
    await tester.pumpWidget(MaterialApp(
      home: BookingReceiptScreen(
        booking: order(payment: 'paid', paidAt: DateTime.utc(2026, 11, 4)),
        onExportPdf: () {
          attempts++;
          return export.future;
        },
      ),
    ));
    await tester.tap(find.text('Save or share PDF'));
    await tester.pump();
    expect(find.text('Preparing PDF…'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    expect(attempts, 1);
    export.completeError(StateError('Offline'));
    await tester.pumpAndSettle();
    expect(find.text('Could not save the PDF receipt. Please try again.'),
        findsOneWidget);
    expect(find.text('Save or share PDF'), findsOneWidget);
  });

  testWidgets('sales card uses release wording and fits narrow screens',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(DemoSalesCard(
        summary: const DemoSalesSummary(
            todayCents: 8500, totalCents: 12500, paidOrders: 8),
        onHistory: () {})));
    await tester.pumpAndSettle();
    expect(find.text('RM 85.00'), findsOneWidget);
    expect(find.text('Sales'), findsOneWidget);
    expect(find.textContaining('TEST MODE'), findsNothing);
    expect(tester.takeException(), isNull);
    await preview(tester, 'vendor-sales');
  });
}
