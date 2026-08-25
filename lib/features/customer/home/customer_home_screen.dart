import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/vendor_service.dart';
import '../../shared/logout_helper.dart';
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

  final List<String> _tabTitles = ['Home', 'Following', 'Profile'];
  String _greeting = 'Welcome!';

  String? _selectedVendorId;
  bool _isLocatingCustomer = true;
  bool _locationPermissionGranted = false;

  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(3.1390, 101.6869),
    zoom: 14,
  );

  @override
  void initState() {
    super.initState();
    _getCustomerLocation();
    _loadGreeting();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGreeting() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (user.isAnonymous) {
      if (mounted) setState(() => _greeting = 'Welcome, Guest');
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

  Future<void> _getCustomerLocation() async {
    if (mounted) setState(() => _isLocatingCustomer = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }

      if (mounted) setState(() => _locationPermissionGranted = true);

      final position = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;

      setState(() {
        _customerPosition = LatLng(position.latitude, position.longitude);
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_customerPosition!, 15),
      );
    } catch (_) {
      // silent fallback
    } finally {
      if (mounted) {
        setState(() => _isLocatingCustomer = false);
      }
    }
  }

  void _selectVendor(VendorModel vendor) {
    setState(() => _selectedVendorId = vendor.vendorId);
    _mapController?.animateCamera(
      CameraUpdate.newLatLng(LatLng(vendor.latitude, vendor.longitude)),
    );
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m away';
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
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () => confirmAndLogout(context, _authService),
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
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: Color(0xFFFF6E41)),
            label: 'Home',
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
      stream: _vendorService.getOpenVendors(),
      builder: (context, snapshot) {
        final allVendors = snapshot.data ?? [];

        final query = _searchQuery.trim().toLowerCase();
        final filteredVendors = query.isEmpty
            ? allVendors
            : allVendors
                .where((v) =>
                    v.stallName.toLowerCase().contains(query) ||
                    v.category.toLowerCase().contains(query))
                .toList();

        final nearbyVendors = List<VendorModel>.from(filteredVendors)
            .where((v) => v.latitude != 0.0 && v.longitude != 0.0)
            .toList();

        if (_customerPosition != null) {
          nearbyVendors.sort((a, b) {
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
        }

        final markers = nearbyVendors
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
                onTap: () => _selectVendor(v),
              ),
            )
            .toSet();

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: _defaultPosition,
              markers: markers,
              myLocationEnabled: _locationPermissionGranted,
              myLocationButtonEnabled: false,
              compassEnabled: true,
              padding: const EdgeInsets.only(top: 60),
              onMapCreated: (controller) {
                _mapController = controller;
                if (_customerPosition != null) {
                  _mapController!.animateCamera(
                    CameraUpdate.newLatLngZoom(_customerPosition!, 15),
                  );
                }
              },
              onTap: (_) {
                if (_selectedVendorId != null) {
                  setState(() => _selectedVendorId = null);
                }
              },
            ),

            // Search bar
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Material(
                elevation: 4,
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search vendors...',
                      border: InputBorder.none,
                      icon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
            ),

            if (_isLocatingCustomer)
              Positioned(
                top: 68,
                left: 12,
                child: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Finding your location...',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator()),

            if (filteredVendors.isEmpty &&
                snapshot.connectionState != ConnectionState.waiting)
              Positioned(
                bottom: 130,
                left: 24,
                right: 24,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      query.isEmpty
                          ? 'No vendors are open nearby right now.'
                          : 'No vendors match "$_searchQuery".',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),

            Positioned(
              right: 12,
              bottom: nearbyVendors.isNotEmpty ? 132 : 24,
              child: FloatingActionButton.small(
                heroTag: 'recenter_button',
                tooltip: 'Go to current location',
                onPressed: () {
                  if (_customerPosition != null) {
                    _mapController?.animateCamera(
                      CameraUpdate.newLatLngZoom(_customerPosition!, 15),
                    );
                  } else {
                    _getCustomerLocation();
                  }
                },
                child: _isLocatingCustomer
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
              ),
            ),

            if (nearbyVendors.isNotEmpty)
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: SizedBox(
                  height: 112,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: nearbyVendors.length,
                    itemBuilder: (context, index) {
                      final vendor = nearbyVendors[index];
                      final isSelected = vendor.vendorId == _selectedVendorId;
                      final distanceLabel = _customerPosition != null
                          ? _formatDistance(
                              Geolocator.distanceBetween(
                                _customerPosition!.latitude,
                                _customerPosition!.longitude,
                                vendor.latitude,
                                vendor.longitude,
                              ),
                            )
                          : null;

                      return GestureDetector(
                        onTap: () {
                          if (isSelected) {
                            _openVendorDetails(vendor);
                          } else {
                            _selectVendor(vendor);
                          }
                        },
                        child: Container(
                          width: 220,
                          margin: const EdgeInsets.only(right: 10),
                          child: Card(
                            elevation: isSelected ? 8 : 4,
                            color: AppColors.cardColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                              side: isSelected
                                  ? BorderSide(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    )
                                  : BorderSide.none,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.circle,
                                        size: 10,
                                        color: vendor.isOpen
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          vendor.stallName.isNotEmpty
                                              ? vendor.stallName
                                              : 'Unnamed Stall',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    vendor.category,
                                    style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (distanceLabel != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      distanceLabel,
                                      style: TextStyle(
                                          color: Colors.grey.shade600,
                                          fontSize: 12),
                                    ),
                                  ],
                                  if (isSelected) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Tap again to view',
                                      style: TextStyle(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        fontSize: 11,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _openVendorDetails(VendorModel vendor) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => VendorDetailsScreen(vendor: vendor)),
    );
  }
}
