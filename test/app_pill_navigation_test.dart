import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/theme/app_theme.dart';
import 'package:stallseeker/core/widgets/app_pill_navigation.dart';

void main() {
  for (final width in [390.0, 960.0]) {
    testWidgets(
        'pill navigation fits ${width.toInt()}px viewport and switches tabs',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var selected = 0;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: StatefulBuilder(builder: (context, setState) {
          return Scaffold(
            extendBody: true,
            body: const ColoredBox(
              key: Key('page-content'),
              color: Colors.green,
              child: SizedBox.expand(),
            ),
            bottomNavigationBar: AppPillNavigation(
              selectedIndex: selected,
              onDestinationSelected: (index) =>
                  setState(() => selected = index),
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home), label: 'Home'),
                NavigationDestination(
                    icon: Icon(Icons.favorite), label: 'Following'),
                NavigationDestination(
                    icon: Icon(Icons.notifications), label: 'Notifications'),
                NavigationDestination(
                    icon: Icon(Icons.settings), label: 'Settings'),
              ],
            ),
          );
        }),
      ));

      expect(tester.takeException(), isNull);
      final bar = tester.getRect(find.byKey(const Key('pill-navigation')));
      expect(bar.left, greaterThanOrEqualTo(12));
      expect(bar.right, lessThanOrEqualTo(width - 12));
      expect(bar.width, closeTo(width < 674 ? width - 24 : 650, 1));
      expect(tester.getRect(find.byKey(const Key('page-content'))).bottom,
          greaterThan(bar.bottom));
      expect(find.byTooltip('Search'), findsNothing);

      await tester.tap(find.text('Following'));
      await tester.pumpAndSettle();
      expect(selected, 1);
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(selected, 3);
      expect(tester.takeException(), isNull);
    });
  }
}
