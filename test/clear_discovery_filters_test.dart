// Exercise the real discovery screen with read-only data and a map placeholder.
// ignore_for_file: depend_on_referenced_packages
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stallseeker/core/theme/app_theme.dart';
import 'package:stallseeker/core/widgets/app_dropdown.dart';
import 'package:stallseeker/features/customer/home/customer_home_screen.dart';
import 'package:stallseeker/features/customer/home/discovery_options.dart';

class _SignedOutAuth extends FirebaseAuthPlatform {
  @override
  FirebaseAuthPlatform delegateFor({required FirebaseApp app}) => this;
  @override
  FirebaseAuthPlatform setInitialValues(
          {PigeonUserDetails? currentUser, String? languageCode}) =>
      this;
  @override
  UserPlatform? get currentUser => null;
}

class _DiscoveryFirestore extends FirebaseFirestorePlatform {
  @override
  FirebaseFirestorePlatform delegateFor(
          {required FirebaseApp app, required String databaseId}) =>
      this;
  @override
  CollectionReferencePlatform collection(String path) =>
      _Collection(this, path);
  @override
  QueryPlatform collectionGroup(String path) => _Collection(this, path);
  @override
  DocumentReferencePlatform doc(String path) => _Document(this, path);
}

class _Collection extends CollectionReferencePlatform {
  _Collection(super.firestore, super.path);
  @override
  DocumentReferencePlatform doc([String? path]) =>
      firestore.doc('${this.path}/${path ?? 'generated'}');
  @override
  Stream<QuerySnapshotPlatform> snapshots(
          {bool includeMetadataChanges = false,
          ServerTimestampBehavior serverTimestampBehavior =
              ServerTimestampBehavior.none,
          required ListenSource listenSource}) =>
      Stream.value(QuerySnapshotPlatform([
        if (path == 'vendors')
          DocumentSnapshotPlatform(
              firestore,
              'vendors/stall',
              {
                'stallName': 'Nasi Stall',
                'category': 'Rice',
                'latitude': 3.139,
                'longitude': 101.6869,
                'isOpen': false,
              },
              PigeonSnapshotMetadata(
                  hasPendingWrites: false, isFromCache: true)),
      ], [], SnapshotMetadataPlatform(false, true)));
}

class _Document extends DocumentReferencePlatform {
  _Document(super.firestore, super.path);
}

class _PlaceholderMaps extends GoogleMapsFlutterPlatform {
  @override
  Widget buildViewWithConfiguration(
          int creationId, PlatformViewCreatedCallback onPlatformViewCreated,
          {required MapWidgetConfiguration widgetConfiguration,
          MapConfiguration mapConfiguration = const MapConfiguration(),
          MapObjects mapObjects = const MapObjects()}) =>
      const SizedBox.expand();
}

class _NoLocation extends GeolocatorPlatform {
  @override
  Future<bool> isLocationServiceEnabled() async => false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
  setUpAll(() async {
    await Firebase.initializeApp();
    FirebaseAuthPlatform.instance = _SignedOutAuth();
    FirebaseFirestorePlatform.instance = _DiscoveryFirestore();
    GoogleMapsFlutterPlatform.instance = _PlaceholderMaps();
    GeolocatorPlatform.instance = _NoLocation();
  });
  setUp(() => SharedPreferences.setMockInitialValues({
        'guest_search_history_v1': ['Previous search'],
      }));

  for (final width in [320.0, 960.0]) {
    testWidgets('clear all discovery filters in map and list views at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightTheme, home: const CustomerHomeScreen()));
      await tester.pumpAndSettle();

      AppDropdown<String> dropdown(String hint) =>
          tester.widget<AppDropdown<String>>(find.byWidgetPredicate((widget) =>
              widget is AppDropdown<String> && widget.hint == hint));
      Finder chip(String label) => find.widgetWithText(InputChip, label);

      for (final listView in [false, true]) {
        if (listView) {
          final switchView = find.widgetWithText(ActionChip, 'List view');
          await Scrollable.ensureVisible(tester.element(switchView),
              alignment: .5);
          await tester.tap(switchView);
          await tester.pumpAndSettle();
        }
        // Set several filters together, including a schedule and price range.
        dropdown('Choose category').onChanged!('Drinks');
        tester
            .widget<AppDropdown<DiscoverySort>>(
                find.byType(AppDropdown<DiscoverySort>))
            .onChanged!(DiscoverySort.price);
        for (final filter in [
          'Available dishes',
          'Self-collect',
          'Updated in 24h'
        ]) {
          tester
              .widget<FilterChip>(find.widgetWithText(FilterChip, filter))
              .onSelected!(true);
        }
        await tester.pump();
        await Scrollable.ensureVisible(tester.element(chip('Any price')),
            alignment: .5);
        await tester.tap(chip('Any price'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField).first, '5');
        await tester.enterText(find.byType(TextFormField).last, '10');
        await tester.tap(find.text('Apply price range'));
        await tester.pumpAndSettle();
        await Scrollable.ensureVisible(tester.element(chip('Open at…')),
            alignment: .5);
        await tester.tap(chip('Open at…'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Tomorrow morning'));
        await tester.pumpAndSettle();
        await tester.enterText(
            find.byType(TextField).first, 'No matching dish');
        await tester.pumpAndSettle();
        expect(dropdown('Choose category').value, 'Drinks');
        expect(dropdown('Choose stall status').displayText, 'Scheduled');

        // The reset stays visible even when the filter strip is scrolled.
        await tester.tap(find.text('Clear filters'));
        await tester.pumpAndSettle();
        expect(
            tester
                .widget<TextField>(find.byType(TextField).first)
                .controller!
                .text,
            isEmpty);
        expect(dropdown('Choose category').value, 'All');
        expect(dropdown('Choose stall status').value, 'All');
        expect(dropdown('Choose stall status').displayText, isNull);
        expect(chip('Any price'), findsOneWidget);
        expect(chip('Open at…'), findsOneWidget);
        for (final filter in [
          'Available dishes',
          'Self-collect',
          'Updated in 24h'
        ]) {
          expect(
              tester
                  .widget<FilterChip>(find.widgetWithText(FilterChip, filter))
                  .selected,
              isFalse);
        }
        expect(
            tester
                .widget<AppDropdown<DiscoverySort>>(
                    find.byType(AppDropdown<DiscoverySort>))
                .value,
            DiscoverySort.price);
        expect(find.text(listView ? 'Map view' : 'List view'), findsOneWidget);
        if (listView) {
          expect(find.text('Nasi Stall'), findsOneWidget);
        } else {
          expect(
              tester.widget<GoogleMap>(find.byType(GoogleMap)).markers.length,
              1);
        }
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getStringList('guest_search_history_v1'),
            ['Previous search']);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
