import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/vendor_service.dart';
import '../following/customer_following_screen.dart';
import '../profile/customer_profile_screen.dart';
import '../vendor_details/vendor_details_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _vendorService = VendorService();
  final _authService = AuthService();
  final _searchController = TextEditingController();

  int _selectedIndex = 0;
  String _searchQuery = '';
  GoogleMapController? _mapController;
  LatLng? _customerPosition;

  // NEW: Track the visible map area to filter vendors
  LatLngBounds? _visibleBounds;

  final List<String> _tabTitles = ['Home', 'Following', 'Profile'];
  String _greeting = 'Welcome!';

  String? _selectedVendorId;
  bool _isLocatingCustomer = true;
  bool _locationPermissionGranted = false;
  String? _locationError;
  String? _category;
  Timer? _freshnessTimer;
  late Stream<List<VendorModel>> _vendors;
  final ScrollController _stallScrollController = ScrollController();
  List<VendorModel> _visibleVendors = [];
  double _cardExtent = 288;
  int _cameraRequest = 0;

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(3.1390, 101.6869),
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();
    _vendors = _vendorService.getOpenVendors();
    _getCustomerLocation();
    _loadGreeting();
    _freshnessTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) { setState(() {}); }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _mapController?.dispose();
    _stallScrollController.dispose();
    _freshnessTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadGreeting() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) { return; }

    if (user.isAnonymous) {
      if (mounted) { setState(() => _greeting = 'Welcome, Guest'); }
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

  Future<void> _getCustomerLocation() async {
    if (_isLocatingCustomer && _locationRequestActive) { return; }
    _locationRequestActive = true;
    if (mounted) { setState(() { _isLocatingCustomer = true; _locationError = null; _locationPermissionGranted = false; }); }
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { throw StateError('Turn on GPS, or browse the map manually.'); }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError(permission == LocationPermission.deniedForever
            ? 'Allow location access in phone settings, or browse manually.'
            : 'Location access denied. You can still browse the map.');
      }

      if (mounted) { setState(() => _locationPermissionGranted = true); }

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 12));
      if (!mounted) { return; }

      setState(() {
        _customerPosition = LatLng(position.latitude, position.longitude);
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_customerPosition!, 15),
      );
    } catch (error) {
      if (mounted) { setState(() {
        _locationError = error is StateError ? error.message.toString()
            : 'Could not find your location. Retry or browse the map manually.';
      }); }
    } finally {
      _locationRequestActive = false;
      if (mounted) {
        setState(() => _isLocatingCustomer = false);
      }
    }
  }

  Future<void> _selectVendor(VendorModel vendor) async {
    if (!vendor.hasValidLocation) { return; }
    FocusScope.of(context).unfocus();
    final request = ++_cameraRequest;
    setState(() => _selectedVendorId = vendor.vendorId);
    _revealSelectedCard();
    final controller = _mapController;
    if (controller == null) { return; }
    try {
      final currentZoom = await controller.getZoomLevel();
      if (!mounted || request != _cameraRequest) { return; }
      // A modest zoom-in with a useful street-level ceiling. Repeated taps
      // keep the same useful view, instead of zooming further on every tap.
      final targetZoom = currentZoom < 16 ? 16.0 : currentZoom.clamp(16.0, 17.5).toDouble();
      await controller.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(vendor.latitude, vendor.longitude), targetZoom,
      ));
    } catch (_) {
      // A controller may be disposed while the user changes screens.
    }
  }

  void _revealSelectedCard() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_stallScrollController.hasClients) { return; }
      final index = _visibleVendors.indexWhere((v) => v.vendorId == _selectedVendorId);
      if (index < 0) { return; }
      final offset = (index * _cardExtent).clamp(
        0.0, _stallScrollController.position.maxScrollExtent,
      ).toDouble();
      _stallScrollController.animateTo(offset,
        duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
    });
  }

  // NEW: Update the visible bounds whenever the map stops moving
  void _updateVisibleBounds() async {
    if (_mapController == null) { return; }
    try {
      final bounds = await _mapController!.getVisibleRegion();
      if (mounted) {
        setState(() => _visibleBounds = bounds);
        _revealSelectedCard();
      }
    } catch (_) {
      // Controller may have been disposed during navigation.
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) { return '${meters.toStringAsFixed(0)} m away'; }
    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? _greeting : _tabTitles[_selectedIndex],
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'Poppins',
          ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
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
          const CustomerProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: Color(0xFFFF6E41)),
            label: 'Discover',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite, color: Color(0xFFFF6E41)),
            label: 'Following',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFFFF6E41)),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildMapTab() {
    return StreamBuilder<List<VendorModel>>(
      stream: _vendors,
      builder: (context, snapshot) {
        final allVendors = (snapshot.data ?? []).where((v) => v.hasValidLocation &&
            (_category == null || v.category == _category)).toList();

        final query = _searchQuery.trim().toLowerCase();
        final filteredVendors = query.isEmpty
            ? allVendors
            : allVendors
                .where((v) =>
                    v.stallName.toLowerCase().contains(query) ||
                    v.category.toLowerCase().contains(query))
                .toList();

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
          if (_customerPosition == null) { return 0; }
          final distA = Geolocator.distanceBetween(
            _customerPosition!.latitude,
            _customerPosition!.longitude,
            a.latitude,
            a.longitude,
          );
          final distB = Geolocator.distanceBetween(
            _customerPosition!.latitude,
            _customerPosition!.longitude,
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
                  snippet: v.category,
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
          final panelHeight = shortViewport ? 52.0
              : (constraints.maxHeight * .34).clamp(168.0, 180.0).toDouble();
          final cardWidth = (constraints.maxWidth - 48).clamp(220.0, 340.0).toDouble();
          _cardExtent = cardWidth + 12;
          return Column(children: [
            Expanded(child: Stack(children: [
              Positioned.fill(child: GoogleMap(
                initialCameraPosition: _defaultPosition,
                markers: markers,
                myLocationEnabled: _locationPermissionGranted,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: true,
                padding: const EdgeInsets.fromLTRB(12, 76, 12, 12),
                onMapCreated: (controller) {
                  _mapController = controller;
                  if (_customerPosition != null) {
                    controller.animateCamera(CameraUpdate.newLatLngZoom(_customerPosition!, 15));
                  }
                  _updateVisibleBounds();
                },
                onCameraIdle: _updateVisibleBounds,
                onTap: (_) {
                  FocusScope.of(context).unfocus();
                },
              )),
              Positioned(top: 12, left: 12, right: 12,
                child: Material(elevation: 3, shadowColor: const Color(0x22000000),
                  color: Colors.white, borderRadius: BorderRadius.circular(18),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() { _searchQuery = value; _selectedVendorId = null; }),
                    decoration: InputDecoration(
                      hintText: 'Find a stall or food category',
                      hintStyle: const TextStyle(fontSize: 13),
                      border: InputBorder.none, enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      prefixIcon: PopupMenuButton<String>(
                        tooltip: 'Filter category', icon: Icon(Icons.tune_rounded,
                          color: _category == null ? AppColors.textDark : AppColors.primary),
                        onSelected: (value) => setState(() {
                          _category = value == 'All' ? null : value;
                          _selectedVendorId = null;
                        }),
                        itemBuilder: (_) => ['All', 'Beverages', 'Snacks & Desserts', 'Malay Food', 'Chinese Food', 'Indian Food', 'Western', 'Noodles']
                            .map((value) => PopupMenuItem(value: value, child: Text(value))).toList(),
                      ),
                      suffixIcon: _searchQuery.isEmpty ? const Icon(Icons.search_rounded)
                          : IconButton(tooltip: 'Clear search', icon: const Icon(Icons.close_rounded),
                              onPressed: () { _searchController.clear(); setState(() => _searchQuery = ''); }),
                    ),
                  ),
                )),
              if (!shortViewport && (_locationError != null || _isLocatingCustomer || _category != null))
                Positioned(top: 76, left: 12, right: 68,
                  child: Material(color: Colors.white, borderRadius: BorderRadius.circular(12),
                    child: Padding(padding: const EdgeInsets.all(10),
                      child: Text(_locationError ?? (_isLocatingCustomer ? 'Finding your location…' : 'Category: $_category'),
                        maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                    ),
                  )),
              Positioned(right: 12, bottom: 12,
                child: FloatingActionButton.small(
                  heroTag: 'recenter_button', tooltip: 'My location',
                  backgroundColor: Colors.white, foregroundColor: AppColors.textDark,
                  onPressed: _getCustomerLocation,
                  child: _isLocatingCustomer
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location_rounded),
                )),
            ])),
            SizedBox(height: panelHeight, child: Material(color: Colors.white,
              child: Column(children: [
                SizedBox(height: 44, child: Padding(
                  padding: const EdgeInsets.only(left: 16, right: 8),
                  child: Row(children: [
                    Expanded(child: Text(snapshot.hasError ? 'Could not load stalls'
                        : snapshot.connectionState == ConnectionState.waiting ? 'Finding stalls…'
                        : '${onScreenVendors.length} open stalls in this area',
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                    TextButton(onPressed: snapshot.hasError
                        ? () => setState(() => _vendors = _vendorService.getOpenVendors())
                        : onScreenVendors.isEmpty ? null : () => _showAllStalls(onScreenVendors),
                      child: Text(snapshot.hasError ? 'Retry' : 'View all')),
                  ]),
                )),
                if (!shortViewport) Expanded(child: snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator())
                    : onScreenVendors.isEmpty
                        ? Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(snapshot.hasError ? 'Check your connection and retry.'
                                : 'Move the map, zoom out, or clear your filters.', textAlign: TextAlign.center,
                                style: const TextStyle(color: Color(0xFF64748B), fontSize: 13))))
                        : ListView.builder(
                            controller: _stallScrollController,
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.fromLTRB(16, 0, 4, 10),
                            itemCount: onScreenVendors.length,
                            itemExtent: _cardExtent,
                            itemBuilder: (context, index) => Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: _stallCard(onScreenVendors[index]),
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
    final position = _customerPosition;
    if (position == null) { return null; }
    return _formatDistance(Geolocator.distanceBetween(
      position.latitude, position.longitude, vendor.latitude, vendor.longitude));
  }

  Widget _stallPhoto(VendorModel vendor, {double size = 48}) => ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: Container(width: size, height: size, color: const Color(0xFFFFF0E9),
      child: vendor.imageUrl.isEmpty ? const Icon(Icons.storefront_rounded, color: AppColors.primary)
          : Image.network(vendor.imageUrl, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.storefront_rounded, color: AppColors.primary))),
  );

  Widget _stallCard(VendorModel vendor) {
    final selected = vendor.vendorId == _selectedVendorId;
    return Material(
      color: selected ? const Color(0xFFFFF8F3) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: selected ? AppColors.primary : const Color(0xFFE5E7EB), width: selected ? 1.5 : 1)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: () => _selectVendor(vendor),
        child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(12, 10, 8, 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _stallPhoto(vendor), const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(vendor.stallName, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text([vendor.category, if (_distanceTo(vendor) != null) _distanceTo(vendor)!].join(' · '),
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
              ])),
              if (selected) const Padding(padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18)),
            ]),
            Row(children: [
              Icon(vendor.hasFreshLocation ? Icons.circle : Icons.history_rounded,
                size: 10, color: vendor.hasFreshLocation ? const Color(0xFF15803D) : const Color(0xFF92400E)),
              const SizedBox(width: 5),
              Expanded(child: Text(vendor.hasFreshLocation ? 'Location updated' : 'Last known location',
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Color(0xFF64748B)))),
              TextButton(onPressed: () => _openVendorDetails(vendor),
                style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact),
                child: const Text('View stall', style: TextStyle(fontSize: 11))),
            ]),
          ]),
        ),
      ),
    );
  }

  Future<void> _showAllStalls(List<VendorModel> vendors) async {
    FocusScope.of(context).unfocus();
    final selected = await showModalBottomSheet<VendorModel>(
      context: context, isScrollControlled: true, useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SizedBox(height: MediaQuery.of(context).size.height * .6,
        child: Column(children: [
          ListTile(title: const Text('Open stalls in this area', style: TextStyle(fontWeight: FontWeight.w700)),
            subtitle: const Text('Choose a stall to find it on the map'),
            trailing: IconButton(tooltip: 'Close list', icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))),
          const Divider(height: 1),
          Expanded(child: ListView.separated(itemCount: vendors.length,
            separatorBuilder: (_, __) => const Divider(height: 1, indent: 80),
            itemBuilder: (context, index) {
              final vendor = vendors[index];
              return ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: _stallPhoto(vendor), title: Text(vendor.stallName),
                subtitle: Text([vendor.category, if (_distanceTo(vendor) != null) _distanceTo(vendor)!].join(' · ')),
                trailing: const Icon(Icons.near_me_outlined, color: AppColors.primary),
                onTap: () => Navigator.pop(context, vendor));
            },
          )),
        ]),
      ),
    );
    if (mounted && selected != null) { await _selectVendor(selected); }
  }

  void _openVendorDetails(VendorModel vendor) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VendorDetailsScreen(vendor: vendor)),
    );
  }
}
