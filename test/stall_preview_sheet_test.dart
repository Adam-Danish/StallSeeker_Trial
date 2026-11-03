import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/models/vendor_model.dart';
import 'package:stallseeker/core/theme/app_theme.dart';
import 'package:stallseeker/core/widgets/app_pill_navigation.dart';
import 'package:stallseeker/features/customer/home/stall_preview_sheet.dart';

const _surface = Key('stall-preview-surface');

class _PreviewHarness extends StatefulWidget {
  const _PreviewHarness({this.reducedMotion = false});
  final bool reducedMotion;

  @override
  State<_PreviewHarness> createState() => _PreviewHarnessState();
}

class _PreviewHarnessState extends State<_PreviewHarness> {
  final extent = ValueNotifier(StallPreviewSheet.initialExtent);
  bool open = true;

  @override
  void dispose() {
    extent.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        theme: AppTheme.lightTheme,
        home: MediaQuery(
          data: MediaQueryData(
            size: MediaQuery.sizeOf(context),
            padding: const EdgeInsets.only(top: 24, bottom: 20),
            viewPadding: const EdgeInsets.only(top: 24, bottom: 20),
            disableAnimations: widget.reducedMotion,
          ),
          child: Scaffold(
            extendBody: true,
            body: SafeArea(
              bottom: false,
              child: Stack(children: [
                const Positioned.fill(child: ColoredBox(color: Colors.green)),
                if (open)
                  Positioned.fill(
                    child: StallPreviewSheet(
                      vendor: VendorModel(
                        vendorId: 'tea',
                        stallName: 'Teh Tarik John',
                        description:
                            List.filled(20, 'Freshly brewed tea.').join(' '),
                        category: 'Beverages',
                        openingHours: '9 AM – 5 PM',
                      ),
                      rating: const Text('4.8 (4 reviews)'),
                      distance: '7 m away',
                      photos: const [],
                      following: false,
                      horizontalInset: 32,
                      bottomInset: 98,
                      onFollow: () {},
                      onDirections: () {},
                      onViewMenu: () {},
                      onSelfCollect: () {},
                      onDetails: () {},
                      onClose: () => setState(() => open = false),
                      onExtentChanged: (value) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) extent.value = value;
                        });
                      },
                    ),
                  ),
              ]),
            ),
            bottomNavigationBar: ValueListenableBuilder<double>(
              valueListenable: extent,
              builder: (_, value, child) => AppPillNavigation(
                visibility:
                    open ? 1 - StallPreviewSheet.expansionProgress(value) : 1,
                selectedIndex: 0,
                onDestinationSelected: (_) {},
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
                  NavigationDestination(
                      icon: Icon(Icons.favorite), label: 'Following'),
                ],
              ),
            ),
          ),
        ),
      );
}

double _navOpacity(WidgetTester tester) => tester
    .widget<Opacity>(find.descendant(
        of: find.byType(AppPillNavigation), matching: find.byType(Opacity)))
    .opacity;

Future<void> _mount(WidgetTester tester, Size size,
    {bool reducedMotion = false, bool settle = true}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(_PreviewHarness(reducedMotion: reducedMotion));
  if (settle) await tester.pumpAndSettle();
}

void _expectFullScreen(WidgetTester tester, Size size) {
  final rect = tester.getRect(find.byKey(_surface));
  expect(rect.left, closeTo(0, .1));
  expect(rect.top, closeTo(24, .1));
  expect(rect.right, closeTo(size.width, .1));
  expect(rect.bottom, closeTo(size.height, .1));
  expect(_navOpacity(tester), 0);
  expect(find.text('Home').hitTestable(), findsNothing);
  expect(find.byTooltip('Exit full screen'), findsOneWidget);
  expect(tester.takeException(), isNull);
}

void main() {
  for (final width in [390.0, 960.0]) {
    testWidgets('preview slides in from the bottom at $width', (tester) async {
      const height = 844.0;
      await _mount(tester, Size(width, height), settle: false);
      expect(tester.getRect(find.byKey(_surface)).top, closeTo(height, .1));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final during = tester.getRect(find.byKey(_surface));
      final finalTop =
          24 + (height - 24) * (1 - StallPreviewSheet.initialExtent);
      expect(during.top, inExclusiveRange(finalTop, height));
      await tester.pumpAndSettle();
      expect(tester.getRect(find.byKey(_surface)).top, closeTo(finalTop, .1));
      expect(find.byTooltip('Full screen').hitTestable(), findsOneWidget);
      expect(_navOpacity(tester), 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('reduced motion skips the entrance animation', (tester) async {
    await _mount(tester, const Size(390, 844),
        reducedMotion: true, settle: false);
    await tester.pump();
    expect(tester.getRect(find.byKey(_surface)).top,
        closeTo(24 + 820 * (1 - StallPreviewSheet.initialExtent), .1));
    expect(tester.hasRunningAnimations, isFalse);
  });

  test('subpixel snap differences restore navigation completely', () {
    expect(StallPreviewSheet.expansionProgress(.55009), 0);
    expect(StallPreviewSheet.expansionProgress(.99995), 1);
    expect(StallPreviewSheet.expansionProgress(.775), closeTo(.5, .001));
  });
  for (final size in [
    const Size(390, 844),
    const Size(960, 800),
    const Size(844, 390)
  ]) {
    testWidgets('fullscreen animates and restores navigation at $size',
        (tester) async {
      await _mount(tester, size);
      final initial = tester.getRect(find.byKey(_surface));
      expect(_navOpacity(tester), 1);
      await tester.tap(find.byTooltip('Full screen'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();
      final during = tester.getRect(find.byKey(_surface));
      expect(during.top, lessThan(initial.top));
      expect(during.top, greaterThan(24));
      expect(_navOpacity(tester), inExclusiveRange(0, 1));
      await tester.pumpAndSettle();
      _expectFullScreen(tester, size);

      await tester.tap(find.byTooltip('Exit full screen'));
      await tester.pumpAndSettle();
      expect(
          tester.getRect(find.byKey(_surface)).top, closeTo(initial.top, .1));
      expect(_navOpacity(tester), 1);
      expect(find.text('Home').hitTestable(), findsOneWidget);

      await tester.tap(find.byTooltip('Full screen'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Close preview'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(_surface), findsOneWidget);
      expect(tester.getRect(find.byKey(_surface)).top, greaterThan(24));
      await tester.pumpAndSettle();
      expect(find.byKey(_surface), findsNothing);
      expect(_navOpacity(tester), 1);
      expect(tester.takeException(), isNull);
    });
  }

  for (final kind in [PointerDeviceKind.touch, PointerDeviceKind.mouse]) {
    testWidgets('$kind drag expands, scrolls, and dismisses to cards',
        (tester) async {
      const size = Size(390, 844);
      await _mount(tester, size);
      final gesture = await tester.startGesture(
          tester.getTopLeft(find.byKey(_surface)) + const Offset(150, 15),
          kind: kind);
      await gesture.moveBy(const Offset(0, -500));
      await gesture.up();
      await tester.pumpAndSettle();
      _expectFullScreen(tester, size);
      await tester.drag(find.byType(ListView), const Offset(0, -450),
          kind: kind);
      await tester.pumpAndSettle();
      expect(find.text('Full stall details & reviews').hitTestable(),
          findsOneWidget);
      expect(_navOpacity(tester), 0);
      await tester.drag(find.byType(ListView), const Offset(0, 1500),
          kind: kind);
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView), const Offset(0, 1000),
          kind: kind);
      await tester.pumpAndSettle();
      expect(find.byKey(_surface), findsNothing);
      expect(_navOpacity(tester), 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('dragging the preview to the bottom dismisses it',
      (tester) async {
    await _mount(tester, const Size(390, 844));
    await tester.drag(find.byType(ListView), const Offset(0, 700));
    await tester.pumpAndSettle();
    expect(find.byKey(_surface), findsNothing);
    expect(find.text('Home').hitTestable(), findsOneWidget);
    expect(_navOpacity(tester), 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'reduced motion expands immediately and Back collapses then closes',
      (tester) async {
    const size = Size(390, 844);
    await _mount(tester, size, reducedMotion: true);
    await tester.tap(find.byTooltip('Full screen'));
    await tester.pumpAndSettle();
    _expectFullScreen(tester, size);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byTooltip('Full screen'), findsOneWidget);
    expect(_navOpacity(tester), 1);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.byKey(_surface), findsNothing);
    expect(_navOpacity(tester), 1);
  });
}
