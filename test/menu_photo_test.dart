import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/widgets/menu_photo.dart';

const _photoUrl = 'https://example.com/menu-photo.png';

Future<void> _openPhoto(WidgetTester tester) async {
  // Supply a real decoded image without depending on an external server. This
  // also works in Chrome, where dart:io HTTP overrides are unavailable.
  await tester.runAsync(() async {
    final image = await createTestImage(width: 400, height: 800);
    PaintingBinding.instance.imageCache.putIfAbsent(
      const NetworkImage(_photoUrl),
      () => OneFrameImageStreamCompleter(Future.value(ImageInfo(image: image))),
    );
  });
  await tester.pumpWidget(const MaterialApp(
    home: Scaffold(
      body: Center(
        child: MenuPhotoThumbnail(imageUrl: _photoUrl, dishName: 'Nasi lemak'),
      ),
    ),
  ));
  await tester.pumpAndSettle();
  await tester.tap(find.byType(MenuPhotoThumbnail));
  await tester.pumpAndSettle();
}

TransformationController _controller(WidgetTester tester) => tester
    .widget<InteractiveViewer>(find.byType(InteractiveViewer))
    .transformationController!;

double _scale(WidgetTester tester) =>
    _controller(tester).value.getMaxScaleOnAxis();

void main() {
  testWidgets('thumbnail opens an uncropped photo and close returns to menu',
      (tester) async {
    await _openPhoto(tester);
    expect(find.byType(MenuPhotoViewer), findsOneWidget);
    expect(find.text('Nasi lemak'), findsOneWidget);
    final photo = tester.widget<Image>(find.descendant(
        of: find.byType(InteractiveViewer), matching: find.byType(Image)));
    expect(photo.fit, BoxFit.contain);
    await tester.tap(find.byTooltip('Close photo'));
    await tester.pumpAndSettle();
    expect(find.byType(MenuPhotoViewer), findsNothing);
    expect(find.byType(MenuPhotoThumbnail), findsOneWidget);
  });

  testWidgets('zoom controls stop at limits and Fit restores the whole photo',
      (tester) async {
    await _openPhoto(tester);
    expect(
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.remove))
            .onPressed,
        isNull);
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byTooltip('Zoom in'), warnIfMissed: false);
      await tester.pump();
    }
    expect(_scale(tester), 5);
    expect(
        tester
            .widget<IconButton>(find.widgetWithIcon(IconButton, Icons.add))
            .onPressed,
        isNull);
    await tester.tap(find.byTooltip('Zoom out'));
    await tester.pump();
    expect(_scale(tester), closeTo(5 / 1.5, 0.001));
    await tester.tap(find.text('Fit'));
    await tester.pump();
    expect(_controller(tester).value, Matrix4.identity());
    expect(find.text('100%'), findsOneWidget);
  });

  testWidgets('double tap zooms at the tapped point and toggles back to fit',
      (tester) async {
    await _openPhoto(tester);
    final point = tester.getTopLeft(find.byType(InteractiveViewer)) +
        const Offset(90, 120);
    await tester.tapAt(point);
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tapAt(point);
    await tester.pumpAndSettle();
    expect(_scale(tester), 2.5);
    expect(_controller(tester).value.getTranslation().x, closeTo(-135, 0.01));
    await tester.tapAt(point);
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tapAt(point);
    await tester.pumpAndSettle();
    expect(_controller(tester).value, Matrix4.identity());
  });

  testWidgets('touch pinch zooms and a drag pans the enlarged photo',
      (tester) async {
    await _openPhoto(tester);
    final center = tester.getCenter(find.byType(InteractiveViewer));
    final first =
        await tester.startGesture(center - const Offset(35, 0), pointer: 1);
    final second =
        await tester.startGesture(center + const Offset(35, 0), pointer: 2);
    await first.moveBy(const Offset(-30, 0));
    await second.moveBy(const Offset(30, 0));
    await tester.pump();
    await first.moveBy(const Offset(-40, 0));
    await second.moveBy(const Offset(40, 0));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pumpAndSettle();
    expect(_scale(tester), greaterThan(1));
    final before = _controller(tester).value.clone();
    await tester.drag(find.byType(InteractiveViewer), const Offset(30, 20));
    await tester.pumpAndSettle();
    expect(_controller(tester).value, isNot(before));
  });

  testWidgets('mouse wheel zooms and keyboard can zoom, fit, and close',
      (tester) async {
    await _openPhoto(tester);
    await tester.sendEventToBinding(PointerScrollEvent(
      position: tester.getCenter(find.byType(InteractiveViewer)),
      scrollDelta: const Offset(0, -120),
    ));
    await tester.pumpAndSettle();
    expect(_scale(tester), greaterThan(1));
    await tester.sendKeyEvent(LogicalKeyboardKey.digit0);
    await tester.pump();
    expect(_scale(tester), 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.equal);
    await tester.pump();
    expect(_scale(tester), 1.5);
    await tester.sendKeyEvent(LogicalKeyboardKey.minus);
    await tester.pump();
    expect(_scale(tester), 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(MenuPhotoViewer), findsNothing);
  });

  testWidgets('small phone and resized wide viewport have no layout errors',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _openPhoto(tester);
    await tester.tap(find.byTooltip('Zoom in'));
    await tester.pump();
    expect(_scale(tester), greaterThan(1));
    await tester.binding.setSurfaceSize(const Size(1200, 700));
    await tester.pumpAndSettle();
    expect(_scale(tester), 1);
    expect(tester.takeException(), isNull);
    await tester.binding.setSurfaceSize(const Size(568, 320));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('missing photo stays a placeholder without opening a viewer',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: MenuPhotoThumbnail(imageUrl: '', dishName: 'Nasi lemak'),
      ),
    ));
    await tester.tap(find.byType(MenuPhotoThumbnail));
    await tester.pumpAndSettle();
    expect(find.byType(MenuPhotoViewer), findsNothing);
    expect(find.byIcon(Icons.restaurant), findsOneWidget);
  });

  testWidgets('failed photo offers retry and can still be closed',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: MenuPhotoThumbnail(
            imageUrl: 'https://example.invalid/missing.jpg',
            dishName: 'Nasi lemak'),
      ),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(MenuPhotoThumbnail));
    await tester.pumpAndSettle();
    expect(find.text('Could not load photo.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Could not load photo.'), findsOneWidget);
    await tester.tap(find.byTooltip('Close photo'));
    await tester.pumpAndSettle();
    expect(find.byType(MenuPhotoViewer), findsNothing);
  }, skip: kIsWeb); // The VM test HTTP client returns a deterministic failure.
}
