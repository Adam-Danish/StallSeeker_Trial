import 'package:flutter/material.dart';

import '../../core/models/demo_order.dart';

String bookingPaymentLabel(DemoOrder booking) {
  if (booking.paymentStatus == 'paid' && booking.paymentRefundedCents > 0) {
    return 'Partially refunded';
  }
  return switch (booking.paymentStatus) {
    'paid' => 'Paid',
    'refund_pending' => 'Refund pending',
    'refund_failed' => 'Refund needs attention',
    'refunded' => 'Refunded',
    'failed' => 'Payment failed',
    'expired' => 'Payment window ended',
    'cancelled' => 'Payment cancelled',
    'unpaid' => booking.status == 'requested'
        ? 'Available after acceptance'
        : 'Awaiting payment',
    _ => 'Awaiting payment',
  };
}

class BookingPaymentCard extends StatelessWidget {
  const BookingPaymentCard(
      {super.key,
      required this.booking,
      required this.isVendor,
      this.busy = false,
      this.busyLabel = 'Processing…',
      this.onPay,
      this.onRefresh});

  final DemoOrder booking;
  final bool isVendor;
  final bool busy;
  final String busyLabel;
  final VoidCallback? onPay;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final paid = booking.paymentStatus == 'paid';
    final problem = {'failed', 'refund_failed'}.contains(booking.paymentStatus);
    final color = paid
        ? const Color(0xFF137547)
        : problem
            ? Theme.of(context).colorScheme.error
            : const Color(0xFF9A5B13);
    final remaining = booking.paymentExpiresAt?.difference(DateTime.now());
    final seconds = remaining?.inSeconds.clamp(0, 600) ?? 0;
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(18),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.credit_card_outlined),
                const SizedBox(width: 10),
                Expanded(
                    child: Text('Payment',
                        style: Theme.of(context).textTheme.titleMedium)),
              ]),
              const SizedBox(height: 8),
              Text('RM ${(booking.totalCents / 100).toStringAsFixed(2)}',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Row(children: [
                Icon(
                    paid
                        ? Icons.check_circle
                        : problem
                            ? Icons.error_outline
                            : Icons.schedule,
                    size: 19,
                    color: color),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(bookingPaymentLabel(booking),
                        style: TextStyle(
                            color: color, fontWeight: FontWeight.w600))),
              ]),
              const SizedBox(height: 10),
              if (booking.status == 'requested')
                const Text('Payment opens when the stall accepts this booking.')
              else if (booking.awaitingPayment)
                Text(seconds > 0
                    ? isVendor
                        ? 'Waiting for the customer to pay. Preparation unlocks after confirmation.'
                        : 'Pay within ${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}.'
                    : 'The payment window has ended. Check payment to confirm the final status.'),
              if (booking.paymentStatus == 'refund_pending')
                const Text(
                    'This booking was cancelled. The full refund to the original payment method is pending.')
              else if (booking.paymentStatus == 'refund_failed')
                const Text(
                    'The refund did not complete. Contact support for help.'),
              if (booking.paymentReference != null) ...[
                const SizedBox(height: 10),
                Text('Payment reference',
                    style: Theme.of(context).textTheme.labelSmall),
                SelectableText(booking.paymentReference!,
                    style: Theme.of(context).textTheme.bodySmall),
              ],
              if (booking.paymentRefundedCents > 0)
                Text(
                    'Refunded: RM ${(booking.paymentRefundedCents / 100).toStringAsFixed(2)}'),
              if (!isVendor && booking.canPay) ...[
                const SizedBox(height: 16),
                SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                        onPressed: busy ? null : onPay,
                        icon: const Icon(Icons.lock_outline, size: 18),
                        label: Text(busy
                            ? busyLabel
                            : 'Pay RM ${(booking.totalCents / 100).toStringAsFixed(2)}'))),
                const SizedBox(height: 8),
                const Text('Complete your payment securely with Stripe.',
                    style: TextStyle(fontSize: 12)),
              ],
              if (booking.paymentStatus != 'unpaid' &&
                  booking.paymentStatus != 'refunded')
                TextButton.icon(
                    onPressed: busy ? null : onRefresh,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: Text(busy ? 'Checking…' : 'Check payment')),
            ])));
  }
}
