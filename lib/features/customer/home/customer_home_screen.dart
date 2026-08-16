import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
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

  // Shown in the AppBar in place of a static "Search" title. Starts as
  // a neutral greeting while the user's name is being fetched.
  String _greeting = 'Welcome!';

  // Which vendor is currently highlighted -- set by tapping either a
  // marker on the map or a card in the horizontal list. Both use the
  // same selection so tapping either one highlights consistently.
  String? _selectedVendorId;

  // True while we're still trying to get the customer's GPS position.
  // Drives a small loading indicator on the map so it's clear the app
  // is actively locating them, not just stuck on the default view.
  bool _isLocatingCustomer = true;

  // Fallback camera position (Kuala Lumpur) used only until the
  // customer's real GPS position is obtained, or if location fails.
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

  // Builds the "Welcome, [Name]" greeting. Guests (anonymous sign-in)
  // have no Firestore profile document to read a name from, so they
  // get a suitable generic greeting instead.
  Future<void> _loadGreeting() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (user.isAnonymous) {
      if (mounted) setState(() => _greeting = 'Welcome!');
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

  // Gets the customer's current GPS position and, once found, animates
  // the map camera to center on them. Fails silently (falls back to the
  // default position) if permission is denied or GPS is off, since this
  // is a "nice to have" and shouldn't block the whole screen. The
  // `finally` block guarantees the loading indicator always turns off,
  // whether location succeeded, failed, or was denied.
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
      // Silently keep the default map position if anything goes wrong.
    } finally {
      if (mounted) {
        setState(() => _isLocatingCustomer = false);
      }
    }
  }

  // Highlights a vendor (on both the map marker and its card) and pans
  // the camera to it, without navigating away -- tapping the same
  // vendor again (already selected) is what actually opens details.
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
          _greeting,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
            fontFamily: 'Poppins',
          ),
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: false, // Aligns the title to the left (iOS style)
        backgroundColor: Colors.transparent, // Makes the bar invisible
        elevation: 0, // Removes the shadow
        // This screen overrides backgroundColor directly (bypassing the
        // app-wide AppBarTheme), so the status bar style needs setting
        // explicitly here too -- dark icons so time/battery/signal stay
        // visible against the light background behind this bar.
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
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
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.favorite), label: 'Following'),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildMapTab() {
    // Live Firebase stream: any vendor that opens/closes updates this map
    // instantly, without the customer needing to refresh.
    return StreamBuilder<List<VendorModel>>(
      stream: _vendorService.getOpenVendors(),
      builder: (context, snapshot) {
        final allVendors = snapshot.data ?? [];

        // Filter by search text (matches stall name or category).
        final query = _searchQuery.trim().toLowerCase();
        final filteredVendors = query.isEmpty
            ? allVendors
            : allVendors
                .where((v) =>
                    v.stallName.toLowerCase().contains(query) ||
                    v.category.toLowerCase().contains(query))
                .toList();

        // For the floating card list: sort by distance from the customer
        // when we know their position, closest first.
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
                // Selected marker shows in a different color so it's
                // clearly distinguishable from the rest.
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  v.vendorId == _selectedVendorId
                      ? BitmapDescriptor.hueOrange
                      : BitmapDescriptor.hueRed,
                ),
                infoWindow: InfoWindow(
                  title: v.stallName,
                  snippet: v.category,
                  // Tapping the info bubble (the label that pops up
                  // above a selected marker) is what opens details --
                  // tapping the marker pin itself just selects it.
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
              myLocationEnabled: true,
              // Replaced by our own recenter button below, so the
              // built-in one (which can end up hidden behind our
              // overlays) isn't shown as well.
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
                // Tapping empty map space clears the current selection.
                if (_selectedVendorId != null) {
                  setState(() => _selectedVendorId = null);
                }
              },
            ),

            // Search bar
            // Search bar
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Material(
                elevation: 2, // <--- 1. Removed the shadow
                color: const Color(
                    0xFFF4F6F8), // <--- 2. Added the light grey background (matches your login inputs)
                borderRadius: BorderRadius.circular(
                    50), // <--- 3. Made it fully pill-shaped
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      color: Color(0xFF212121),
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Search your fav vendors here...', // <--- 5. Changed the text to match the vibe
                      hintStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        color: Colors.grey
                            .shade400, // <--- 6. Made the hint text softer grey
                      ),
                      border: InputBorder.none,
                      icon: const Icon(Icons.search,
                          color: Colors.grey), // Adjust icon color here
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.grey),
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

            // Small "locating you" indicator, shown just below the
            // search bar only while GPS lookup is still in progress.
            if (_isLocatingCustomer)
              Positioned(
                top: 70,
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
                          ' Finding your location...',
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w400,
                              fontSize: 12),
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

            // Recenter-to-current-location button. Sits above the
            // nearby-stalls list when it's showing, otherwise sits
            // closer to the bottom.
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
                    // Location wasn't available earlier (denied/off at
                    // the time) -- try fetching it again now.
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

            // Floating horizontal list of nearby stalls, sitting above
            // the bottom navigation bar.
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
                          // Tap once to highlight + pan to it on the
                          // map; tap again while already selected to
                          // open the full details screen.
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
                            color: isSelected
                                ? Theme.of(context).colorScheme.primaryContainer
                                : null,
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
