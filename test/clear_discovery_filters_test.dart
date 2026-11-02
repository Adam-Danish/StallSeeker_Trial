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
import 'package:stallseeker/features/customer/home/discovery_map_widgets.dart';
import 'package:stallseeker/features/customer/home/customer_home_screen.dart';
import 'package:stallseeker/features/customer/home/discovery_options.dart';
import 'package:stallseeker/features/customer/profile/customer_profile_screen.dart';
import 'package:stallseeker/features/shared/manual_location_dialog.dart';

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

class _AllowedLocation extends _NoLocation {
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;
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

  testWidgets(
      'manual search keeps the GPS layer enabled and adds no search pin',
      (tester) async {
    GeolocatorPlatform.instance = _AllowedLocation();
    addTearDown(() => GeolocatorPlatform.instance = _NoLocation());
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme, home: const CustomerHomeScreen()));
    await tester.pumpAndSettle();
    expect(tester.widget<GoogleMap>(find.byType(GoogleMap)).myLocationEnabled,
        isTrue);
    final profile = tester.widget<CustomerProfileScreen>(
        find.byType(CustomerProfileScreen, skipOffstage: false));
    profile.onLocationChanged(
        const LocationSelection(
            coordinates: LatLng(3.14, 101.69), label: 'Manual search area'),
        true);
    await tester.pumpAndSettle();
    final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
    expect(map.myLocationEnabled, isTrue);
    expect(
        map.markers.any(
            (marker) => marker.markerId.value == 'customer-search-location'),
        isFalse);
    await tester.pumpWidget(const SizedBox.shrink());
  });

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

      DiscoveryMapFilters filters() =>
          tester.widget<DiscoveryMapFilters>(find.byType(DiscoveryMapFilters));
      Future<void> chooseMore(String label) async {
        await tester.tap(find.byTooltip('More map options'));
        await tester.pumpAndSettle();
        await tester.tap(find.text(label));
        await tester.pumpAndSettle();
      }

      for (final listView in [false, true]) {
        if (listView) {
          await chooseMore('List view');
        }
        // Set several filters together, including a schedule and price range.
        filters().onCategory('Beverages');
        filters().onSort(DiscoverySort.price);
        filters().onAvailable(true);
        filters().onSelfCollect(true);
        filters().onRecent(true);
        await tester.pump();
        await chooseMore('Any price');
        await tester.enterText(find.byType(TextFormField).first, '5');
        await tester.enterText(find.byType(TextFormField).last, '10');
        await tester.tap(find.text('Apply price range'));
        await tester.pumpAndSettle();
        await chooseMore('Open at…');
        await tester.tap(find.text('Tomorrow morning'));
        await tester.pumpAndSettle();
        await tester.enterText(
            find.byType(TextField).first, 'No matching dish');
        await tester.pumpAndSettle();
        expect(filters().category, 'Beverages');
        expect(filters().hasExtraFilters, isTrue);

        await tester.tap(find.byTooltip('Filter stalls'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Reset filters'));
        await tester.pumpAndSettle();
        expect(
            tester
                .widget<TextField>(find.byType(TextField).first)
                .controller!
                .text,
            isEmpty);
        expect(filters().category, isNull);
        expect(filters().openNow, isFalse);
        expect(filters().availableOnly, isFalse);
        expect(filters().selfCollectOnly, isFalse);
        expect(filters().recentOnly, isFalse);
        expect(filters().hasExtraFilters, isFalse);
        expect(filters().sort, DiscoverySort.distance);
        await tester.tap(find.byTooltip('More map options'));
        await tester.pumpAndSettle();
        expect(find.text('Any price'), findsOneWidget);
        expect(find.text('Open at…'), findsOneWidget);
        expect(find.text(listView ? 'Map view' : 'List view'), findsOneWidget);
        await tester.tap(find.byTooltip('More map options'));
        await tester.pumpAndSettle();
        expect(find.text('Nasi Stall'), findsOneWidget);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getStringList('guest_search_history_v1'),
            ['Previous search']);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}
