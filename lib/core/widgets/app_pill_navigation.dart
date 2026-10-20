import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// A wide, floating navigation bar that stays inside the device safe area.
class AppPillNavigation extends StatelessWidget {
  const AppPillNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: Material(
                  elevation: 8,
                  shadowColor: const Color(0x25000000),
                  color: AppColors.cardColor,
                  shape: const StadiumBorder(
                      side: BorderSide(color: AppColors.border)),
                  clipBehavior: Clip.antiAlias,
                  child: NavigationBar(
                    height: 68,
                    selectedIndex: selectedIndex,
                    onDestinationSelected: onDestinationSelected,
                    backgroundColor: AppColors.cardColor,
                    indicatorColor: AppColors.mint,
                    labelBehavior:
                        NavigationDestinationLabelBehavior.alwaysShow,
                    destinations: destinations,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
