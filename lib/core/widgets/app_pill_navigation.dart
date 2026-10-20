import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// A wide, floating navigation bar that stays inside the device safe area.
class AppPillNavigation extends StatelessWidget {
  const AppPillNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.destinations,
    this.settingsStyle = false,
    this.onSearch,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final List<NavigationDestination> destinations;
  final bool settingsStyle;
  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context) {
    if (settingsStyle) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Row(children: [
            Expanded(
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(35),
                  boxShadow: const [
                    BoxShadow(
                        color: Color(0x18000000),
                        blurRadius: 16,
                        offset: Offset(0, 3)),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(35),
                  clipBehavior: Clip.antiAlias,
                  child: Row(children: [
                    for (var index = 0; index < destinations.length; index++)
                      Expanded(
                        child: InkWell(
                          onTap: () => onDestinationSelected(index),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconTheme(
                                  data: IconThemeData(
                                    size: 25,
                                    color: index == selectedIndex
                                        ? const Color(0xFF1688E8)
                                        : const Color(0xFF242424),
                                  ),
                                  child: index == selectedIndex
                                      ? (destinations[index].selectedIcon ??
                                          destinations[index].icon)
                                      : destinations[index].icon,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  destinations[index].label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: index == selectedIndex
                                        ? const Color(0xFF1688E8)
                                        : const Color(0xFF242424),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ]),
                ),
              ),
            ),
            if (onSearch != null) ...[
              const SizedBox(width: 8),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: Color(0x18000000),
                        blurRadius: 16,
                        offset: Offset(0, 3)),
                  ],
                ),
                child: IconButton(
                  tooltip: 'Search',
                  onPressed: onSearch,
                  icon: const Icon(Icons.search, color: Colors.black, size: 28),
                ),
              ),
            ],
          ]),
        ),
      );
    }
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
