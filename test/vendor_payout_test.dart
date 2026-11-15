import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/models/demo_order.dart';
import 'package:stallseeker/core/models/vendor_payout.dart';
import 'package:stallseeker/core/theme/app_theme.dart';
import 'package:stallseeker/features/vendor/profile/vendor_payout_details_screen.dart';

DemoOrder _paidOrder({
  required String id,
  required int totalCents,
  int refundedCents = 0,
  String mode = 'live',
  String status = 'paid',
  String vendorId = 'vendor-1',
  bool paidAtSet = true,
}) =>
    DemoOrder(
      id: id,
      customerId: 'cust-1',
      vendorId: vendorId,
      customerName: 'Amina',
      stallName: 'Gerai Amina',
      status: 'collected',
      items: const [
        DemoOrderItem(
          itemId: 'item-1',
          name: 'Nasi Goreng',
          unitPriceCents: 1000,
          quantity: 1,
        ),
      ],
      totalCents: totalCents,
      createdAt: DateTime.utc(2026, 11, 15, 8),
      paymentMode: mode,
      paymentStatus: status,
      paymentPaidAt: paidAtSet ? DateTime.utc(2026, 11, 15, 8) : null,
      paymentRefundedCents: refundedCents,
    );

VendorPayoutRecord _payout({
  required String id,
  required int amountCents,
  required String status,
  String vendorId = 'vendor-1',
  String ref = '',
  String adminNote = '',
}) =>
    VendorPayoutRecord(
      id: id,
      vendorId: vendorId,
      stallName: 'Gerai Amina',
      amountCents: amountCents,
      status: status,
      bankName: 'Maybank',
      accountHolderName: 'Amina binti Ali',
      accountNumber: '112233445566',
      transferReference: ref,
      adminNote: adminNote,
      requestedAt: DateTime.utc(2026, 11, 15, 9),
    );

void main() {
  test('bank account normalization & validation accept valid numbers and reject invalid ones',
      () {
    expect(normalizeBankAccountNumber('1122 3344-5566'), '112233445566');
    expect(normalizeBankAccountNumber('12345'), isNull);
    expect(normalizeBankAccountNumber('12345abc6789'), isNull);
    expect(normalizeBankAccountNumber('1' * 25), isNull);
    expect(maskBankAccountNumber('112233445566'), '•••• 5566');

    expect(validateBankName(''), isNotNull);
    expect(validateBankName('Maybank'), isNull);
    expect(validateAccountHolderName('A'), isNotNull);
    expect(validateAccountHolderName('Amina binti Ali'), isNull);
    expect(validateBankAccountNumber('123-456-7890'), isNull);
    expect(validateBankAccountNumber('abc'), isNotNull);
  });

  test('balance summary isolates live paid sales from test orders, paidouts, pending and rejected payouts',
      () {
    final orders = [
      _paidOrder(id: 'o1', totalCents: 2500, mode: 'live'),
      _paidOrder(id: 'o2', totalCents: 1500, refundedCents: 300, mode: 'live'),
      _paidOrder(id: 'o3', totalCents: 9900, mode: 'test'),
      _paidOrder(id: 'o4', totalCents: 1000, status: 'awaiting_payment', mode: 'live', paidAtSet: false),
      _paidOrder(id: 'o5', totalCents: 5000, vendorId: 'other-vendor', mode: 'live'),
    ];
    final payouts = [
      _payout(id: 'p1', amountCents: 1000, status: 'paid', ref: 'MBB-1001'),
      _payout(id: 'p2', amountCents: 700, status: 'pending'),
      _payout(id: 'p3', amountCents: 500, status: 'rejected', adminNote: 'Wrong account'),
    ];

    final summary = VendorPayoutBalanceSummary.compute(
      orders: orders,
      payouts: payouts,
      vendorId: 'vendor-1',
    );

    expect(summary.liveNetSalesCents, 3700);
    expect(summary.livePaidOrdersCount, 2);
    expect(summary.testNetSalesCents, 9900);
    expect(summary.paidOutCents, 1000);
    expect(summary.pendingCents, 700);
    expect(summary.unsettledLiveCents, 2700);
    expect(summary.availableToRequestCents, 2000);
    expect(summary.canRequestPayout, isTrue);
  });

  testWidgets('vendor can save custom Other bank details without errors',
      (tester) async {
    VendorPayoutDetails? saved;
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: VendorPayoutDetailsView(
        loading: false,
        savingDetails: false,
        requestingPayout: false,
        details: null,
        summary: const VendorPayoutBalanceSummary(
          liveNetSalesCents: 5000,
          livePaidOrdersCount: 2,
          testNetSalesCents: 0,
          paidOutCents: 0,
          pendingCents: 0,
          unsettledLiveCents: 5000,
          availableToRequestCents: 5000,
        ),
        payouts: const [],
        onSaveDetails: (details) async => saved = details,
        onRequestPayout: ({required amountCents, required vendorNote}) async {},
      ),
    ));

    expect(find.text('Bank Needed'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Save Bank Details'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final dropdown = find.byType(DropdownButton<String>);
    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Other'),
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Other').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Specify Bank Name'),
      'MBSB Bank',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Account Holder Name'),
      'Warung Sedap Sdn Bhd',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Bank Account Number'),
      '5510 2233 4455',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'DuitNow ID (Optional)'),
      '0123456789',
    );

    final saveButton = find.text('Save Bank Details');
    await tester.ensureVisible(saveButton);
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.bankName, 'MBSB Bank');
    expect(saved!.accountHolderName, 'Warung Sedap Sdn Bhd');
    expect(saved!.accountNumber, '551022334455');
    expect(saved!.duitNowId, '0123456789');
    expect(tester.takeException(), isNull);
  });

  testWidgets('saved vendor can request payout via confirmation modal and view history',
      (tester) async {
    int? requestedCents;
    String? requestedNote;

    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: const TextScaler.linear(1.25)),
        child: child!,
      ),
      home: VendorPayoutDetailsView(
        loading: false,
        savingDetails: false,
        requestingPayout: false,
        details: const VendorPayoutDetails(
          vendorId: 'vendor-1',
          bankName: 'Maybank',
          accountHolderName: 'Amina binti Ali',
          accountNumber: '112233445566',
        ),
        summary: const VendorPayoutBalanceSummary(
          liveNetSalesCents: 4500,
          livePaidOrdersCount: 3,
          testNetSalesCents: 1200,
          paidOutCents: 1500,
          pendingCents: 0,
          unsettledLiveCents: 3000,
          availableToRequestCents: 3000,
        ),
        payouts: [
          _payout(id: 'p1', amountCents: 1500, status: 'paid', ref: 'FT20261115'),
        ],
        onSaveDetails: (_) async {},
        onRequestPayout: ({required amountCents, required vendorNote}) async {
          requestedCents = amountCents;
          requestedNote = vendorNote;
        },
      ),
    ));

    expect(find.text('Bank Saved'), findsOneWidget);
    expect(find.text('Ref: FT20261115'), findsOneWidget);
    expect(
      find.textContaining('Stripe Test mode orders is not transferable'),
      findsOneWidget,
    );

    final requestBtn = find.text('Request Payout (RM 30.00)');
    await tester.ensureVisible(requestBtn);
    await tester.tap(requestBtn);
    await tester.pumpAndSettle();

    expect(find.text('Request Payout'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Note for admin (optional)'),
      'Daily transfer',
    );
    await tester.tap(find.text('Send Request'));
    await tester.pumpAndSettle();

    expect(requestedCents, 3000);
    expect(requestedNote, 'Daily transfer');
    expect(tester.takeException(), isNull);
  });
}
