import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/vendor_service.dart';
import '../../../core/services/follow_service.dart';
import '../vendor_details/vendor_details_screen.dart';

class CustomerFollowingScreen extends StatefulWidget {
  const CustomerFollowingScreen({super.key});

  @override
  State<CustomerFollowingScreen> createState() =>
      _CustomerFollowingScreenState();
}

class _CustomerFollowingScreenState extends State<CustomerFollowingScreen> {
  final followService = FollowService();
  final vendorService = VendorService();

  @override
  Widget build(BuildContext context) {
    final customerId = FirebaseAuth.instance.currentUser?.uid;

    if (customerId == null || FirebaseAuth.instance.currentUser!.isAnonymous) {
      return const Center(child: Text('Please log in to see followed stalls.'));
    }

    return StreamBuilder<List<String>>(
      stream: followService.getFollowedVendorIds(customerId),
      builder: (context, idSnapshot) {
        if (idSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (idSnapshot.hasError) {
          return const Center(child: Text('Could not load followed stalls. Please reopen this screen.'));
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

        return RefreshIndicator(
          onRefresh: () async {
            // Trigger a rebuild to re‑fetch vendor profiles.
            setState(() {});
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: vendorIds.length,
            itemBuilder: (context, index) {
              final vendorId = vendorIds[index];

              return StreamBuilder<VendorModel?>(
                stream: vendorService.watchVendorProfile(vendorId),
                builder: (context, vendorSnapshot) {
                  if (vendorSnapshot.hasError) {
                    return const ListTile(title: Text('Could not update this stall.'));
                  }
                  if (!vendorSnapshot.hasData || vendorSnapshot.data == null) {
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
          ),
        );
      },
    );
  }
}
