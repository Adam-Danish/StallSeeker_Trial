import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/services/demo_order_service.dart';
import 'dashboard/vendor_dashboard_screen.dart';
import 'profile/vendor_profile_screen.dart';

class VendorMainScreen extends StatefulWidget {
  const VendorMainScreen({super.key});

  @override
  State<VendorMainScreen> createState() => _VendorMainScreenState();
}

class _VendorMainScreenState extends State<VendorMainScreen> {
  int _selectedIndex = 0;
  late final Stream<int> _newBookings = DemoOrderService().watchUnseenCount(
      FirebaseAuth.instance.currentUser?.uid ?? '',
      isVendor: true);

  static const _titles = ['Vendor Dashboard', 'Settings'];

  // Key to call dashboard refresh method
  final _dashboardKey = GlobalKey<VendorDashboardScreenState>();

  void _refreshDashboard() {
    _dashboardKey.currentState?.fetchVendorDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        actions: [
          // Refresh button only on Dashboard
          if (_selectedIndex == 0)
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.black),
              tooltip: 'Refresh',
              onPressed: _refreshDashboard,
            ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          VendorDashboardScreen(key: _dashboardKey),
          const VendorProfileScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        backgroundColor: Colors.white,
        indicatorColor: Colors.transparent,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: [
          NavigationDestination(
            icon: _dashboardIcon(false),
            selectedIcon: _dashboardIcon(true),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(CupertinoIcons.gear, color: Color(0xFF929294)),
            selectedIcon:
                Icon(CupertinoIcons.gear_solid, color: Color(0xFF1C1C1E)),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  Widget _dashboardIcon(bool selected) => StreamBuilder<int>(
      stream: _newBookings,
      builder: (context, snapshot) => Badge(
            isLabelVisible: (snapshot.data ?? 0) > 0,
            label: Text(
                (snapshot.data ?? 0) > 99 ? '99+' : '${snapshot.data ?? 0}'),
            child: Icon(
                selected
                    ? CupertinoIcons.square_grid_2x2_fill
                    : CupertinoIcons.square_grid_2x2,
                color: selected
                    ? const Color(0xFF1C1C1E)
                    : const Color(0xFF929294)),
          ));
}
