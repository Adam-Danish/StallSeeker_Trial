import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/models/demo_order.dart';
import 'package:stallseeker/core/models/stall_schedule.dart';
import 'package:stallseeker/core/models/vendor_model.dart';
import 'package:stallseeker/core/theme/app_theme.dart';
import 'package:stallseeker/core/widgets/app_pill_navigation.dart';
import 'package:stallseeker/features/vendor/dashboard/vendor_dashboard_view.dart';

final _now = DateTime.utc(2026, 10, 24, 4);

VendorModel _vendor({bool temporaryClosure = false}) => VendorModel(
      vendorId: 'seller',
      stallName: 'Warung Pak Ali',
      description: 'Fresh local favourites',
      category: 'Malay',
      openingHours: '8 AM – 4 PM',
      phoneNumber: '0123456789',
      isOpen: true,
      selfCollectEnabled: true,
      temporaryClosures: temporaryClosure
          ? [
              TemporaryClosure(
                  DateTime.now().subtract(const Duration(hours: 1)),
                  DateTime.now().add(const Duration(hours: 1))),
            ]
          : [],
    );

DemoOrder _booking(String id, String status,
        {bool paid = true, DateTime? createdAt, DateTime? expiresAt}) =>
    DemoOrder(
      id: id,
      customerId: id,
      vendorId: 'seller',
      customerName: id,
      stallName: 'Warung Pak Ali',
      status: status,
      items: const [
        DemoOrderItem(
            itemId: 'dish',
            name: 'Nasi Lemak',
            unitPriceCents: 600,
            quantity: 2),
      ],
      totalCents: 1200,
      createdAt: createdAt ?? _now,
      expiresAt: expiresAt,
      paymentMode: 'test',
      paymentStatus: paid ? 'paid' : 'awaiting_payment',
      paymentPaidAt: paid ? _now : null,
    );

Widget _app({
  List<DemoOrder> bookings = const [],
  VendorModel? vendor,
  bool error = false,
  bool loading = false,
  bool sharing = true,
  bool saving = false,
  String? locationError,
  Set<String> busy = const {},
  double scale = 1,
  ValueChanged<String>? onAction,
}) {
  void action(String name) => onAction?.call(name);
  return MaterialApp(
    theme: AppTheme.lightTheme,
    builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!),
    home: RepaintBoundary(
      key: const Key('dashboard-preview'),
      child: Scaffold(
        extendBody: true,
        body: SafeArea(
          bottom: false,
          child: VendorDashboardView(
            vendor: vendor ?? _vendor(),
            bookings: bookings,
            bookingsLoading: loading,
            bookingsError: error,
            saving: saving,
            locationSharing: sharing,
            locationError: locationError,
            busyBookings: busy,
            now: _now,
            onRefresh: () async => action('refresh'),
            onToggleOpen: (open) => action('open:$open'),
            onToggleSelfCollect: (enabled) => action('collect:$enabled'),
            onResumeLocation: () => action('resume'),
            onPreview: () => action('preview'),
            onEditStall: () => action('edit'),
            onMenu: () => action('menu'),
            onStock: () => action('stock'),
            onBookings: () => action('bookings'),
            onPaymentHistory: () => action('history'),
            onOpenBooking: (booking) => action('view:${booking.id}'),
            onAdvanceBooking: (booking) => action('advance:${booking.id}'),
          ),
        ),
        bottomNavigationBar: AppPillNavigation(
          selectedIndex: 0,
          onDestinationSelected: (_) {},
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.grid_view), label: 'Dashboard'),
            NavigationDestination(
                icon: Icon(Icons.settings), label: 'Settings'),
          ],
        ),
      ),
    ),
  );
}

void _viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _show(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
}

Future<void> _preview(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('DASHBOARD_PREVIEW')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('dashboard-preview')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('tmp/vendor-dashboard').create(recursive: true);
    await File('tmp/vendor-dashboard/$name.png')
        .writeAsBytes(data!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    if (!const bool.fromEnvironment('DASHBOARD_PREVIEW')) return;
    const fontRoot = String.fromEnvironment('PREVIEW_FONT_ROOT');
    final fonts = FontLoader('Roboto');
    for (final name in ['regular', 'medium', 'bold', 'black']) {
      final bytes = await File('$fontRoot/roboto-$name.ttf').readAsBytes();
      fonts.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await fonts.load();
    final fallback = FontLoader('Ahem')
      ..addFont(Future.value(ByteData.sublistView(
          await File('$fontRoot/roboto-regular.ttf').readAsBytes())));
    await fallback.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });

  testWidgets('stall controls, preview and each quick action are connected',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    final actions = <String>[];
    await tester.pumpWidget(_app(onAction: actions.add));
    expect(tester.getTopLeft(find.text('Your stall is open')).dy,
        lessThan(tester.getTopLeft(find.text('Quick actions')).dy));
    await tester.tap(find.text('Preview'));
    await tester.tap(find.text('Menu'));
    await tester.tap(find.text('Stock'));
    await tester.tap(find.text('Bookings').first);
    await tester.tap(find.byType(Switch).first);
    await tester.tap(find.byType(Switch).last);
    expect(actions, [
      'preview',
      'menu',
      'stock',
      'bookings',
      'open:false',
      'collect:false'
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('requests come first and expired requests are excluded',
      (tester) async {
    _viewport(tester, const Size(390, 1400));
    final actions = <String>[];
    await tester.pumpWidget(_app(bookings: [
      _booking('Daniel', 'preparing'),
      _booking('Old request', 'requested',
          expiresAt: DateTime.now().subtract(const Duration(minutes: 1))),
      _booking('Aisyah', 'requested'),
    ], onAction: actions.add));
    expect(find.text('Old request'), findsNothing);
    expect(tester.getTopLeft(find.text('Aisyah')).dy,
        lessThan(tester.getTopLeft(find.text('Daniel')).dy));
    await tester.tap(find.text('Review booking'));
    await tester.tap(find.text('Mark ready'));
    expect(actions, ['view:Aisyah', 'advance:Daniel']);
    expect(find.textContaining('Collect at'), findsNothing);
    expect(find.textContaining('Booked 24/10'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
    await _preview(tester, 'dashboard-full');
  });

  testWidgets('unpaid bookings cannot prepare and busy actions are disabled',
      (tester) async {
    _viewport(tester, const Size(390, 1400));
    await tester.pumpWidget(_app(bookings: [
      _booking('Unpaid', 'confirmed', paid: false),
      _booking('Paid', 'confirmed'),
    ], busy: {
      'Paid'
    }, saving: true));
    expect(find.text('Start preparing'), findsNothing);
    expect(find.text('Updating…'), findsOneWidget);
    expect(find.text('View booking'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull);
    for (final control in tester.widgetList<Switch>(find.byType(Switch))) {
      expect(control.onChanged, isNull);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('closure and location problems have clear recovery actions',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    final actions = <String>[];
    await tester.pumpWidget(
        _app(vendor: _vendor(temporaryClosure: true), onAction: actions.add));
    expect(find.text('Temporarily closed'), findsOneWidget);
    expect(tester.widget<Switch>(find.byType(Switch).first).onChanged, isNull);
    await tester.tap(find.text('Manage temporary closure'));
    expect(actions, ['edit']);
    await tester.pumpWidget(
        _app(sharing: true, locationError: 'Check GPS', onAction: actions.add));
    expect(find.text('Check GPS'), findsOneWidget);
    await tester.tap(find.text('Retry location'));
    expect(actions.last, 'resume');
    expect(tester.takeException(), isNull);
  });

  testWidgets('overview counts Malaysia dates and uses release wording',
      (tester) async {
    _viewport(tester, const Size(390, 1400));
    await tester.pumpWidget(_app(bookings: [
      _booking('Today', 'collected', createdAt: DateTime.utc(2026, 10, 23, 16)),
      _booking('Yesterday', 'collected',
          createdAt: DateTime.utc(2026, 10, 23, 15, 59)),
    ]));
    await _show(tester, find.text('Today’s overview'));
    expect(find.text('1'), findsOneWidget);
    expect(find.text('RM 24.00'), findsOneWidget);
    expect(find.text('Sales'), findsOneWidget);
    expect(
        find.textContaining(RegExp(r'test|demo|simulat', caseSensitive: false)),
        findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 720), const Size(960, 1000)]) {
    testWidgets('dashboard fits ${size.width} wide with enlarged text',
        (tester) async {
      _viewport(tester, size);
      await tester.pumpWidget(_app(scale: 1.6, bookings: [
        _booking('A customer with a very long name', 'confirmed'),
        _booking('Another customer', 'preparing'),
      ]));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await _show(tester, find.text('Edit my stall'));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('loading and failure do not present zero sales as real data',
      (tester) async {
    _viewport(tester, const Size(390, 1400));
    final actions = <String>[];
    await tester.pumpWidget(_app(error: true, onAction: actions.add));
    expect(find.text('Could not load bookings.'), findsOneWidget);
    expect(find.text('RM 0.00'), findsNothing);
    await tester.tap(find.text('Retry'));
    expect(actions, ['refresh']);
    await tester.pumpWidget(_app(loading: true));
    expect(find.text('Loading bookings…'), findsOneWidget);
    expect(find.text('No active bookings'), findsNothing);
    expect(find.text('RM 0.00'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
