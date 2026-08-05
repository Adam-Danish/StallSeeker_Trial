import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/vendor_service.dart';
import '../profile/edit_stall_screen.dart';
import '../menu/vendor_menu_screen.dart';
import 'package:geolocator/geolocator.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  final _vendorService = VendorService();
  final _auth = FirebaseAuth.instance;

  VendorModel? _vendorModel;
  bool _isLoading = true;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _fetchVendorDetails();
  }

  // Fetch Vendor Profile from Firestore
  Future<void> _fetchVendorDetails() async {
    final user = _auth.currentUser;
    if (user != null) {
      VendorModel? vendor = await _vendorService.getVendorProfile(user.uid);
      if (mounted) {
        setState(() {
          _vendorModel = vendor;
          _isOpen = vendor?.isOpen ?? false;
          _isLoading = false;
        });
      }
    }
  }

  // Gets the vendor's current GPS position, handling permission requests
  // and the various ways a phone can refuse to give location.
  // Returns null if location could not be obtained for any reason.
  Future<Position?> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please turn on location services on your phone.'),
          ),
        );
      }
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // First time asking, or the vendor said "no" before but can still
      // be asked again (as opposed to "denied forever" below).
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied.')),
          );
        }
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // The vendor permanently blocked location for this app. The app
      // cannot ask again -- they must go into phone Settings manually.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission is permanently denied. '
              'Please enable it in your phone Settings > Apps > StallSeeker.',
            ),
          ),
        );
      }
      return null;
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  // Fast toggle for Open/Closed status
  Future<void> _handleStatusToggle(bool val) async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _isOpen = val;
    });

    try {
      if (val) {
        // Opening the stall: capture the vendor's current GPS location
        // first, so customers can actually find this stall on the map.
        final position = await _determinePosition();

        if (position == null) {
          // Couldn't get a location (permission denied, GPS off, etc).
          // Revert the switch instead of marking the stall "open" with
          // no location -- that would show nothing on the customer map
          // anyway, so it's misleading to leave it toggled on.
          setState(() {
            _isOpen = false;
          });
          return;
        }

        await _vendorService.updateVendorLocation(
          user.uid,
          position.latitude,
          position.longitude,
        );
      }

      await _vendorService.toggleStallStatus(user.uid, val);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(val ? 'Stall is now OPEN!' : 'Stall is now CLOSED.'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Revert switch state on failure
      setState(() {
        _isOpen = !val;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // No Scaffold/AppBar here -- VendorMainScreen (the bottom-nav shell)
    // now provides those, so this widget is just the tab's content.
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: _fetchVendorDetails,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // Live Status Switch Card
                Card(
                  color: _isOpen ? Colors.green.shade50 : Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stall Status',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              _isOpen ? 'Currently Open' : 'Currently Closed',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isOpen ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isOpen,
                          onChanged: _handleStatusToggle,
                          activeTrackColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Stall Information Overview Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _vendorModel?.stallName.isNotEmpty == true
                                    ? _vendorModel!.stallName
                                    : 'Stall Name Not Set',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const EditStallScreen(),
                                  ),
                                );
                                // Refresh details upon returning
                                _fetchVendorDetails();
                              },
                            ),
                          ],
                        ),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text('Category: ${_vendorModel?.category ?? "N/A"}'),
                        const SizedBox(height: 4),
                        Text('Hours: ${_vendorModel?.openingHours ?? "N/A"}'),
                        const SizedBox(height: 8),
                        Text(
                          _vendorModel?.description ??
                              'No description provided.',
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                        const SizedBox(height: 16),

                        // Manage Menu Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.restaurant_menu),
                            label: const Text('Manage Menu & Stock'),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const VendorMenuScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
  }
}
