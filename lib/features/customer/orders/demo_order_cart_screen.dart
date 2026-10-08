import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/models/menu_item_model.dart';
import '../../../core/models/demo_order.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/demo_order_service.dart';
import '../../../core/services/menu_service.dart';
import '../../shared/booking_detail_screen.dart';

class DemoOrderCartScreen extends StatefulWidget {
  const DemoOrderCartScreen({super.key, required this.vendor});
  final VendorModel vendor;

  @override
  State<DemoOrderCartScreen> createState() => _DemoOrderCartScreenState();
}

class _DemoOrderCartScreenState extends State<DemoOrderCartScreen> {
  final _quantities = <String, int>{};
  final _service = DemoOrderService();
  final _menuService = MenuService();
  late final Stream<List<MenuItemModel>> _menu;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _menu = _menuService.getMenuItems(widget.vendor.vendorId);
  }

  Future<void> _submit(List<MenuItemModel> items) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous || !user.emailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sign in with a verified customer account to book.')));
      return;
    }
    final selected = <DemoOrderItem>[];
    for (final item in items) {
      final quantity = _quantities[item.itemId] ?? 0;
      if (quantity > 0 && item.status != 'out_of_stock') {
        selected.add(DemoOrderItem(
            itemId: item.itemId,
            name: item.name,
            unitPriceCents: (item.price * 100).round(),
            quantity: quantity));
      }
    }
    if (selected.isEmpty) return;
    setState(() => _sending = true);
    try {
      final bookingId = await _service.requestOrder(widget.vendor, selected);
      if (!mounted) return;
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  BookingDetailScreen(bookingId: bookingId, isVendor: false)));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not save this booking. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Book from ${widget.vendor.stallName}')),
        body: StreamBuilder<List<MenuItemModel>>(
          stream: _menu,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Could not load the menu.'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snapshot.data!;
            final total = items.fold<int>(
                0,
                (sum, item) =>
                    sum +
                    (_quantities[item.itemId] ?? 0) *
                        (item.price * 100).round());
            return Column(children: [
              const MaterialBanner(
                  content: Text(
                      'Your request goes to the vendor. No in-app payment.'),
                  actions: [SizedBox.shrink()]),
              Expanded(
                  child: items.isEmpty
                      ? const Center(child: Text('No dishes on the menu.'))
                      : ListView.builder(
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            final available = item.status != 'out_of_stock';
                            final quantity = _quantities[item.itemId] ?? 0;
                            return ListTile(
                              title: Text(item.name),
                              subtitle: Text(available
                                  ? 'RM ${item.price.toStringAsFixed(2)}'
                                  : 'Out of stock'),
                              trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                        icon: const Icon(
                                            Icons.remove_circle_outline),
                                        onPressed: quantity > 0
                                            ? () => setState(() =>
                                                _quantities[item.itemId] =
                                                    quantity - 1)
                                            : null),
                                    Text('$quantity'),
                                    IconButton(
                                        icon: const Icon(
                                            Icons.add_circle_outline),
                                        onPressed: available && quantity < 20
                                            ? () => setState(() =>
                                                _quantities[item.itemId] =
                                                    quantity + 1)
                                            : null),
                                  ]),
                            );
                          },
                        )),
              SafeArea(
                  child: Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed:
                        total > 0 && !_sending ? () => _submit(items) : null,
                    child: Text(_sending
                        ? 'Sending…'
                        : 'Request booking · RM ${(total / 100).toStringAsFixed(2)}'),
                  ),
                ),
              )),
            ]);
          },
        ),
      );
}
