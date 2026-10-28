import '../../core/widgets/app_page_app_bar.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_colors.dart';
import '../../core/models/demo_order.dart';
import '../../core/services/demo_order_service.dart';
import 'booking_payment_card.dart';

enum _PaymentTransition { openingCheckout, checkingPayment }

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
            Text(bookingStatusLabel(booking),
                style: TextStyle(color: color, fontWeight: FontWeight.w700)),
            if (booking.hasTestPayment) ...[
              const SizedBox(height: 4),
              Text(bookingPaymentLabel(booking),
                  style: Theme.of(context).textTheme.bodySmall),
            ],
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
            if (booking.specialInstructions.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text('Special instructions: ${booking.specialInstructions}',
                  maxLines: compact ? 1 : 2, overflow: TextOverflow.ellipsis),
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
      {super.key,
      required this.bookingId,
      required this.isVendor,
      this.openCheckoutOnStart = false});
  final String bookingId;
  final bool isVendor;
  final bool openCheckoutOnStart;

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen>
    with WidgetsBindingObserver {
  final _service = DemoOrderService();
  late final Stream<DemoOrder?> _booking =
      _service.watchBooking(widget.bookingId);
  bool _busy = false;
  bool _viewing = false;
  bool _initialPaymentCheck = false;
  bool _hasTestPayment = false;
  bool _checkoutLaunched = false;
  bool _refreshOnResume = false;
  bool _refreshWithTransition = false;
  _PaymentTransition? _paymentTransition;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.openCheckoutOnStart && !widget.isVendor) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(
              _runPaymentTransition(_pay, _PaymentTransition.openingCheckout));
        }
      });
    }
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _hasTestPayment) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _hasTestPayment) {
      final showTransition = _checkoutLaunched && !widget.isVendor;
      _checkoutLaunched = false;
      if (_busy) {
        _refreshOnResume = true;
        _refreshWithTransition |= showTransition;
      } else {
        unawaited(showTransition
            ? _checkPayment()
            : _act(() => _service.refreshPayment(widget.bookingId)));
      }
    }
  }

  Future<void> _checkPayment() => _runPaymentTransition(
        () => _service.refreshPayment(widget.bookingId),
        _PaymentTransition.checkingPayment,
      );

  Future<void> _runPaymentTransition(
      Future<void> Function() action, _PaymentTransition transition) async {
    if (!mounted || _busy) return;
    setState(() => _paymentTransition = transition);
    try {
      await _act(action);
    } finally {
      if (mounted) setState(() => _paymentTransition = null);
    }
  }

  Future<void> _pay() async {
    final uri = await _service.createTestCheckout(widget.bookingId);
    await _launchCheckout(uri);
  }

  Future<void> _launchCheckout(Uri uri) async {
    bool opened;
    _checkoutLaunched = true;
    try {
      opened = await launchUrl(uri,
          mode: LaunchMode.externalApplication, webOnlyWindowName: '_blank');
    } catch (_) {
      opened = false;
    }
    if (!opened) _checkoutLaunched = false;
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Could not open Stripe checkout.'),
          action: SnackBarAction(
              label: 'Try again',
              onPressed: () {
                unawaited(_runPaymentTransition(() => _launchCheckout(uri),
                    _PaymentTransition.openingCheckout));
              })));
    }
  }

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
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                error is FirebaseFunctionsException && error.message != null
                    ? error.message!
                    : 'Could not update this booking. Please try again.')));
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        if (_refreshOnResume) {
          final showTransition = _refreshWithTransition;
          _refreshOnResume = false;
          _refreshWithTransition = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              unawaited(showTransition
                  ? _checkPayment()
                  : _act(() => _service.refreshPayment(widget.bookingId)));
            }
          });
        }
      }
    }
  }

  Widget _paymentTransitionView() {
    final opening = _paymentTransition == _PaymentTransition.openingCheckout;
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Semantics(
            liveRegion: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded,
                    size: 38, color: AppColors.primary),
                const SizedBox(height: 24),
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 24),
                Text(
                  opening
                      ? 'Opening secure checkout'
                      : 'Checking payment status',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textDark,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  opening
                      ? 'Please wait while we open Stripe.'
                      : 'Confirming your payment with Stripe.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Secure payment with Stripe',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _action(String label, Future<void> Function() action,
      {bool primary = true}) {
    return primary
        ? FilledButton(
            onPressed: _busy ? null : () => _act(action), child: Text(label))
        : OutlinedButton(
            onPressed: _busy ? null : () => _act(action), child: Text(label));
  }

  Future<void> _confirmCancellation(DemoOrder booking) async {
    final paid = booking.paymentStatus == 'paid';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: Text(paid
            ? 'The full payment will be refunded to the original payment method. Refund status may take time to update.'
            : 'The booking will be cancelled. Any open checkout will close.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep booking'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(paid ? 'Cancel and refund' : 'Cancel booking'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _service.cancel(booking.id);
  }

  List<Widget> _actions(DemoOrder booking) {
    final status = booking.effectiveStatus;
    if (!widget.isVendor) {
      return booking.canCustomerCancel
          ? [
              _action(
                  booking.paymentStatus == 'paid'
                      ? 'Cancel and refund'
                      : 'Cancel booking',
                  () => _confirmCancellation(booking),
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
          if (booking.canPrepare)
            _action(
                'Start preparing', () => _service.advance(booking.id, status)),
          _action(
              booking.paymentStatus == 'paid'
                  ? 'Cancel and refund'
                  : 'Cancel booking',
              () => _confirmCancellation(booking),
              primary: false),
        ],
      'preparing' => [
          _action('Mark ready', () => _service.advance(booking.id, status)),
          _action(
              booking.paymentStatus == 'paid'
                  ? 'Cancel and refund'
                  : 'Cancel booking',
              () => _confirmCancellation(booking),
              primary: false),
        ],
      'ready' => [
          _action('Mark collected', () => _service.advance(booking.id, status)),
          _action(
              booking.paymentStatus == 'paid'
                  ? 'Cancel and refund'
                  : 'Cancel booking',
              () => _confirmCancellation(booking),
              primary: false),
        ],
      _ => [],
    };
  }

  Widget _progress(DemoOrder booking) {
    final steps = [
      if (booking.checkoutFirst)
        'checkout_started'
      else ...[
        'requested',
        'confirmed',
      ],
      if (booking.hasTestPayment) 'payment_confirmed',
      'preparing',
      'ready',
      'collected'
    ];
    var position = steps.indexOf(booking.effectiveStatus);
    if (booking.checkoutFirst && booking.status == 'confirmed') {
      position = steps.indexOf(booking.paymentStatus == 'paid'
          ? 'payment_confirmed'
          : 'checkout_started');
    } else if (booking.hasTestPayment &&
        booking.status == 'confirmed' &&
        booking.paymentStatus == 'paid') {
      position = steps.indexOf('payment_confirmed');
    }
    return Column(children: [
      for (var i = 0; i < steps.length; i++)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Icon(i <= position ? Icons.check_circle : Icons.circle_outlined,
                size: 20,
                color: i <= position ? const Color(0xFF137547) : Colors.grey),
            const SizedBox(width: 10),
            Expanded(
                child: Text(
                    steps[i] == 'payment_confirmed'
                        ? 'Payment confirmed'
                        : steps[i] == 'checkout_started'
                            ? 'Checkout started'
                            : demoOrderStatusLabel(steps[i]),
                    style: TextStyle(
                        fontWeight: i == position ? FontWeight.bold : null))),
          ]),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: [
          Scaffold(
            appBar: AppPageAppBar(title: const Text('Booking details')),
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
                _hasTestPayment = booking.hasTestPayment;
                if (!_initialPaymentCheck &&
                    booking.hasTestPayment &&
                    booking.paymentStatus != 'unpaid') {
                  _initialPaymentCheck = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !_busy) {
                      unawaited(
                          _act(() => _service.refreshPayment(booking.id)));
                    }
                  });
                }
                return ListView(padding: const EdgeInsets.all(18), children: [
                  Text(
                      widget.isVendor
                          ? booking.customerName
                          : booking.stallName,
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 6),
                  if (booking.createdAt != null)
                    Text(
                        '${booking.checkoutFirst ? 'Started' : 'Requested'} ${_dateTime(booking.createdAt!)}'),
                  const SizedBox(height: 18),
                  Card(
                      child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Progress',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const SizedBox(height: 10),
                                if (booking.isActive ||
                                    booking.status == 'collected')
                                  _progress(booking)
                                else
                                  Text(
                                      demoOrderStatusLabel(
                                          booking.effectiveStatus),
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
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                                const SizedBox(height: 8),
                                for (final item in booking.items)
                                  Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 3),
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
                  if (booking.specialInstructions.trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    BookingSpecialInstructionsCard(
                        instructions: booking.specialInstructions),
                  ],
                  if (booking.hasTestPayment) ...[
                    const SizedBox(height: 12),
                    BookingPaymentCard(
                        booking: booking,
                        isVendor: widget.isVendor,
                        busy: _busy,
                        busyLabel: switch (_paymentTransition) {
                          _PaymentTransition.openingCheckout =>
                            'Opening checkout…',
                          _PaymentTransition.checkingPayment =>
                            'Checking payment…',
                          null => 'Processing…',
                        },
                        onPay: () => _runPaymentTransition(
                            _pay, _PaymentTransition.openingCheckout),
                        onRefresh: () => _checkPayment()),
                  ],
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
                  if (!booking.hasTestPayment)
                    const Text(
                        'This earlier booking uses payment arranged directly with the stall.'),
                ]);
              },
            ),
          ),
          if (_paymentTransition != null)
            Positioned.fill(
              child: AbsorbPointer(
                child: Material(
                  color: AppColors.background,
                  child: SafeArea(child: _paymentTransitionView()),
                ),
              ),
            ),
        ],
      );
}

class BookingSpecialInstructionsCard extends StatelessWidget {
  const BookingSpecialInstructionsCard({super.key, required this.instructions});

  final String instructions;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Special instructions',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(instructions),
              const SizedBox(height: 8),
              Text('Requests are subject to vendor acceptance.',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      );
}
