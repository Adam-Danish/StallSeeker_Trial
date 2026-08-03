import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/vendor_service.dart';
import '../following/customer_following_screen.dart';
import '../profile/customer_profile_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _vendorService = VendorService();
  int _selectedIndex = 0;

  // Default camera position: Kuala Lumpur city center.
  // TODO (later step): replace with the customer's real GPS position using Geolocator.
  static const CameraPosition _defaultPosition = CameraPosition(
    target: LatLng(3.1390, 101.6869),
    zoom: 14,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StallSeeker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      // IndexedStack keeps each tab's state alive when switching between them,
      // instead of rebuilding the map from scratch every time you tap "Following".
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
        onDestinationSelected: (index) => setState(() => _selectedIndex = index),
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
        final vendors = snapshot.data ?? [];

        final markers = vendors
            .where((v) => v.latitude != 0.0 && v.longitude != 0.0)
            .map(
              (v) => Marker(
                markerId: MarkerId(v.vendorId),
                position: LatLng(v.latitude, v.longitude),
                infoWindow: InfoWindow(title: v.stallName, snippet: v.category),
                onTap: () => _openVendorDetails(v),
              ),
            )
            .toSet();

        return Stack(
          children: [
            GoogleMap(
              initialCameraPosition: _defaultPosition,
              markers: markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            ),

            // Search bar shell — UI only for now, not wired to filtering logic yet.
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(12),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search vendors...',
                      border: InputBorder.none,
                      icon: Icon(Icons.search),
                    ),
                  ),
                ),
              ),
            ),

            if (snapshot.connectionState == ConnectionState.waiting)
              const Center(child: CircularProgressIndicator()),

            if (vendors.isEmpty &&
                snapshot.connectionState != ConnectionState.waiting)
              const Positioned(
                bottom: 24,
                left: 24,
                right: 24,
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'No vendors are open nearby right now.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _openVendorDetails(VendorModel vendor) {
    // TODO (next roadmap step): navigate to VendorDetailsScreen instead.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text('Tapped ${vendor.stallName} — details screen coming next.'),
      ),
    );
  }
}
