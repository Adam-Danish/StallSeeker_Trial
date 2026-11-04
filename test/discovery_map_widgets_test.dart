import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/models/vendor_model.dart';
import 'package:stallseeker/features/customer/home/discovery_map_widgets.dart';
import 'package:stallseeker/features/customer/home/discovery_options.dart';
import 'package:stallseeker/features/customer/home/stall_preview_sheet.dart';
import 'package:stallseeker/features/customer/home/stall_map_marker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:stallseeker/core/models/stall_schedule.dart';

void main() {
  for (final kind in [PointerDeviceKind.touch, PointerDeviceKind.mouse]) {
    testWidgets('$kind double tap opens a card once without selecting it first',
        (tester) async {
      var selected = 0;
      var opened = 0;
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: Center(
        child: SizedBox(
            width: 350,
            height: 180,
            child: StallMapCard(
              vendor: _vendor(),
              onTap: () => selected++,
              onDoubleTap: () => opened++,
            )),
      ))));
      final title = find.text('Adam stalls');
      await tester.tap(title, kind: kind);
      await tester.pump(const Duration(milliseconds: 70));
      await tester.tap(title, kind: kind);
      await tester.pumpAndSettle();
      expect(opened, 1);
      expect(selected, 0);
      await tester.tap(title, kind: kind);
      await tester.pumpAndSettle(const Duration(milliseconds: 350));
      expect(selected, 1);
      expect(opened, 1);
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [320.0, 390.0, 1280.0]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
          'search stays beside or directly above cards at $width / $scale',
          (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var searched = false;
        var opened = false;
        await tester.pumpWidget(MaterialApp(
            home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(scale)),
          child: Scaffold(
              body: Builder(
                  builder: (context) => SizedBox(
                        height: DiscoveryResultsHeader.heightFor(context, width,
                            showSearchHere: true),
                        child: DiscoveryResultsHeader(
                            countLabel: '5 stalls nearby',
                            onViewAll: () => opened = true,
                            onSearchHere: () => searched = true),
                      ))),
        )));
        final search = find.byKey(const ValueKey('search-here'));
        final action = find.byKey(const ValueKey('view-all-stalls'));
        final count = find.text('5 stalls nearby');
        expect(tester.getCenter(search).dx, closeTo(width / 2, .01));
        final header = tester.getRect(find.byType(DiscoveryResultsHeader));
        if (width < 600 || scale > 1) {
          expect(tester.getRect(count).bottom,
              lessThan(tester.getRect(search).top));
          expect(
              header.bottom - tester.getRect(search).bottom, closeTo(8, .01));
        } else {
          expect(tester.getCenter(search).dy,
              closeTo(tester.getCenter(count).dy, .01));
          expect(
              header.bottom - tester.getRect(search).bottom, closeTo(8, .01));
        }
        expect(tester.getCenter(count).dy,
            closeTo(tester.getCenter(action).dy, .01));
        final label = tester.getRect(find.text('View all'));
        expect(tester.getRect(action).contains(label.topLeft), isTrue);
        expect(tester.getRect(action).contains(label.bottomRight), isTrue);
        expect(label.right, lessThan(width));
        await tester.tap(search);
        await tester.tap(action);
        expect(searched && opened, isTrue);
        expect(tester.takeException(), isNull);
      });
    }
  }
  for (final width in [390.0, 1280.0]) {
    testWidgets(
        'last card stops at the right edge without empty space at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const ids = ['a', 'b', 'c', 'd', 'e'];
      var selected = 'a';
      await tester.pumpWidget(MaterialApp(
          home: Scaffold(
              body: StatefulBuilder(
        builder: (_, setState) => SizedBox(
            height: 180,
            child: StallCardCarousel(
              ids: ids,
              selectedId: selected,
              cardsPerPage: width >= 600 ? 3 : 1,
              itemBuilder: (_, index) => Center(child: Text(ids[index])),
            )),
      ))));
      final strip = find.byKey(const ValueKey('stall-card-carousel'));
      await tester.drag(strip, const Offset(-6000, 0));
      await tester.pumpAndSettle();
      final controller = tester.widget<ListView>(strip).controller!;
      expect(controller.offset, controller.position.maxScrollExtent);
      expect(tester.getTopRight(find.byKey(const ValueKey('e'))).dx,
          closeTo(width - 12, .01));
      expect(selected, 'a');
      await tester.drag(strip, const Offset(-200, 0));
      await tester.pumpAndSettle();
      expect(controller.offset, controller.position.maxScrollExtent);
      await tester.drag(strip, const Offset(180, 0));
      await tester.pumpAndSettle();
      expect(controller.offset, lessThan(controller.position.maxScrollExtent));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'free scrolling retains a half-visible card through selection rebuilds',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var selected = 'a';
    late StateSetter update;
    const ids = ['a', 'b', 'c', 'd'];
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: StatefulBuilder(
      builder: (_, setState) {
        update = setState;
        return SizedBox(
            height: 180,
            child: StallCardCarousel(
              ids: ids,
              selectedId: selected,
              itemBuilder: (_, index) => Center(child: Text(ids[index])),
            ));
      },
    ))));
    final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('stall-card-carousel'))));
    await gesture.moveBy(const Offset(-230, 0));
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.up();
    await tester.pumpAndSettle();
    final controller = tester
        .widget<ListView>(find.byKey(const ValueKey('stall-card-carousel')))
        .controller!;
    final stoppedOffset = controller.offset;
    expect(selected, 'a');
    expect(stoppedOffset, greaterThan(180));
    expect(stoppedOffset, lessThan(300));
    update(() {});
    await tester.pumpAndSettle();
    expect(controller.offset, closeTo(stoppedOffset, .001));
    update(() => selected = 'd');
    await tester.pumpAndSettle();
    expect(controller.offset, controller.position.maxScrollExtent);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'tablet shows multiple compact cards and retains selection on rotation',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final ids = ['a', 'b', 'c', 'd', 'e', 'f'];
    var selected = 'a';
    var columns = 3;
    late StateSetter update;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: StatefulBuilder(
      builder: (_, setState) {
        update = setState;
        return SizedBox(
            height: 200,
            child: StallCardCarousel(
              ids: ids,
              selectedId: selected,
              cardsPerPage: columns,
              itemBuilder: (_, index) =>
                  Center(child: Text('Card ${ids[index]}')),
            ));
      },
    ))));
    for (final id in ['a', 'b', 'c']) {
      final center = tester.getCenter(find.text('Card $id'));
      expect(center.dx, inInclusiveRange(0, 1280));
    }
    await tester.drag(find.byKey(const ValueKey('stall-card-carousel')),
        const Offset(-1100, 0));
    await tester.pumpAndSettle();
    expect(selected, 'a');
    update(() => selected = 'c');
    await tester.pumpAndSettle();
    tester.view.physicalSize = const Size(834, 1194);
    update(() => columns = 2);
    await tester.pumpAndSettle();
    expect(selected, 'c');
    expect(tester.getCenter(find.text('Card c')).dx, inInclusiveRange(0, 834));
    expect(tester.takeException(), isNull);
  });

  test('landscape tablets retain a full header and centered carousel', () {
    for (final size in [
      const Size(1194, 834),
      const Size(1280, 600),
      const Size(834, 1194)
    ]) {
      final geometry = DiscoveryMapGeometry(size);
      expect(geometry.overlayWidth, size.width - 24);
      expect(geometry.cardWidth, lessThanOrEqualTo(420));
      expect(geometry.multipleCards, isTrue);
      expect(geometry.panelLeft + geometry.panelWidth / 2,
          closeTo(size.width / 2, .01));
    }
  });

  test('card closing time supports an overnight schedule', () {
    final vendor = _vendor().copyWith(weeklyHours: {
      1: [const StallHoursInterval(22 * 60, 2 * 60)]
    });
    expect(
        stallCardOpeningText(vendor, now: malaysiaInstant(2026, 11, 3, 1, 0)),
        'Closes 2 AM');
  });

  test('closed card shows the next scheduled opening day', () {
    final vendor = _vendor().copyWith(isOpen: false, weeklyHours: {
      6: [const StallHoursInterval(10 * 60, 18 * 60)]
    });
    expect(
        stallCardOpeningText(vendor, now: malaysiaInstant(2026, 11, 2, 11, 0)),
        'Opens Saturday');
  });

  test('temporary closure is included when finding the next opening', () {
    final vendor = _vendor().copyWith(
      weeklyHours: {
        1: [const StallHoursInterval(10 * 60, 18 * 60)]
      },
      temporaryClosures: [
        TemporaryClosure(malaysiaInstant(2026, 11, 2, 11, 0),
            malaysiaInstant(2026, 11, 2, 12, 0))
      ],
    );
    expect(
        stallCardOpeningText(vendor, now: malaysiaInstant(2026, 11, 2, 11, 30)),
        'Opens 12 PM');
  });

  testWidgets(
      'category, filter and nested sort use identical dropdown surfaces',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: DiscoveryMapFilters(
      category: null,
      openNow: true,
      sort: DiscoverySort.distance,
      availableOnly: false,
      selfCollectOnly: false,
      recentOnly: false,
      onCategory: (_) {},
      onOpenNow: (_) {},
      onSort: (_) {},
      onAvailable: (_) {},
      onSelfCollect: (_) {},
      onRecent: (_) {},
      onReset: () {},
      moreItems: const [],
    ))));
    Material surfaceFor(String text) => tester.widget<Material>(find
        .ancestor(
            of: find.text(text),
            matching: find
                .byWidgetPredicate((w) => w is Material && w.elevation == 8))
        .first);
    void checkSurface(Material surface) {
      expect(surface.color, Colors.white);
      expect(surface.surfaceTintColor, Colors.transparent);
      expect((surface.shape as RoundedRectangleBorder).borderRadius,
          BorderRadius.circular(20));
    }

    await tester.tap(find.byTooltip('Filter stalls'));
    await tester.pumpAndSettle();
    checkSurface(surfaceFor('Open now'));
    await tester.tap(find.text('Sort results'));
    await tester.pumpAndSettle();
    checkSurface(surfaceFor(DiscoverySort.distance.label));
    expect(find.byType(Checkbox), findsNothing);
    await tester.tapAt(const Offset(700, 550));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Choose stall category'));
    await tester.pumpAndSettle();
    checkSurface(surfaceFor('Beverages'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tablet card matches the reference hierarchy and content height',
      (tester) async {
    tester.view.physicalSize = const Size(834, 1194);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final geometry = DiscoveryMapGeometry(const Size(834, 1194));
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
      builder: (context) => SizedBox(
        width: geometry.cardWidth,
        height: StallMapCard.preferredHeight(
                context, geometry.panelWidth, [_vendor()],
                viewportFraction: geometry.viewportFraction,
                cardsPerPage: geometry.cardsPerPage) -
            10,
        child: StallMapCard(vendor: _vendor(), onTap: () {}),
      ),
    ))));
    await tester.pumpAndSettle();
    final surface =
        tester.getRect(find.byKey(const ValueKey('stall-map-card-surface')));
    final description =
        tester.getRect(find.byKey(const ValueKey('stall-card-description')));
    final photo =
        tester.getRect(find.byKey(const ValueKey('stall-card-thumbnail')));
    final title = tester.getRect(find.text('Adam stalls'));
    final category =
        tester.getRect(find.byKey(const ValueKey('stall-card-category')));
    final status =
        tester.getRect(find.byKey(const ValueKey('stall-card-status')));
    expect(surface.width, lessThan(500));
    expect(photo.size, const Size(64, 64));
    expect(tester.widget<Text>(find.text('Adam stalls')).style!.fontSize, 16);
    expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('stall-card-description')))
            .style!
            .fontSize,
        14);
    expect(surface.bottom - description.bottom, inInclusiveRange(13, 15));
    expect(title.top, closeTo(photo.top, 1));
    expect(category.top, greaterThan(title.bottom));
    expect(status.top, greaterThan(category.bottom));
    expect(description.left, closeTo(photo.left, 1));
    expect(description.top, greaterThan(photo.bottom));
    expect(
        tester
            .widget<Text>(find.byKey(const ValueKey('stall-card-description')))
            .maxLines,
        3);
    expect(tester.takeException(), isNull);
  });

  testWidgets('category remains a compact pill on a tablet', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: DiscoveryMapFilters(
      category: null,
      openNow: false,
      sort: DiscoverySort.distance,
      availableOnly: false,
      selfCollectOnly: false,
      recentOnly: false,
      onCategory: (_) {},
      onOpenNow: (_) {},
      onSort: (_) {},
      onAvailable: (_) {},
      onSelfCollect: (_) {},
      onRecent: (_) {},
      onReset: () {},
      moreItems: const [],
    ))));
    expect(tester.getSize(find.byTooltip('Choose stall category')).width,
        lessThan(250));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'circular markers render distinct selected and normal PNGs and reuse the cache',
      (tester) async {
    final cache = StallMapMarkerCache();
    final normal = cache.icon('Beverages', selected: false);
    expect(identical(normal, cache.icon('Beverages', selected: false)), isTrue);
    final icons = await tester.runAsync(() => Future.wait([
          normal,
          cache.icon('Beverages', selected: true),
        ]));
    final light = icons![0] as BytesMapBitmap;
    final selected = icons[1] as BytesMapBitmap;
    expect(light.byteData.take(4), [137, 80, 78, 71]);
    expect(light.byteData, isNot(equals(selected.byteData)));
    expect(light.imagePixelRatio, 3);
  });
  testWidgets(
      'scroll preserves selection; explicit marker selection reveals its card',
      (tester) async {
    var selected = 'a';
    var ids = ['a', 'b', 'c'];
    late StateSetter update;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: StatefulBuilder(
      builder: (context, setState) {
        update = setState;
        return SizedBox(
            height: 200,
            child: StallCardCarousel(
              ids: ids,
              selectedId: selected,
              itemBuilder: (_, index) => Center(child: Text(ids[index])),
            ));
      },
    ))));
    await tester.drag(find.byKey(const ValueKey('stall-card-carousel')),
        const Offset(-750, 0));
    await tester.pumpAndSettle();
    expect(selected, 'a');
    update(() => selected = 'c');
    await tester.pumpAndSettle();
    expect(selected, 'c');
    final controller = tester
        .widget<ListView>(find.byKey(const ValueKey('stall-card-carousel')))
        .controller!;
    expect(controller.offset, controller.position.maxScrollExtent);
    update(() {
      ids = ['c'];
    });
    await tester.pumpAndSettle();
    expect(selected, 'c');
    expect(tester.takeException(), isNull);
  });

  testWidgets('filter menu keeps multiple checked options active',
      (tester) async {
    var open = false;
    var sort = DiscoverySort.distance;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: StatefulBuilder(
      builder: (_, setState) => DiscoveryMapFilters(
        category: null,
        openNow: open,
        sort: sort,
        availableOnly: false,
        selfCollectOnly: false,
        recentOnly: false,
        onCategory: (_) {},
        onOpenNow: (value) => setState(() => open = value),
        onSort: (value) => setState(() => sort = value),
        onAvailable: (_) {},
        onSelfCollect: (_) {},
        onRecent: (_) {},
        onReset: () {},
        moreItems: const [],
      ),
    ))));
    await tester.tap(find.byTooltip('Filter stalls'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open now'));
    await tester.pumpAndSettle();
    expect(open, isTrue);
    await tester.tap(find.text('Top rated'));
    await tester.pumpAndSettle();
    expect(sort, DiscoverySort.rating);
    expect(find.text('Open now'), findsOneWidget);
    expect(find.text('Top rated'), findsOneWidget);
  });

  testWidgets('reference card fits a small phone with enlarged text',
      (tester) async {
    tester.view.reset();
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(2)),
      child: Scaffold(
          body: SizedBox(
              height: 220,
              child: StallMapCard(
                vendor: _vendor(),
                onTap: () {},
              ))),
    )));
    await tester.pumpAndSettle();
    expect(find.text('Adam stalls'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('preview collapses, expands to full screen and closes',
      (tester) async {
    final extents = <double>[];
    var closed = false;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: SizedBox(
      height: 700,
      child: StallPreviewSheet(
        vendor: _vendor(),
        rating: const Text('★ 4.8'),
        distance: '229 m away',
        photos: const [],
        following: false,
        onFollow: () {},
        onDirections: () {},
        onViewMenu: () {},
        onSelfCollect: () {},
        onDetails: () {},
        onClose: () => closed = true,
        onExtentChanged: extents.add,
      ),
    ))));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Collapse preview'));
    await tester.pumpAndSettle();
    expect(extents.last, closeTo(.28, .005));
    await tester.tap(find.byTooltip('Full screen'));
    await tester.pumpAndSettle();
    expect(extents.last, closeTo(1, .005));
    await tester.tap(find.byTooltip('Close preview'));
    await tester.pumpAndSettle();
    expect(closed, isTrue);
    expect(tester.takeException(), isNull);
  });
}

VendorModel _vendor() => VendorModel(
      vendorId: 'adam',
      stallName: 'Adam stalls',
      category: 'Beverages',
      description:
          'Fresh drinks and refreshments near German-Malaysian Institute.',
      openingHours: '10 AM – 8 PM',
      isOpen: true,
      selfCollectEnabled: true,
    );
