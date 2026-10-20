import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Floating iOS-style tab bar shared by customer and vendor screens.
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
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 650),
              child: Container(
                key: const Key('pill-navigation'),
                height: 66,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x18000000),
                      blurRadius: 16,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(36),
                  clipBehavior: Clip.antiAlias,
                  child: Row(children: [
                    for (var index = 0; index < destinations.length; index++)
                      Expanded(
                        child: InkWell(
                          onTap: () => onDestinationSelected(index),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconTheme(
                                  data: IconThemeData(
                                    size: 25,
                                    color: index == selectedIndex
                                        ? AppColors.primary
                                        : AppColors.textDark,
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
                                    height: 1.1,
                                    color: index == selectedIndex
                                        ? AppColors.primary
                                        : AppColors.textDark,
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
          ),
        ),
      );
}
