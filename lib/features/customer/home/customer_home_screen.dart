import '../../../core/services/notification_history_service.dart';
import '../notifications/customer_notifications_screen.dart';
import 'dart:async'; // bawak time, future dan unawaited
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/stall_categories.dart';
import '../../../core/models/stall_schedule.dart';
import '../../../core/models/dish_search_entry.dart';
import 'open_at_picker.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/dish_search_service.dart';
import '../../../core/services/search_history_service.dart';
import '../../../core/services/vendor_service.dart';
import '../following/customer_following_screen.dart';
import '../profile/customer_profile_screen.dart';
import '../vendor_details/vendor_details_screen.dart';
import '../../shared/manual_location_dialog.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _vendorService = VendorService(); // loads vendor
  final _authService = AuthService(); // loads customer info
  final _dishSearchService = DishSearchService();
  final _searchHistoryService = SearchHistoryService();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  Stream<int>? _unreadCount;

  int _selectedIndex = 0;
  String _searchQuery = '';
  GoogleMapController? _mapController; // move the map dan zoom
  LatLng? _customerPosition;
  String? _customerLocationLabel;
  double _searchRadiusKm = 5;

  // NEW: Track the visible map area to filter vendors
  LatLngBounds? _visibleBounds;
  LatLngBounds? _pendingBounds;
  LatLng? _mapCenter;
  CameraPosition? _lastCameraPosition;
  final ValueNotifier<double> _mapBearing = ValueNotifier(0);
  LatLng? _searchCenter;
  bool _showSearchArea = false;
  bool _programmaticCameraMove = false;
  OpeningTimeFilter? _openingTime;

  final List<String> _tabTitles = [
    'Home',
    'Following',
    'Notifications',
    'Profile'
  ];
  String _greeting = 'Welcome!';

  String? _selectedVendorId;
  bool _isLocatingCustomer = true;
  bool _locationPermissionGranted = false;
  String? _locationError;
  String? _category;
  String _statusFilter = 'Open';
  Timer? _freshnessTimer;
  late Stream<List<VendorModel>> _vendors;
  StreamSubscription<List<DishSearchEntry>>? _dishSubscription;
  List<DishSearchEntry> _allDishes = const [];
  List<String> _recentSearches = const [];
  bool _dishesLoading = true;
  String? _dishSearchError;
  final ScrollController _stallScrollController = ScrollController();
  List<VendorModel> _visibleVendors = [];
  double _cardExtent = 288;
  int _cameraRequest = 0;

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(3.1390, 101.6869),
    zoom: 14,
  );

// cari vendor data, tgk notification, loads customer location, name for greeting
  @override
  void initState() {
    super.initState();
    _vendors = _vendorService.getAllVendors();
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
    _searchController.dispose();
    _searchFocus
      ..removeListener(_onSearchFocusChanged)
      ..dispose();
    _dishSubscription?.cancel();
    _mapController?.dispose();
    _mapBearing.dispose();
    _stallScrollController.dispose();
    _freshnessTimer?.cancel();
    super.dispose();
  }

  void _onSearchFocusChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadRecentSearches() async {
    try {
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
        setState(() => _greeting = 'Welcome, Guest');
      }
      return;
    }

    final userData = await _authService.getUserData(user.uid);
    final name = userData?.fullName;
    if (mounted) {
      setState(() {
        _greeting =
            (name != null && name.isNotEmpty) ? 'Welcome, $name' : 'Welcome!';
      });
    }
  }

  bool _locationRequestActive = false;

  Future<void> _initializeCustomerLocation() async {
    // check kalau customer ada saved location, kalau takde baru call getcustomerlocation
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      final userData = await _authService.getUserData(user.uid);
      if (!mounted) {
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
    await _getCustomerLocation(); // get cust loc
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
      _customerPosition = selection.coordinates;
      _searchCenter = selection.coordinates;
      _visibleBounds = null;
      _showSearchArea = false;
      _customerLocationLabel = selection.label;
      _locationPermissionGranted = !isManual;
      _locationError = null; // buang error
    });
    _mapController?.animateCamera(
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
    if (mounted) {
      setState(() {
        _isLocatingCustomer = true;
        _locationError = null;
        _locationPermissionGranted = false;
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
      String label;
      try {
        label = await describeLocation(coordinates);
      } catch (_) {
        label = 'Current location';
      }
      _applyCustomerLocation(
        LocationSelection(coordinates: coordinates, label: label),
        false,
      );
    } catch (error) {
      if (mounted) {
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
    setState(() => _searchRadiusKm = radius);
    final center = _searchCenter ?? _customerPosition;
    _visibleBounds = null;
    if (center != null) {
      final zoom = switch (radius) {
        <= 5 => 13.5,
        <= 10 => 12.5,
        <= 25 => 11.0,
        _ => 10.0,
      };
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(center, zoom));
    }
  }

  // ui for set location, enter manually button
  Future<void> _chooseLocationSource() async {
    FocusScope.of(context).unfocus();
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Set your location',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
          ),
          ListTile(
            leading:
                const Icon(Icons.my_location_rounded, color: AppColors.primary),
            title: const Text('Use current location'),
            subtitle: const Text('Find stalls near where you are now'),
            onTap: () => Navigator.pop(ctx, 'current'),
          ),
          ListTile(
            leading: const Icon(Icons.edit_location_alt_outlined,
                color: AppColors.primary),
            title: const Text('Enter manually'),
            subtitle:
                const Text('Search for an area, city, state, or postcode'),
            onTap: () => Navigator.pop(ctx, 'manual'),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
    if (!mounted || choice == null) {
      return;
    }
    if (choice == 'current') {
      await _getCustomerLocation();
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
    setState(() => _selectedVendorId = vendor.vendorId);
    _programmaticCameraMove = true;
    _revealSelectedCard();
    final controller = _mapController;
    if (controller == null) {
      return;
    }
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
    }
  }

  void _revealSelectedCard() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_stallScrollController.hasClients) {
        return;
      }
      final index =
          _visibleVendors.indexWhere((v) => v.vendorId == _selectedVendorId);
      if (index < 0) {
        return;
      }
      final offset = (index * _cardExtent)
          .clamp(
            0.0,
            _stallScrollController.position.maxScrollExtent,
          )
          .toDouble();
      _stallScrollController.animateTo(offset,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic);
    });
  }

  // NEW: Update the visible bounds whenever the map stops moving
  void _updateVisibleBounds() async {
    if (_mapController == null) {
      return;
    }
    try {
      final bounds = await _mapController!.getVisibleRegion();
      if (mounted) {
        setState(() {
          _pendingBounds = bounds;
          if (_visibleBounds == null) {
            _visibleBounds = bounds;
            _showSearchArea = false;
          } else if (!_programmaticCameraMove) {
            final previous = _visibleBounds!;
            _showSearchArea =
                (previous.southwest.latitude - bounds.southwest.latitude)
                            .abs() >
                        0.0001 ||
                    (previous.southwest.longitude - bounds.southwest.longitude)
                            .abs() >
                        0.0001 ||
                    (previous.northeast.latitude - bounds.northeast.latitude)
                            .abs() >
                        0.0001 ||
                    (previous.northeast.longitude - bounds.northeast.longitude)
                            .abs() >
                        0.0001;
          }
          _programmaticCameraMove = false;
        });
        _revealSelectedCard();
      }
    } catch (_) {
      // Controller may have been disposed during navigation.
    }
  }

  void _searchThisArea() {
    if (_pendingBounds == null || _mapCenter == null) return;
    setState(() {
      _visibleBounds = _pendingBounds;
      _searchCenter = _mapCenter;
      _showSearchArea = false;
      _selectedVendorId = null;
    });
    if (_stallScrollController.hasClients) _stallScrollController.jumpTo(0);
  }

  Future<void> _resetCompass() async {
    final controller = _mapController;
    if (controller == null) return;

    try {
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
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? _greeting : _tabTitles[_selectedIndex],
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              tooltip: 'Refresh',
              onPressed: _getCustomerLocation,
            ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildMapTab(),
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
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: Color(0xFFFF6E41)),
            label: 'Discover',
          ),
          const NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite, color: Color(0xFFFF6E41)),
            label: 'Following',
          ),
          NavigationDestination(
            icon: _notificationIcon(false),
            selectedIcon: _notificationIcon(true),
            label: 'Notifications',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFFFF6E41)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _notificationIcon(bool selected) => StreamBuilder<int>(
        stream: _unreadCount,
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;
          return Badge(
            isLabelVisible: count > 0,
            label: Text(count >= 100 ? '99+' : '$count'),
            child: Icon(
                selected
                    ? Icons.notifications
                    : Icons.notifications_none_rounded,
                color: selected ? const Color(0xFFFF6E41) : null),
          );
        },
      );

  List<_SearchSuggestion> _searchSuggestions(List<VendorModel> vendors) {
    final typed = _searchController.text.trim().toLowerCase();
    final suggestions = <_SearchSuggestion>[];
    final seen = <String>{};

    void add(_SearchSuggestion suggestion) {
      final key = suggestion.label.toLowerCase();
      if (seen.add(key) && suggestions.length < 8) suggestions.add(suggestion);
    }

    for (final recent in _recentSearches) {
      if (typed.isEmpty || recent.toLowerCase().contains(typed)) {
        add(_SearchSuggestion(
          label: recent,
          detail: 'Recent search',
          icon: Icons.history_rounded,
          isRecent: true,
        ));
      }
    }
    if (typed.isEmpty) return suggestions;

    for (final dish in _allDishes) {
      if (dish.item.name.toLowerCase().contains(typed)) {
        add(_SearchSuggestion(
          label: dish.item.name,
          detail: 'Dish',
          icon: Icons.restaurant_menu_rounded,
        ));
      }
    }
    for (final vendor in vendors) {
      if (vendor.stallName.toLowerCase().contains(typed)) {
        add(_SearchSuggestion(
          label: vendor.stallName,
          detail: 'Stall',
          icon: Icons.storefront_rounded,
        ));
      }
    }
    for (final category in stallCategories) {
      if (category.toLowerCase().contains(typed)) {
        add(_SearchSuggestion(
          label: category,
          detail: 'Category',
          icon: Icons.category_outlined,
        ));
      }
    }
    return suggestions;
  }

  Widget _suggestionPanel(List<_SearchSuggestion> suggestions) => Material(
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
                  leading: Icon(suggestion.icon,
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

  Widget _buildMapTab() {
    return StreamBuilder<List<VendorModel>>(
      stream: _vendors,
      builder: (context, snapshot) {
        final allVendors = (snapshot.data ?? [])
            .where((v) =>
                v.hasValidLocation &&
                (_category == null || v.category == _category))
            .toList();

        final query = _searchQuery.trim().toLowerCase();
        final matchingDishVendorIds = query.isEmpty
            ? const <String>{}
            : _allDishes
                .where((dish) => dish.item.name.toLowerCase().contains(query))
                .map((dish) => dish.vendorId)
                .toSet();
        final matchingVendors = allVendors.where((vendor) {
          final nameMatches = vendor.stallName.toLowerCase().contains(query);
          final categoryMatches = vendor.category.toLowerCase().contains(query);
          final dishMatches = matchingDishVendorIds.contains(vendor.vendorId);
          // A dish search must show every nearby seller, including closed
          // stalls, so the customer can compare availability and status.
          if (!dishMatches && !_matchesOpening(vendor)) return false;
          return query.isEmpty || nameMatches || categoryMatches || dishMatches;
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
            : _allDishes
                .where((dish) =>
                    dish.item.name.toLowerCase().contains(query) &&
                    filteredVendorById.containsKey(dish.vendorId))
                .toList()
          ..sort((a, b) {
            final vendorA = filteredVendorById[a.vendorId]!;
            final vendorB = filteredVendorById[b.vendorId]!;
            final center = _searchCenter ?? _customerPosition;
            if (center != null) {
              final distanceA = Geolocator.distanceBetween(center.latitude,
                  center.longitude, vendorA.latitude, vendorA.longitude);
              final distanceB = Geolocator.distanceBetween(center.latitude,
                  center.longitude, vendorB.latitude, vendorB.longitude);
              final distanceOrder = distanceA.compareTo(distanceB);
              if (distanceOrder != 0) return distanceOrder;
            }
            return a.item.name
                .toLowerCase()
                .compareTo(b.item.name.toLowerCase());
          });
        final suggestions = _searchSuggestions(allVendors);
        final showSuggestions = _searchFocus.hasFocus && suggestions.isNotEmpty;
        final showingDishResults = query.isNotEmpty && dishResults.isNotEmpty;

        // NEW: Filter to only vendors that are physically inside the current map view
        var onScreenVendors = List<VendorModel>.from(filteredVendors);

        if (_visibleBounds != null) {
          final southWest = _visibleBounds!.southwest;
          final northEast = _visibleBounds!.northeast;

          onScreenVendors = onScreenVendors.where((v) {
            return v.latitude >= southWest.latitude &&
                v.latitude <= northEast.latitude &&
                v.longitude >= southWest.longitude &&
                v.longitude <= northEast.longitude;
          }).toList();
        }

        // Sort by distance for easier viewing
        onScreenVendors.sort((a, b) {
          final sortCenter = _searchCenter ?? _customerPosition;
          if (sortCenter == null) {
            return 0;
          }
          final distA = Geolocator.distanceBetween(
            sortCenter.latitude,
            sortCenter.longitude,
            a.latitude,
            a.longitude,
          );
          final distB = Geolocator.distanceBetween(
            sortCenter.latitude,
            sortCenter.longitude,
            b.latitude,
            b.longitude,
          );
          return distA.compareTo(distB);
        });

        _visibleVendors = onScreenVendors;

        final markers = filteredVendors
            .map(
              (v) => Marker(
                markerId: MarkerId(v.vendorId),
                position: LatLng(v.latitude, v.longitude),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  v.vendorId == _selectedVendorId
                      ? BitmapDescriptor.hueOrange
                      : BitmapDescriptor.hueRed,
                ),
                infoWindow: InfoWindow(
                  title: v.stallName,
                  snippet: '${v.category} · ${_stallStatus(v)}',
                  onTap: () => _openVendorDetails(v),
                ),
                consumeTapEvents: true,
                onTap: () => _selectVendor(v),
              ),
            )
            .toSet();

        return LayoutBuilder(builder: (context, constraints) {
          // The panel is a sibling below the map, never an overlay. It cannot
          // grow to obscure the map, even after tapping or scrolling a stall.
          final shortViewport = constraints.maxHeight < 400;
          final panelHeight = shortViewport
              ? 52.0
              : (constraints.maxHeight * .34).clamp(168.0, 180.0).toDouble();
          final cardWidth =
              (constraints.maxWidth - 48).clamp(220.0, 340.0).toDouble();
          _cardExtent = cardWidth + 12;
          return Column(children: [
            Expanded(
                child: Stack(children: [
              Positioned.fill(
                  child: GoogleMap(
                initialCameraPosition: _defaultPosition,
                markers: markers,
                myLocationEnabled: _locationPermissionGranted,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: false,
                padding: const EdgeInsets.fromLTRB(12, 132, 12, 12),
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (_customerPosition != null) {
                    controller.animateCamera(
                        CameraUpdate.newLatLngZoom(_customerPosition!, 15));
                  }
                  _updateVisibleBounds();
                },
                onCameraMove: (position) {
                  _mapCenter = position.target;
                  _lastCameraPosition = position;
                  if ((_mapBearing.value - position.bearing).abs() > .1) {
                    _mapBearing.value = position.bearing;
                  }
                },
                onCameraIdle: _updateVisibleBounds,
                onTap: (_) {
                  FocusScope.of(context).unfocus();
                },
              )),
              Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: Material(
                    elevation: 3,
                    shadowColor: const Color(0x22000000),
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      textInputAction: TextInputAction.search,
                      onTap: () => setState(() {}),
                      onChanged: (value) => setState(() {
                        _searchQuery = value;
                        _selectedVendorId = null;
                      }),
                      onSubmitted: _submitSearch,
                      decoration: InputDecoration(
                        hintText: 'Find dishes, stalls or categories',
                        hintStyle: const TextStyle(fontSize: 13),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
                        prefixIcon: PopupMenuButton<String>(
                          tooltip: 'Filter category',
                          icon: Icon(Icons.tune_rounded,
                              color: _category == null
                                  ? AppColors.textDark
                                  : AppColors.primary),
                          onSelected: (value) => setState(() {
                            _category = value == 'All' ? null : value;
                            _selectedVendorId = null;
                          }),
                          itemBuilder: (_) => ['All', ...stallCategories]
                              .map((value) => PopupMenuItem(
                                  value: value, child: Text(value)))
                              .toList(),
                        ),
                        suffixIcon: _searchQuery.isEmpty
                            ? const Icon(Icons.search_rounded)
                            : IconButton(
                                tooltip: 'Clear search',
                                icon: const Icon(Icons.close_rounded),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchQuery = '');
                                }),
                      ),
                    ),
                  )),
              Positioned(
                  top: 76,
                  left: 12,
                  right: 12,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(children: [
                      ActionChip(
                          avatar: const Icon(Icons.edit_location_alt_outlined,
                              size: 18),
                          label: const Text('Set location'),
                          onPressed: _chooseLocationSource),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        tooltip: 'Choose stall status',
                        onSelected: (status) => setState(() {
                          _statusFilter = status;
                          _openingTime = null;
                        }),
                        itemBuilder: (_) => ['Open', 'Closed', 'All']
                            .map((status) => PopupMenuItem(
                                value: status,
                                child: Text(status == 'Open'
                                    ? 'Open now'
                                    : status == 'Closed'
                                        ? 'Closed'
                                        : 'All stalls')))
                            .toList(),
                        child: Chip(
                            avatar: Icon(
                                _statusFilter == 'Open'
                                    ? Icons.storefront
                                    : _statusFilter == 'Closed'
                                        ? Icons.store_mall_directory_outlined
                                        : Icons.filter_alt_outlined,
                                size: 18),
                            label: Text(_openingTime != null
                                ? 'Scheduled'
                                : _statusFilter == 'Open'
                                    ? 'Open now'
                                    : _statusFilter == 'Closed'
                                        ? 'Closed'
                                        : 'All stalls')),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        tooltip: 'Choose category',
                        onSelected: (value) => setState(
                            () => _category = value == 'All' ? null : value),
                        itemBuilder: (_) => ['All', ...stallCategories]
                            .map((value) =>
                                PopupMenuItem(value: value, child: Text(value)))
                            .toList(),
                        child: Chip(
                            label: Text(_category ?? 'All categories'),
                            avatar:
                                const Icon(Icons.category_outlined, size: 18)),
                      ),
                      const SizedBox(width: 8),
                      InputChip(
                        avatar: const Icon(Icons.schedule, size: 18),
                        label: Text(_openingTime?.label ?? 'Open at…'),
                        onPressed: _chooseOpeningTime,
                        onDeleted: _openingTime == null
                            ? null
                            : () => setState(() {
                                  _openingTime = null;
                                  _statusFilter = 'Open';
                                }),
                      ),
                      if (_searchCenter != null ||
                          _customerPosition != null) ...[
                        const SizedBox(width: 8),
                        PopupMenuButton<double>(
                          tooltip: 'Choose distance',
                          onSelected: _setSearchRadius,
                          itemBuilder: (_) => [5.0, 10.0, 25.0, 50.0]
                              .map((radius) => PopupMenuItem(
                                  value: radius,
                                  child: Text(
                                      'Within ${radius.toStringAsFixed(0)} km')))
                              .toList(),
                          child: Chip(
                              avatar: const Icon(Icons.radar, size: 18),
                              label: Text(
                                  'Within ${_searchRadiusKm.toStringAsFixed(0)} km')),
                        ),
                      ],
                    ]),
                  )),
              if (_showSearchArea)
                Positioned(
                    top: 126,
                    left: 0,
                    right: 0,
                    child: Center(
                        child: ElevatedButton.icon(
                      onPressed: _searchThisArea,
                      icon: const Icon(Icons.search, size: 18),
                      label: const Text('Search this area'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF1967D2),
                          elevation: 3),
                    ))),
              if (_locationError != null)
                Positioned(
                    top: _showSearchArea ? 180 : 132,
                    left: 12,
                    right: 68,
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(children: [
                          Expanded(
                              child: Text(_locationError!,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12))),
                          TextButton(
                              onPressed: _enterCustomerLocationManually,
                              child: const Text('Enter manually')),
                        ]),
                      ),
                    ))
              else if (!shortViewport && _isLocatingCustomer)
                Positioned(
                    top: 132,
                    left: 12,
                    right: 68,
                    child: Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Text('Finding your location…',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12))))),
              Positioned(
                  right: 12,
                  bottom: 12,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    FloatingActionButton.small(
                      heroTag: 'compass_button',
                      tooltip: 'Reset compass',
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textDark,
                      onPressed: _resetCompass,
                      child: ValueListenableBuilder<double>(
                        valueListenable: _mapBearing,
                        child: const Icon(Icons.navigation_rounded),
                        builder: (context, bearing, child) => Transform.rotate(
                          angle: -bearing * math.pi / 180,
                          child: child,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton.small(
                      heroTag: 'recenter_button',
                      tooltip: 'My location',
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.textDark,
                      onPressed: _getCustomerLocation,
                      child: _isLocatingCustomer
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.my_location_rounded),
                    ),
                  ])),
              if (showSuggestions)
                Positioned(
                  top: 72,
                  left: 12,
                  right: 12,
                  child: _suggestionPanel(suggestions),
                ),
            ])),
            SizedBox(
                height: panelHeight,
                child: Material(
                  color: Colors.white,
                  child: Column(children: [
                    SizedBox(
                        height: 44,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16, right: 8),
                          child: Row(children: [
                            Expanded(
                                child: Text(
                                    snapshot.hasError
                                        ? 'Could not load stalls'
                                        : snapshot.connectionState ==
                                                ConnectionState.waiting
                                            ? 'Finding stalls…'
                                            : showingDishResults
                                                ? '${dishResults.length} dishes nearby'
                                                : query.isEmpty
                                                    ? '${onScreenVendors.length} stalls in this area'
                                                    : '${onScreenVendors.length} matching stalls in this area',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700))),
                            TextButton(
                                onPressed: snapshot.hasError
                                    ? () => setState(() => _vendors =
                                        _vendorService.getAllVendors())
                                    : showingDishResults
                                        ? () => _showAllDishes(
                                            dishResults, filteredVendorById)
                                        : onScreenVendors.isEmpty
                                            ? null
                                            : () =>
                                                _showAllStalls(onScreenVendors),
                                child: Text(
                                    snapshot.hasError ? 'Retry' : 'View all')),
                          ]),
                        )),
                    if (!shortViewport)
                      Expanded(
                          child: snapshot.connectionState ==
                                  ConnectionState.waiting
                              ? const Center(child: CircularProgressIndicator())
                              : showingDishResults
                                  ? ListView.builder(
                                      controller: _stallScrollController,
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.fromLTRB(
                                          16, 0, 4, 10),
                                      itemCount: dishResults.length,
                                      itemExtent: _cardExtent,
                                      itemBuilder: (context, index) {
                                        final dish = dishResults[index];
                                        return Padding(
                                          padding:
                                              const EdgeInsets.only(right: 12),
                                          child: _dishCard(
                                              dish,
                                              filteredVendorById[
                                                  dish.vendorId]!),
                                        );
                                      },
                                    )
                                  : onScreenVendors.isEmpty
                                      ? Center(
                                          child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 24),
                                              child: Text(
                                                  snapshot.hasError
                                                      ? 'Check your connection and retry.'
                                                      : query.isNotEmpty &&
                                                              _dishSearchError !=
                                                                  null
                                                          ? 'Could not search dishes. Check your connection and retry.'
                                                          : query.isNotEmpty &&
                                                                  _dishesLoading
                                                              ? 'Searching dishes…'
                                                              : _customerPosition !=
                                                                          null &&
                                                                      _searchRadiusKm <
                                                                          50
                                                                  ? 'No stalls found within ${_searchRadiusKm.toStringAsFixed(0)} km. Try Expand area.'
                                                                  : query
                                                                          .isNotEmpty
                                                                      ? 'No nearby dishes or stalls match “${_searchController.text.trim()}”.'
                                                                      : 'Move the map, zoom out, or clear your filters.',
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                      color: Color(0xFF64748B),
                                                      fontSize: 13))))
                                      : ListView.builder(
                                          controller: _stallScrollController,
                                          scrollDirection: Axis.horizontal,
                                          padding: const EdgeInsets.fromLTRB(
                                              16, 0, 4, 10),
                                          itemCount: onScreenVendors.length,
                                          itemExtent: _cardExtent,
                                          itemBuilder: (context, index) =>
                                              Padding(
                                            padding: const EdgeInsets.only(
                                                right: 12),
                                            child: _stallCard(
                                                onScreenVendors[index]),
                                          ),
                                        )),
                  ]),
                )),
          ]);
        });
      },
    );
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
          color: const Color(0xFFFFF0E9),
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
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openVendorDetails(vendor),
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
                    Text('RM ${dish.item.price.toStringAsFixed(2)}',
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
            color: const Color(0xFFFFF0E9),
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
    return Material(
      color: selected ? const Color(0xFFFFF8F3) : Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: selected ? AppColors.primary : const Color(0xFFE5E7EB),
              width: selected ? 1.5 : 1)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _selectVendor(vendor),
        onDoubleTap: () => _openVendorDetails(vendor),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 4),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _stallPhoto(vendor),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(vendor.stallName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(
                        [
                          vendor.category,
                          _stallStatus(vendor),
                          if (_distanceTo(vendor) != null) _distanceTo(vendor)!
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF64748B))),
                  ])),
              if (selected)
                const Padding(
                    padding: EdgeInsets.only(left: 4),
                    child: Icon(Icons.location_on_rounded,
                        color: AppColors.primary, size: 18)),
            ]),
            Row(children: [
              Icon(
                  vendor.hasFreshLocation
                      ? Icons.circle
                      : Icons.history_rounded,
                  size: 10,
                  color: vendor.hasFreshLocation
                      ? const Color(0xFF15803D)
                      : const Color(0xFF92400E)),
              const SizedBox(width: 5),
              Expanded(
                  child: Text(
                      vendor.hasFreshLocation
                          ? 'Location updated'
                          : 'Last known location',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF64748B)))),
              if (vendor.phoneNumber.isNotEmpty)
                TextButton.icon(
                  onPressed: () =>
                      launchUrl(Uri(scheme: 'tel', path: vendor.phoneNumber)),
                  icon: const Icon(Icons.call_outlined, size: 14),
                  label: Text(vendor.phoneNumber,
                      style: const TextStyle(fontSize: 10)),
                ),
              TextButton(
                  onPressed: () => _openVendorDetails(vendor),
                  style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      visualDensity: VisualDensity.compact),
                  child:
                      const Text('View stall', style: TextStyle(fontSize: 11))),
            ]),
          ]),
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
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * .6,
        child: Column(children: [
          ListTile(
              title: const Text('Stalls in this area',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              subtitle: const Text('Choose a stall to find it on the map'),
              trailing: IconButton(
                  tooltip: 'Close list',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context))),
          const Divider(height: 1),
          Expanded(
              child: ListView.separated(
            itemCount: vendors.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 80),
            itemBuilder: (context, index) {
              final vendor = vendors[index];
              return ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: _stallPhoto(vendor),
                  title: Text(vendor.stallName),
                  subtitle: Text([
                    vendor.category,
                    _stallStatus(vendor),
                    if (_distanceTo(vendor) != null) _distanceTo(vendor)!
                  ].join(' · ')),
                  trailing: const Icon(Icons.near_me_outlined,
                      color: AppColors.primary),
                  onTap: () => Navigator.pop(context, vendor));
            },
          )),
        ]),
      ),
    );
    if (mounted && selected != null) {
      await _selectVendor(selected);
    }
  }

  Future<void> _showAllDishes(
      List<DishSearchEntry> dishes, Map<String, VendorModel> vendors) async {
    _searchFocus.unfocus();
    final selected = await showModalBottomSheet<VendorModel>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * .72,
        child: Column(children: [
          ListTile(
            title: Text('${dishes.length} nearby dish results',
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('Results for “${_searchController.text.trim()}”'),
            trailing: IconButton(
              tooltip: 'Close results',
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
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
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: _dishPhoto(dish),
                  title: Text(dish.item.name),
                  subtitle: Text([
                    'RM ${dish.item.price.toStringAsFixed(2)}',
                    _stockLabel(dish.item.status),
                    vendor.stallName,
                    if (_distanceTo(vendor) != null) _distanceTo(vendor)!,
                    _stallStatus(vendor),
                  ].join(' · ')),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pop(context, vendor),
                );
              },
            ),
          ),
        ]),
      ),
    );
    if (mounted && selected != null) _openVendorDetails(selected);
  }

  void _openVendorDetails(VendorModel vendor) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VendorDetailsScreen(vendor: vendor)),
    );
  }
}

class _SearchSuggestion {
  const _SearchSuggestion({
    required this.label,
    required this.detail,
    required this.icon,
    this.isRecent = false,
  });

  final String label;
  final String detail;
  final IconData icon;
  final bool isRecent;
}
