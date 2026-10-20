import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stallseeker/core/models/menu_item_model.dart';
import 'package:stallseeker/core/theme/app_theme.dart';
import 'package:stallseeker/features/customer/orders/demo_order_cart_screen.dart';

void main() {
  for (final width in [320.0, 390.0, 960.0]) {
    testWidgets('booking cart fits ${width.toInt()}px and updates the total',
        (tester) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final item = MenuItemModel(itemId: 'tea', name: 'Air teh', price: 2);
      final quantities = <String, int>{};
      var submitted = false;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          appBar: AppBar(title: const Text('Your order')),
          body: StatefulBuilder(
              builder: (context, setState) => BookingCartView(
                    stallName: 'Adam stalls',
                    items: [item],
                    quantities: quantities,
                    sending: false,
                    onQuantityChanged: (item, quantity) =>
                        setState(() => quantities[item.itemId] = quantity),
                    onSubmit: () => submitted = true,
                  )),
        ),
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('Choose an item'), findsOneWidget);
      expect(find.text('RM 0.00'), findsOneWidget);

      await tester.tap(find.byTooltip('Add Air teh'));
      await tester.pump();
      expect(find.text('RM 2.00'), findsNWidgets(2));
      expect(find.text('Continue to payment'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('Continue to payment'));
      expect(submitted, isTrue);
    });
  }

  testWidgets('out-of-stock selection cannot count toward payment',
      (tester) async {
    final item = MenuItemModel(
        itemId: 'tea', name: 'Air teh', price: 2, status: 'out_of_stock');
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(
        body: BookingCartView(
          stallName: 'Adam stalls',
          items: [item],
          quantities: const {'tea': 1},
          sending: false,
          onQuantityChanged: (_, __) {},
          onSubmit: () {},
        ),
      ),
    ));
    expect(find.text('RM 0.00'), findsOneWidget);
    expect(find.text('Out of stock'), findsOneWidget);
    expect(tester.widget<IconButton>(find.byType(IconButton).last).onPressed,
        isNull);
  });
}
