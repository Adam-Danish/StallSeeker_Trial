// Exercise the real discovery screen with read-only data and a map placeholder.
// ignore_for_file: depend_on_referenced_packages
import 'dart:async';
import 'package:cloud_firestore_platform_interface/cloud_firestore_platform_interface.dart';
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:flutter/foundation.dart';
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
import 'package:stallseeker/core/widgets/app_pill_navigation.dart';
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

class _BrowserLocation extends _NoLocation {
  final updates = StreamController<Position>();
  final firstFix = Completer<Position>();
  int requests = 0;

  @override
  Future<LocationPermission> checkPermission() async =>
      LocationPermission.unableToDetermine;

  @override
  Future<Position> getCurrentPosition({LocationSettings? locationSettings}) {
    requests++;
    return firstFix.future;
  }

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) =>
      updates.stream;

  Position fix(double latitude) => Position(
        latitude: latitude,
        longitude: 101.6869,
        timestamp: DateTime.now(),
        accuracy: 10,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
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

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets('Back restores customer tabs in visit order on $platform',
        (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme.copyWith(
          platform: platform,
          splashFactory: InkRipple.splashFactory,
        ),
        home: const CustomerHomeScreen(),
      ));
      await tester.pumpAndSettle();

      final tabBar = find.byKey(const Key('pill-navigation'));
      Future<void> selectTab(String label) async {
        await tester.tap(find.descendant(of: tabBar, matching: find.text(label)));
        await tester.pump();
      }

      int selectedTab() => tester
          .widget<AppPillNavigation>(find.byType(AppPillNavigation))
          .selectedIndex;

      Future<void> goBack() async {
        if (platform == TargetPlatform.iOS) {
          await tester.dragFrom(const Offset(5, 300), const Offset(140, 0));
        } else {
          await tester.binding.handlePopRoute();
        }
        await tester.pump();
      }

      final homeSearch = find.byType(TextField).first;
      final searchController = tester.widget<TextField>(homeSearch).controller;
      await selectTab('Following');
      expect(selectedTab(), 1);
      await goBack();
      expect(selectedTab(), 0);
      expect(tester.widget<TextField>(homeSearch).controller,
          same(searchController));

      await selectTab('Notifications');
      await selectTab('Settings');
      expect(selectedTab(), 3);
      final profile = tester.state(find.byType(CustomerProfileScreen));
      expect(find.text('Edit Profile'), findsNothing);
      expect(find.text('Sign in to edit profile'), findsOneWidget);
      await goBack();
      expect(selectedTab(), 2);

      await selectTab('Settings');
      await selectTab('Home');
      await selectTab('Home');
      expect(selectedTab(), 0);

      final context = tester.element(find.byType(CustomerHomeScreen));
      showDialog<void>(
        context: context,
        builder: (_) => const AlertDialog(title: Text('Open dialog')),
      );
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Open dialog'), findsNothing);
      expect(selectedTab(), 0);

      if (platform == TargetPlatform.iOS) {
        await tester.dragFrom(const Offset(100, 300), const Offset(140, 0));
        await tester.pumpAndSettle();
        expect(selectedTab(), 0);
      }

      for (final previousTab in [3, 2, 0]) {
        await goBack();
        expect(selectedTab(), previousTab);
        if (previousTab == 3) {
          expect(tester.state(find.byType(CustomerProfileScreen)), same(profile));
          expect(find.text('Sign in to edit profile'), findsOneWidget);
        }
      }
      expect(Navigator.of(context).canPop(), isFalse);
    });
  }

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

  testWidgets('map stall list expands, collapses, and scrolls', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final maps = _InteractiveMaps();
    GoogleMapsFlutterPlatform.instance = maps;
    final originalVendors = firestore.vendors;
    firestore.vendors = [
      for (var i = 0; i < 12; i++)
        {
          'stallName': 'Nasi Stall ${i.toString().padLeft(2, '0')}',
          'category': 'Rice',
          'latitude': 3.139 + i * .0001,
          'longitude': 101.6869,
          'isOpen': false,
        },
    ];
    addTearDown(() {
      GoogleMapsFlutterPlatform.instance = _PlaceholderMaps();
      firestore.vendors = originalVendors;
    });
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme, home: const CustomerHomeScreen()));
    await tester.pumpAndSettle();
    expect(find.text('12 stalls nearby'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('view-all-stalls')));
    await tester.pumpAndSettle();

    final title = find.text('Stalls in this area');
    final list = find.descendant(
      of: find.byType(DraggableScrollableSheet),
      matching: find.byType(CustomScrollView),
    );
    expect(tester.getSize(list).height, closeTo(844 * .6, 1));
    await tester.drag(title, const Offset(0, -240));
    await tester.pumpAndSettle();
    expect(tester.getSize(list).height, closeTo(844 * .9, 1));
    expect(tester.getTopLeft(list).dy, greaterThan(0));

    await tester.drag(title, const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(tester.getSize(list).height, closeTo(844 * .6, 1));
    await tester.drag(title, const Offset(0, -240));
    await tester.pumpAndSettle();

    final lastStall = find.widgetWithText(ListTile, 'Nasi Stall 11');
    expect(lastStall.hitTestable(), findsNothing);
    await tester.scrollUntilVisible(lastStall, 180,
        scrollable:
            find.descendant(of: list, matching: find.byType(Scrollable)));
    await tester.tap(lastStall);
    await tester.pumpAndSettle();
    expect(title, findsNothing);
    expect(maps.cameraMoves, hasLength(1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

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
  }, skip: kIsWeb);

  testWidgets('web GPS marker follows real fixes despite unknown permission',
      (tester) async {
    tester.view.physicalSize = const Size(960, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final location = _BrowserLocation();
    GeolocatorPlatform.instance = location;
    addTearDown(() => GeolocatorPlatform.instance = _NoLocation());
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme, home: const CustomerHomeScreen()));
    await tester.pumpAndSettle();

    GoogleMap map() => tester.widget<GoogleMap>(find.byType(GoogleMap));
    Marker? gpsMarker() => map()
        .markers
        .where((marker) => marker.markerId.value == 'current-gps-location')
        .firstOrNull;
    expect(location.requests, 0);
    expect(gpsMarker(), isNull);

    final button = tester.widget<FloatingActionButton>(find.byWidgetPredicate(
        (widget) =>
            widget is FloatingActionButton && widget.tooltip == 'My location'));
    button.onPressed!();
    location.firstFix.complete(location.fix(3.139));
    await tester.pump();
    expect(gpsMarker()?.position, const LatLng(3.139, 101.6869));
    expect(gpsMarker()?.clusterManagerId, isNull);
    expect(map().myLocationEnabled, isFalse);

    final profile = tester.widget<CustomerProfileScreen>(
        find.byType(CustomerProfileScreen, skipOffstage: false));
    profile.onLocationChanged(
        const LocationSelection(
            coordinates: LatLng(3.14, 101.69), label: 'Manual search area'),
        true);
    location.updates.add(location.fix(3.141));
    await tester.pump();
    expect(gpsMarker()?.position, const LatLng(3.141, 101.6869));

    location.updates.addError(const PermissionDeniedException('Revoked'));
    await tester.pump();
    expect(gpsMarker(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await location.updates.close();
  }, skip: !kIsWeb);

  testWidgets('discovery menus block map gestures until dismissed',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme, home: const CustomerHomeScreen()));
    await tester.pumpAndSettle();

    final shield = find.byKey(const ValueKey('map-menu-pointer-shield'));
    void expectMapBlocked(bool blocked) {
      final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
      expect(map.scrollGesturesEnabled, !blocked);
      expect(map.zoomGesturesEnabled, !blocked);
      expect(map.rotateGesturesEnabled, !blocked);
      expect(map.tiltGesturesEnabled, !blocked);
      expect(map.webGestureHandling,
          blocked ? WebGestureHandling.none : WebGestureHandling.auto);
      expect(shield, kIsWeb && blocked ? findsOneWidget : findsNothing);
    }

    Future<void> tap(Finder finder) async {
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    expectMapBlocked(false);
    await tap(find.text('All stalls'));
    expectMapBlocked(true);
    await tap(find.text('Malay Food'));
    expectMapBlocked(false);

    await tap(find.byTooltip('Filter stalls'));
    await tap(find.text('Open now'));
    expectMapBlocked(true);
    await tap(find.text('Sort results'));
    expect(find.text(DiscoverySort.rating.label), findsOneWidget);
    expectMapBlocked(true);
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expectMapBlocked(false);

    await tap(find.byTooltip('More map options'));
    expectMapBlocked(true);
    await tap(find.text('List view'));
    expect(find.byType(GoogleMap), findsNothing);
    await tap(find.byTooltip('More map options'));
    await tap(find.text('Map view'));
    expectMapBlocked(false);
    expect(tester.takeException(), isNull);
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
