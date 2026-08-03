This file is a merged representation of a subset of the codebase, containing specifically included files, combined into a single document by Repomix.

# File Summary

## Purpose
This file contains a packed representation of a subset of the repository's contents that is considered the most important context.
It is designed to be easily consumable by AI systems for analysis, code review,
or other automated processes.

## File Format
The content is organized as follows:
1. This summary section
2. Repository information
3. Directory structure
4. Repository files (if enabled)
5. Multiple file entries, each consisting of:
  a. A header with the file path (## File: path/to/file)
  b. The full contents of the file in a code block

## Usage Guidelines
- This file should be treated as read-only. Any changes should be made to the
  original repository files, not this packed version.
- When processing this file, use the file path to distinguish
  between different files in the repository.
- Be aware that this file may contain sensitive information. Handle it with
  the same level of security as you would the original repository.

## Notes
- Some files may have been excluded based on .gitignore rules and Repomix's configuration
- Binary files are not included in this packed representation. Please refer to the Repository Structure section for a complete list of file paths, including binary files
- Only files matching these patterns are included: **/*.dart
- Files matching patterns in .gitignore are excluded
- Files matching default ignore patterns are excluded
- Files are sorted by Git change count (files with more changes are at the bottom)

# Directory Structure
````
lib/
  core/
    constants/
      app_colors.dart
      firestore_collections.dart
    models/
      menu_item_model.dart
      user_model.dart
      vendor_model.dart
    services/
      lib/
        core/
          services/
            storage_service.dart
      auth_service.dart
      follow_service.dart
      menu_service.dart
      vendor_service.dart
    theme/
      app_theme.dart
  features/
    auth/
      screens/
        login_screen.dart
        register_screen.dart
      auth_wrapper.dart
    customer/
      following/
        customer_following_screen.dart
      home/
        customer_home_screen.dart
      profile/
        customer_profile_screen.dart
      vendor_details/
        vendor_details_screen.dart
    vendor/
      dashboard/
        vendor_dashboard_screen.dart
      menu/
        vendor_menu_screen.dart
      profile/
        edit_stall_screen.dart
  firebase_options.dart
  main.dart
````

# Files

## File: lib/core/services/lib/core/services/storage_service.dart
````dart
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // Opens the gallery picker. Returns null if the vendor backed out
  // without choosing anything.
  Future<File?> pickImage() async {
    final XFile? picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 80,
    );
    if (picked == null) return null;
    return File(picked.path);
  }

  // Uploads a stall's cover photo. Always uses the same file name per
  // vendor, so re-uploading overwrites the old photo instead of leaving
  // unused files in Storage.
  Future<String> uploadStallImage(String vendorId, File imageFile) async {
    final ref = _storage.ref().child('stall_images/$vendorId.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  // Uploads a photo for one menu item. Named by itemId so each dish has
  // its own file, and re-uploading a photo for the same dish overwrites it.
  Future<String> uploadMenuItemImage(
    String vendorId,
    String itemId,
    File imageFile,
  ) async {
    final ref = _storage.ref().child('menu_images/$vendorId/$itemId.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }
}
````

## File: lib/core/services/follow_service.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FollowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _followsRef => _firestore.collection('follows');

  // Combining customerId + vendorId into one predictable document ID
  // means a customer can never accidentally follow the same vendor
  // twice -- the second "follow" would just overwrite the same document.
  String _followId(String customerId, String vendorId) =>
      '${customerId}_$vendorId';

  Future<void> followVendor(String customerId, String vendorId) async {
    await _followsRef.doc(_followId(customerId, vendorId)).set({
      'customerId': customerId,
      'vendorId': vendorId,
      'followedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unfollowVendor(String customerId, String vendorId) async {
    await _followsRef.doc(_followId(customerId, vendorId)).delete();
  }

  // Live stream of whether this customer currently follows this vendor.
  // Used to show the correct Follow/Unfollow button state, and keeps it
  // in sync automatically if changed from another device.
  Stream<bool> isFollowing(String customerId, String vendorId) {
    return _followsRef
        .doc(_followId(customerId, vendorId))
        .snapshots()
        .map((doc) => doc.exists);
  }

  // Live stream of vendor IDs this customer follows -- used by the
  // Following tab to build its list.
  Stream<List<String>> getFollowedVendorIds(String customerId) {
    return _followsRef
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => doc['vendorId'] as String).toList());
  }
}
````

## File: lib/features/customer/vendor_details/vendor_details_screen.dart
````dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/models/menu_item_model.dart';
import '../../../core/services/menu_service.dart';
import '../../../core/services/follow_service.dart';

class VendorDetailsScreen extends StatelessWidget {
  final VendorModel vendor;

  const VendorDetailsScreen({super.key, required this.vendor});

  // Opens the phone's default maps app with directions to this vendor.
  Future<void> _openNavigation() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${vendor.latitude},${vendor.longitude}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'low_stock':
        return Colors.orange;
      case 'out_of_stock':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'available':
        return 'Available';
      case 'low_stock':
        return 'Low Stock';
      case 'out_of_stock':
        return 'Out of Stock';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuService = MenuService();
    final followService = FollowService();
    final customerId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(vendor.stallName.isNotEmpty ? vendor.stallName : 'Stall'),
        actions: [
          // Follow/unfollow button -- only shown if someone is logged in.
          if (customerId != null)
            StreamBuilder<bool>(
              stream: followService.isFollowing(customerId, vendor.vendorId),
              builder: (context, snapshot) {
                final isFollowing = snapshot.data ?? false;
                return IconButton(
                  icon: Icon(
                    isFollowing ? Icons.favorite : Icons.favorite_border,
                    color: isFollowing ? Colors.red : null,
                  ),
                  tooltip: isFollowing ? 'Unfollow' : 'Follow',
                  onPressed: () async {
                    if (isFollowing) {
                      await followService.unfollowVendor(
                          customerId, vendor.vendorId);
                    } else {
                      await followService.followVendor(
                          customerId, vendor.vendorId);
                    }
                  },
                );
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Stall cover photo -- only shown if the vendor has uploaded one.
          if (vendor.imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                vendor.imageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 160,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.storefront,
                      size: 48, color: Colors.grey),
                ),
              ),
            ),
          if (vendor.imageUrl.isNotEmpty) const SizedBox(height: 16),

          // Stall overview card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 12,
                        color: vendor.isOpen ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        vendor.isOpen ? 'Open now' : 'Closed',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: vendor.isOpen ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Category: ${vendor.category}'),
                  const SizedBox(height: 4),
                  Text('Hours: ${vendor.openingHours}'),
                  const SizedBox(height: 8),
                  Text(
                    vendor.description.isNotEmpty
                        ? vendor.description
                        : 'No description provided.',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.directions),
                      label: const Text('Navigate'),
                      onPressed: _openNavigation,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Text(
            'Menu',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Live menu list -- same stream the vendor's own menu screen
          // uses, so any status change the vendor makes appears here
          // instantly too.
          StreamBuilder<List<MenuItemModel>>(
            stream: menuService.getMenuItems(vendor.vendorId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final items = snapshot.data ?? [];

              if (items.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No menu items yet.')),
                );
              }

              return Column(
                children: items.map((item) {
                  return Card(
                    child: ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: SizedBox(
                          width: 48,
                          height: 48,
                          child: item.imageUrl.isNotEmpty
                              ? Image.network(
                                  item.imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.fastfood,
                                        color: Colors.grey),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.fastfood,
                                      color: Colors.grey),
                                ),
                        ),
                      ),
                      title: Text(item.name),
                      subtitle: Text('RM ${item.price.toStringAsFixed(2)}'),
                      trailing: Chip(
                        label: Text(
                          _statusLabel(item.status),
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: _statusColor(item.status),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
````

## File: lib/core/models/menu_item_model.dart
````dart
class MenuItemModel {
  final String itemId;
  final String name;
  final double price;
  final String
      status; // 'available' (Green), 'low_stock' (Yellow), 'out_of_stock' (Red)
  final String imageUrl;

  MenuItemModel({
    required this.itemId,
    required this.name,
    required this.price,
    this.status = 'available',
    this.imageUrl = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'name': name,
      'price': price,
      'status': status,
      'imageUrl': imageUrl,
    };
  }

  factory MenuItemModel.fromMap(Map<String, dynamic> map, String id) {
    return MenuItemModel(
      itemId: id,
      name: map['name'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      status: map['status'] ?? 'available',
      imageUrl: map['imageUrl'] ?? '',
    );
  }
}
````

## File: lib/core/services/menu_service.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item_model.dart';

class MenuService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream menu items for a specific vendor
  Stream<List<MenuItemModel>> getMenuItems(String vendorId) {
    return _db
        .collection('vendors')
        .doc(vendorId)
        .collection('menu')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MenuItemModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Generates a new, unused document ID for a menu item before it exists.
  // Needed when a photo has to be uploaded (and named after the item's ID)
  // before the item document itself is written.
  String newMenuItemId(String vendorId) {
    return _db.collection('vendors').doc(vendorId).collection('menu').doc().id;
  }

  // Add new menu item. Pass itemId (from newMenuItemId) when a photo was
  // uploaded ahead of time so the item is saved under that same ID.
  Future<void> addMenuItem(
    String vendorId,
    String name,
    double price, {
    String? itemId,
    String? imageUrl,
  }) async {
    final docRef = itemId != null
        ? _db.collection('vendors').doc(vendorId).collection('menu').doc(itemId)
        : _db.collection('vendors').doc(vendorId).collection('menu').doc();

    final newItem = MenuItemModel(
      itemId: docRef.id,
      name: name,
      price: price,
      status: 'available',
      imageUrl: imageUrl ?? '',
    );

    await docRef.set(newItem.toMap());
  }

  // Quick Traffic Light Status Update
  Future<void> updateItemStatus(
      String vendorId, String itemId, String newStatus) async {
    await _db
        .collection('vendors')
        .doc(vendorId)
        .collection('menu')
        .doc(itemId)
        .update({'status': newStatus});
  }

  // Update just the photo for an existing menu item
  Future<void> updateItemImage(
      String vendorId, String itemId, String imageUrl) async {
    await _db
        .collection('vendors')
        .doc(vendorId)
        .collection('menu')
        .doc(itemId)
        .update({'imageUrl': imageUrl});
  }

  // Delete item
  Future<void> deleteMenuItem(String vendorId, String itemId) async {
    await _db
        .collection('vendors')
        .doc(vendorId)
        .collection('menu')
        .doc(itemId)
        .delete();
  }
}
````

## File: lib/core/services/vendor_service.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vendor_model.dart';

class VendorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _vendorsRef => _firestore.collection('vendors');

  Future<VendorModel?> getVendorProfile(String vendorId) async {
    try {
      DocumentSnapshot doc = await _vendorsRef.doc(vendorId).get();
      if (doc.exists && doc.data() != null) {
        return VendorModel.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      print('Error fetching vendor profile: $e');
      return null;
    }
  }

  Future<void> saveVendorProfile(VendorModel vendor) async {
    try {
      await _vendorsRef.doc(vendor.vendorId).set(
            vendor.toMap(),
            SetOptions(merge: true),
          );
    } catch (e) {
      print('Error saving vendor profile: $e');
      rethrow;
    }
  }

  Future<void> toggleStallStatus(String vendorId, bool isOpen) async {
    try {
      await _vendorsRef.doc(vendorId).set({
        'vendorId': vendorId,
        'isOpen': isOpen,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error toggling stall status: $e');
      rethrow;
    }
  }

  Future<void> updateVendorLocation(
    String vendorId,
    double latitude,
    double longitude,
  ) async {
    try {
      await _vendorsRef.doc(vendorId).update({
        'latitude': latitude,
        'longitude': longitude,
      });
    } catch (e) {
      print('Error updating vendor location: $e');
      rethrow;
    }
  }

  // Live stream of vendors currently marked as open — used by the
  // customer map screen to show markers that update in real time.
  Stream<List<VendorModel>> getOpenVendors() {
    return _vendorsRef.where('isOpen', isEqualTo: true).snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) =>
                VendorModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}
````

## File: lib/core/theme/app_theme.dart
````dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    );
  }
}
````

## File: lib/features/customer/following/customer_following_screen.dart
````dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/vendor_service.dart';
import '../../../core/services/follow_service.dart';
import '../vendor_details/vendor_details_screen.dart';

class CustomerFollowingScreen extends StatelessWidget {
  const CustomerFollowingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final customerId = FirebaseAuth.instance.currentUser?.uid;
    final followService = FollowService();
    final vendorService = VendorService();

    if (customerId == null) {
      return const Center(child: Text('Please log in to see followed stalls.'));
    }

    // Live stream of vendor IDs this customer follows. If they follow/
    // unfollow anywhere (including from the details screen), this list
    // updates automatically without needing to refresh.
    return StreamBuilder<List<String>>(
      stream: followService.getFollowedVendorIds(customerId),
      builder: (context, idSnapshot) {
        if (idSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final vendorIds = idSnapshot.data ?? [];

        if (vendorIds.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                'You are not following any stalls yet.\n'
                'Tap the heart icon on a stall to follow it.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: vendorIds.length,
          itemBuilder: (context, index) {
            final vendorId = vendorIds[index];

            // Each followed ID needs its own one-time fetch to get the
            // vendor's current name/category/status for display.
            return FutureBuilder<VendorModel?>(
              future: vendorService.getVendorProfile(vendorId),
              builder: (context, vendorSnapshot) {
                if (!vendorSnapshot.hasData || vendorSnapshot.data == null) {
                  // Still loading, or the vendor profile no longer exists.
                  return const SizedBox.shrink();
                }

                final vendor = vendorSnapshot.data!;

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: vendor.isOpen
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      child: Icon(
                        Icons.storefront,
                        color: vendor.isOpen ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(vendor.stallName.isNotEmpty
                        ? vendor.stallName
                        : 'Unnamed Stall'),
                    subtitle: Text(
                        '${vendor.category} • ${vendor.isOpen ? "Open" : "Closed"}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VendorDetailsScreen(vendor: vendor),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
````

## File: lib/features/customer/home/customer_home_screen.dart
````dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/models/vendor_model.dart';
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
  final _searchController = TextEditingController();

  int _selectedIndex = 0;
  String _searchQuery = '';
  GoogleMapController? _mapController;
  LatLng? _customerPosition;

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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Gets the customer's current GPS position and, once found, animates
  // the map camera to center on them. Fails silently (falls back to the
  // default position) if permission is denied or GPS is off, since this
  // is a "nice to have" and shouldn't block the whole screen.
  Future<void> _getCustomerLocation() async {
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
        desiredAccuracy: LocationAccuracy.high,
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
    }
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m away';
    return '${(meters / 1000).toStringAsFixed(1)} km away';
  }

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
              onMapCreated: (controller) {
                _mapController = controller;
                if (_customerPosition != null) {
                  _mapController!.animateCamera(
                    CameraUpdate.newLatLngZoom(_customerPosition!, 15),
                  );
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
                        onTap: () => _openVendorDetails(vendor),
                        child: Container(
                          width: 220,
                          margin: const EdgeInsets.only(right: 10),
                          child: Card(
                            elevation: 4,
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
````

## File: lib/features/customer/profile/customer_profile_screen.dart
````dart
import 'package:flutter/material.dart';

/// Placeholder for now. Will be replaced with real profile editing,
/// change password, FAQ, and About screens in a later roadmap step.
class CustomerProfileScreen extends StatelessWidget {
  const CustomerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Text(
          'Profile, Change Password, FAQ, and About\nwill appear here.\n(Coming soon)',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
````

## File: lib/features/vendor/dashboard/vendor_dashboard_screen.dart
````dart
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
````

## File: lib/features/vendor/menu/vendor_menu_screen.dart
````dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/menu_item_model.dart';
import '../../../core/services/menu_service.dart';
import '../../../core/services/storage_service.dart';

class VendorMenuScreen extends StatefulWidget {
  const VendorMenuScreen({super.key});

  @override
  State<VendorMenuScreen> createState() => _VendorMenuScreenState();
}

class _VendorMenuScreenState extends State<VendorMenuScreen> {
  final _menuService = MenuService();
  final _storageService = StorageService();
  final _auth = FirebaseAuth.instance;

  void _showAddDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    File? pickedImage;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Menu Item'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final file = await _storageService.pickImage();
                  if (file != null) {
                    setDialogState(() {
                      pickedImage = file;
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: pickedImage != null
                      ? Image.file(pickedImage!, fit: BoxFit.cover)
                      : const Center(
                          child: Icon(Icons.add_a_photo, color: Colors.grey),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                    labelText: 'Item Name (e.g. Nasi Lemak)'),
              ),
              TextField(
                controller: priceController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Price (RM)'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isUploading
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      final price =
                          double.tryParse(priceController.text.trim()) ?? 0.0;
                      final user = _auth.currentUser;

                      if (name.isNotEmpty && price > 0 && user != null) {
                        setDialogState(() {
                          isUploading = true;
                        });

                        // Photo needs the item's ID in its filename, so
                        // generate the ID first if a photo was picked.
                        String? itemId;
                        String? imageUrl;
                        if (pickedImage != null) {
                          itemId = _menuService.newMenuItemId(user.uid);
                          imageUrl = await _storageService.uploadMenuItemImage(
                              user.uid, itemId, pickedImage!);
                        }

                        await _menuService.addMenuItem(
                          user.uid,
                          name,
                          price,
                          itemId: itemId,
                          imageUrl: imageUrl,
                        );
                        if (mounted) Navigator.pop(ctx);
                      }
                    },
              child: isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add Item'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'available':
        return Colors.green;
      case 'low_stock':
        return Colors.orange;
      case 'out_of_stock':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Menu'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddDialog,
        icon: const Icon(Icons.add),
        label: const Text('Add Dish'),
      ),
      body: user == null
          ? const Center(child: Text('Not logged in.'))
          : StreamBuilder<List<MenuItemModel>>(
              stream: _menuService.getMenuItems(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final items = snapshot.data ?? [];

                if (items.isEmpty) {
                  return const Center(
                    child:
                        Text('No menu items added yet.\nTap + Add Dish below!'),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12.0),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: SizedBox(
                                width: 48,
                                height: 48,
                                child: item.imageUrl.isNotEmpty
                                    ? Image.network(
                                        item.imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                          color: Colors.grey.shade200,
                                          child: const Icon(Icons.fastfood,
                                              color: Colors.grey),
                                        ),
                                      )
                                    : Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.fastfood,
                                            color: Colors.grey),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text('RM ${item.price.toStringAsFixed(2)}'),
                                ],
                              ),
                            ),

                            // Traffic Light Buttons
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Green Button (Available)
                                IconButton(
                                  icon: Icon(
                                    Icons.circle,
                                    color: item.status == 'available'
                                        ? Colors.green
                                        : Colors.green.shade100,
                                    size: item.status == 'available' ? 28 : 20,
                                  ),
                                  onPressed: () =>
                                      _menuService.updateItemStatus(
                                          user.uid, item.itemId, 'available'),
                                ),
                                // Yellow Button (Low Stock)
                                IconButton(
                                  icon: Icon(
                                    Icons.circle,
                                    color: item.status == 'low_stock'
                                        ? Colors.orange
                                        : Colors.orange.shade100,
                                    size: item.status == 'low_stock' ? 28 : 20,
                                  ),
                                  onPressed: () =>
                                      _menuService.updateItemStatus(
                                          user.uid, item.itemId, 'low_stock'),
                                ),
                                // Red Button (Out of Stock)
                                IconButton(
                                  icon: Icon(
                                    Icons.circle,
                                    color: item.status == 'out_of_stock'
                                        ? Colors.red
                                        : Colors.red.shade100,
                                    size:
                                        item.status == 'out_of_stock' ? 28 : 20,
                                  ),
                                  onPressed: () =>
                                      _menuService.updateItemStatus(user.uid,
                                          item.itemId, 'out_of_stock'),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.grey),
                                  onPressed: () => _menuService.deleteMenuItem(
                                      user.uid, item.itemId),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
````

## File: lib/features/vendor/profile/edit_stall_screen.dart
````dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/vendor_service.dart';
import '../../../core/services/storage_service.dart';

class EditStallScreen extends StatefulWidget {
  const EditStallScreen({super.key});

  @override
  State<EditStallScreen> createState() => _EditStallScreenState();
}

class _EditStallScreenState extends State<EditStallScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vendorService = VendorService();
  final _storageService = StorageService();
  final _auth = FirebaseAuth.instance;

  final _stallNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _openingHoursController = TextEditingController();

  String _selectedCategory = 'Beverages';
  final List<String> _categories = [
    'Beverages',
    'Snacks & Desserts',
    'Malay Food',
    'Chinese Food',
    'Indian Food',
    'Western',
    'Noodles',
  ];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isOpen = false;

  // Existing photo URL loaded from Firestore, and a newly picked local
  // file (not yet uploaded) if the vendor chose a new photo this session.
  String _existingImageUrl = '';
  File? _pickedImage;

  @override
  void initState() {
    super.initState();
    _loadExistingVendorData();
  }

  // Fetch vendor info from Firestore to pre-fill the form
  Future<void> _loadExistingVendorData() async {
    final user = _auth.currentUser;
    if (user != null) {
      VendorModel? vendor = await _vendorService.getVendorProfile(user.uid);
      if (vendor != null) {
        _stallNameController.text = vendor.stallName;
        _descriptionController.text = vendor.description;
        _openingHoursController.text = vendor.openingHours;
        _isOpen = vendor.isOpen;
        _existingImageUrl = vendor.imageUrl;
        if (_categories.contains(vendor.category)) {
          _selectedCategory = vendor.category;
        }
      }
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _pickImage() async {
    final file = await _storageService.pickImage();
    if (file != null) {
      setState(() {
        _pickedImage = file;
      });
    }
  }

  // Save updated stall profile to Firestore
  Future<void> _saveStallProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _auth.currentUser;
    if (user == null) return;

    setState(() {
      _isSaving = true;
    });

    try {
      // Only upload if the vendor picked a new photo this session.
      // Otherwise keep whatever URL was already saved.
      String imageUrl = _existingImageUrl;
      if (_pickedImage != null) {
        imageUrl =
            await _storageService.uploadStallImage(user.uid, _pickedImage!);
      }

      final vendor = VendorModel(
        vendorId: user.uid,
        stallName: _stallNameController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        openingHours: _openingHoursController.text.trim(),
        isOpen: _isOpen,
        imageUrl: imageUrl,
      );

      await _vendorService.saveVendorProfile(vendor);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stall profile saved successfully!')),
        );
        Navigator.pop(context); // Return to Dashboard
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _stallNameController.dispose();
    _descriptionController.dispose();
    _openingHoursController.dispose();
    super.dispose();
  }

  Widget _buildImagePicker() {
    Widget imageContent;
    if (_pickedImage != null) {
      imageContent = Image.file(_pickedImage!, fit: BoxFit.cover);
    } else if (_existingImageUrl.isNotEmpty) {
      imageContent = Image.network(
        _existingImageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.storefront, size: 48, color: Colors.grey),
      );
    } else {
      imageContent = const Icon(Icons.storefront, size: 48, color: Colors.grey);
    }

    return GestureDetector(
      onTap: _pickImage,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: double.infinity,
            height: 160,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAlias,
            child: imageContent,
          ),
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.all(6),
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Stall Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Stall Photo
                    _buildImagePicker(),
                    const SizedBox(height: 16),

                    // Stall Name
                    TextFormField(
                      controller: _stallNameController,
                      decoration: const InputDecoration(
                        labelText: 'Stall Name',
                        hintText: 'e.g. Uncle John Drink Stall',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Enter stall name'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Category Dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Food Category',
                        border: OutlineInputBorder(),
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedCategory = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        hintText: 'Describe your food/drinks offered...',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Enter description'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    // Operating Hours
                    TextFormField(
                      controller: _openingHoursController,
                      decoration: const InputDecoration(
                        labelText: 'Opening Hours',
                        hintText: 'e.g. 8:00 AM - 5:00 PM',
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Enter opening hours'
                          : null,
                    ),
                    const SizedBox(height: 24),

                    // Save Button
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveStallProfile,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator()
                          : const Text(
                              'Save Changes',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
````

## File: lib/core/constants/app_colors.dart
````dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color primary =
      Color(0xFFE65100); // Deep Orange / Food Stall theme
  static const Color primaryLight = Color(0xFFFF8142);
  static const Color background = Color(0xFFF8F9FA);
  static const Color cardColor = Colors.white;
  static const Color textDark = Color(0xFF212121);
  static const Color textMuted = Color(0xFF757575);

  // Status Colors
  static const Color openGreen = Color(0xFF2E7D32);
  static const Color closedRed = Color(0xFFC62828);
  static const Color limitedYellow = Color(0xFFF57F17);
}
````

## File: lib/core/constants/firestore_collections.dart
````dart
class FirestoreCollections {
  static const String users = 'users';
  static const String vendors = 'vendors';
  static const String menus = 'menus';
  static const String follows = 'follows';
}
````

## File: lib/core/models/user_model.dart
````dart
class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String role; // 'customer' or 'vendor'
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    required this.role,
    required this.createdAt,
  });

  // Convert Firestore Document to UserModel Object
  factory UserModel.fromMap(Map<String, dynamic> map, String docId) {
    return UserModel(
      uid: docId,
      email: map['email'] ?? '',
      fullName: map['fullName'] ?? '',
      role: map['role'] ?? 'customer',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as dynamic).toDate()
          : DateTime.now(),
    );
  }

  // Convert UserModel Object to Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'role': role,
      'createdAt': createdAt,
    };
  }
}
````

## File: lib/core/models/vendor_model.dart
````dart
class VendorModel {
  final String vendorId;
  final String stallName;
  final String description;
  final String category;
  final String openingHours;
  final bool isOpen;
  final double latitude;
  final double longitude;
  final String imageUrl;

  VendorModel({
    required this.vendorId,
    required this.stallName,
    required this.description,
    required this.category,
    required this.openingHours,
    this.isOpen = false,
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.imageUrl = '',
  });

  // Convert VendorModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'vendorId': vendorId,
      'stallName': stallName,
      'description': description,
      'category': category,
      'openingHours': openingHours,
      'isOpen': isOpen,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
    };
  }

  // Create VendorModel from Firestore Document Snapshot
  factory VendorModel.fromMap(Map<String, dynamic> map, String documentId) {
    return VendorModel(
      vendorId: documentId,
      stallName: map['stallName'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? '',
      openingHours: map['openingHours'] ?? '',
      isOpen: map['isOpen'] ?? false,
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
    );
  }

  // CopyWith method for easy state updates
  VendorModel copyWith({
    String? stallName,
    String? description,
    String? category,
    String? openingHours,
    bool? isOpen,
    double? latitude,
    double? longitude,
    String? imageUrl,
  }) {
    return VendorModel(
      vendorId: vendorId,
      stallName: stallName ?? this.stallName,
      description: description ?? this.description,
      category: category ?? this.category,
      openingHours: openingHours ?? this.openingHours,
      isOpen: isOpen ?? this.isOpen,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
````

## File: lib/core/services/auth_service.dart
````dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../constants/firestore_collections.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of auth state changes (logged in / logged out)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current Firebase user
  User? get currentUser => _auth.currentUser;

  // Register user with Email, Password, Name & Role
  Future<String?> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      if (credential.user != null) {
        UserModel newUser = UserModel(
          uid: credential.user!.uid,
          email: email.trim(),
          fullName: fullName.trim(),
          role: role,
          createdAt: DateTime.now(),
        );

        // Save user details into Firestore 'users' collection
        await _firestore
            .collection(FirestoreCollections.users)
            .doc(credential.user!.uid)
            .set(newUser.toMap());

        return null; // Success (no error message)
      }
      return "User creation failed.";
    } on FirebaseAuthException catch (e) {
      return e.message ?? "An authentication error occurred.";
    } catch (e) {
      return e.toString();
    }
  }

  // Login user with Email & Password
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return null; // Success
    } on FirebaseAuthException catch (e) {
      return e.message ?? "An authentication error occurred.";
    } catch (e) {
      return e.toString();
    }
  }

  // Fetch current user's data from Firestore
  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection(FirestoreCollections.users)
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print("Error fetching user data: $e");
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
````

## File: lib/features/auth/screens/register_screen.dart
````dart
import 'package:flutter/material.dart';
import 'package:stallseeker/core/services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String _selectedRole = 'customer';
  bool _isLoading = false;

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String? error = await _authService.signUp(
      email: _emailController.text,
      password: _passwordController.text,
      fullName: _fullNameController.text,
      role: _selectedRole,
    );

    setState(() => _isLoading = false);

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else if (mounted) {
      Navigator.pop(context); // Go back to login after successful registration
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Enter your name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (val) => val == null || !val.contains('@')
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (val) => val == null || val.length < 6
                      ? 'Password must be 6+ chars'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: const InputDecoration(labelText: 'I am a...'),
                  items: const [
                    DropdownMenuItem(
                        value: 'customer', child: Text('Customer')),
                    DropdownMenuItem(
                        value: 'vendor', child: Text('Vendor / Stall Owner')),
                  ],
                  onChanged: (val) => setState(() => _selectedRole = val!),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Register'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
````

## File: lib/firebase_options.dart
````dart
// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBPTOZDnYDXxe9VNSzYLXPvso5nIiHTsPc',
    appId: '1:793011933510:web:e9cb5587fb777961911547',
    messagingSenderId: '793011933510',
    projectId: 'stallseeker-c2ffe',
    authDomain: 'stallseeker-c2ffe.firebaseapp.com',
    storageBucket: 'stallseeker-c2ffe.firebasestorage.app',
    measurementId: 'G-KEBYKY2P8P',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBzTEscU-ljvVtKgSVFs-KN3J3BtDre2Cs',
    appId: '1:793011933510:android:7127576788f40c81911547',
    messagingSenderId: '793011933510',
    projectId: 'stallseeker-c2ffe',
    storageBucket: 'stallseeker-c2ffe.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCrE5vzUXqYDTN5UQrbVKzx8LBwiA18mrc',
    appId: '1:793011933510:ios:29aa93bdf1ed90e6911547',
    messagingSenderId: '793011933510',
    projectId: 'stallseeker-c2ffe',
    storageBucket: 'stallseeker-c2ffe.firebasestorage.app',
    iosClientId: '793011933510-gphe3f510j5v4u555g4uo4ls5bm7bnsm.apps.googleusercontent.com',
    iosBundleId: 'com.example.stallseeker',
  );
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCrE5vzUXqYDTN5UQrbVKzx8LBwiA18mrc',
    appId: '1:793011933510:ios:29aa93bdf1ed90e6911547',
    messagingSenderId: '793011933510',
    projectId: 'stallseeker-c2ffe',
    storageBucket: 'stallseeker-c2ffe.firebasestorage.app',
    iosClientId: '793011933510-gphe3f510j5v4u555g4uo4ls5bm7bnsm.apps.googleusercontent.com',
    iosBundleId: 'com.example.stallseeker',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyBPTOZDnYDXxe9VNSzYLXPvso5nIiHTsPc',
    appId: '1:793011933510:web:b99eecd2060151e1911547',
    messagingSenderId: '793011933510',
    projectId: 'stallseeker-c2ffe',
    authDomain: 'stallseeker-c2ffe.firebaseapp.com',
    storageBucket: 'stallseeker-c2ffe.firebasestorage.app',
    measurementId: 'G-QFFLHPN0GT',
  );
}
````

## File: lib/features/auth/screens/login_screen.dart
````dart
import 'package:flutter/material.dart';
import 'package:stallseeker/core/services/auth_service.dart';
import 'package:stallseeker/features/auth/screens/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // --- Add this method inside _LoginScreenState ---

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController(
      text: _emailController.text, // pre-fill with whatever they already typed
    );
    bool isSending = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Reset Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter your email address and we will send you a link to reset your password.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final email = resetEmailController.text.trim();
                          if (email.isEmpty || !email.contains('@')) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text('Enter a valid email first.')),
                            );
                            return;
                          }

                          setDialogState(() => isSending = true);

                          final error =
                              await _authService.resetPassword(email: email);

                          if (!mounted) return;
                          Navigator.pop(dialogContext);

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                error ??
                                    'Password reset email sent. Check your inbox.',
                              ),
                              backgroundColor:
                                  error != null ? Colors.red : Colors.green,
                            ),
                          );
                        },
                  child: isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send Reset Link'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- Add this TextButton in your build() method, right below the
  // existing Login ElevatedButton (before the Register TextButton) ---

  //   TextButton(
  //     onPressed: _showForgotPasswordDialog,
  //     child: const Text('Forgot Password?'),
  //   ),

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true); // loading spinner

    String? error = await _authService.login(
      // code pauses here until firebase responds
      email: _emailController.text,
      password: _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'StallSeeker',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val == null || !val.contains('@')
                    ? 'Enter a valid email'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (val) =>
                    val == null || val.isEmpty ? 'Enter your password' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Login'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  );
                },
                child: const Text("Don't have an account? Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
````

## File: lib/main.dart
````dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_wrapper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    // Catches duplicate-app exception if initialized natively
    print('Firebase initialization error ignored: $e');
  }

  runApp(const StallSeekerApp());
}

class StallSeekerApp extends StatelessWidget {
  const StallSeekerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StallSeeker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}
````

## File: lib/features/auth/auth_wrapper.dart
````dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/login_screen.dart';
import '../vendor/dashboard/vendor_dashboard_screen.dart';
import '../customer/home/customer_home_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. Waiting for auth status
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2. User is logged in
        if (snapshot.hasData && snapshot.data != null) {
          final String uid = snapshot.data!.uid;

          return FutureBuilder<DocumentSnapshot>(
            future:
                FirebaseFirestore.instance.collection('users').doc(uid).get(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userSnapshot.hasData && userSnapshot.data!.exists) {
                final userData =
                    userSnapshot.data!.data() as Map<String, dynamic>?;
                final String role = userData?['role'] ?? 'customer';

                if (role == 'vendor') {
                  return const VendorDashboardScreen();
                } else {
                  return const CustomerHomeScreen();
                }
              }

              return const LoginScreen();
            },
          );
        }

        // 3. User is NOT logged in
        return const LoginScreen();
      },
    );
  }
}
````
