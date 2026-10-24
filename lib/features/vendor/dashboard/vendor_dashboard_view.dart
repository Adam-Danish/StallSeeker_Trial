import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/demo_order.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/utils/vendor_phone.dart';
import '../../shared/booking_payment_card.dart';
import 'vendor_demo_sales.dart';

/// Presentation only; the screen owns subscriptions and business actions.
class VendorDashboardView extends StatelessWidget {
  const VendorDashboardView({
    super.key,
    required this.vendor,
    required this.bookings,
    required this.bookingsLoading,
    required this.bookingsError,
    required this.saving,
    required this.locationSharing,
    required this.locationError,
    required this.busyBookings,
    required this.onRefresh,
    required this.onToggleOpen,
    required this.onToggleSelfCollect,
    required this.onResumeLocation,
    required this.onPreview,
    required this.onEditStall,
    required this.onMenu,
    required this.onStock,
    required this.onBookings,
    required this.onPaymentHistory,
    required this.onOpenBooking,
    required this.onAdvanceBooking,
    this.now,
  });

  final VendorModel? vendor;
  final List<DemoOrder> bookings;
  final bool bookingsLoading;
  final bool bookingsError;
  final bool saving;
  final bool locationSharing;
  final String? locationError;
  final Set<String> busyBookings;
  final Future<void> Function() onRefresh;
  final ValueChanged<bool> onToggleOpen;
  final ValueChanged<bool> onToggleSelfCollect;
  final VoidCallback onResumeLocation;
  final VoidCallback onPreview;
  final VoidCallback onEditStall;
  final VoidCallback onMenu;
  final VoidCallback onStock;
  final VoidCallback onBookings;
  final VoidCallback onPaymentHistory;
  final ValueChanged<DemoOrder> onOpenBooking;
  final ValueChanged<DemoOrder> onAdvanceBooking;
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final active = bookings.where((booking) => booking.isActive).toList()
      ..sort((a, b) {
        final attention = _priority(a).compareTo(_priority(b));
        if (attention != 0) return attention;
        return (a.createdAt ?? DateTime(1970))
            .compareTo(b.createdAt ?? DateTime(1970));
      });
    final attention = active.where(_needsAction).length;
    final summary = DemoSalesSummary.fromOrders(bookings,
        vendorId: vendor?.vendorId ?? '', now: now ?? DateTime.now());
    final today = _malaysia(now ?? DateTime.now());
    final todaysBookings = bookings.where((booking) {
      if (booking.createdAt == null) return false;
      final created = _malaysia(booking.createdAt!);
      return created.year == today.year &&
          created.month == today.month &&
          created.day == today.day;
    }).length;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        key: const PageStorageKey('vendor-dashboard-scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            sliver: SliverToBoxAdapter(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 650),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _header(context),
                      const SizedBox(height: 22),
                      _statusCard(context),
                      if (vendor == null ||
                          vendor!.stallName.trim().isEmpty ||
                          normalizeVendorPhone(vendor!.phoneNumber) ==
                              null) ...[
                        const SizedBox(height: 12),
                        _DashboardCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Finish setting up your stall',
                                  style:
                                      TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              const Text(
                                  'Add your stall name and business phone number before opening.'),
                              TextButton.icon(
                                onPressed: onEditStall,
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                label: const Text('Set up my stall'),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      _heading(context, 'Quick actions'),
                      const SizedBox(height: 12),
                      Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _QuickAction(
                                  label: 'Menu',
                                  icon: Icons.restaurant_menu_rounded,
                                  onTap: onMenu),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _QuickAction(
                                  label: 'Stock',
                                  icon: Icons.inventory_2_outlined,
                                  onTap: onStock),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _QuickAction(
                                  label: 'Bookings',
                                  icon: Icons.calendar_today_outlined,
                                  count: bookingsError || bookingsLoading
                                      ? 0
                                      : active
                                          .where((b) => b.vendorNeedsAttention)
                                          .length,
                                  onTap: onBookings),
                            ),
                          ]),
                      const SizedBox(height: 24),
                      Row(children: [
                        Expanded(child: _heading(context, 'Active bookings')),
                        TextButton(
                            onPressed: onBookings,
                            child: const Text('View all')),
                      ]),
                      if (!bookingsLoading && !bookingsError && attention > 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _StatusBadge(
                                label: attention == 1
                                    ? '1 needs attention'
                                    : '$attention need attention',
                                color: AppColors.primary),
                          ),
                        ),
                      if (bookingsLoading)
                        const _DashboardCard(
                          child: Column(children: [
                            LinearProgressIndicator(),
                            SizedBox(height: 12),
                            Text('Loading bookings…'),
                          ]),
                        )
                      else if (bookingsError)
                        _DashboardCard(
                          child: Column(children: [
                            const Icon(Icons.wifi_off_outlined,
                                color: AppColors.textMuted),
                            const SizedBox(height: 8),
                            const Text('Could not load bookings.',
                                textAlign: TextAlign.center),
                            TextButton(
                                onPressed: onRefresh,
                                child: const Text('Retry')),
                          ]),
                        )
                      else if (active.isEmpty)
                        const _DashboardCard(
                          child: Column(children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 32, color: AppColors.primary),
                            SizedBox(height: 12),
                            Text('No active bookings',
                                style: TextStyle(fontWeight: FontWeight.w700)),
                            SizedBox(height: 4),
                            Text('New bookings will appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: AppColors.textMuted)),
                          ]),
                        )
                      else ...[
                        for (final booking in active.take(2))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _bookingCard(context, booking),
                          ),
                        if (active.length > 2)
                          TextButton(
                              onPressed: onBookings,
                              child: Text(
                                  'View ${active.length - 2} more active bookings')),
                      ],
                      const SizedBox(height: 24),
                      _heading(context, 'Today’s overview'),
                      const SizedBox(height: 12),
                      _overview(context, summary, todaysBookings),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.center,
                        child: TextButton.icon(
                          onPressed: onEditStall,
                          icon: const Icon(Icons.storefront_outlined, size: 18),
                          label: const Text('Edit my stall'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static DateTime _malaysia(DateTime time) =>
      time.toUtc().add(const Duration(hours: 8));

  static bool _needsAction(DemoOrder booking) =>
      booking.effectiveStatus == 'requested' ||
      booking.canPrepare ||
      booking.vendorNeedsAttention;

  static int _priority(DemoOrder booking) => _needsAction(booking)
      ? 0
      : booking.effectiveStatus == 'ready'
          ? 1
          : 2;

  Widget _heading(BuildContext context, String title) => Text(title,
      style: Theme.of(context)
          .textTheme
          .titleLarge
          ?.copyWith(fontWeight: FontWeight.w700));

  Widget _header(BuildContext context) {
    final identity = Row(children: [
      Tooltip(
        message: 'Change stall photo',
        child: Semantics(
          label: 'Change stall photo',
          button: true,
          child: InkWell(
            onTap: onEditStall,
            customBorder: const CircleBorder(),
            child: Stack(children: [
              ClipOval(
                  child: SizedBox(
                width: 54,
                height: 54,
                child: vendor?.imageUrl.isNotEmpty == true
                    ? Image.network(vendor!.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _stallPlaceholder())
                    : _stallPlaceholder(),
              )),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                      color: AppColors.primary, shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_outlined,
                      size: 12, color: Colors.white),
                ),
              ),
            ]),
          ),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('StallSeeker',
              style: TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(
            vendor?.stallName.trim().isNotEmpty == true
                ? vendor!.stallName
                : 'Your stall',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ]),
      ),
    ]);
    final preview = OutlinedButton.icon(
      onPressed: vendor == null ? null : onPreview,
      icon: const Icon(Icons.visibility_outlined, size: 20),
      label: const Text('Preview'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: const BorderSide(color: AppColors.primary),
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 330 ||
          MediaQuery.textScalerOf(context).scale(14) > 19) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          identity,
          const SizedBox(height: 12),
          preview,
        ]);
      }
      return Row(children: [
        Expanded(child: identity),
        const SizedBox(width: 10),
        preview,
      ]);
    });
  }

  Widget _stallPlaceholder() => Container(
      color: AppColors.mint,
      child: const Icon(Icons.storefront_rounded,
          size: 30, color: AppColors.primary));

  Widget _statusCard(BuildContext context) {
    final closedTemporarily = vendor?.isTemporarilyClosed ?? false;
    final open = vendor?.isOpenNow ?? false;
    final statusColor = closedTemporarily
        ? const Color(0xFF946000)
        : open
            ? AppColors.openGreen
            : AppColors.textMuted;
    final locationLabel = !open
        ? 'Location sharing off'
        : locationError ??
            (locationSharing
                ? 'Live location active'
                : 'Location sharing paused');
    return _DashboardCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.circle, color: statusColor, size: 14),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              closedTemporarily
                  ? 'Temporarily closed'
                  : open
                      ? 'Your stall is open'
                      : 'Your stall is closed',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                  fontSize: 19),
            ),
          ),
          const SizedBox(width: 6),
          Semantics(
            label: 'Open stall',
            child: Switch.adaptive(
                activeTrackColor: AppColors.openGreen,
                value: open,
                onChanged: saving || closedTemporarily ? null : onToggleOpen),
          ),
        ]),
        const SizedBox(height: 4),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(
              open && locationError != null
                  ? Icons.location_off_outlined
                  : Icons.location_on_outlined,
              size: 18,
              color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(locationLabel,
                style: const TextStyle(color: AppColors.textMuted)),
          ),
        ]),
        if (open && (!locationSharing || locationError != null))
          TextButton.icon(
              onPressed: saving ? null : onResumeLocation,
              icon: const Icon(Icons.my_location, size: 18),
              label:
                  Text(locationSharing ? 'Retry location' : 'Resume sharing')),
        if (closedTemporarily)
          TextButton(
              onPressed: onEditStall,
              child: const Text('Manage temporary closure')),
        const Divider(height: 28),
        Row(children: [
          const Icon(Icons.shopping_bag_outlined, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Text('Self-collect bookings',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 6),
          Semantics(
            label: 'Self-collect bookings',
            child: Switch.adaptive(
                activeTrackColor: AppColors.openGreen,
                value: vendor?.selfCollectEnabled ?? false,
                onChanged: saving ? null : onToggleSelfCollect),
          ),
        ]),
        if (saving) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
        ],
      ]),
    );
  }

  Widget _bookingCard(BuildContext context, DemoOrder booking) {
    final status = booking.effectiveStatus;
    final review = status == 'requested';
    final canAdvance = booking.canPrepare || status == 'preparing';
    final busy = busyBookings.contains(booking.id);
    final color = status == 'ready'
        ? AppColors.openGreen
        : status == 'preparing'
            ? const Color(0xFF946000)
            : AppColors.primary;
    final label = review
        ? 'Review booking'
        : booking.canPrepare
            ? 'Start preparing'
            : status == 'preparing'
                ? 'Mark ready'
                : 'View booking';
    final action = busy
        ? null
        : () => canAdvance ? onAdvanceBooking(booking) : onOpenBooking(booking);
    final time =
        booking.createdAt == null ? null : _malaysia(booking.createdAt!);
    final timeLabel = time == null
        ? null
        : MaterialLocalizations.of(context).formatTimeOfDay(
            TimeOfDay.fromDateTime(time),
            alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context));
    return _DashboardCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Wrap(
          spacing: 10,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(booking.customerName,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            _StatusBadge(
                label: review ? 'New' : bookingStatusLabel(booking),
                color: color),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          booking.items
              .map((item) => '${item.quantity} × ${item.name}')
              .join(', '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.textMuted),
        ),
        if (timeLabel != null) ...[
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.schedule_outlined,
                size: 18, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Expanded(
                child: Text(
                    'Booked ${time!.day}/${time.month} at $timeLabel · MYT',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted))),
          ]),
        ],
        if (booking.hasTestPayment) ...[
          const SizedBox(height: 6),
          Text(bookingPaymentLabel(booking),
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
        ],
        const SizedBox(height: 14),
        if (review || booking.canPrepare)
          FilledButton(
              onPressed: action,
              style: _bookingButtonStyle(),
              child: Text(busy ? 'Updating…' : label))
        else
          OutlinedButton(
              onPressed: action,
              style: _bookingButtonStyle(),
              child: Text(busy ? 'Updating…' : label)),
      ]),
    );
  }

  ButtonStyle _bookingButtonStyle() => TextButton.styleFrom(
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)));

  Widget _overview(
      BuildContext context, DemoSalesSummary summary, int todaysBookings) {
    return _DashboardCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (bookingsLoading)
          const LinearProgressIndicator()
        else if (bookingsError)
          const Text('Today’s overview is unavailable. Retry loading bookings.')
        else
          LayoutBuilder(builder: (context, constraints) {
            final sales = _metric(context, 'Sales',
                'RM ${(summary.todayCents / 100).toStringAsFixed(2)}');
            final count = _metric(context, 'Bookings', '$todaysBookings');
            if (constraints.maxWidth < 260 ||
                MediaQuery.textScalerOf(context).scale(14) > 19) {
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [sales, const SizedBox(height: 16), count]);
            }
            return IntrinsicHeight(
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(flex: 3, child: sales),
                const VerticalDivider(width: 28),
                Expanded(flex: 2, child: count),
              ]),
            );
          }),
        const SizedBox(height: 8),
        const Text('Today in Malaysia',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        TextButton.icon(
            onPressed: onPaymentHistory,
            icon: const Icon(Icons.receipt_long_outlined, size: 18),
            label: const Text('Payment history')),
      ]),
    );
  }

  Widget _metric(BuildContext context, String title, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ],
      );
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border.withValues(alpha: .65)),
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
                color: Color(0x05000000), blurRadius: 14, offset: Offset(0, 4)),
          ],
        ),
        child: child,
      );
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(
      {required this.label,
      required this.icon,
      required this.onTap,
      this.count = 0});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final int count;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.border.withValues(alpha: .65))),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 20),
            child: Column(children: [
              Badge(
                isLabelVisible: count > 0,
                label: Text(count > 99 ? '99+' : '$count'),
                backgroundColor: AppColors.mint,
                textColor: AppColors.primary,
                child: Icon(icon, color: AppColors.primary, size: 30),
              ),
              const SizedBox(height: 12),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: color.withValues(alpha: .09),
            borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w700)),
      );
}
