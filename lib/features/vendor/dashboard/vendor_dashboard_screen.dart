import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/vendor_service.dart';
import '../profile/edit_stall_screen.dart';
import '../menu/vendor_menu_screen.dart'; // ✅ Added Menu Screen import

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

  // Fast toggle for Open/Closed status
  Future<void> _handleStatusToggle(bool val) async {
    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _isOpen = val;
    });

    try {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: _isLoading
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
            ),
    );
  }
}
