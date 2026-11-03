import '../../../core/widgets/app_sheet_header.dart';
import '../../../core/widgets/app_page_app_bar.dart';
import 'discovery_options.dart';
import '../../../core/services/stall_review_service.dart';
import '../../../core/services/saved_search_service.dart';
import '../../../core/services/notification_history_service.dart';
import '../../../core/services/demo_order_service.dart';
import '../notifications/customer_notifications_screen.dart';
import 'dart:async'; // bawak time, future dan unawaited
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../core/widgets/map_overlay.dart';
import '../../../core/widgets/map_gesture_guard.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_pill_navigation.dart';
import '../../../core/widgets/ios_grouped.dart';
import '../../../core/constants/stall_categories.dart';
import '../../../core/models/stall_schedule.dart';
import '../../../core/models/dish_search_entry.dart';
import 'open_at_picker.dart';
import 'discovery_search_filters.dart';
import 'price_range_picker.dart';
import 'discovery_map_widgets.dart';
import 'stall_map_marker.dart';
import 'map_marker_visibility.dart';
import 'stall_preview_sheet.dart';
import '../../../core/services/follow_service.dart';
import '../orders/demo_order_cart_screen.dart';
import '../../auth/screens/login_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/dish_search_service.dart';
import '../../../core/services/search_history_service.dart';
import '../../../core/services/vendor_service.dart';
import '../following/customer_following_screen.dart';
import '../profile/customer_profile_screen.dart';
import '../../shared/profile_page.dart';
import '../vendor_details/vendor_details_screen.dart';
import '../../shared/manual_location_dialog.dart';
import '../../shared/saved_locations_sheet.dart';
import '../../shared/pin_location_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen>
    with WidgetsBindingObserver {
  final _vendorService = VendorService(); // loads vendor
  final _authService = AuthService(); // loads customer info
  final _dishSearchService = DishSearchService();
  final _searchHistoryService = SearchHistoryService();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Stream<int>? _unreadCount;
  Stream<int>? _bookingUnreadCount;

  int _selectedIndex = 0;
  String _searchQuery = '';
  GoogleMapController? _mapController; // move the map dan zoom
  LatLng? _customerPosition;
  String? _customerLocationLabel;
  double _searchRadiusKm = 5;

  // Bounds are used only for the Search here action.
  LatLngBounds? _searchedBounds;
  LatLngBounds? _pendingBounds;
  LatLng? _mapCenter;
  CameraPosition? _lastCameraPosition;
  final ValueNotifier<double> _mapBearing = ValueNotifier(0);
  LatLng? _searchCenter;
  bool _showSearchArea = false;
  bool _programmaticCameraMove = false;
  Timer? _cameraMoveGuard;
  bool _cameraMovedByUser = false;
  int _boundsRequest = 0;
  Timer? _viewportRefreshTimer;
  Size _mapViewportSize = Size.zero;
  EdgeInsets _mapViewportPadding = EdgeInsets.zero;
  double _mapCoordinateScale = 1;
  List<VendorModel> _projectionVendors = const [];
  List<(String, double, double)> _projectionLocations = const [];
  Set<String> _onScreenVendorIds = const {};
  DiscoverySort _sort = DiscoverySort.distance;
  bool _listOnly = false;
  bool _pointerOverResults = false;
  final Set<int> _resultPointers = {};
  bool get _blockMapGestures =>
      _pointerOverResults || _resultPointers.isNotEmpty;

  void _trackResultPointer(int pointer, bool down) {
    if (!kIsWeb || !mounted) return;
    setState(() {
      if (down) {
        _resultPointers.add(pointer);
      } else {
        _resultPointers.remove(pointer);
      }
    });
  }

  bool _availableOnly = false;
  bool _selfCollectOnly = false;
  bool _recentOnly = false;
  final _reviewService = StallReviewService();
  final _savedSearches = SavedSearchService();
  final _ratings = <String, StallRatingSummary>{};
  final _ratingErrors = <String>{};
  final _ratingSubscriptions = <String, StreamSubscription<dynamic>>{};
  static const _clusterId = ClusterManagerId('nearby-stalls');
  OpeningTimeFilter? _openingTime;
  MenuPriceRange? _priceRange;

  final List<String> _tabTitles = [
    'Home',
    'Following',
    'Notifications',
    'Settings'
  ];
  String _greeting = 'Guest';

  static const _mapStyle = '''[
    {"featureType":"all","elementType":"labels.icon","stylers":[{"visibility":"off"}]},
    {"featureType":"landscape","elementType":"geometry","stylers":[{"color":"#f7f2e3"}]},
    {"featureType":"landscape.natural","elementType":"geometry","stylers":[{"color":"#d9efd9"}]},
    {"featureType":"poi.park","elementType":"geometry","stylers":[{"color":"#cce9d0"}]},
    {"featureType":"road","elementType":"geometry","stylers":[{"color":"#ebe9df"}]},
    {"featureType":"road","elementType":"geometry.stroke","stylers":[{"color":"#d9d9ce"}]},
    {"featureType":"water","elementType":"geometry","stylers":[{"color":"#bfdfe7"}]},
    {"featureType":"transit","elementType":"geometry","stylers":[{"visibility":"off"}]}
  ]''';

  String get _welcomeLine {
    final hour = DateTime.now().hour;
    final salutation = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    return '$salutation, $_greeting 👋';
  }

  String? _selectedVendorId;
  bool _isLocatingCustomer = true;
  bool _locationPermissionGranted = false;
  LatLng? _gpsPosition;
  BitmapDescriptor? _gpsDotIcon;
  StreamSubscription<Position>? _gpsSubscription;
  bool _checkingGps = false;
  String? _locationError;
  String? _category;
  String _statusFilter = 'All';
  Timer? _freshnessTimer;
  late Stream<List<VendorModel>> _vendors;
  StreamSubscription<List<DishSearchEntry>>? _dishSubscription;
  List<DishSearchEntry> _allDishes = const [];
  List<String> _recentSearches = const [];
  bool _dishesLoading = true;
  String? _dishSearchError;
  final _markerCache = StallMapMarkerCache();
  final _markerIcons = <(String, bool), BitmapDescriptor>{};
  final _followService = FollowService();
  final _previewExtent = ValueNotifier<double>(.55);
  String? _previewVendorId;
  String? _selectedDishId;
  CameraPosition? _previewCamera;
  EdgeInsets _previewMapPadding = EdgeInsets.zero;
  Stream<bool>? _previewFollowStream;
  bool _followingBusy = false;
  int _cameraRequest = 0;

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(3.1390, 101.6869),
    zoom: 14,
  );

// cari vendor data, tgk notification, loads customer location, name for greeting
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refreshGpsDisplay());
    _vendors = _watchVendors();
    unawaited(_loadMapMarkerIcons());
    _searchFocus.addListener(_onSearchFocusChanged);
    _dishSubscription = _dishSearchService.watchAllDishes().listen(
      (dishes) {
        if (!mounted) return;
        setState(() {
          _allDishes = dishes;
          _dishesLoading = false;
          _dishSearchError = null;
        });
      },
      onError: (Object error) {
        if (!mounted) return;
        setState(() {
          _dishesLoading = false;
          _dishSearchError = 'Could not load dishes.';
        });
      },
    );
    unawaited(_loadRecentSearches());
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      _unreadCount = NotificationHistoryService().watchUnreadCount(user.uid);
      _bookingUnreadCount =
          DemoOrderService().watchUnseenCount(user.uid, isVendor: false);
    }
    _initializeCustomerLocation();
    _loadGreeting();
    _freshnessTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      // refresh location setiap 30sec
      if (mounted) {
        setState(() {});
      }
    });
  }

// bila customer leave app dia clean up
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _gpsSubscription?.cancel();
    _searchController.dispose();
    _searchFocus
      ..removeListener(_onSearchFocusChanged)
      ..dispose();
    _dishSubscription?.cancel();
    for (final subscription in _ratingSubscriptions.values) {
      subscription.cancel();
    }
    _mapController?.dispose();
    _mapBearing.dispose();
    _previewExtent.dispose();
    _freshnessTimer?.cancel();
    _cameraMoveGuard?.cancel();
    _viewportRefreshTimer?.cancel();
    super.dispose();
  }

  void _expectProgrammaticCameraMove() {
    _programmaticCameraMove = true;
    _cameraMoveGuard?.cancel();
    _cameraMoveGuard = Timer(const Duration(seconds: 3), () {
      _programmaticCameraMove = false;
    });
  }

  void _onSearchFocusChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadRecentSearches() async {
    try {
      await _searchHistoryService.mergeGuestHistoryIntoCustomerAccount();
      final recent = await _searchHistoryService.loadRecent();
      if (mounted) setState(() => _recentSearches = recent);
    } catch (_) {
      // Search still works when history is unavailable.
    }
  }

  void _submitSearch(String rawQuery) {
    final query = rawQuery.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (query.isEmpty) return;
    _searchController.text = query;
    _searchController.selection = TextSelection.collapsed(offset: query.length);
    setState(() {
      _searchQuery = query;
      _selectedVendorId = null;
      _recentSearches = [
        query,
        ..._recentSearches
            .where((item) => item.toLowerCase() != query.toLowerCase()),
      ].take(10).toList();
    });
    _searchFocus.unfocus();
    unawaited(_searchHistoryService.save(query).catchError((Object error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Search worked, but history could not be saved.')));
      }
    }));
  }

  Future<void> _removeRecentSearch(String query) async {
    setState(() => _recentSearches = _recentSearches
        .where((item) => item.toLowerCase() != query.toLowerCase())
        .toList());
    try {
      await _searchHistoryService.remove(query);
    } catch (_) {
      if (mounted) await _loadRecentSearches();
    }
  }

  Future<void> _clearRecentSearches() async {
    setState(() => _recentSearches = const []);
    try {
      await _searchHistoryService.clear();
    } catch (_) {
      if (mounted) await _loadRecentSearches();
    }
  }

  Future<void> _loadGreeting() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return;
    }

    if (user.isAnonymous) {
      if (mounted) {
        setState(() => _greeting = 'Guest');
      }
      return;
    }

    final userData = await _authService.getUserData(user.uid);
    final name = userData?.fullName;
    if (mounted) {
      setState(() {
        _greeting = (name != null && name.trim().isNotEmpty)
            ? name.trim().split(RegExp(r'\s+')).first
            : 'Guest';
      });
    }
  }

  bool _locationRequestActive = false;
  int _locationSelectionVersion = 0;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(_refreshGpsDisplay());
  }

  Future<void> _refreshGpsDisplay() async {
    if (_checkingGps) return;
    _checkingGps = true;
    try {
      final permission = await Geolocator.checkPermission();
      final granted = permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always;
      if (!mounted) return;
      setState(() => _locationPermissionGranted = granted);
      if (!granted) {
        await _gpsSubscription?.cancel();
        _gpsSubscription = null;
        return;
      }
      // Native Google Maps draws its own GPS dot. The web implementation
      // needs a dot sourced from real GPS, independently of the search area.
      if (kIsWeb) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high),
        ).timeout(const Duration(seconds: 12));
        if (!mounted) return;
        setState(
            () => _gpsPosition = LatLng(position.latitude, position.longitude));
        _gpsSubscription ??= Geolocator.getPositionStream().listen((position) {
          if (mounted) {
            setState(() =>
                _gpsPosition = LatLng(position.latitude, position.longitude));
          }
        }, onError: (Object _) {});
      }
    } catch (_) {
      // A temporary GPS failure must not change the selected search area.
    } finally {
      _checkingGps = false;
    }
  }

  Future<void> _initializeCustomerLocation() async {
    final selectionVersion = _locationSelectionVersion;
    // check kalau customer ada saved location, kalau takde baru call getcustomerlocation
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      final userData = await _authService.getUserData(user.uid);
      if (!mounted || selectionVersion != _locationSelectionVersion) {
        return;
      }
      if (userData?.hasCustomerLocation == true) {
        _applyCustomerLocation(
          LocationSelection(
            coordinates: LatLng(
              userData!.customerLatitude!,
              userData.customerLongitude!,
            ),
            label: userData.customerLocationLabel ?? 'Selected location',
          ),
          userData.customerLocationIsManual,
          persist: false, // false for check cust loc, it move to get cust loc
        );
        setState(() => _isLocatingCustomer = false);
        return;
      }
    }
    if (mounted && selectionVersion == _locationSelectionVersion) {
      if (kIsWeb) {
        // Browser permission prompts should follow a deliberate My location
        // click. Reuse an existing grant without prompting on page load.
        try {
          final permission = await Geolocator.checkPermission()
              .timeout(const Duration(seconds: 8));
          if (!mounted || selectionVersion != _locationSelectionVersion) return;
          if (permission != LocationPermission.whileInUse &&
              permission != LocationPermission.always) {
            setState(() => _isLocatingCustomer = false);
            return;
          }
        } catch (_) {
          if (mounted) setState(() => _isLocatingCustomer = false);
          return;
        }
      }
      await _getCustomerLocation(); // get cust loc
    }
  }

  void _applyCustomerLocation(
    LocationSelection selection,
    bool isManual, {
    bool persist = true,
  }) {
    if (!mounted) {
      return;
    }
    setState(() {
      // default
      _locationSelectionVersion++;
      _isLocatingCustomer = false;
      _selectedVendorId = null;
      _customerPosition = selection.coordinates;
      _searchCenter = selection.coordinates;
      _searchedBounds = null;
      _previewVendorId = null;
      _selectedDishId = null;
      _showSearchArea = false;
      _customerLocationLabel = selection.label;
      _locationError = null; // buang error
    });
    final controller = _mapController;
    if (controller != null) _expectProgrammaticCameraMove();
    controller?.animateCamera(
      CameraUpdate.newLatLngZoom(
          selection.coordinates,
          isManual
              ? 13.5
              : 15), // moves map. 13.5 size kalau manual, 15 gps (closer)
    );
    if (persist) {
      unawaited(_authService.saveCustomerLocation(
        latitude: selection.coordinates.latitude,
        longitude: selection.coordinates.longitude,
        label: selection.label,
        isManual: isManual,
      ));
    }
  }

  Future<void> _getCustomerLocation() async {
    if (_isLocatingCustomer && _locationRequestActive) {
      return;
    }
    _locationRequestActive = true;
    final selectionVersion = _locationSelectionVersion;
    if (mounted) {
      setState(() {
        _isLocatingCustomer = true;
        _locationError = null;
      });
    }
    try {
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled(); // check gps bukak ke tak
      if (!serviceEnabled) {
        throw StateError('Turn on GPS, or browse the map manually.');
      }

      LocationPermission permission =
          await Geolocator.checkPermission(); // check gps permission
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || // customer reject
          permission == LocationPermission.deniedForever) {
        // customer kena allow gps thru setting phone
        throw StateError(permission == LocationPermission.deniedForever
            ? 'Allow location access in phone settings, or browse manually.'
            : 'Location access denied. You can still browse the map.');
      }

      final position = await Geolocator.getCurrentPosition(
        // read coordinate lepas allow gps, 12s limit kalau x, set manual
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 12));
      if (!mounted) {
        return;
      }
      final coordinates = LatLng(position.latitude, position.longitude);
      setState(() {
        _locationPermissionGranted = true;
        _gpsPosition = coordinates;
      });
      unawaited(_refreshGpsDisplay());
      String label;
      try {
        label = await describeLocation(coordinates);
      } catch (_) {
        label = 'Current location';
      }
      if (!mounted || selectionVersion != _locationSelectionVersion) return;
      _applyCustomerLocation(
        LocationSelection(coordinates: coordinates, label: label),
        false,
      );
    } catch (error) {
      if (mounted && selectionVersion == _locationSelectionVersion) {
        setState(() {
          _locationError = error is StateError
              ? error.message.toString()
              : 'Could not find your location. Retry or browse the map manually.';
        });
      }
    } finally {
      _locationRequestActive = false;
      if (mounted) {
        setState(() => _isLocatingCustomer = false);
      }
    }
  }

  Future<void> _enterCustomerLocationManually() async {
    final selection = await showManualLocationDialog(
      context,
      initialLocation: _customerPosition ?? _defaultPosition.target,
      title: 'Set Search Location',
    );

    if (selection == null || !mounted) {
      return;
    }

    _applyCustomerLocation(selection, true);
  }

  void _setSearchRadius(double radius) {
    setState(() {
      _searchRadiusKm = radius;
      _searchedBounds = null;
      _showSearchArea = false;
    });
    final center = _searchCenter ?? _customerPosition;
    if (center != null) {
      if (_mapController != null) _expectProgrammaticCameraMove();
      final zoom = switch (radius) {
        <= 5 => 13.5,
        <= 10 => 12.5,
        <= 25 => 11.0,
        _ => 10.0,
      };
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(center, zoom));
    }
  }

  Future<void> _chooseSavedLocation({String? type}) async {
    final selection = await showSavedLocationsSheet(context,
        initialLocation:
            _searchCenter ?? _customerPosition ?? _defaultPosition.target,
        initialType: type);
    if (!mounted || selection == null) return;
    _applyCustomerLocation(selection, true);
  }

  Future<void> _pinSearchLocation() async {
    final selection = await Navigator.push<LocationSelection>(
        context,
        MaterialPageRoute(
            builder: (_) => PinLocationScreen(
                initialLocation: _searchCenter ??
                    _customerPosition ??
                    _defaultPosition.target)));
    if (!mounted || selection == null) return;
    _applyCustomerLocation(selection, true);
  }

  // ui for set location, enter manually button
  Future<void> _chooseLocationSource() async {
    FocusScope.of(context).unfocus();
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 8, 20, 18),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Set your location',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AppGroupedCard(children: [
              ListTile(
                leading: const AppIconTile(
                    icon: Icons.my_location_rounded, color: Color(0xFF43CE72)),
                title: const Text('Use current location'),
                subtitle: const Text('Find stalls near where you are now'),
                onTap: () => Navigator.pop(ctx, 'current'),
              ),
              ListTile(
                leading: const AppIconTile(
                    icon: Icons.search_rounded, color: AppColors.primary),
                title: const Text('Enter manually'),
                subtitle:
                    const Text('Search for an area, city, state, or postcode'),
                onTap: () => Navigator.pop(ctx, 'manual'),
              ),
              ListTile(
                leading: const AppIconTile(
                    icon: Icons.push_pin_rounded, color: Color(0xFFFFAE22)),
                title: const Text('Pin on map'),
                subtitle: const Text('Choose an exact search location'),
                onTap: () => Navigator.pop(ctx, 'pin'),
              ),
              ListTile(
                leading: const AppIconTile(
                    icon: Icons.home_rounded, color: Color(0xFFAD55E8)),
                title: const Text('Home & saved places'),
                subtitle: const Text('Save and choose Home or custom pins'),
                onTap: () => Navigator.pop(ctx, 'saved'),
              ),
            ]),
          ),
          const SizedBox(height: 20),
        ]),
      ),
    );
    if (!mounted || choice == null) {
      return;
    }
    if (choice == 'current') {
      await _getCustomerLocation();
    } else if (choice == 'saved') {
      await _chooseSavedLocation();
    } else if (choice == 'pin') {
      await _pinSearchLocation();
    } else {
      await _enterCustomerLocationManually();
    }
  }

  Future<void> _selectVendor(VendorModel vendor) async {
    if (!vendor.hasValidLocation) {
      return;
    }
    FocusScope.of(context).unfocus();
    final request = ++_cameraRequest;
    setState(() {
      _selectedVendorId = vendor.vendorId;
    });
    final controller = _mapController;
    if (controller == null) {
      return;
    }
    _expectProgrammaticCameraMove();
    try {
      final currentZoom = await controller.getZoomLevel();
      if (!mounted || request != _cameraRequest) {
        return;
      }

      final targetZoom =
          currentZoom < 16 ? 16.0 : currentZoom.clamp(16.0, 17.5).toDouble();
      await controller.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(vendor.latitude, vendor.longitude),
        targetZoom,
      ));
    } catch (_) {
      // A controller may be disposed while the user changes screens.
      if (request == _cameraRequest) {
        _programmaticCameraMove = false;
        _cameraMoveGuard?.cancel();
      }
    }
  }

  // Projection inputs change on data updates, filtering, and map resize.
  void _syncMapViewport(
      List<VendorModel> vendors, Size size, double scale, EdgeInsets padding) {
    final locations = [
      for (final vendor in vendors)
        (vendor.vendorId, vendor.latitude, vendor.longitude),
    ];
    if (_mapViewportSize == size &&
        _mapViewportPadding == padding &&
        _mapCoordinateScale == scale &&
        listEquals(_projectionLocations, locations)) {
      return;
    }
    _mapViewportSize = size;
    _mapViewportPadding = padding;
    _mapCoordinateScale = scale;
    _projectionVendors = List<VendorModel>.of(vendors);
    _projectionLocations = locations;
    _boundsRequest++;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _scheduleViewportRefresh();
    });
  }

  // Throttle rather than debounce so cards update during a continuous gesture.
  void _scheduleViewportRefresh() {
    if (_viewportRefreshTimer?.isActive ?? false) return;
    _viewportRefreshTimer = Timer(const Duration(milliseconds: 80), () {
      _viewportRefreshTimer = null;
      if (mounted) _updateVisibleBounds(cameraIdle: false);
    });
  }

  // Cards follow the full map, including its padded region.
  // Scrolling cards never moves this camera.
  void _updateVisibleBounds({bool cameraIdle = true}) async {
    final controller = _mapController;
    final size = _mapViewportSize;
    if (controller == null || size.isEmpty) return;
    final vendors = _projectionVendors;
    final scale = _mapCoordinateScale;
    final request = ++_boundsRequest;
    final movedByUser = _cameraMovedByUser && !_programmaticCameraMove;
    try {
      final bounds = await controller.getVisibleRegion();
      final coordinates = await Future.wait([
        for (final vendor in vendors)
          controller
              .getScreenCoordinate(LatLng(vendor.latitude, vendor.longitude)),
      ]);
      if (!mounted ||
          controller != _mapController ||
          request != _boundsRequest) {
        return;
      }
      final visibleIds = <String>{
        for (var i = 0; i < vendors.length; i++)
          if (stallMarkerIntersectsViewport(
            coordinate: coordinates[i],
            viewport: size,
            pixelsPerLogicalPixel: scale,
          ))
            vendors[i].vendorId,
      };
      setState(() {
        _cameraMovedByUser = false;
        _onScreenVendorIds = visibleIds;
        _pendingBounds = bounds;
        _searchedBounds ??= bounds;
        if (movedByUser) {
          final previous = _searchedBounds!;
          _showSearchArea =
              (previous.southwest.latitude - bounds.southwest.latitude).abs() >
                      .0001 ||
                  (previous.southwest.longitude - bounds.southwest.longitude)
                          .abs() >
                      .0001 ||
                  (previous.northeast.latitude - bounds.northeast.latitude)
                          .abs() >
                      .0001 ||
                  (previous.northeast.longitude - bounds.northeast.longitude)
                          .abs() >
                      .0001;
        }
        if (cameraIdle) {
          _programmaticCameraMove = false;
          _cameraMoveGuard?.cancel();
        }
      });
    } catch (_) {
      if (cameraIdle && mounted && request == _boundsRequest) {
        _programmaticCameraMove = false;
        _cameraMoveGuard?.cancel();
      }
    }
  }

  void _searchThisArea() {
    if (_pendingBounds == null || _mapCenter == null) return;
    setState(() {
      _searchedBounds = _pendingBounds;
      _selectedDishId = null;
      _searchCenter = _mapCenter;
      _showSearchArea = false;
      _selectedVendorId = null;
    });
  }

  Future<void> _resetCompass() async {
    final controller = _mapController;
    if (controller == null) return;

    try {
      _expectProgrammaticCameraMove();
      final camera = _lastCameraPosition;
      final zoom = camera?.zoom ?? await controller.getZoomLevel();
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: camera?.target ??
                _mapCenter ??
                _searchCenter ??
                _customerPosition ??
                _defaultPosition.target,
            zoom: zoom,
            bearing: 0,
            tilt: 0,
          ),
        ),
      );
    } catch (_) {
      // The map may be disposed while the user changes screens.
    }
  }

  Future<void> _chooseOpeningTime() async {
    final result = await showOpeningTimePicker(context);
    if (result == null || !mounted) return;
    setState(() {
      _openingTime = result;
      _statusFilter = 'All';
    });
  }

  Future<void> _choosePriceRange() async {
    _searchFocus.unfocus();
    final result =
        await showPriceRangePicker(context, initialRange: _priceRange);
    if (result == null || !mounted) return;
    setState(() {
      _priceRange = result.isActive ? result : null;
      _selectedVendorId = null;
    });
  }

  void _clearDiscoveryFilters() {
    _searchFocus.unfocus();
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _category = null;
      _priceRange = null;
      _openingTime = null;
      _statusFilter = 'All';
      _sort = DiscoverySort.distance;
      _availableOnly = false;
      _selfCollectOnly = false;
      _recentOnly = false;
      _selectedVendorId = null;
    });
  }

  bool _matchesOpening(VendorModel vendor) {
    final filter = _openingTime;
    if (filter != null) {
      return filter.end == null
          ? vendor.isScheduledOpenAt(filter.start)
          : hasScheduledOpening(filter.start, filter.end!, vendor.weeklyHours,
              vendor.temporaryClosures);
    }
    if (_statusFilter == 'Open') return vendor.isOpenNow;
    if (_statusFilter == 'Closed') return !vendor.isOpenNow;
    return true;
  }

  String _stallStatus(VendorModel vendor) => _openingTime != null
      ? 'Scheduled open'
      : vendor.isOpenNow
          ? 'Open now'
          : 'Closed';

  String _formatDistance(double meters) {
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m away';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor:
          _selectedIndex == 3 ? ProfilePage.background : AppColors.background,
      appBar: _selectedIndex == 0 || _selectedIndex == 3
          ? null
          : AppPageAppBar(
              title: Text(
                _tabTitles[_selectedIndex],
                overflow: TextOverflow.ellipsis,
              ),
              centerTitle: true,
              systemOverlayStyle: SystemUiOverlayStyle.dark,
            ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          SafeArea(top: true, bottom: false, child: _buildMapTab()),
          const CustomerFollowingScreen(),
          const CustomerNotificationsScreen(),
          CustomerProfileScreen(
            location: _customerPosition == null
                ? null
                : LocationSelection(
                    coordinates: _customerPosition!,
                    label: _customerLocationLabel ?? 'Selected location',
                  ),
            onLocationChanged: _applyCustomerLocation,
            onHomeLocation: () => _chooseSavedLocation(type: 'home'),
            onCustomLocation: () => _chooseSavedLocation(type: 'custom'),
          ),
        ],
      ),
      bottomNavigationBar: ValueListenableBuilder<double>(
        valueListenable: _previewExtent,
        builder: (context, extent, _) => AppPillNavigation(
          visibility: _selectedIndex == 0 && _previewVendorId != null
              ? 1 - StallPreviewSheet.expansionProgress(extent)
              : 1,
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() {
              _selectedIndex = index;
              if (index != 0) {
                _previewVendorId = null;
                _previewCamera = null;
              }
            });

            if (index == 0) {
              unawaited(_loadGreeting());
            }
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'Following',
            ),
            NavigationDestination(
              icon: _notificationIcon(false),
              selectedIcon: _notificationIcon(true),
              label: 'Notifications',
            ),
            NavigationDestination(
              icon: _settingsIcon(false),
              selectedIcon: _settingsIcon(true),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _mapHeader() => Row(children: [
        Expanded(
          child: Material(
            color: AppColors.cardColor.withValues(alpha: .94),
            elevation: 3,
            shadowColor: const Color(0x18000000),
            borderRadius: BorderRadius.circular(25),
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: _chooseLocationSource,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 12, 6),
                child: Row(children: [
                  const CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.mint,
                    child:
                        Icon(Icons.person_rounded, color: AppColors.textDark),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_welcomeLine,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Row(children: [
                        const Icon(Icons.place_outlined,
                            size: 13, color: AppColors.textMuted),
                        const SizedBox(width: 3),
                        Expanded(
                            child: Text(
                                _customerLocationLabel ?? 'Set your location',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11, color: AppColors.textMuted))),
                      ]),
                    ],
                  )),
                ]),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          color: AppColors.cardColor.withValues(alpha: .94),
          elevation: 3,
          shadowColor: const Color(0x18000000),
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: 'Notifications',
            onPressed: () => setState(() => _selectedIndex = 2),
            icon: _notificationIcon(false),
          ),
        ),
      ]);

  Widget _notificationIcon(bool selected) => StreamBuilder<int>(
        stream: _unreadCount,
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;
          return Badge(
            isLabelVisible: count > 0,
            label: Text(count >= 100 ? '99+' : '$count'),
            child: Icon(
              selected ? Icons.notifications : Icons.notifications_none_rounded,
            ),
          );
        },
      );

  Widget _settingsIcon(bool selected) => StreamBuilder<int>(
        stream: _bookingUnreadCount,
        builder: (context, snapshot) => Badge(
          isLabelVisible: (snapshot.data ?? 0) > 0,
          label:
              Text((snapshot.data ?? 0) > 99 ? '99+' : '${snapshot.data ?? 0}'),
          child: Icon(selected ? Icons.settings : Icons.settings_outlined),
        ),
      );

  IconData _suggestionIcon(DiscoverySuggestion suggestion) =>
      switch (suggestion.kind) {
        DiscoverySuggestionKind.dish => Icons.restaurant_menu_rounded,
        DiscoverySuggestionKind.stall => Icons.storefront_rounded,
        DiscoverySuggestionKind.category => Icons.category_outlined,
        DiscoverySuggestionKind.recent => Icons.history_rounded,
      };

  Widget _suggestionPanel(List<DiscoverySuggestion> suggestions) => Material(
        elevation: 7,
        shadowColor: const Color(0x33000000),
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 304),
          child: ListView(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            children: [
              if (_searchController.text.trim().isEmpty &&
                  _recentSearches.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 6, 0),
                  child: Row(children: [
                    const Expanded(
                        child: Text('Recent searches',
                            style: TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w700))),
                    TextButton(
                        onPressed: _clearRecentSearches,
                        child: const Text('Clear')),
                  ]),
                ),
              for (final suggestion in suggestions)
                ListTile(
                  dense: true,
                  leading: Icon(_suggestionIcon(suggestion),
                      size: 20, color: const Color(0xFF64748B)),
                  title: Text(suggestion.label,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(suggestion.detail),
                  trailing: suggestion.isRecent
                      ? IconButton(
                          tooltip: 'Remove recent search',
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () =>
                              _removeRecentSearch(suggestion.label))
                      : const Icon(Icons.north_west_rounded, size: 17),
                  onTap: () => _submitSearch(suggestion.label),
                ),
            ],
          ),
        ),
      );

  Stream<List<VendorModel>> _watchVendors() =>
      _vendorService.getAllVendors().map((vendors) {
        final ids = vendors.map((vendor) => vendor.vendorId).toSet();
        for (final id in _ratingSubscriptions.keys.toList()) {
          if (!ids.contains(id)) {
            _ratingSubscriptions.remove(id)?.cancel();
            _ratings.remove(id);
            _ratingErrors.remove(id);
          }
        }
        for (final id in ids) {
          _ratingSubscriptions.putIfAbsent(
              id,
              () => _reviewService.watchReviews(id).listen((reviews) {
                    if (!mounted) return;
                    setState(() {
                      _ratingErrors.remove(id);
                      _ratings[id] = StallRatingSummary(
                          reviews.isEmpty
                              ? 0
                              : reviews.fold<int>(
                                      0, (sum, review) => sum + review.rating) /
                                  reviews.length,
                          reviews.length);
                    });
                  }, onError: (Object _) {
                    if (mounted) setState(() => _ratingErrors.add(id));
                  }));
        }
        return vendors;
      });

  Widget _ratingLine(VendorModel vendor) {
    final summary = _ratings[vendor.vendorId];
    final text = _ratingErrors.contains(vendor.vendorId)
        ? 'Rating unavailable'
        : summary == null
            ? 'Loading rating…'
            : summary.count == 0
                ? 'No reviews yet'
                : '${summary.average.toStringAsFixed(1)} (${summary.count} ${summary.count == 1 ? 'review' : 'reviews'})';
    return Row(children: [
      const Icon(Icons.star_rounded, size: 15, color: Color(0xFF946000)),
      const SizedBox(width: 4),
      Expanded(
          child: Text(text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 11, color: AppColors.textMuted))),
    ]);
  }

  Future<void> _zoomToCluster(Cluster cluster) async {
    final controller = _mapController;
    if (controller == null) return;
    try {
      if (cluster.bounds.southwest == cluster.bounds.northeast) {
        final zoom = await controller.getZoomLevel();
        await controller.animateCamera(CameraUpdate.newLatLngZoom(
            cluster.position, (zoom + 2).clamp(0, 21).toDouble()));
      } else {
        await controller
            .animateCamera(CameraUpdate.newLatLngBounds(cluster.bounds, 60));
      }
    } catch (_) {
      // The map may have been closed while its camera was updating.
    }
  }

  bool get _canSaveSearch =>
      FirebaseAuth.instance.currentUser != null &&
      FirebaseAuth.instance.currentUser!.isAnonymous == false &&
      FirebaseAuth.instance.currentUser!.emailVerified;

  Widget _buildDiscoveryList(
      AsyncSnapshot<List<VendorModel>> snapshot,
      List<VendorModel> vendors,
      List<DishSearchEntry> dishes,
      Map<String, VendorModel> vendorById,
      List<DiscoverySuggestion> suggestions) {
    final showDishes = _searchQuery.trim().isNotEmpty && dishes.isNotEmpty;
    final count = showDishes ? dishes.length : vendors.length;
    return Column(children: [
      Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
          child: _mapHeader()),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() {
                    _searchQuery = value;
                    _selectedVendorId = null;
                  }),
              onSubmitted: _submitSearch,
              decoration: InputDecoration(
                  hintText: 'Search dishes or stalls…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          icon: const Icon(Icons.close),
                          onPressed: () => setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                                _selectedVendorId = null;
                              }))))),
      Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 0, 4),
          child: _compactMapFilters()),
      if (suggestions.isNotEmpty)
        ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 150),
            child: _suggestionPanel(suggestions)),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Expanded(
                child: Text('$count ${showDishes ? 'dishes' : 'stalls'}',
                    style: const TextStyle(fontWeight: FontWeight.w700))),
            if ((_searchCenter ?? _customerPosition) == null)
              const Flexible(
                  child: Text('Set a location for distance sorting',
                      style:
                          TextStyle(fontSize: 11, color: AppColors.textMuted))),
          ])),
      Expanded(
          child: snapshot.hasError
              ? Center(
                  child: TextButton(
                      onPressed: () =>
                          setState(() => _vendors = _watchVendors()),
                      child: const Text('Retry loading stalls')))
              : snapshot.connectionState == ConnectionState.waiting
                  ? const Center(child: CircularProgressIndicator())
                  : count == 0
                      ? Center(
                          child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                  _dishesLoading
                                      ? 'Loading dishes…'
                                      : _dishSearchError ??
                                          'No results match these filters. Try another search or a wider area.',
                                  textAlign: TextAlign.center)))
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(16, 4, 16,
                              MediaQuery.paddingOf(context).bottom + 24),
                          itemCount: count,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final scaled =
                                MediaQuery.textScalerOf(context).scale(14) > 19;
                            return SizedBox(
                                height: scaled
                                    ? 210
                                    : showDishes
                                        ? 144
                                        : 136,
                                child: showDishes
                                    ? _dishCard(dishes[index],
                                        vendorById[dishes[index].vendorId]!)
                                    : _stallCard(vendors[index]));
                          })),
    ]);
  }

  Map<String, dynamic> _currentSearchFilters() {
    final center = _searchCenter ?? _customerPosition;
    return {
      'query': _searchController.text.trim(),
      'category': _category,
      'minimum': _priceRange?.minimum,
      'maximum': _priceRange?.maximum,
      'radius': _searchRadiusKm,
      'status': _statusFilter,
      'sort': _sort.name,
      'availableOnly': _availableOnly,
      'selfCollectOnly': _selfCollectOnly,
      'recentOnly': _recentOnly,
      'listOnly': _listOnly,
      'latitude': center?.latitude,
      'longitude': center?.longitude,
      'openingStart': _openingTime?.start.millisecondsSinceEpoch,
      'openingEnd': _openingTime?.end?.millisecondsSinceEpoch,
      'openingLabel': _openingTime?.label,
    };
  }

  Future<void> _saveCurrentSearch() async {
    if (!_canSaveSearch) return;
    _searchFocus.unfocus();
    final filters = _currentSearchFilters();
    final query = _searchController.text.trim();
    var name =
        '${query.isEmpty ? 'Nearby stalls' : query}${_priceRange == null ? '' : ' · ${_priceRange!.label}'} · within ${_searchRadiusKm.toStringAsFixed(0)} km';
    if (name.length > 80) name = name.substring(0, 80);
    final chosen = await showDialog<String>(
        context: context,
        builder: (dialog) => StatefulBuilder(
            builder: (context, update) => AlertDialog(
                    title: const Text('Save this search'),
                    content: TextFormField(
                        initialValue: name,
                        maxLength: 80,
                        decoration:
                            const InputDecoration(labelText: 'Search name'),
                        onChanged: (value) => update(() => name = value)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(dialog),
                          child: const Text('Cancel')),
                      FilledButton(
                          onPressed: name.trim().isEmpty
                              ? null
                              : () => Navigator.pop(dialog, name.trim()),
                          child: const Text('Save')),
                    ])));
    if (chosen == null || !mounted || !_canSaveSearch) return;
    try {
      await _savedSearches.save(chosen, filters);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Search saved.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not save this search. Please retry.')));
      }
    }
  }

  Future<void> _showSavedSearches() async {
    if (!_canSaveSearch) return;
    _searchFocus.unfocus();
    var future = _savedSearches.load();
    final selected = await showModalBottomSheet<SavedDiscoverySearch>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (sheet) => StatefulBuilder(
            builder: (context, update) => SizedBox(
                height: MediaQuery.sizeOf(context).height * .65,
                child: Column(children: [
                  AppSheetHeader(
                      title: const Text('Saved searches'),
                      onBack: () => Navigator.pop(sheet)),
                  Expanded(
                      child: FutureBuilder<List<SavedDiscoverySearch>>(
                          future: future,
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                  child: TextButton(
                                      onPressed: () => update(
                                          () => future = _savedSearches.load()),
                                      child: const Text(
                                          'Retry loading saved searches')));
                            }
                            if (!snapshot.hasData) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            final searches = snapshot.data!;
                            if (searches.isEmpty) {
                              return const Center(
                                  child: Text('No saved searches yet.'));
                            }
                            return ListView.builder(
                                itemCount: searches.length,
                                itemBuilder: (context, index) {
                                  final search = searches[index];
                                  return ListTile(
                                      title: Text(search.name),
                                      leading:
                                          const Icon(Icons.bookmark_outline),
                                      onTap: () => Navigator.pop(sheet, search),
                                      trailing: IconButton(
                                          tooltip: 'Delete saved search',
                                          icon:
                                              const Icon(Icons.delete_outline),
                                          onPressed: () async {
                                            try {
                                              await _savedSearches
                                                  .remove(search.id);
                                              if (context.mounted) {
                                                update(() => future =
                                                    _savedSearches.load());
                                              }
                                            } catch (_) {
                                              if (sheet.mounted) {
                                                ScaffoldMessenger.of(sheet)
                                                    .showSnackBar(const SnackBar(
                                                        content: Text(
                                                            'Could not delete this search.')));
                                              }
                                            }
                                          }));
                                });
                          })),
                ]))));
    if (selected == null || !mounted || !_canSaveSearch) return;
    final filters = selected.filters;
    setState(() {
      _searchQuery = filters['query'] as String;
      _searchController.text = _searchQuery;
      _searchController.selection =
          TextSelection.collapsed(offset: _searchQuery.length);
      _category = filters['category'] as String?;
      final minimum = (filters['minimum'] as num?)?.toDouble();
      final maximum = (filters['maximum'] as num?)?.toDouble();
      _priceRange = minimum == null && maximum == null
          ? null
          : MenuPriceRange(minimum: minimum, maximum: maximum);
      _searchRadiusKm = (filters['radius'] as num).toDouble();
      _statusFilter = filters['status'] as String;
      _sort = DiscoverySort.values.firstWhere(
          (sort) => sort.name == filters['sort'],
          orElse: () => DiscoverySort.distance);
      _availableOnly = filters['availableOnly'] == true;
      _selfCollectOnly = filters['selfCollectOnly'] == true;
      _recentOnly = filters['recentOnly'] == true;
      _listOnly = filters['listOnly'] == true;
      _searchCenter = filters['latitude'] == null
          ? null
          : LatLng((filters['latitude'] as num).toDouble(),
              (filters['longitude'] as num).toDouble());
      _openingTime = filters['openingStart'] == null
          ? null
          : OpeningTimeFilter(
              DateTime.fromMillisecondsSinceEpoch(
                  filters['openingStart'] as int),
              filters['openingLabel'] as String,
              end: filters['openingEnd'] == null
                  ? null
                  : DateTime.fromMillisecondsSinceEpoch(
                      filters['openingEnd'] as int));
      _selectedVendorId = null;
      _searchedBounds = null;
      if (_listOnly) _mapController = null;
    });
    if (!_listOnly && _searchCenter != null && _mapController != null) {
      try {
        await _mapController!
            .animateCamera(CameraUpdate.newLatLngZoom(_searchCenter!, 14));
      } catch (_) {/* The map may still be mounting. */}
    }
  }

  Widget _buildMapTab() {
    return StreamBuilder<List<VendorModel>>(
      stream: _vendors,
      builder: (context, snapshot) {
        final eligibleDishes = _allDishes
            .where((dish) => !_availableOnly || dishIsAvailable(dish))
            .toList();
        final allVendors = (snapshot.data ?? [])
            .where((v) =>
                v.hasValidLocation &&
                (_category == null || v.hasCategory(_category!)))
            .toList();

        final query = normalizeDiscoveryQuery(_searchQuery);
        final dishesByVendor = <String, List<DishSearchEntry>>{};
        for (final dish in eligibleDishes) {
          (dishesByVendor[dish.vendorId] ??= []).add(dish);
        }
        final sortMenus = _sort == DiscoverySort.price && _priceRange != null
            ? {
                for (final entry in dishesByVendor.entries)
                  entry.key: entry.value.where(_priceRange!.contains).toList()
              }
            : dishesByVendor;
        final currentRatings = {
          for (final entry in _ratings.entries)
            if (!_ratingErrors.contains(entry.key)) entry.key: entry.value
        };
        final matchingVendors = allVendors.where((vendor) {
          final menu =
              dishesByVendor[vendor.vendorId] ?? const <DishSearchEntry>[];
          if (_availableOnly &&
              (!vendor.isOpenNow || !menu.any(dishIsAvailable))) {
            return false;
          }
          if (_selfCollectOnly && !vendor.selfCollectEnabled) return false;
          if (_recentOnly && !stallUpdatedRecently(vendor, menu)) return false;
          // All stalls are visible until the customer explicitly filters hours.
          // Open now must also apply to stalls found through a dish search.
          if (!_matchesOpening(vendor)) return false;
          return vendorMatchesQueryAndPrice(
            vendor: vendor,
            dishes: dishesByVendor[vendor.vendorId] ?? const [],
            query: query,
            priceRange: _priceRange,
          );
        });
        final filteredVendors = matchingVendors.where((vendor) {
          final position = _searchCenter ?? _customerPosition;
          if (position == null) {
            return true;
          }
          return Geolocator.distanceBetween(position.latitude,
                  position.longitude, vendor.latitude, vendor.longitude) <=
              _searchRadiusKm * 1000;
        }).toList();

        final filteredVendorById = {
          for (final vendor in filteredVendors) vendor.vendorId: vendor,
        };
        final dishResults = query.isEmpty
            ? <DishSearchEntry>[]
            : eligibleDishes
                .where((dish) =>
                    discoveryMatches(query, dish.item.name) &&
                    (_priceRange == null || _priceRange!.contains(dish)) &&
                    filteredVendorById.containsKey(dish.vendorId))
                .toList()
          ..sort((a, b) => compareDiscoveryDishes(a, b,
              sort: _sort,
              vendors: filteredVendorById,
              center: _searchCenter ?? _customerPosition,
              ratings: currentRatings,
              dishes: sortMenus,
              query: query));
        final suggestionVendors = allVendors.where((vendor) {
          final center = _searchCenter ?? _customerPosition;
          return center == null ||
              Geolocator.distanceBetween(center.latitude, center.longitude,
                      vendor.latitude, vendor.longitude) <=
                  _searchRadiusKm * 1000;
        });
        final suggestions = buildDiscoverySuggestions(
          query: _searchController.text,
          vendors: suggestionVendors,
          dishes: eligibleDishes,
          categories: stallCategories,
          recentSearches: _recentSearches,
          priceRange: _priceRange,
        );
        final showSuggestions = _searchFocus.hasFocus && suggestions.isNotEmpty;
        final showingDishResults = query.isNotEmpty && dishResults.isNotEmpty;

        // Cards include only eligible stalls currently visible on the map.
        var onScreenVendors = List<VendorModel>.from(filteredVendors);

        if (!_listOnly) {
          onScreenVendors = onScreenVendors
              .where((vendor) => _onScreenVendorIds.contains(vendor.vendorId))
              .toList();
        }

        onScreenVendors.sort((a, b) => compareDiscoveryVendors(a, b,
            sort: _sort,
            center: _searchCenter ?? _customerPosition,
            ratings: currentRatings,
            dishes: sortMenus,
            query: query));

        if (!onScreenVendors
            .any((vendor) => vendor.vendorId == _selectedVendorId)) {
          if (!filteredVendorById.containsKey(_selectedVendorId)) {
            _selectedVendorId = null;
          }
        }
        if (_previewVendorId != null &&
            !onScreenVendors
                .any((vendor) => vendor.vendorId == _previewVendorId)) {
          _previewVendorId = null;
          _previewCamera = null;
        }

        final markers = filteredVendors
            .where((vendor) =>
                _markerIcons.containsKey((_markerCategory(vendor), false)))
            .map(
              (v) => Marker(
                markerId: MarkerId(v.vendorId),
                clusterManagerId:
                    v.vendorId == _selectedVendorId ? null : _clusterId,
                position: LatLng(v.latitude, v.longitude),
                anchor: const Offset(.5, .5),
                zIndexInt: v.vendorId == _selectedVendorId ? 2 : 1,
                icon: _markerIcons[(
                  _markerCategory(v),
                  v.vendorId == _selectedVendorId
                )]!,
                infoWindow: InfoWindow(
                  title: v.stallName,
                  snippet: '${v.categoryLabel} · ${_stallStatus(v)}',
                  onTap: () => _openStallPreview(v),
                ),
                consumeTapEvents: true,
                onTap: () => _selectVendor(v),
              ),
            )
            .toSet();
        if (kIsWeb &&
            _locationPermissionGranted &&
            _gpsPosition != null &&
            _gpsDotIcon != null) {
          markers.add(Marker(
            markerId: const MarkerId('current-gps-location'),
            position: _gpsPosition!,
            icon: _gpsDotIcon!,
            anchor: const Offset(.5, .5),
            zIndexInt: 3,
            infoWindow: const InfoWindow(title: 'Your current location'),
          ));
        }
        if (_listOnly) {
          return _buildDiscoveryList(snapshot, onScreenVendors, dishResults,
              filteredVendorById, showSuggestions ? suggestions : const []);
        }

        return LayoutBuilder(builder: (context, constraints) {
          // Android returns physical pixels; iOS and web return logical units.
          final coordinateScale =
              !kIsWeb && defaultTargetPlatform == TargetPlatform.android
                  ? MediaQuery.devicePixelRatioOf(context)
                  : 1.0;
          final navClearance = MediaQuery.paddingOf(context).bottom + 4;
          final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
          final geometry = DiscoveryMapGeometry(constraints.biggest);
          final overlayWidth = geometry.overlayWidth;
          const headerToSearchGap = 6.0;
          const searchToFiltersGap = 6.0;
          final headerHeight = math.max(52.0, 32 * textScale + 14);
          final searchTop = 10 + headerHeight + headerToSearchGap;
          final searchHeight = math.max(52.0, 16 * textScale + 28);
          final filterTop = searchTop + searchHeight + searchToFiltersGap;
          final headerBottom =
              filterTop + math.max(48.0, 14 * textScale + 26) + 10;
          final panelWidth = geometry.panelWidth;
          final desiredCardHeight = showingDishResults
              ? 160.0 * textScale
              : StallMapCard.preferredHeight(
                  context, panelWidth, onScreenVendors,
                  viewportFraction: geometry.viewportFraction,
                  cardsPerPage: geometry.cardsPerPage);
          final cardHeight = math.min(
              desiredCardHeight,
              math.max(100.0,
                  constraints.maxHeight - headerBottom - navClearance - 56));
          final panelHeight = cardHeight +
              DiscoveryResultsHeader.heightFor(context, panelWidth,
                  showSearchHere: _showSearchArea);
          final preview = onScreenVendors
              .where((vendor) => vendor.vendorId == _previewVendorId)
              .firstOrNull;
          final cards = showingDishResults
              ? dishResults
                  .where((dish) => onScreenVendors
                      .any((vendor) => vendor.vendorId == dish.vendorId))
                  .toList()
              : <DishSearchEntry>[];
          final resultCount =
              showingDishResults ? cards.length : onScreenVendors.length;
          final ids = showingDishResults
              ? cards
                  .map((dish) => '${dish.vendorId}/${dish.item.itemId}')
                  .toList()
              : onScreenVendors.map((vendor) => vendor.vendorId).toList();
          if (showingDishResults &&
              !cards.any((dish) =>
                  '${dish.vendorId}/${dish.item.itemId}' == _selectedDishId &&
                  dish.vendorId == _selectedVendorId)) {
            final dish = cards
                    .where((dish) => dish.vendorId == _selectedVendorId)
                    .firstOrNull ??
                cards.firstOrNull;
            _selectedDishId =
                dish == null ? null : '${dish.vendorId}/${dish.item.itemId}';
          }
          final selectedCard =
              showingDishResults ? _selectedDishId : _selectedVendorId;
          final searching = snapshot.connectionState == ConnectionState.waiting;

          return ValueListenableBuilder<double>(
            valueListenable: _previewExtent,
            builder: (context, extent, _) {
              final covered = preview == null
                  ? panelHeight + 64
                  : (constraints.maxHeight - navClearance) * extent;
              final controlsBottom = navClearance + covered + 12;
              final controlsRoom = constraints.maxHeight -
                  controlsBottom -
                  headerBottom -
                  (_locationError != null ? 60 : 0);
              final mapTopInset =
                  math.min(headerBottom, constraints.maxHeight * .38);
              // Resizing/scrolling the preview must not change map padding:
              // Google Maps shifts its camera when padding changes.
              final mapPadding = preview != null
                  ? _previewMapPadding
                  : EdgeInsets.fromLTRB(
                      12,
                      mapTopInset,
                      12,
                      math.min(
                          navClearance + covered + 12,
                          math.max(
                              12, constraints.maxHeight - mapTopInset - 80)));
              _syncMapViewport(filteredVendors, constraints.biggest,
                  coordinateScale, mapPadding);
              return Stack(
                  children: [
                Positioned.fill(
                    child: MapGestureGuard(
                        blocked: _blockMapGestures ||
                            preview != null ||
                            _selectedIndex != 0,
                        builder: (context, blocked) => GoogleMap(
                              style: _mapStyle,
                              initialCameraPosition: CameraPosition(
                                target: _lastCameraPosition?.target ??
                                    _searchCenter ??
                                    _customerPosition ??
                                    _defaultPosition.target,
                                zoom: _lastCameraPosition?.zoom ?? 14,
                              ),
                              markers: markers,
                              clusterManagers: {
                                ClusterManager(
                                    clusterManagerId: _clusterId,
                                    onClusterTap: _zoomToCluster)
                              },
                              myLocationEnabled: _locationPermissionGranted,
                              myLocationButtonEnabled: false,
                              zoomControlsEnabled: false,
                              mapToolbarEnabled: false,
                              compassEnabled: false,
                              webGestureHandling: blocked
                                  ? WebGestureHandling.none
                                  : WebGestureHandling.auto,
                              scrollGesturesEnabled: !blocked,
                              zoomGesturesEnabled: !blocked,
                              rotateGesturesEnabled: !blocked,
                              tiltGesturesEnabled: !blocked,
                              padding: mapPadding,
                              onMapCreated: (controller) {
                                _mapController = controller;
                                if (_lastCameraPosition != null) {
                                  _expectProgrammaticCameraMove();
                                  controller.moveCamera(
                                      CameraUpdate.newCameraPosition(
                                          _lastCameraPosition!));
                                } else if (_customerPosition != null) {
                                  _expectProgrammaticCameraMove();
                                  controller.animateCamera(
                                      CameraUpdate.newLatLngZoom(
                                          _customerPosition!, 15));
                                }
                                _updateVisibleBounds();
                              },
                              onCameraMove: (position) {
                                _mapCenter = position.target;
                                _lastCameraPosition = position;
                                _scheduleViewportRefresh();
                                if ((_mapBearing.value - position.bearing)
                                        .abs() >
                                    .1) {
                                  _mapBearing.value = position.bearing;
                                }
                              },
                              onCameraMoveStarted: () {
                                _boundsRequest++;
                                if (!_programmaticCameraMove) {
                                  _cameraMovedByUser = true;
                                }
                              },
                              onCameraIdle: () {
                                _viewportRefreshTimer?.cancel();
                                _viewportRefreshTimer = null;
                                _updateVisibleBounds();
                              },
                              onTap: (_) => _searchFocus.unfocus(),
                            ))),
                Positioned(
                    top: 10,
                    left: 12,
                    width: overlayWidth,
                    height: headerHeight,
                    child: _mapHeader()),
                Positioned(
                    top: searchTop,
                    left: 12,
                    width: overlayWidth,
                    height: searchHeight,
                    child: Material(
                      color: AppColors.cardColor,
                      elevation: 3,
                      shadowColor: const Color(0x22000000),
                      borderRadius: BorderRadius.circular(28),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocus,
                        textInputAction: TextInputAction.search,
                        onChanged: (value) => setState(() {
                          _searchQuery = value;
                          _selectedVendorId = null;
                          _selectedDishId = null;
                          _previewVendorId = null;
                        }),
                        onSubmitted: _submitSearch,
                        decoration: InputDecoration(
                          filled: false,
                          hintText: 'Search dishes or stalls…',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 14),
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: AppColors.textMuted),
                          suffixIcon: _searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'Clear search',
                                  icon: const Icon(Icons.close_rounded),
                                  onPressed: () => setState(() {
                                    _searchController.clear();
                                    _searchQuery = '';
                                    _selectedVendorId = null;
                                    _selectedDishId = null;
                                  }),
                                ),
                        ),
                      ),
                    )),
                Positioned(
                    top: filterTop,
                    left: 12,
                    width: overlayWidth,
                    child: _compactMapFilters()),
                if (_locationError != null && preview == null)
                  Positioned(
                      top: headerBottom,
                      left: 12,
                      width: overlayWidth,
                      child: Material(
                        color: AppColors.cardColor,
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Row(children: [
                            const Icon(Icons.location_off_outlined, size: 18),
                            const SizedBox(width: 8),
                            const Expanded(
                                child: Text(
                                    'Location unavailable. Browse the map or set a location.',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 11))),
                            TextButton(
                                onPressed: _chooseLocationSource,
                                child: const Text('Set location')),
                          ]),
                        ),
                      )),
                if (controlsRoom >= 48 && (preview == null || extent < .7))
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 120),
                    right: 12,
                    bottom: controlsBottom,
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      if (controlsRoom >= 104) ...[
                        FloatingActionButton.small(
                          heroTag: 'compass_button',
                          tooltip: 'Reset compass',
                          backgroundColor: AppColors.cardColor,
                          onPressed: _resetCompass,
                          child: ValueListenableBuilder<double>(
                              valueListenable: _mapBearing,
                              builder: (_, bearing, __) => Transform.rotate(
                                  angle: -bearing * math.pi / 180,
                                  child: const Icon(Icons.navigation_rounded))),
                        ),
                        const SizedBox(height: 8),
                      ],
                      FloatingActionButton.small(
                        heroTag: 'recenter_button',
                        tooltip: 'My location',
                        backgroundColor: AppColors.cardColor,
                        onPressed: _getCustomerLocation,
                        child: _isLocatingCustomer
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.my_location_rounded),
                      ),
                    ]),
                  ),
                ...[
                  Positioned(
                    left: geometry.panelLeft,
                    bottom: navClearance,
                    width: panelWidth,
                    height: panelHeight,
                    child: IgnorePointer(
                      ignoring: preview != null,
                      child: ExcludeSemantics(
                        excluding: preview != null,
                        child: Opacity(
                          opacity: preview == null
                              ? 1
                              : (1 - extent / .28).clamp(0.0, 1.0),
                          child: Listener(
                              behavior: HitTestBehavior.opaque,
                              onPointerDown: (event) =>
                                  _trackResultPointer(event.pointer, true),
                              onPointerUp: (event) =>
                                  _trackResultPointer(event.pointer, false),
                              onPointerCancel: (event) =>
                                  _trackResultPointer(event.pointer, false),
                              child: MouseRegion(
                                  onEnter: (_) {
                                    if (kIsWeb) {
                                      setState(
                                          () => _pointerOverResults = true);
                                    }
                                  },
                                  onExit: (_) {
                                    if (kIsWeb) {
                                      setState(
                                          () => _pointerOverResults = false);
                                    }
                                  },
                                  child: Column(children: [
                                    DiscoveryResultsHeader(
                                      countLabel:
                                          '$resultCount ${showingDishResults ? 'dishes' : 'stalls'} nearby',
                                      actionLabel: snapshot.hasError
                                          ? 'Retry'
                                          : 'View all',
                                      onViewAll: snapshot.hasError
                                          ? () => setState(
                                              () => _vendors = _watchVendors())
                                          : () => showingDishResults
                                              ? _showAllDishes(
                                                  cards, filteredVendorById)
                                              : _showAllStalls(onScreenVendors),
                                      onSearchHere: _showSearchArea
                                          ? _searchThisArea
                                          : null,
                                    ),
                                    Expanded(
                                      child: searching
                                          ? const Center(
                                              child:
                                                  CircularProgressIndicator())
                                          : resultCount == 0
                                              ? Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 16),
                                                  child: Material(
                                                    color: AppColors.cardColor,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            23),
                                                    child: Center(
                                                      child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(18),
                                                          child: Text(
                                                              snapshot.hasError
                                                                  ? 'Could not load stalls. Check your connection and retry.'
                                                                  : _dishSearchError !=
                                                                              null &&
                                                                          (query
                                                                                  .isNotEmpty ||
                                                                              _priceRange !=
                                                                                  null)
                                                                      ? _dishSearchError!
                                                                      : _dishesLoading &&
                                                                              (query.isNotEmpty ||
                                                                                  _priceRange !=
                                                                                      null)
                                                                          ? 'Loading dishes and prices…'
                                                                          : 'No matching stalls in this area. Move the map, expand the distance, or reset filters.',
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                              style: const TextStyle(
                                                                  fontSize: 13,
                                                                  color: AppColors
                                                                      .textMuted))),
                                                    ),
                                                  ))
                                              : StallCardCarousel(
                                                  key: ValueKey(
                                                      showingDishResults
                                                          ? 'dish-map-cards'
                                                          : 'stall-map-cards'),
                                                  ids: ids,
                                                  selectedId: selectedCard,
                                                  viewportFraction:
                                                      geometry.viewportFraction,
                                                  cardsPerPage:
                                                      geometry.cardsPerPage,
                                                  itemBuilder: (_, index) =>
                                                      showingDishResults
                                                          ? _dishCard(
                                                              cards[index],
                                                              filteredVendorById[
                                                                  cards[index]
                                                                      .vendorId]!)
                                                          : StallMapCard(
                                                              onDoubleTap: () =>
                                                                  _openStallPreview(
                                                                      onScreenVendors[
                                                                          index]),
                                                              vendor:
                                                                  onScreenVendors[
                                                                      index],
                                                              selected: onScreenVendors[
                                                                          index]
                                                                      .vendorId ==
                                                                  _selectedVendorId,
                                                              onTap: () {
                                                                final vendor =
                                                                    onScreenVendors[
                                                                        index];
                                                                if (vendor
                                                                        .vendorId ==
                                                                    _selectedVendorId) {
                                                                  _openStallPreview(
                                                                      vendor);
                                                                } else {
                                                                  _selectVendor(
                                                                      vendor);
                                                                }
                                                              }),
                                                ),
                                    ),
                                  ]))),
                        ),
                      ),
                    ),
                  ),
                ],
                if (preview != null)
                  Positioned.fill(
                      child: _buildStallPreview(preview,
                          horizontalInset: geometry.previewInset,
                          bottomInset: navClearance)),
                if (showSuggestions && preview == null)
                  Positioned(
                      top: searchTop + searchHeight + 4,
                      left: 12,
                      width: overlayWidth,
                      child: ConstrainedBox(
                          constraints: BoxConstraints(
                              maxHeight: constraints.maxHeight * .4),
                          child: _suggestionPanel(suggestions))),
              ].map(interceptMapOverlay).toList());
            },
          );
        });
      },
    );
  }

  Widget _compactMapFilters() => DiscoveryMapFilters(
        category: _category,
        hasExtraFilters: _priceRange != null ||
            _openingTime != null ||
            _statusFilter == 'Closed' ||
            _searchRadiusKm != 5,
        openNow: _statusFilter == 'Open' && _openingTime == null,
        sort: _sort,
        availableOnly: _availableOnly,
        selfCollectOnly: _selfCollectOnly,
        recentOnly: _recentOnly,
        onCategory: (value) => setState(() {
          _category = value;
          _selectedVendorId = null;
        }),
        onOpenNow: (value) => setState(() {
          _statusFilter = value ? 'Open' : 'All';
          _openingTime = null;
        }),
        onSort: (value) => setState(() => _sort = value),
        onAvailable: (value) => setState(() => _availableOnly = value),
        onSelfCollect: (value) => setState(() => _selfCollectOnly = value),
        onRecent: (value) => setState(() => _recentOnly = value),
        onReset: _clearDiscoveryFilters,
        moreItems: [
          MenuItemButton(
              leadingIcon: Icon(_listOnly ? Icons.map_outlined : Icons.list),
              onPressed: () {
                _searchFocus.unfocus();
                setState(() {
                  _listOnly = !_listOnly;
                  _previewVendorId = null;
                  if (_listOnly) _mapController = null;
                });
              },
              child: Text(_listOnly ? 'Map view' : 'List view')),
          MenuItemButton(
              onPressed: _chooseLocationSource,
              child: const Text('Set location')),
          MenuItemButton(
              onPressed: _choosePriceRange,
              child: Text(_priceRange?.label ?? 'Any price')),
          MenuItemButton(
              onPressed: _chooseOpeningTime,
              child: Text(_openingTime?.label ?? 'Open at…')),
          SubmenuButton(
              menuStyle: discoveryMenuStyle,
              menuChildren: [
                for (final radius in [5.0, 10.0, 25.0, 50.0])
                  DiscoveryMenuChoice(
                      label: 'Within ${radius.toStringAsFixed(0)} km',
                      selected: _searchRadiusKm == radius,
                      onPressed: () => _setSearchRadius(radius)),
              ],
              child:
                  Text('Distance: ${_searchRadiusKm.toStringAsFixed(0)} km')),
          SubmenuButton(
              menuStyle: discoveryMenuStyle,
              menuChildren: [
                for (final status in ['All', 'Open', 'Closed'])
                  DiscoveryMenuChoice(
                      label: status == 'All' ? 'All stalls' : status,
                      selected: _statusFilter == status && _openingTime == null,
                      onPressed: () => setState(() {
                            _statusFilter = status;
                            _openingTime = null;
                          })),
              ],
              child: const Text('Stall status')),
          if (_canSaveSearch) ...[
            MenuItemButton(
                onPressed: _saveCurrentSearch,
                child: const Text('Save search')),
            MenuItemButton(
                onPressed: _showSavedSearches,
                child: const Text('Saved searches')),
          ],
        ],
      );

  String _markerCategory(VendorModel vendor) =>
      vendor.allCategories.where(stallCategories.contains).firstOrNull ?? '';

  Future<void> _loadMapMarkerIcons() async {
    try {
      if (kIsWeb) _gpsDotIcon = await _markerCache.currentLocationDot();
      final entries = await Future.wait([
        for (final category in ['', ...stallCategories])
          for (final selected in [false, true])
            _markerCache
                .icon(category, selected: selected)
                .then((icon) => MapEntry((category, selected), icon)),
      ]);
      if (mounted) setState(() => _markerIcons.addEntries(entries));
    } catch (_) {
      // A disposed renderer must not interrupt discovery.
    }
  }

  void _openStallPreview(VendorModel vendor) {
    _searchFocus.unfocus();
    _previewExtent.value = 0;
    _previewCamera = _lastCameraPosition;
    _previewMapPadding = _mapViewportPadding;
    final user = FirebaseAuth.instance.currentUser;
    _previewFollowStream = user == null || user.isAnonymous
        ? Stream.value(false)
        : _followService.isFollowing(user.uid, vendor.vendorId);
    _expectProgrammaticCameraMove();
    setState(() {
      _selectedVendorId = vendor.vendorId;
      _previewVendorId = vendor.vendorId;
    });
  }

  Future<void> _closeStallPreview() async {
    final camera = _previewCamera;
    _expectProgrammaticCameraMove();
    setState(() {
      _previewVendorId = null;
      _previewCamera = null;
    });
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    if (camera != null && _mapController != null) {
      try {
        await _mapController!
            .animateCamera(CameraUpdate.newCameraPosition(camera));
      } catch (_) {/* Map can be disposed during navigation. */}
    }
  }

  Widget _buildStallPreview(VendorModel vendor,
          {required double horizontalInset, required double bottomInset}) =>
      StreamBuilder<bool>(
        stream: _previewFollowStream,
        builder: (context, snapshot) => StallPreviewSheet(
          key: ValueKey('preview-${vendor.vendorId}'),
          vendor: vendor,
          horizontalInset: horizontalInset,
          bottomInset: bottomInset,
          rating: _ratingLine(vendor),
          distance: _distanceTo(vendor),
          photos: <String>{
            if (vendor.imageUrl.isNotEmpty) vendor.imageUrl,
            ..._allDishes
                .where((dish) => dish.vendorId == vendor.vendorId)
                .map((dish) => dish.item.imageUrl)
                .where((url) => url.isNotEmpty)
          }.take(6).toList(),
          following: snapshot.data ?? false,
          onFollow: _followingBusy ||
                  snapshot.connectionState == ConnectionState.waiting
              ? null
              : () => snapshot.hasError
                  ? _retryPreviewFollow(vendor)
                  : _togglePreviewFollow(vendor, snapshot.data ?? false),
          onDirections: () => _previewDirections(vendor),
          onViewMenu: () => _openVendorDetails(vendor,
              dishId: _allDishes
                  .where((dish) => dish.vendorId == vendor.vendorId)
                  .firstOrNull
                  ?.item
                  .itemId),
          onSelfCollect: vendor.isOpenNow && vendor.hasValidLocation
              ? () => _previewSelfCollect(vendor)
              : null,
          onDetails: () => _openVendorDetails(vendor),
          onClose: _closeStallPreview,
          onExtentChanged: (extent) {
            if ((_previewExtent.value - extent).abs() > .0001) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted || _previewVendorId != vendor.vendorId) return;
                _previewExtent.value = extent;
              });
            }
          },
        ),
      );

  void _retryPreviewFollow(VendorModel vendor) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) return;
    setState(() => _previewFollowStream =
        _followService.isFollowing(user.uid, vendor.vendorId));
    _previewMessage('Could not load following. Retrying…');
  }

  void _previewMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<bool> _requireCustomerForPreview() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      final signIn = await showDialog<bool>(
          context: context,
          builder: (dialog) => AlertDialog(
                title: const Text('Sign in to continue'),
                content: const Text(
                    'Use your customer account to follow stalls or book self-collect.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(dialog, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(dialog, true),
                      child: const Text('Sign in'))
                ],
              ));
      if (mounted && signIn == true) {
        Navigator.push(
            context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
      return false;
    }
    if (!user.emailVerified) {
      _previewMessage('Verify your email to continue.');
      return false;
    }
    final profile = await _authService.getUserData(user.uid);
    if (!mounted) return false;
    if (profile?.role != 'customer') {
      _previewMessage(
          'Only customer accounts can follow stalls or book self-collect.');
      return false;
    }
    return true;
  }

  Future<void> _togglePreviewFollow(VendorModel vendor, bool following) async {
    if (_followingBusy) return;
    setState(() => _followingBusy = true);
    try {
      if (!await _requireCustomerForPreview() || !mounted) return;
      final uid = FirebaseAuth.instance.currentUser!.uid;
      if (following) {
        await _followService.unfollowVendor(uid, vendor.vendorId);
      } else {
        await _followService.followVendor(uid, vendor.vendorId);
      }
    } catch (_) {
      _previewMessage('Could not update following. Please retry.');
    } finally {
      if (mounted) setState(() => _followingBusy = false);
    }
  }

  Future<void> _previewDirections(VendorModel vendor) async {
    try {
      final launched = await launchUrl(
          Uri.https('www.google.com', '/maps/dir/', {
            'api': '1',
            'destination': '${vendor.latitude},${vendor.longitude}',
          }),
          mode: LaunchMode.externalApplication);
      if (!launched) {
        _previewMessage('Could not open directions. Please retry.');
      }
    } catch (_) {
      _previewMessage('Could not open directions. Please retry.');
    }
  }

  Future<void> _previewSelfCollect(VendorModel vendor) async {
    try {
      if (!await _requireCustomerForPreview() || !mounted) return;
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => DemoOrderCartScreen(vendor: vendor)));
    } catch (_) {
      _previewMessage('Could not open self-collect. Please retry.');
    }
  }

  String? _distanceTo(VendorModel vendor) {
    final position = _searchCenter ?? _customerPosition;
    if (position == null) {
      return null;
    }
    return _formatDistance(Geolocator.distanceBetween(position.latitude,
        position.longitude, vendor.latitude, vendor.longitude));
  }

  String _stockLabel(String status) => switch (status) {
        'low_stock' => 'Low stock',
        'out_of_stock' => 'Out of stock',
        _ => 'In stock',
      };

  Color _stockColor(String status) => switch (status) {
        'low_stock' => const Color(0xFFB45309),
        'out_of_stock' => const Color(0xFFB91C1C),
        _ => const Color(0xFF15803D),
      };

  Widget _dishPhoto(DishSearchEntry dish, {double size = 70}) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: size,
          height: size,
          color: AppColors.mint,
          child: dish.item.imageUrl.isEmpty
              ? const Icon(Icons.restaurant_rounded, color: AppColors.primary)
              : Image.network(
                  dish.item.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                      Icons.restaurant_rounded,
                      color: AppColors.primary),
                ),
        ),
      );

  Widget _dishCard(DishSearchEntry dish, VendorModel vendor) => Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openVendorDetails(vendor, dishId: dish.item.itemId),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _dishPhoto(dish),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dish.item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(
                        dish.priceIsKnown
                            ? 'RM ${dish.item.price.toStringAsFixed(2)}'
                            : 'Price unavailable',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    Text(vendor.stallName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11)),
                    const Spacer(),
                    Wrap(spacing: 7, runSpacing: 2, children: [
                      Text(_stockLabel(dish.item.status),
                          style: TextStyle(
                              color: _stockColor(dish.item.status),
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                      Text(_stallStatus(vendor),
                          style: const TextStyle(
                              color: Color(0xFF64748B), fontSize: 10)),
                      if (_distanceTo(vendor) != null)
                        Text(_distanceTo(vendor)!,
                            style: const TextStyle(
                                color: Color(0xFF64748B), fontSize: 10)),
                    ]),
                  ],
                ),
              ),
            ]),
          ),
        ),
      );

  Widget _stallPhoto(VendorModel vendor, {double size = 48}) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Container(
            width: size,
            height: size,
            color: AppColors.mint,
            child: vendor.imageUrl.isEmpty
                ? const Icon(Icons.storefront_rounded, color: AppColors.primary)
                : Image.network(vendor.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.storefront_rounded,
                        color: AppColors.primary))),
      );

  Widget _stallCard(VendorModel vendor) {
    final selected = vendor.vendorId == _selectedVendorId;
    final distance = _distanceTo(vendor);
    final pricedMenu = _allDishes.where((dish) =>
        dish.vendorId == vendor.vendorId &&
        (!_availableOnly || dishIsAvailable(dish)) &&
        (_priceRange == null || _priceRange!.contains(dish)));
    final fromPrice = lowestDishPrice(pricedMenu, _searchQuery);

    return Material(
      color: selected ? AppColors.mint : AppColors.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _listOnly
            ? () => _openVendorDetails(vendor)
            : () => _selectVendor(vendor),
        onDoubleTap: () => _openVendorDetails(vendor),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              _stallPhoto(vendor, size: 48),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor.stallName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textDark,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        vendor.categoryLabel,
                        _stallStatus(vendor),
                        if (distance != null) distance,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(children: [
                      Expanded(child: _ratingLine(vendor)),
                      if (fromPrice != null) ...[
                        const SizedBox(width: 6),
                        Text('From RM ${fromPrice.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.primary)),
                      ],
                    ]),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(
                          vendor.hasFreshLocation
                              ? Icons.circle
                              : Icons.history_rounded,
                          size: 11,
                          color: vendor.hasFreshLocation
                              ? AppColors.openGreen
                              : AppColors.primary,
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            vendor.hasFreshLocation
                                ? 'Location updated'
                                : 'Last known location',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'View stall',
                onPressed: () => _openVendorDetails(vendor),
                icon: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAllStalls(List<VendorModel> vendors) async {
    FocusScope.of(context).unfocus();
    final selected = await showModalBottomSheet<VendorModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => PointerInterceptor(
          intercepting: kIsWeb,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * .6,
            child: Column(children: [
              const AppSheetHeader(
                  title: Text('Stalls in this area'),
                  subtitle: Text('Choose a stall to find it on the map')),
              const Divider(height: 1),
              Expanded(
                  child: ListView.separated(
                itemCount: vendors.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 80),
                itemBuilder: (context, index) {
                  final vendor = vendors[index];
                  return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: _stallPhoto(vendor),
                      title: Text(vendor.stallName),
                      subtitle: Text([
                        vendor.categoryLabel,
                        _stallStatus(vendor),
                        if (_distanceTo(vendor) != null) _distanceTo(vendor)!
                      ].join(' · ')),
                      trailing: const Icon(Icons.near_me_outlined,
                          color: AppColors.primary),
                      onTap: () => Navigator.pop(context, vendor));
                },
              )),
            ]),
          )),
    );
    if (mounted && selected != null) {
      await _selectVendor(selected);
    }
  }

  Future<void> _showAllDishes(
      List<DishSearchEntry> dishes, Map<String, VendorModel> vendors) async {
    _searchFocus.unfocus();
    final selected = await showModalBottomSheet<DishSearchEntry>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => PointerInterceptor(
          intercepting: kIsWeb,
          child: SizedBox(
            height: MediaQuery.of(context).size.height * .72,
            child: Column(children: [
              AppSheetHeader(
                  title: Text('${dishes.length} nearby dish results'),
                  subtitle:
                      Text('Results for “${_searchController.text.trim()}”')),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  itemCount: dishes.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, indent: 100),
                  itemBuilder: (context, index) {
                    final dish = dishes[index];
                    final vendor = vendors[dish.vendorId]!;
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: _dishPhoto(dish),
                      title: Text(dish.item.name),
                      subtitle: Text([
                        dish.priceIsKnown
                            ? 'RM ${dish.item.price.toStringAsFixed(2)}'
                            : 'Price unavailable',
                        _stockLabel(dish.item.status),
                        vendor.stallName,
                        if (_distanceTo(vendor) != null) _distanceTo(vendor)!,
                        _stallStatus(vendor),
                      ].join(' · ')),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => Navigator.pop(context, dish),
                    );
                  },
                ),
              ),
            ]),
          )),
    );
    if (mounted && selected != null) {
      _openVendorDetails(vendors[selected.vendorId]!,
          dishId: selected.item.itemId);
    }
  }

  void _openVendorDetails(VendorModel vendor, {String? dishId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) =>
              VendorDetailsScreen(vendor: vendor, initialDishId: dishId)),
    );
  }
}
