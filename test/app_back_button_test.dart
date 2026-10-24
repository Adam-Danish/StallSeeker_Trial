import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/theme/app_theme.dart';
import 'package:stallseeker/core/widgets/app_back_button.dart';
import 'package:stallseeker/core/widgets/app_page_app_bar.dart';
import 'package:stallseeker/core/widgets/app_sheet_header.dart';
import 'package:stallseeker/features/shared/info_page.dart';
import 'package:stallseeker/features/vendor/profile/unsaved_stall_changes_guard.dart';

Widget app(Widget Function(BuildContext) page, {double scale = 1}) =>
    MaterialApp(
      theme: AppTheme.lightTheme,
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      home: Builder(
          builder: (context) => Scaffold(
              appBar: const AppPageAppBar(title: Text('Home')),
              body: TextButton(
                  onPressed: () =>
                      Navigator.push(context, MaterialPageRoute(builder: page)),
                  child: const Text('Open page')))),
    );

void main() {
  for (final width in [320.0, 390.0, 960.0]) {
    for (final scale in [1.0, 1.6, 2.0]) {
      testWidgets('back navigation fits $width px with $scale text',
          (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(app(
            (_) => Scaffold(
                appBar: AppPageAppBar(
                    title: const Text('Stall details'),
                    actions: [
                      IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.favorite_outline))
                    ]),
                body: const Text('Page content')),
            scale: scale));
        expect(find.byType(AppBackButton), findsNothing);
        await tester.tap(find.text('Open page'));
        await tester.pumpAndSettle();
        expect(find.text('Back'), findsOneWidget);
        final back = tester.getRect(find.byType(AppBackButton));
        expect(back.left, closeTo(16, 1));
        expect(back.top, lessThan(80));
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Back'));
        await tester.pumpAndSettle();
        expect(find.text('Open page'), findsOneWidget);
        expect(find.text('Page content'), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('information pages use the same back navigation', (tester) async {
    await tester.pumpWidget(app((_) => const InfoPage(
        title: 'About StallSeeker', children: [Text('Information')])));
    await tester.tap(find.text('Open page'));
    await tester.pumpAndSettle();
    expect(find.byType(AppBackButton), findsOneWidget);
    expect(tester.getRect(find.byType(AppBackButton)).left, closeTo(16, 1));
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Open page'), findsOneWidget);
  });

  for (final width in [320.0, 960.0]) {
    testWidgets('sheet close button is at top left at $width px',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightTheme,
          home: Builder(
              builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () => showModalBottomSheet<void>(
                          context: context,
                          builder: (_) => const SizedBox(
                              height: 350,
                              child: Column(children: [
                                AppSheetHeader(title: Text('Saved searches')),
                                Expanded(
                                    child:
                                        Center(child: Text('Sheet content'))),
                              ]))),
                      child: const Text('Open sheet'))))));
      await tester.tap(find.text('Open sheet'));
      await tester.pumpAndSettle();
      final header = tester.getRect(find.byType(AppSheetHeader));
      final close = tester.getRect(find.byType(AppBackButton));
      expect(close.left, closeTo(header.left + 16, 1));
      expect(close.top, closeTo(header.top + 12, 1));
      expect(close.top,
          lessThan(tester.getTopLeft(find.text('Saved searches')).dy));
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Sheet content'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a disabled back button cannot leave while saving',
      (tester) async {
    await tester.pumpWidget(app((_) => const Scaffold(
        appBar: AppPageAppBar(title: Text('Saving'), backEnabled: false),
        body: Text('Editor'))));
    await tester.tap(find.text('Open page'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Editor'), findsOneWidget);
    expect(find.text('Open page'), findsNothing);
  });

  for (final customBack in [false, true]) {
    testWidgets('back keeps the unsaved-changes prompt (custom: $customBack)',
        (tester) async {
      final guard = GlobalKey<UnsavedStallChangesGuardState>();
      await tester.pumpWidget(app((_) => UnsavedStallChangesGuard(
          key: guard,
          hasChanges: true,
          saving: false,
          onSave: () async {},
          child: Scaffold(
              appBar: AppPageAppBar(
                  title: const Text('Edit stall'),
                  backLabel: 'Cancel',
                  onBack: customBack
                      ? () => guard.currentState!.requestLeave()
                      : null),
              body: const Text('Unsaved editor')))));
      await tester.tap(find.text('Open page'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Save your changes?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.text('Unsaved editor'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard changes'));
      await tester.pumpAndSettle();
      expect(find.text('Open page'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
