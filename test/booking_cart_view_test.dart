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
      final instructions = TextEditingController();
      addTearDown(instructions.dispose);
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
                    specialInstructionsController: instructions,
                    onQuantityChanged: (item, quantity) =>
                        setState(() => quantities[item.itemId] = quantity),
                    onSubmit: () => submitted = true,
                  )),
        ),
      ));

      expect(tester.takeException(), isNull);
      expect(find.text('Choose an item'), findsOneWidget);
      expect(find.text('RM 0.00'), findsOneWidget);

      final field = find.byType(TextField);
      await tester.ensureVisible(field);
      await tester.enterText(field, 'Less spicy, please');
      expect(find.text('Requests are subject to vendor acceptance.'),
          findsOneWidget);
      expect(tester.widget<TextField>(field).maxLength, 500);
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      await tester.ensureVisible(find.byTooltip('Add Air teh'));
      await tester.tap(find.byTooltip('Add Air teh'));
      await tester.pump();
      expect(find.text('RM 2.00'), findsNWidgets(2));
      expect(find.text('Continue to payment'), findsOneWidget);
      expect(tester.takeException(), isNull);
      expect(instructions.text, 'Less spicy, please');

      await tester.tap(find.text('Continue to payment'));
      expect(submitted, isTrue);
      expect(instructions.text, 'Less spicy, please');
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

  testWidgets('special instructions are disabled while submitting',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: BookingCartView(
          stallName: 'Stall',
          items: [MenuItemModel(itemId: 'tea', name: 'Tea', price: 2)],
          quantities: const {'tea': 1},
          sending: true,
          onQuantityChanged: (_, __) {},
          onSubmit: () {},
        ),
      ),
    ));
    expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
  });
}
