import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/vendor_service.dart';
import '../profile/edit_stall_screen.dart';
import '../menu/vendor_menu_screen.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});

  @override
  VendorDashboardScreenState createState() => VendorDashboardScreenState();
}

class VendorDashboardScreenState extends State<VendorDashboardScreen> {
  final _vendorService = VendorService();
  final _auth = FirebaseAuth.instance;

  VendorModel? _vendorModel;
  bool _isLoading = true;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    fetchVendorDetails();
  }

  // Public method for parent to call
  Future<void> fetchVendorDetails() async {
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

  Future<bool> _confirmShareLocation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Share Your Location?'),
        content: const Text(
          'Turning your stall Open will capture your current location and '
          'show it to customers on the map so they can find you. '
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Share Location'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

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
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Future<void> _handleStatusToggle(bool val) async {
    final user = _auth.currentUser;
    if (user == null) return;

    if (val) {
      final hasName = _vendorModel?.stallName.trim().isNotEmpty == true;
      if (!hasName) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please set your stall name before opening your stall.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final agreed = await _confirmShareLocation();
      if (!agreed) {
        return;
      }
    }

    setState(() {
      _isOpen = val;
    });

    try {
      if (val) {
        final position = await _determinePosition();

        if (position == null) {
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
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: fetchVendorDetails,
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
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
                                fetchVendorDetails();
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
