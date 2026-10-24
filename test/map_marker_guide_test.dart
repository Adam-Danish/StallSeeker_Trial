import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/theme/app_theme.dart';
import 'package:stallseeker/features/customer/home/map_marker_guide.dart';

void main() {
  for (final width in [320.0, 390.0, 420.0]) {
    for (final scale in [1.0, 1.6]) {
      testWidgets(
          'marker guide reserves enough space at $width px / $scale text',
          (tester) async {
        tester.view.physicalSize = Size(width, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.lightTheme,
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: Scaffold(
              body: Builder(builder: (context) {
                return SizedBox(
                  height: MapMarkerGuide.heightFor(context, width) + 112,
                  child: const Column(children: [
                    MapMarkerGuide(),
                    SizedBox(height: 112, child: Text('Stall card')),
                  ]),
                );
              }),
            ),
          ),
        ));
        expect(find.text('Search location'), findsOneWidget);
        expect(find.text('Other stalls'), findsOneWidget);
        expect(find.text('Selected stall'), findsOneWidget);
        expect(tester.getBottomLeft(find.byType(MapMarkerGuide)).dy,
            lessThanOrEqualTo(tester.getTopLeft(find.text('Stall card')).dy));
        expect(tester.takeException(), isNull);
      });
    }
  }
}
