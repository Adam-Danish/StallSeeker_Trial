// Exercise the real discovery screen with read-only data and a map placeholder.
// ignore_for_file: depend_on_referenced_packages
import 'dart:async';
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stallseeker/core/theme/app_theme.dart';
import 'package:stallseeker/core/constants/app_colors.dart';
import 'package:stallseeker/features/customer/home/discovery_map_widgets.dart';
import 'package:stallseeker/features/customer/home/customer_home_screen.dart';
import 'package:stallseeker/features/customer/home/discovery_options.dart';
import 'package:stallseeker/features/customer/home/stall_preview_sheet.dart';
import 'package:stallseeker/features/customer/profile/customer_profile_screen.dart';
import 'package:stallseeker/features/shared/manual_location_dialog.dart';
import 'package:stallseeker/features/shared/moderation_screen.dart';

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
  List<Map<String, Object>> vendors = const [
    {
      'stallName': 'Nasi Stall',
      'category': 'Rice',
      'latitude': 3.139,
      'longitude': 101.6869,
      'isOpen': false
    },
  ];
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
          for (final entry
              in (firestore as _DiscoveryFirestore).vendors.indexed)
            DocumentSnapshotPlatform(
                firestore,
                'vendors/stall${entry.$1 == 0 ? '' : entry.$1}',
                entry.$2,
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

class _InteractiveMaps extends MethodChannelGoogleMapsFlutter {
  final created = <int>{};
  final cameraMoves = <CameraUpdate>[];
  final immediateCameraMoves = <CameraUpdate>[];
  final configurations = <MapConfiguration>[];
  Completer<double>? pendingZoom;
  LatLngBounds bounds = LatLngBounds(
    southwest: const LatLng(3.138, 101.68),
    northeast: const LatLng(3.142, 101.69),
  );
  @override
  Future<void> init(int mapId) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            ensureChannelInitialized(mapId), (_) async => null);
    return super.init(mapId);
  }

  @override
  Future<LatLngBounds> getVisibleRegion({required int mapId}) async => bounds;
  @override
  Future<double> getZoomLevel({required int mapId}) async =>
      pendingZoom == null ? 16 : await pendingZoom!.future;
  @override
  Future<ScreenCoordinate> getScreenCoordinate(LatLng latLng,
          {required int mapId}) async =>
      bounds.contains(latLng)
          ? const ScreenCoordinate(x: 100, y: 100)
          : const ScreenCoordinate(x: -1000, y: -1000);
  @override
  Future<void> moveCamera(CameraUpdate cameraUpdate,
      {required int mapId}) async {
    immediateCameraMoves.add(cameraUpdate);
  }

  @override
  Future<void> updateMapConfiguration(MapConfiguration configuration,
      {required int mapId}) async {
    configurations.add(configuration);
  }

  @override
  Future<void> animateCamera(CameraUpdate cameraUpdate,
      {required int mapId}) async {
    cameraMoves.add(cameraUpdate);
  }

  @override
  Future<void> updateGroundOverlays(GroundOverlayUpdates updates,
      {required int mapId}) async {}

  @override
  Widget buildViewWithConfiguration(
      int creationId, PlatformViewCreatedCallback onPlatformViewCreated,
      {required MapWidgetConfiguration widgetConfiguration,
      MapConfiguration mapConfiguration = const MapConfiguration(),
      MapObjects mapObjects = const MapObjects()}) {
    if (created.add(creationId)) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => onPlatformViewCreated(creationId));
    }
    return const SizedBox.expand();
  }
}

class _AllowedLocation extends _NoLocation {
  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.whileInUse;
}

void main() {
  final firestore = _DiscoveryFirestore();
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
  setUpAll(() async {
    await Firebase.initializeApp();
    FirebaseAuthPlatform.instance = _SignedOutAuth();
    FirebaseFirestorePlatform.instance = firestore;
    GoogleMapsFlutterPlatform.instance = _PlaceholderMaps();
    GeolocatorPlatform.instance = _NoLocation();
  });
  setUp(() => SharedPreferences.setMockInitialValues({
        'guest_search_history_v1': ['Previous search'],
      }));

  for (final width in [360.0, 960.0]) {
    testWidgets(
        'customer can open Report this stall from the preview at $width',
        (tester) async {
      GoogleMapsFlutterPlatform.instance = _InteractiveMaps();
      addTearDown(
          () => GoogleMapsFlutterPlatform.instance = _PlaceholderMaps());
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightTheme, home: const CustomerHomeScreen()));
      await tester.pumpAndSettle();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();
      GoogleMap map() => tester.widget<GoogleMap>(find.byType(GoogleMap));
      map().onCameraMove!(
          const CameraPosition(target: LatLng(3.139, 101.6869), zoom: 16));
      map().onCameraIdle!();
      await tester.pumpAndSettle();
      map().markers.single.infoWindow.onTap!();
      await tester.pumpAndSettle();
      final report = find.text('Report this stall');
      expect(report, findsOneWidget);
      await tester.ensureVisible(report);
      await tester.tap(report);
      await tester.pumpAndSettle();
      expect(find.byType(ReportStallScreen), findsOneWidget);
      expect(find.textContaining('Sign in with a verified account'),
          findsOneWidget);
      expect(find.text('Create an Account'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  for (final width in [390.0, 1280.0]) {
    testWidgets(
        'real stall profile keeps map stationary while scrolling at $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final maps = _InteractiveMaps();
      GoogleMapsFlutterPlatform.instance = maps;
      final originalVendors = firestore.vendors;
      firestore.vendors = [
        {
          ...originalVendors.first,
          'description': List.filled(200, 'Stall profile details.').join(' '),
        },
      ];
      addTearDown(() async {
        if (maps.pendingZoom case final pending? when !pending.isCompleted) {
          pending.complete(16);
        }
        await tester.pumpWidget(const SizedBox.shrink());
        GoogleMapsFlutterPlatform.instance = _PlaceholderMaps();
        firestore.vendors = originalVendors;
      });
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightTheme, home: const CustomerHomeScreen()));
      await tester.pumpAndSettle();
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pumpAndSettle();
      GoogleMap map() => tester.widget<GoogleMap>(find.byType(GoogleMap));
      const camera = CameraPosition(target: LatLng(3.139, 101.6869), zoom: 16);
      map().onCameraMove!(camera);
      map().onCameraIdle!();
      await tester.pumpAndSettle();

      // Open the real profile before a pending marker-focus request finishes.
      // That request must never move the map behind the open profile.
      maps.pendingZoom = Completer<double>();
      map().markers.single.onTap!();
      map().markers.single.infoWindow.onTap!();
      await tester.pumpAndSettle();
      expect(find.byType(StallPreviewSheet), findsOneWidget);
      final frozenPadding = map().padding;
      expect(map().scrollGesturesEnabled, isFalse);
      expect(map().zoomGesturesEnabled, isFalse);
      expect(map().rotateGesturesEnabled, isFalse);
      expect(map().tiltGesturesEnabled, isFalse);
      expect(map().webGestureHandling, WebGestureHandling.none);
      maps.pendingZoom!.complete(16);
      await tester.pumpAndSettle();
      expect(maps.cameraMoves, isEmpty,
          reason:
              'A delayed marker focus must be cancelled when the profile opens.');
      final cameraCommands = maps.immediateCameraMoves.length;
      maps.configurations.clear();
      final list = find.descendant(
          of: find.byType(StallPreviewSheet), matching: find.byType(ListView));
      await tester.drag(list, const Offset(0, -240));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Expand preview'));
      await tester.pumpAndSettle();
      final controller = tester.widget<ListView>(list).controller!;
      final offset = controller.offset;
      await tester.sendEventToBinding(PointerScrollEvent(
          position: tester.getCenter(list), scrollDelta: const Offset(0, 200)));
      await tester.pumpAndSettle();
      expect(controller.offset, greaterThan(offset));
      expect(map().padding, frozenPadding);
      expect(map().scrollGesturesEnabled, isFalse);
      expect(map().webGestureHandling, WebGestureHandling.none);
      expect(maps.cameraMoves, isEmpty);
      expect(maps.immediateCameraMoves, hasLength(cameraCommands));
      expect(maps.created, hasLength(1));
      expect(maps.configurations.where((config) => config.padding != null),
          isEmpty,
          reason: 'Profile scrolling must not update the map viewport.');
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
      'cards follow viewport; scrolling leaves markers and camera unchanged; tapping focuses',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final maps = _InteractiveMaps();
    GoogleMapsFlutterPlatform.instance = maps;
    final originalVendors = firestore.vendors;
    firestore.vendors = [
      for (var i = 0; i < 4; i++)
        {
          'stallName': 'Nasi Stall $i',
          'category': 'Rice',
          'latitude': i == 3 ? 3.16 : 3.139 + i * .001,
          'longitude': 101.6869,
          'isOpen': false
        },
    ];
    addTearDown(() {
      GoogleMapsFlutterPlatform.instance = _PlaceholderMaps();
      firestore.vendors = originalVendors;
    });
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme, home: const CustomerHomeScreen()));
    await tester.pumpAndSettle();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)));
    await tester.pumpAndSettle();
    GoogleMap map() => tester.widget<GoogleMap>(find.byType(GoogleMap));
    final before = map();
    expect(before.markers.length, 4);
    expect(tester.widget<StallCardCarousel>(find.byType(StallCardCarousel)).ids,
        ['stall', 'stall1', 'stall2']);
    expect(find.text('3 stalls nearby'), findsOneWidget);
    await tester.drag(find.byKey(const ValueKey('stall-card-carousel')),
        const Offset(-1200, 0));
    await tester.pumpAndSettle();
    expect(map().markers, unorderedEquals(before.markers));
    expect(map().initialCameraPosition, before.initialCameraPosition);
    expect(maps.cameraMoves, isEmpty);
    await tester.tap(find.text('Nasi Stall 2'));
    await tester.pumpAndSettle();
    final selectedCard = find.byWidgetPredicate((widget) =>
        widget is StallMapCard && widget.vendor.vendorId == 'stall2');
    final selectedSurface = tester.widget<Material>(find.descendant(
        of: selectedCard,
        matching: find.byKey(const ValueKey('stall-map-card-surface'))));
    expect((selectedSurface.shape! as RoundedRectangleBorder).side.color,
        AppColors.primary);
    final selectedSize = tester.getSize(selectedCard);
    await tester.drag(find.byKey(const ValueKey('stall-card-carousel')),
        const Offset(160, 0));
    await tester.pumpAndSettle();
    expect(tester.widget<StallMapCard>(selectedCard).selected, isTrue);
    expect(tester.getSize(selectedCard), selectedSize);
    expect(maps.cameraMoves, hasLength(1));
    expect(
        map()
            .markers
            .firstWhere((m) => m.markerId.value == 'stall2')
            .clusterManagerId,
        isNull);
    // Finish the explicit focus, then simulate a user pan to a different stall.
    map().onCameraIdle!();
    await tester.pumpAndSettle();
    maps.bounds = LatLngBounds(
        southwest: const LatLng(3.159, 101.68),
        northeast: const LatLng(3.161, 101.69));
    map().onCameraMoveStarted!();
    map().onCameraMove!(
        const CameraPosition(target: LatLng(3.16, 101.6869), zoom: 16));
    map().onCameraIdle!();
    await tester.pumpAndSettle();
    expect(tester.widget<StallCardCarousel>(find.byType(StallCardCarousel)).ids,
        ['stall3']);
    expect(find.text('1 stalls nearby'), findsOneWidget);
    expect(find.text('Search here'), findsOneWidget);
    expect(map().markers.map((m) => m.markerId),
        unorderedEquals(before.markers.map((m) => m.markerId)));
    expect(maps.cameraMoves, hasLength(1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

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
