import '../../../core/widgets/app_page_app_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/models/demo_order.dart';
import '../../../core/services/demo_order_service.dart';
import '../../shared/booking_detail_screen.dart';
import '../../shared/booking_payment_card.dart';

class DemoSalesSummary {
  const DemoSalesSummary(
      {required this.todayCents,
      required this.totalCents,
      required this.paidOrders});
  final int todayCents;
  final int totalCents;
  final int paidOrders;

  factory DemoSalesSummary.fromOrders(List<DemoOrder> orders,
      {required String vendorId, required DateTime now}) {
    DateTime malaysia(DateTime value) =>
        value.toUtc().add(const Duration(hours: 8));
    final today = malaysia(now);
    var daily = 0;
    var total = 0;
    var count = 0;
    for (final order in orders) {
      if (order.vendorId != vendorId ||
          order.demoSalesCents <= 0 ||
          order.paymentPaidAt == null) {
        continue;
      }
      total += order.demoSalesCents;
      count++;
      final paid = malaysia(order.paymentPaidAt!);
      if (paid.year == today.year &&
          paid.month == today.month &&
          paid.day == today.day) {
        daily += order.demoSalesCents;
      }
    }
    return DemoSalesSummary(
        todayCents: daily, totalCents: total, paidOrders: count);
  }
}

class VendorDemoSales extends StatefulWidget {
  const VendorDemoSales({super.key});
  @override
  State<VendorDemoSales> createState() => _VendorDemoSalesState();
}

class _VendorDemoSalesState extends State<VendorDemoSales> {
  late final String _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  late final _orders = DemoOrderService().watchVendorOrders(_uid);

  @override
  Widget build(BuildContext context) {
    if (_uid.isEmpty) return const SizedBox.shrink();
    return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: StreamBuilder<List<DemoOrder>>(
            stream: _orders,
            builder: (context, snapshot) {
              final summary = DemoSalesSummary.fromOrders(snapshot.data ?? [],
                  vendorId: _uid, now: DateTime.now());
              return DemoSalesCard(
                  summary: summary,
                  loading: !snapshot.hasData,
                  hasError: snapshot.hasError,
                  onHistory: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const VendorPaymentHistoryScreen())));
            }));
  }
}

class DemoSalesCard extends StatelessWidget {
  const DemoSalesCard(
      {super.key,
      required this.summary,
      required this.onHistory,
      this.loading = false,
      this.hasError = false});
  final DemoSalesSummary summary;
  final VoidCallback onHistory;
  final bool loading;
  final bool hasError;

  @override
  Widget build(BuildContext context) => Card(
      child: Padding(
          padding: const EdgeInsets.all(18),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.payments_outlined),
              const SizedBox(width: 10),
              Expanded(
                  child: Text('Sales',
                      style: Theme.of(context).textTheme.titleLarge)),
            ]),
            const SizedBox(height: 12),
            if (hasError)
              const Text('Sales could not load. Check your connection.')
            else if (loading)
              const LinearProgressIndicator()
            else ...[
              const Text('Today · Malaysia time'),
              const SizedBox(height: 4),
              Text('RM ${(summary.todayCents / 100).toStringAsFixed(2)}',
                  style: Theme.of(context)
                      .textTheme
                      .headlineLarge
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                  '${summary.paidOrders} paid orders · RM ${(summary.totalCents / 100).toStringAsFixed(2)} total'),
            ],
            const SizedBox(height: 12),
            TextButton.icon(
                onPressed: onHistory,
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('View payment history')),
          ])));
}

class VendorPaymentHistoryScreen extends StatefulWidget {
  const VendorPaymentHistoryScreen({super.key});
  @override
  State<VendorPaymentHistoryScreen> createState() =>
      _VendorPaymentHistoryScreenState();
}

class _VendorPaymentHistoryScreenState
    extends State<VendorPaymentHistoryScreen> {
  late final _orders = DemoOrderService()
      .watchVendorOrders(FirebaseAuth.instance.currentUser?.uid ?? '');

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppPageAppBar(title: const Text('Payment history')),
      body: StreamBuilder<List<DemoOrder>>(
          stream: _orders,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                  child: Text('Payments could not load. Please retry.'));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final orders = snapshot.data!
                .where((order) =>
                    order.hasTestPayment && order.paymentStatus != 'unpaid')
                .toList();
            return ListView(padding: const EdgeInsets.all(16), children: [
              if (orders.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                        'No payments yet. Paid bookings will appear here.')),
              for (final order in orders)
                Card(
                    child: ListTile(
                        leading: const Icon(Icons.receipt_long_outlined),
                        title: Text(order.customerName),
                        subtitle: Text(bookingPaymentLabel(order)),
                        trailing: Text(
                            'RM ${(order.totalCents / 100).toStringAsFixed(2)}'),
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => BookingDetailScreen(
                                    bookingId: order.id, isVendor: true))))),
            ]);
          }));
}
