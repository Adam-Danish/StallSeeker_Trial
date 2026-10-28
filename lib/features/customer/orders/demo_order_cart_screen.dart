import '../../../core/widgets/app_page_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
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
  final _specialInstructions = TextEditingController();
  final _service = DemoOrderService();
  final _menuService = MenuService();
  late final Stream<List<MenuItemModel>> _menu;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _menu = _menuService.getMenuItems(widget.vendor.vendorId);
  }

  @override
  void dispose() {
    _specialInstructions.dispose();
    super.dispose();
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
      final bookingId = await _service.requestOrder(widget.vendor, selected,
          specialInstructions: _specialInstructions.text);
      if (!mounted) return;
      Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => BookingDetailScreen(
                  bookingId: bookingId,
                  isVendor: false,
                  openCheckoutOnStart: true)));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                error is FirebaseFunctionsException && error.message != null
                    ? error.message!
                    : 'Could not save this booking. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppPageAppBar(title: const Text('Your order')),
        body: StreamBuilder<List<MenuItemModel>>(
          stream: _menu,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Could not load the menu.'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            return BookingCartView(
              stallName: widget.vendor.stallName,
              items: snapshot.data!,
              quantities: _quantities,
              sending: _sending,
              specialInstructionsController: _specialInstructions,
              onQuantityChanged: (item, quantity) => setState(() {
                _quantities[item.itemId] = quantity;
              }),
              onSubmit: () => _submit(snapshot.data!),
            );
          },
        ),
      );
}

class BookingCartView extends StatelessWidget {
  const BookingCartView({
    super.key,
    required this.stallName,
    required this.items,
    required this.quantities,
    required this.sending,
    required this.onQuantityChanged,
    required this.onSubmit,
    this.specialInstructionsController,
  });

  final String stallName;
  final List<MenuItemModel> items;
  final Map<String, int> quantities;
  final bool sending;
  final void Function(MenuItemModel, int) onQuantityChanged;
  final VoidCallback onSubmit;
  final TextEditingController? specialInstructionsController;

  @override
  Widget build(BuildContext context) {
    final total = items.fold<int>(
      0,
      (sum, item) =>
          sum +
          (item.status == 'out_of_stock' ? 0 : (quantities[item.itemId] ?? 0)) *
              (item.price * 100).round(),
    );
    final itemCount = items.fold<int>(
      0,
      (sum, item) =>
          sum +
          (item.status == 'out_of_stock' ? 0 : (quantities[item.itemId] ?? 0)),
    );
    final canContinue = total >= 200 && !sending;

    return Column(children: [
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('SELF-COLLECT',
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 6),
                    Text(stallName,
                        style: const TextStyle(
                            color: AppColors.textDark,
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            height: 1.15)),
                    const SizedBox(height: 8),
                    const Text('Choose your food for pickup.',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 14)),
                    const SizedBox(height: 22),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.mint.withValues(alpha: .65),
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.check_circle_outline_rounded,
                              size: 21, color: AppColors.openGreen),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Pay to confirm',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textDark)),
                                SizedBox(height: 3),
                                Text(
                                    'The stall gets your booking after payment.',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Padding(
                      padding: EdgeInsets.only(left: 2),
                      child: Text('Secure payment with Stripe',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ),
                    const SizedBox(height: 30),
                    Row(children: [
                      const Text('Menu',
                          style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                      const Spacer(),
                      Text(
                          '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ]),
                    const SizedBox(height: 12),
                    if (items.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child:
                            Center(child: Text('No dishes on the menu yet.')),
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.cardColor,
                          borderRadius: BorderRadius.circular(26),
                        ),
                        child: Column(
                          children: [
                            for (var i = 0; i < items.length; i++) ...[
                              if (i > 0)
                                const Divider(
                                    height: 1, indent: 16, endIndent: 16),
                              _MenuItemRow(
                                item: items[i],
                                quantity: items[i].status == 'out_of_stock'
                                    ? 0
                                    : (quantities[items[i].itemId] ?? 0),
                                onChanged: (quantity) =>
                                    onQuantityChanged(items[i], quantity),
                              ),
                            ],
                          ],
                        ),
                      ),
                    if (items.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      TextField(
                        controller: specialInstructionsController,
                        enabled: !sending,
                        minLines: 2,
                        maxLines: 4,
                        maxLength: 500,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Special instructions (optional)',
                          hintText: 'E.g. Less spicy, please',
                          helperText:
                              'Requests are subject to vendor acceptance.',
                          helperMaxLines: 2,
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          color: AppColors.cardColor,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 680),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text(
                            itemCount == 0
                                ? 'Order total'
                                : '$itemCount ${itemCount == 1 ? 'item' : 'items'} · Total',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14, color: AppColors.textMuted)),
                      ),
                      const SizedBox(width: 8),
                      Text('RM ${(total / 100).toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textDark)),
                    ]),
                    if (itemCount > 0 && total < 200) ...[
                      const SizedBox(height: 5),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Minimum order RM2.00',
                            style: TextStyle(
                                fontSize: 12, color: AppColors.primary)),
                      ),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton(
                        onPressed: canContinue ? onSubmit : null,
                        child: sending
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      itemCount == 0
                                          ? 'Choose an item'
                                          : 'Continue to payment',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (itemCount > 0) ...[
                                    const SizedBox(width: 8),
                                    const Icon(Icons.arrow_forward_rounded,
                                        size: 18),
                                  ],
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}

class _MenuItemRow extends StatelessWidget {
  const _MenuItemRow({
    required this.item,
    required this.quantity,
    required this.onChanged,
  });

  final MenuItemModel item;
  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final available = item.status != 'out_of_stock';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 15, 12, 15),
      child: Row(children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: available
                          ? AppColors.textDark
                          : AppColors.textMuted)),
              const SizedBox(height: 5),
              Text(
                  available
                      ? 'RM ${item.price.toStringAsFixed(2)}'
                      : 'Out of stock',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: available ? FontWeight.w500 : FontWeight.w400,
                      color:
                          available ? AppColors.primary : AppColors.textMuted)),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            IconButton(
              tooltip: 'Remove ${item.name}',
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
              iconSize: 20,
              onPressed: quantity > 0 ? () => onChanged(quantity - 1) : null,
              icon: const Icon(Icons.remove_rounded),
            ),
            SizedBox(
              width: 24,
              child: Text('$quantity',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ),
            IconButton(
              tooltip: 'Add ${item.name}',
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              padding: EdgeInsets.zero,
              iconSize: 20,
              onPressed: available && quantity < 20
                  ? () => onChanged(quantity + 1)
                  : null,
              icon: const Icon(Icons.add_rounded),
            ),
          ]),
        ),
      ]),
    );
  }
}
