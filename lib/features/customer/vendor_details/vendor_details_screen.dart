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
