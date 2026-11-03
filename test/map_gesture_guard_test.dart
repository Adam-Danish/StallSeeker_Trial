import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:stallseeker/core/models/vendor_model.dart';
import 'package:stallseeker/core/widgets/map_gesture_guard.dart';
import 'package:stallseeker/core/widgets/map_overlay.dart';
import 'package:stallseeker/features/customer/home/stall_preview_sheet.dart';

const mapKey = ValueKey('map-surface');

void main() {
  testWidgets('overlay interception leaves the guarded map interactive',
      (tester) async {
    var mapEvents = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Stack(children: [
          interceptMapOverlay(Positioned.fill(
            child: MapGestureGuard(
              blocked: false,
              builder: (_, blocked) => Listener(
                key: mapKey,
                behavior: HitTestBehavior.opaque,
                onPointerMove: (_) => mapEvents++,
                child: const SizedBox.expand(),
              ),
            ),
          )),
        ]),
      ),
    ));
    expect(find.byType(PointerInterceptor), findsNothing);
    await tester.drag(find.byKey(mapKey), const Offset(50, 20));
    expect(mapEvents, greaterThan(0));
  });

  for (final width in [390.0, 1280.0]) {
    testWidgets('View all scrolls independently and restores the map at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final listController = ScrollController();
      addTearDown(listController.dispose);
      var mapBlocked = false;
      var mapEvents = 0;
      late BuildContext homeContext;
      await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
        homeContext = context;
        return Scaffold(
          body: MapGestureGuard(
            blocked: false,
            builder: (_, blocked) {
              mapBlocked = blocked;
              return Listener(
                key: mapKey,
                behavior: HitTestBehavior.opaque,
                onPointerSignal: (_) => mapEvents++,
                onPointerMove: (_) => mapEvents++,
                child: const SizedBox.expand(),
              );
            },
          ),
        );
      })));
      expect(mapBlocked, isFalse);
      final sheet = showModalBottomSheet<int>(
        context: homeContext,
        isScrollControlled: true,
        builder: (context) => PointerInterceptor(
          child: SizedBox(
            height: 500,
            child: ListView.builder(
              controller: listController,
              itemExtent: 64,
              itemCount: 50,
              itemBuilder: (context, index) => ListTile(
                title: Text('Stall $index'),
                onTap: () => Navigator.pop(context, index),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(mapBlocked, isTrue);
      final list = find.byType(ListView);
      await tester.sendEventToBinding(PointerScrollEvent(
        position: tester.getCenter(list),
        scrollDelta: const Offset(0, 180),
      ));
      await tester.pumpAndSettle();
      expect(listController.offset, greaterThan(0));
      final wheelOffset = listController.offset;
      await tester.drag(list, const Offset(0, -180));
      await tester.pumpAndSettle();
      expect(listController.offset, greaterThan(wheelOffset));
      expect(mapEvents, 0);
      // Exposed map area also stays still while the modal is open.
      await tester.sendEventToBinding(const PointerScrollEvent(
        position: Offset(100, 100),
        scrollDelta: Offset(0, 180),
      ));
      await tester.pumpAndSettle();
      expect(mapEvents, 0);
      await tester.tap(find.byType(ListTile).hitTestable().first);
      await tester.pumpAndSettle();
      expect(await sheet, isA<int>());
      expect(mapBlocked, isFalse);
      await tester.drag(find.byKey(mapKey), const Offset(50, 20));
      expect(mapEvents, greaterThan(0));
      expect(tester.takeException(), isNull);
    });

    testWidgets('stall preview scrolls and resizes without map input at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var previewOpen = true;
      var mapBlocked = false;
      var mapEvents = 0;
      final extents = <double>[];
      await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(disableAnimations: true),
                child: child!,
              ),
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: Stack(children: [
                Positioned.fill(
                  child: MapGestureGuard(
                    blocked: previewOpen,
                    builder: (_, blocked) {
                      mapBlocked = blocked;
                      return Listener(
                        key: mapKey,
                        behavior: HitTestBehavior.opaque,
                        onPointerMove: (_) => mapEvents++,
                        onPointerSignal: (_) => mapEvents++,
                        child: const SizedBox.expand(),
                      );
                    },
                  ),
                ),
                if (previewOpen)
                  interceptMapOverlay(Positioned.fill(
                    child: StallPreviewSheet(
                      vendor: VendorModel(
                        vendorId: 'stall',
                        stallName: 'Test stall',
                        description:
                            List.filled(100, 'Stall details.').join(' '),
                        category: 'Beverages',
                        openingHours: '9 AM - 5 PM',
                      ),
                      rating: const Text('4.8'),
                      distance: '100 m away',
                      photos: const [],
                      following: false,
                      onFollow: () {},
                      onDirections: () {},
                      onViewMenu: () {},
                      onSelfCollect: () {},
                      onDetails: () {},
                      onClose: () => setState(() => previewOpen = false),
                      onExtentChanged: extents.add,
                    ),
                  )),
              ]),
            ),
          )));
      expect(mapBlocked, isTrue);
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, -220));
      await tester.pumpAndSettle();
      expect(extents.any((extent) => extent > .55), isTrue);
      expect(find.byTooltip('Exit full screen'), findsOneWidget);
      final scroll = tester.widget<ListView>(find.byType(ListView)).controller!;
      final initialOffset = scroll.offset;
      await tester.sendEventToBinding(PointerScrollEvent(
        position: tester.getCenter(find.byType(ListView)),
        scrollDelta: const Offset(0, 220),
      ));
      await tester.pumpAndSettle();
      expect(scroll.offset, greaterThan(initialOffset));
      expect(mapEvents, 0);
      await tester.drag(find.byType(ListView), const Offset(0, 5000));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, 1000));
      await tester.pumpAndSettle();
      expect(find.byType(StallPreviewSheet), findsNothing);
      expect(mapBlocked, isFalse);
      await tester.drag(find.byKey(mapKey), const Offset(30, 10));
      expect(mapEvents, greaterThan(0));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('full details route disables map until back navigation',
      (tester) async {
    var mapBlocked = false;
    late BuildContext homeContext;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      homeContext = context;
      return MapGestureGuard(
        blocked: false,
        builder: (_, blocked) {
          mapBlocked = blocked;
          return const SizedBox.expand();
        },
      );
    })));
    final route = Navigator.of(homeContext).push(MaterialPageRoute<void>(
      builder: (_) => const Scaffold(body: Text('Stall details')),
    ));
    await tester.pumpAndSettle();
    expect(mapBlocked, isTrue);
    Navigator.of(homeContext).pop();
    await tester.pumpAndSettle();
    await route;
    expect(mapBlocked, isFalse);
  });
}
