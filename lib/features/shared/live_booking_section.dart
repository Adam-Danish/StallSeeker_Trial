import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/models/demo_order.dart';
import '../../core/services/demo_order_service.dart';
import 'booking_detail_screen.dart';
import 'demo_orders_screen.dart';

class LiveBookingSection extends StatefulWidget {
  const LiveBookingSection({super.key, required this.isVendor});
  final bool isVendor;

  @override
  State<LiveBookingSection> createState() => _LiveBookingSectionState();
}

class _LiveBookingSectionState extends State<LiveBookingSection> {
  final _service = DemoOrderService();
  late final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  late final Stream<List<DemoOrder>> _bookings = widget.isVendor
      ? _service.watchVendorOrders(_uid)
      : _service.watchCustomerOrders(_uid);

  void _openAll() => Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => DemoOrdersScreen(isVendor: widget.isVendor)));

  @override
  Widget build(BuildContext context) {
    if (_uid.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: StreamBuilder<List<DemoOrder>>(
            stream: _bookings,
            builder: (context, snapshot) {
              final active =
                  snapshot.data?.where((order) => order.isActive).toList() ??
                      const <DemoOrder>[];
              final unseen = (snapshot.data ?? const <DemoOrder>[])
                  .where((order) => widget.isVendor
                      ? order.effectiveStatus == 'requested' &&
                          order.vendorUnseenRequest
                      : order.customerUnseenReady)
                  .length;
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.receipt_long_outlined),
                      const SizedBox(width: 8),
                      const Expanded(
                          child: Text('Live bookings',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w700))),
                      if (unseen > 0)
                        Badge(label: Text(unseen > 99 ? '99+' : '$unseen')),
                      TextButton(
                          onPressed: _openAll, child: const Text('View all')),
                    ]),
                    if (snapshot.hasError)
                      const Text(
                          'Could not load bookings. Check your connection.')
                    else if (!snapshot.hasData)
                      const LinearProgressIndicator()
                    else if (active.isEmpty)
                      Text(widget.isVendor
                          ? 'No active bookings.'
                          : 'No active bookings yet. Your progress will appear here.'),
                    for (final order in active.take(2))
                      BookingSummaryCard(
                        booking: order,
                        isVendor: widget.isVendor,
                        compact: true,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => BookingDetailScreen(
                                    bookingId: order.id,
                                    isVendor: widget.isVendor))),
                      ),
                    if (active.length > 2)
                      Text('${active.length - 2} more active bookings',
                          style: Theme.of(context).textTheme.bodySmall),
                  ]);
            },
          ),
        ),
      ),
    );
  }
}
