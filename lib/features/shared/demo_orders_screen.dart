import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/models/demo_order.dart';
import '../../core/services/demo_order_service.dart';
import '../../core/services/local_demo_booking_service.dart';
import 'booking_detail_screen.dart';

class DemoOrdersScreen extends StatefulWidget {
  const DemoOrdersScreen({super.key, required this.isVendor});
  final bool isVendor;

  @override
  State<DemoOrdersScreen> createState() => _DemoOrdersScreenState();
}

class _DemoOrdersScreenState extends State<DemoOrdersScreen> {
  final _service = DemoOrderService();
  final _local = LocalDemoBookingService();
  late final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  late final Stream<List<DemoOrder>> _live = widget.isVendor
      ? _service.watchVendorOrders(_uid)
      : _service.watchCustomerOrders(_uid);
  late final Stream<List<DemoOrder>> _demos = widget.isVendor
      ? _local.watchVendorOrders(_uid)
      : _local.watchCustomerOrders(_uid);

  Widget _list(List<DemoOrder> bookings, {required bool isDemo}) {
    if (bookings.isEmpty) {
      return Center(
          child: Text(isDemo
              ? 'No past demo bookings.'
              : 'No bookings in this section yet.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return BookingSummaryCard(
          booking: booking,
          isVendor: widget.isVendor,
          onTap: isDemo
              ? () => showDialog<void>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                        title: Text(booking.stallName),
                        content: Text(
                            '${demoOrderStatusLabel(booking.effectiveStatus)}\n'
                            '${booking.items.map((item) => '${item.quantity}× ${item.name}').join(', ')}\n'
                            'This was a same-phone demo. It was not sent to the vendor.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Close'))
                        ],
                      ))
              : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => BookingDetailScreen(
                          bookingId: booking.id, isVendor: widget.isVendor))),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: widget.isVendor ? 2 : 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.isVendor ? 'Stall bookings' : 'My bookings'),
            bottom: TabBar(tabs: [
              const Tab(text: 'Active'),
              const Tab(text: 'History'),
              if (!widget.isVendor) const Tab(text: 'Past demos'),
            ]),
          ),
          body: StreamBuilder<List<DemoOrder>>(
            stream: _live,
            builder: (context, snapshot) {
              final active = snapshot.data?.where((item) => item.isActive).toList()
                  ?? const <DemoOrder>[];
              final history = snapshot.data?.where((item) => !item.isActive).toList()
                  ?? const <DemoOrder>[];
              final unavailable = snapshot.hasError
                  ? const Center(child: Text(
                      'Could not load bookings. Check your connection and try again.'))
                  : const Center(child: CircularProgressIndicator());
              return TabBarView(children: [
                snapshot.hasData ? _list(active, isDemo: false) : unavailable,
                snapshot.hasData ? _list(history, isDemo: false) : unavailable,
                if (!widget.isVendor)
                  StreamBuilder<List<DemoOrder>>(
                    stream: _demos,
                    builder: (context, local) {
                      if (local.hasError) {
                        return const Center(
                            child: Text(
                                'Could not load past demos on this phone.'));
                      }
                      if (!local.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return _list(local.data!, isDemo: true);
                    },
                  ),
              ]);
            },
          ),
        ),
      );
}
