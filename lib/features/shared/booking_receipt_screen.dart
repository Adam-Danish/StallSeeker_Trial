import 'package:flutter/material.dart';

import '../../core/models/demo_order.dart';
import '../../core/services/booking_receipt_service.dart';
import '../../core/widgets/app_page_app_bar.dart';
import 'booking_payment_card.dart';

class BookingReceiptScreen extends StatefulWidget {
  const BookingReceiptScreen(
      {super.key, required this.booking, this.onExportPdf});

  final DemoOrder booking;
  final Future<void> Function()? onExportPdf;

  @override
  State<BookingReceiptScreen> createState() => _BookingReceiptScreenState();
}

class _BookingReceiptScreenState extends State<BookingReceiptScreen> {
  DemoOrder get booking => widget.booking;
  bool _exporting = false;

  Future<void> _exportPdf() async {
    setState(() => _exporting = true);
    try {
      await (widget.onExportPdf?.call() ??
          BookingReceiptService().exportPdf(booking.id));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content:
                Text('Could not save the PDF receipt. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  String _money(int cents) => 'RM ${(cents / 100).toStringAsFixed(2)}';

  String _date(DateTime date) {
    final local = date.toLocal();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    if (!booking.hasReceipt) {
      return Scaffold(
        appBar: AppPageAppBar(title: const Text('Payment receipt')),
        body: const Center(child: Text('Receipt available after payment.')),
      );
    }

    final theme = Theme.of(context);
    final refunded = booking.paymentRefundedCents;
    return Scaffold(
      appBar: AppPageAppBar(title: const Text('Payment receipt')),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          FilledButton.icon(
            onPressed: _exporting ? null : _exportPdf,
            icon: _exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.picture_as_pdf_outlined),
            label: Text(_exporting ? 'Preparing PDF…' : 'Save or share PDF'),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(children: [
                    Icon(Icons.receipt_long_outlined, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text('StallSeeker payment receipt',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Text('Stripe test payment', style: theme.textTheme.bodySmall),
                  const Divider(height: 32),
                  Text(booking.stallName,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _detail('Customer', booking.customerName),
                  _detail('Paid on', _date(booking.paymentPaidAt!)),
                  _detail('Booking ID', booking.id),
                  if (booking.paymentReference?.isNotEmpty == true)
                    _detail('Payment reference', booking.paymentReference!),
                  const Divider(height: 32),
                  Text('Items', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 10),
                  for (final item in booking.items) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${item.quantity} × ${item.name}'),
                              Text('${_money(item.unitPriceCents)} each',
                                  style: theme.textTheme.bodySmall),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(_money(item.subtotalCents)),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                  const Divider(),
                  _amount('Amount paid', booking.totalCents, theme),
                  if (refunded > 0) ...[
                    const SizedBox(height: 8),
                    _amount('Refunded', refunded, theme),
                    const SizedBox(height: 8),
                    _amount(
                        'Remaining paid',
                        (booking.totalCents - refunded)
                            .clamp(0, booking.totalCents),
                        theme),
                  ],
                  if (booking.paymentStatus != 'paid' || refunded > 0) ...[
                    const SizedBox(height: 16),
                    Text('Current status: ${bookingPaymentLabel(booking)}',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            SelectableText(value),
          ],
        ),
      );

  Widget _amount(String label, int cents, ThemeData theme) => Row(
        children: [
          Expanded(
            child: Text(label,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
          ),
          Text(_money(cents),
              style: theme.textTheme.bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      );
}
