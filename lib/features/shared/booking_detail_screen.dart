import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/models/demo_order.dart';
import '../../core/services/demo_order_service.dart';

class BookingSummaryCard extends StatelessWidget {
  const BookingSummaryCard(
      {super.key,
      required this.booking,
      required this.isVendor,
      required this.onTap,
      this.compact = false});

  final DemoOrder booking;
  final bool isVendor;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final unseen =
        isVendor ? booking.vendorUnseenRequest : booking.customerUnseenReady;
    final color = booking.status == 'ready'
        ? const Color(0xFF137547)
        : booking.status == 'requested'
            ? const Color(0xFFB65A16)
            : Theme.of(context).colorScheme.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (unseen) ...[
                const CircleAvatar(
                    radius: 4, backgroundColor: Color(0xFFE84E36)),
                const SizedBox(width: 8),
              ],
              Expanded(
                  child: Text(
                      isVendor ? booking.customerName : booking.stallName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16))),
              Text('RM ${(booking.totalCents / 100).toStringAsFixed(2)}'),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 20),
            ]),
            const SizedBox(height: 8),
            Text(demoOrderStatusLabel(booking.effectiveStatus),
                style: TextStyle(color: color, fontWeight: FontWeight.w700)),
            if (!compact) ...[
              const SizedBox(height: 4),
              Text(
                  booking.items
                      .map((item) => '${item.quantity}× ${item.name}')
                      .join(', '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
            if (booking.createdAt != null) ...[
              const SizedBox(height: 4),
              Text(_dateTime(booking.createdAt!),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ]),
        ),
      ),
    );
  }
}

String _dateTime(DateTime date) => '${date.day}/${date.month}/${date.year} '
    '${date.hour.toString().padLeft(2, '0')}:'
    '${date.minute.toString().padLeft(2, '0')}';

class BookingDetailScreen extends StatefulWidget {
  const BookingDetailScreen(
      {super.key, required this.bookingId, required this.isVendor});
  final String bookingId;
  final bool isVendor;

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  final _service = DemoOrderService();
  late final Stream<DemoOrder?> _booking =
      _service.watchBooking(widget.bookingId);
  bool _busy = false;
  bool _viewing = false;

  void _viewIfNeeded(DemoOrder booking) {
    final unseen = widget.isVendor
        ? booking.vendorUnseenRequest
        : booking.customerUnseenReady;
    if (!unseen || _viewing) return;
    _viewing = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await _service.markViewed(widget.bookingId);
      } catch (_) {
        // The booking remains unread and can be retried when reopened.
      } finally {
        _viewing = false;
      }
    });
  }

  Future<void> _act(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not update this booking. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _action(String label, Future<void> Function() action,
      {bool primary = true}) {
    return primary
        ? FilledButton(
            onPressed: _busy ? null : () => _act(action), child: Text(label))
        : OutlinedButton(
            onPressed: _busy ? null : () => _act(action), child: Text(label));
  }

  List<Widget> _actions(DemoOrder booking) {
    final status = booking.effectiveStatus;
    if (!widget.isVendor) {
      return status == 'requested'
          ? [
              _action('Cancel request', () => _service.cancel(booking.id),
                  primary: false)
            ]
          : [];
    }
    return switch (status) {
      'requested' => [
          _action('Accept', () => _service.respond(booking.id, accept: true)),
          _action('Reject', () => _service.respond(booking.id, accept: false),
              primary: false),
        ],
      'confirmed' => [
          _action(
              'Start preparing', () => _service.advance(booking.id, status)),
          _action('Cancel booking', () => _service.cancel(booking.id),
              primary: false),
        ],
      'preparing' => [
          _action('Mark ready', () => _service.advance(booking.id, status)),
          _action('Cancel booking', () => _service.cancel(booking.id),
              primary: false),
        ],
      'ready' => [
          _action('Mark collected', () => _service.advance(booking.id, status)),
          _action('Cancel booking', () => _service.cancel(booking.id),
              primary: false),
        ],
      _ => [],
    };
  }

  Widget _progress(DemoOrder booking) {
    const steps = ['requested', 'confirmed', 'preparing', 'ready', 'collected'];
    final position = steps.indexOf(booking.effectiveStatus);
    return Column(children: [
      for (var i = 0; i < steps.length; i++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Icon(i <= position ? Icons.check_circle : Icons.circle_outlined,
                size: 20,
                color: i <= position ? const Color(0xFF137547) : Colors.grey),
            const SizedBox(width: 10),
            Text(demoOrderStatusLabel(steps[i]),
                style: TextStyle(
                    fontWeight: i == position ? FontWeight.bold : null)),
          ]),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Booking details')),
        body: StreamBuilder<DemoOrder?>(
          stream: _booking,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                  child: Text(
                      'Could not load this booking. Check your connection.'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final booking = snapshot.data;
            if (booking == null) {
              return const Center(child: Text('Booking not found.'));
            }
            _viewIfNeeded(booking);
            return ListView(padding: const EdgeInsets.all(18), children: [
              Text(widget.isVendor ? booking.customerName : booking.stallName,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              if (booking.createdAt != null)
                Text('Requested ${_dateTime(booking.createdAt!)}'),
              const SizedBox(height: 18),
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Progress',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 10),
                            if (booking.isActive ||
                                booking.status == 'collected')
                              _progress(booking)
                            else
                              Text(
                                  demoOrderStatusLabel(booking.effectiveStatus),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            if (booking.effectiveStatus == 'requested' &&
                                booking.expiresAt != null)
                              Text(
                                  'Vendor reply due by ${_dateTime(booking.expiresAt!)}'),
                          ]))),
              const SizedBox(height: 12),
              Card(
                  child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Items',
                                style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 8),
                            for (final item in booking.items)
                              Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 3),
                                  child: Row(children: [
                                    Expanded(
                                        child: Text(
                                            '${item.quantity}× ${item.name}')),
                                    Text(
                                        'RM ${(item.subtotalCents / 100).toStringAsFixed(2)}'),
                                  ])),
                            const Divider(),
                            Row(children: [
                              const Expanded(child: Text('Total')),
                              Text(
                                  'RM ${(booking.totalCents / 100).toStringAsFixed(2)}')
                            ]),
                          ]))),
              if (booking.pickupLatitude != null &&
                  booking.pickupLongitude != null)
                TextButton.icon(
                  onPressed: () => launchUrl(Uri.parse(
                      'https://www.google.com/maps/search/?api=1&query=${booking.pickupLatitude},${booking.pickupLongitude}')),
                  icon: const Icon(Icons.place_outlined),
                  label: const Text('Self-collect location'),
                ),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 4, children: _actions(booking)),
              const SizedBox(height: 8),
              const Text(
                  'No in-app payment. Arrange payment directly with the stall.'),
            ]);
          },
        ),
      );
}
