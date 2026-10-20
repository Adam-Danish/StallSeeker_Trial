import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

import '../../core/models/demo_order.dart';
import '../../core/services/demo_order_service.dart';
import 'booking_detail_screen.dart';

class DemoOrdersScreen extends StatefulWidget {
  const DemoOrdersScreen(
      {super.key, required this.isVendor, this.accountId, this.liveBookings});
  final bool isVendor;
  final String? accountId;
  final Stream<List<DemoOrder>>? liveBookings;

  @override
  State<DemoOrdersScreen> createState() => _DemoOrdersScreenState();
}

class _DemoOrdersScreenState extends State<DemoOrdersScreen> {
  late final _service = DemoOrderService();
  late final String _uid =
      widget.accountId ?? FirebaseAuth.instance.currentUser?.uid ?? '';
  late final Stream<List<DemoOrder>> _live = widget.liveBookings ??
      (widget.isVendor
          ? _service.watchVendorOrders(_uid)
          : _service.watchCustomerOrders(_uid));

  Widget _list(List<DemoOrder> bookings) {
    if (bookings.isEmpty) {
      return const Center(child: Text('No bookings in this section yet.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return BookingSummaryCard(
          booking: booking,
          isVendor: widget.isVendor,
          onTap: () => Navigator.push(
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
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.isVendor ? 'Stall bookings' : 'My bookings'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(50),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E2E7),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TabBar(
                    indicator: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: AppColors.textDark,
                    unselectedLabelColor: AppColors.textMuted,
                    tabs: const [Tab(text: 'Active'), Tab(text: 'History')],
                  ),
                ),
              ),
            ),
          ),
          body: StreamBuilder<List<DemoOrder>>(
            stream: _live,
            builder: (context, snapshot) {
              final active =
                  snapshot.data?.where((item) => item.isActive).toList() ??
                      const <DemoOrder>[];
              final history =
                  snapshot.data?.where((item) => !item.isActive).toList() ??
                      const <DemoOrder>[];
              final unavailable = snapshot.hasError
                  ? const Center(
                      child: Text(
                          'Could not load bookings. Check your connection and try again.'))
                  : const Center(child: CircularProgressIndicator());
              return TabBarView(children: [
                snapshot.hasData ? _list(active) : unavailable,
                snapshot.hasData ? _list(history) : unavailable,
              ]);
            },
          ),
        ),
      );
}
