import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/app_pill_navigation.dart';
import '../../core/widgets/tab_navigation_history.dart';
import '../../core/widgets/web_page_navigation.dart';
import '../../core/services/demo_order_service.dart';
import '../../core/services/last_tab.dart';
import 'dashboard/vendor_dashboard_screen.dart';
import 'profile/vendor_profile_screen.dart';
import '../shared/profile_page.dart';

class VendorMainScreen extends StatefulWidget {
  const VendorMainScreen({super.key, this.initialPath});

  final String? initialPath;

  @override
  State<VendorMainScreen> createState() => _VendorMainScreenState();
}

class _VendorMainScreenState extends State<VendorMainScreen>
    with TabNavigationHistory<VendorMainScreen> {
  late final _accountId = FirebaseAuth.instance.currentUser?.uid;
  late int _selectedIndex =
      tabIndexForPath(widget.initialPath, vendorTabPaths) ??
          lastTab(_accountId, 'vendor', vendorTabPaths.length);
  late final Stream<int> _newBookings = DemoOrderService().watchUnseenCount(
      FirebaseAuth.instance.currentUser?.uid ?? '',
      isVendor: true);

  void _selectTab(int index) {
    final previousIndex = _selectedIndex;
    if (index == previousIndex) return;
    rememberTabChange(() => _showTab(previousIndex));
    _showTab(index);
  }

  void _showTab(int index) {
    setState(() => _selectedIndex = index);
    unawaited(saveLastTab(_accountId, 'vendor', index));
  }

  @override
  Widget build(BuildContext context) {
    showTabPath(vendorTabPaths[_selectedIndex]);
    return Scaffold(
      extendBody: true,
      backgroundColor:
          _selectedIndex == 1 ? ProfilePage.background : AppColors.background,
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: withTabBackGesture(
          context,
          IndexedStack(
            index: _selectedIndex,
            children: [
              const SafeArea(bottom: false, child: VendorDashboardScreen()),
              const VendorProfileScreen(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: AppPillNavigation(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: [
          NavigationDestination(
            icon: _dashboardIcon(false),
            selectedIcon: _dashboardIcon(true),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(CupertinoIcons.gear),
            selectedIcon: Icon(CupertinoIcons.gear_solid),
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
                color: selected ? AppColors.textDark : AppColors.textMuted),
          ));
}
