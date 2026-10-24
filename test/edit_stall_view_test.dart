import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/models/stall_schedule.dart';
import 'package:stallseeker/core/models/vendor_model.dart';
import 'package:stallseeker/core/theme/app_theme.dart';
import 'package:stallseeker/features/vendor/profile/edit_stall_view.dart';
import 'package:stallseeker/features/vendor/profile/stall_profile_draft.dart';

class _Harness extends StatefulWidget {
  const _Harness(
      {this.saving = false,
      this.loading = false,
      this.picking = false,
      this.onAction});
  final bool saving, loading, picking;
  final ValueChanged<String>? onAction;
  @override
  State<_Harness> createState() => _HarnessState();
}

class _HarnessState extends State<_Harness> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(text: 'Uncle John Drink Stall');
  final description = TextEditingController(
      text: 'Freshly brewed teh tarik and refreshing local drinks.');
  final phone = TextEditingController(text: '012-345 6789');
  final categories = <String>{'Beverages'};
  Map<int, List<StallHoursInterval>> hours = {
    for (var day = 1; day <= 5; day++)
      day: [const StallHoursInterval(540, 1020)]
  };
  List<TemporaryClosure> closures = [];
  @override
  void dispose() {
    name.dispose();
    description.dispose();
    phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => EditStallView(
        formKey: form,
        nameController: name,
        descriptionController: description,
        phoneController: phone,
        image: Container(
            height: 180,
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(20)),
            alignment: Alignment.center,
            child: FilledButton.icon(
                onPressed: widget.saving || widget.picking
                    ? null
                    : () => widget.onAction?.call('photo'),
                icon: const Icon(Icons.camera_alt_outlined),
                label: const Text('Change photo'))),
        categoryOptions: const ['Beverages', 'Burger', 'Malay Food'],
        selectedCategories: categories,
        hours: hours,
        closures: closures,
        loading: widget.loading,
        saving: widget.saving,
        pickingImage: widget.picking,
        onCategoryChanged: (category, selected) => setState(() {
          if (selected) {
            categories.add(category);
          } else {
            categories.remove(category);
          }
        }),
        onScheduleChanged: (nextHours, nextClosures) => setState(() {
          hours = nextHours;
          closures = nextClosures;
        }),
        onFormChanged: () => setState(() {}),
        onCancel: () => widget.onAction?.call('cancel'),
        onSave: () {
          if (form.currentState!.validate()) {
            widget.onAction?.call('save:${name.text}');
          }
        },
        onPreview: () => widget.onAction?.call('preview:${name.text}'),
      );
}

ThemeData _previewTheme() {
  final theme = AppTheme.lightTheme;
  if (!const bool.fromEnvironment('EDIT_STALL_PREVIEW')) {
    return theme;
  }
  return theme.copyWith(
    appBarTheme: theme.appBarTheme.copyWith(
        titleTextStyle:
            theme.appBarTheme.titleTextStyle?.copyWith(fontFamily: 'Roboto')),
    chipTheme: theme.chipTheme.copyWith(
        labelStyle: theme.chipTheme.labelStyle?.copyWith(fontFamily: 'Roboto')),
  );
}

Widget _app(
        {double scale = 1,
        bool saving = false,
        bool loading = false,
        bool picking = false,
        ValueChanged<String>? onAction}) =>
    MaterialApp(
      theme: _previewTheme(),
      builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!),
      home: RepaintBoundary(
          key: const Key('edit-stall-preview'),
          child: _Harness(
              saving: saving,
              loading: loading,
              picking: picking,
              onAction: onAction)),
    );
void _viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('EDIT_STALL_PREVIEW')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const Key('edit-stall-preview')));
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('tmp/edit-stall-previews').create(recursive: true);
    await File('tmp/edit-stall-previews/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    if (!const bool.fromEnvironment('EDIT_STALL_PREVIEW')) return;
    const root = String.fromEnvironment('PREVIEW_FONT_ROOT');
    final font = FontLoader('Roboto');
    for (final name in ['Regular', 'Medium']) {
      font.addFont(Future.value(ByteData.sublistView(
          await File('$root/Roboto-$name.ttf').readAsBytes())));
    }
    await font.load();
    final fallback = FontLoader('Ahem')
      ..addFont(Future.value(ByteData.sublistView(
          await File('$root/Roboto-Regular.ttf').readAsBytes())));
    await fallback.load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  test('draft changes profile fields without changing live operational state',
      () {
    final original = VendorModel(
        vendorId: 'v',
        stallName: 'Old name',
        description: 'Old description',
        category: 'Beverages',
        openingHours: '9 AM – 5 PM',
        isOpen: true,
        latitude: 3.14,
        longitude: 101.69,
        selfCollectEnabled: true,
        locationSharingActive: true,
        locationUpdatedAt: DateTime.utc(2026, 10, 25),
        imageUrl: 'https://example.com/old.jpg');
    final hours = {
      1: [const StallHoursInterval(1320, 120)]
    };
    final closures = [
      TemporaryClosure(DateTime.utc(2026, 10, 26), DateTime.utc(2026, 10, 27))
    ];
    final draft = buildStallProfileDraft(
        original: original,
        name: ' New name ',
        description: ' New description ',
        phone: '012-345 6789',
        legacyHours: original.openingHours,
        categories: ['Beverages', 'Burger'],
        hours: hours,
        closures: closures);
    expect(draft.stallName, 'New name');
    expect(draft.phoneNumber, '+60123456789');
    expect(draft.allCategories, ['Beverages', 'Burger']);
    expect(draft.isOpen, true);
    expect(draft.selfCollectEnabled, true);
    expect(draft.latitude, original.latitude);
    expect(draft.longitude, original.longitude);
    expect(draft.locationSharingActive, true);
    expect(draft.locationUpdatedAt, original.locationUpdatedAt);
    expect(draft.imageUrl, original.imageUrl);
    expect(original.stallName, 'Old name');
    hours[1]!.clear();
    closures.clear();
    expect(draft.weeklyHours[1], hasLength(1));
    expect(draft.temporaryClosures, hasLength(1));
  });
  for (final size in [
    const Size(320, 740),
    const Size(390, 844),
    const Size(768, 1024),
    const Size(960, 700),
    const Size(1280, 800)
  ]) {
    testWidgets('responsive Edit stall at ${size.width} × ${size.height}',
        (tester) async {
      _viewport(tester, size);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      final wide = size.width >= 900;
      expect(
          find.byKey(Key(
              wide ? 'edit-stall-two-columns' : 'edit-stall-single-column')),
          findsOneWidget);
      final details =
          tester.getRect(find.byKey(const Key('edit-stall-details')));
      final hours = tester.getRect(find.byKey(const Key('edit-stall-hours')));
      if (wide) {
        expect(hours.left, greaterThan(details.right));
        expect(hours.top, closeTo(details.top, 1));
      } else {
        expect(hours.top, greaterThan(details.bottom));
      }
      final save = find.byKey(const Key('edit-stall-save'));
      expect(tester.getRect(save).bottom, lessThanOrEqualTo(size.height));
      expect(tester.getRect(save).top, greaterThan(size.height - 100));
      expect(tester.getSize(save).height, greaterThanOrEqualTo(48));
      expect(tester.takeException(), isNull);
      await _capture(tester, 'edit-stall-${size.width.toInt()}');
    });
  }
  testWidgets(
      'Save stays fixed while scrolling and opening hours expands on phone',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    await tester.pumpWidget(_app());
    final save = find.byKey(const Key('edit-stall-save'));
    final before = tester.getRect(save);
    expect(find.text('Monday'), findsNothing);
    await tester.ensureVisible(find.text('Opening hours'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Opening hours'));
    await tester.pumpAndSettle();
    expect(find.text('Monday'), findsOneWidget);
    expect(tester.getRect(save), before);
    await tester.ensureVisible(find.text('Monday'));
    await tester.tap(find.text('Monday'));
    await tester.pumpAndSettle();
    final state = tester.state<_HarnessState>(find.byType(_Harness));
    expect(state.hours[1], isEmpty);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'hours sheet edits the draft and closing it does not save the profile',
      (tester) async {
    _viewport(tester, const Size(1280, 800));
    final actions = <String>[];
    await tester.pumpWidget(_app(onAction: actions.add));
    await tester.tap(find.text('Edit weekly hours'));
    await tester.pumpAndSettle();
    expect(find.text('Weekly opening hours'), findsOneWidget);
    await tester.tap(find.text('Monday').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();
    expect(
        tester.state<_HarnessState>(find.byType(_Harness)).hours[1], isEmpty);
    expect(actions, isEmpty);
  });
  testWidgets(
      'category chooser keeps multiple selections and form edits on resize',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    await tester.pumpWidget(_app());
    await tester.enterText(
        find.byType(TextFormField).first, 'My updated stall');
    await tester.ensureVisible(find.text('Choose categories'));
    await tester.tap(find.text('Choose categories'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Burger'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(tester.state<_HarnessState>(find.byType(_Harness)).categories,
        {'Beverages', 'Burger'});
    tester.view.physicalSize = const Size(1280, 800);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('edit-stall-two-columns')), findsOneWidget);
    expect(
        tester
            .widget<TextFormField>(find.byType(TextFormField).first)
            .controller!
            .text,
        'My updated stall');
    expect(tester.takeException(), isNull);
  });
  testWidgets('Preview reads unsaved text and does not trigger Save',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    final actions = <String>[];
    await tester.pumpWidget(_app(onAction: actions.add));
    await tester.enterText(find.byType(TextFormField).first, 'New stall name');
    await tester.tap(find.text('Preview'));
    await tester.pumpAndSettle();
    expect(actions, ['preview:New stall name']);
    await tester.tap(find.text('Cancel'));
    expect(actions.last, 'cancel');
  });
  testWidgets('fixed Save validates and uses the latest fields',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    final actions = <String>[];
    await tester.pumpWidget(_app(onAction: actions.add));
    await tester.enterText(find.byType(TextFormField).first, '   ');
    await tester.tap(find.byKey(const Key('edit-stall-save')));
    await tester.pumpAndSettle();
    expect(find.text('Enter your stall name.'), findsOneWidget);
    expect(actions, isEmpty);
    await tester.enterText(find.byType(TextFormField).first, 'New name');
    await tester.tap(find.byKey(const Key('edit-stall-save')));
    await tester.pumpAndSettle();
    expect(actions, ['save:New name']);
  });
  testWidgets(
      'Save and Preview disable during saving, loading and photo selection',
      (tester) async {
    _viewport(tester, const Size(390, 844));
    for (final mode in ['saving', 'loading', 'picking']) {
      await tester.pumpWidget(_app(
          saving: mode == 'saving',
          loading: mode == 'loading',
          picking: mode == 'picking'));
      await tester.pump();
      expect(
          tester
              .widget<FilledButton>(find.byKey(const Key('edit-stall-save')))
              .onPressed,
          isNull);
      expect(
          tester
              .widget<OutlinedButton>(
                  find.widgetWithText(OutlinedButton, 'Preview'))
              .onPressed,
          isNull);
      expect(tester.takeException(), isNull);
    }
  });
  for (final width in [320.0, 960.0]) {
    testWidgets('large text fits $width and footer remains above the keyboard',
        (tester) async {
      _viewport(tester, Size(width, 900));
      await tester.pumpWidget(_app(scale: 1.6));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      final save = tester.getRect(find.byKey(const Key('edit-stall-save')));
      expect(save.bottom, lessThanOrEqualTo(600));
      expect(tester.takeException(), isNull);
      tester.view.viewInsets = const FakeViewPadding();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Opening hours'));
      await tester.tap(find.text('Opening hours'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Opens 9:00 AM').first);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
