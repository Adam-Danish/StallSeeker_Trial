import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/models/vendor_model.dart';
import '../../../core/services/vendor_service.dart';
import '../../../core/widgets/app_page_app_bar.dart';
import 'vendor_details_screen.dart';

class SharedStallPage extends StatefulWidget {
  const SharedStallPage({super.key, required this.stallId});

  final String? stallId;

  @override
  State<SharedStallPage> createState() => _SharedStallPageState();
}

class _SharedStallPageState extends State<SharedStallPage> {
  late Future<VendorModel?> _stall = _loadStall();

  Future<VendorModel?> _loadStall() async {
    final id = widget.stallId;
    if (id == null) return null;
    return VendorService()
        .fetchVendorProfile(id,
            options: const GetOptions(source: Source.server))
        .timeout(const Duration(seconds: 12));
  }

  void _explore() => Navigator.of(context).pushReplacementNamed('/');

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _stall,
      builder: (context, snapshot) {
        final stall = snapshot.data;
        if (stall != null &&
            !stall.isSuspended &&
            stall.stallName.trim().isNotEmpty) {
          return VendorDetailsScreen(
            vendor: stall,
            previewOnly: true,
            onExplore: _explore,
          );
        }

        return Scaffold(
          appBar: AppPageAppBar(title: const Text('Stall details')),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: snapshot.connectionState == ConnectionState.waiting
                  ? const CircularProgressIndicator()
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          snapshot.hasError
                              ? 'Could not load this stall. Check your connection and retry.'
                              : 'This stall is no longer available.',
                          textAlign: TextAlign.center,
                        ),
                        if (snapshot.hasError)
                          TextButton(
                            onPressed: () =>
                                setState(() => _stall = _loadStall()),
                            child: const Text('Retry'),
                          ),
                        TextButton(
                          onPressed: _explore,
                          child: const Text('Explore StallSeeker'),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}
