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
    this.reviewsCard,
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
  final Widget? reviewsCard;

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
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            sliver: SliverToBoxAdapter(
                child: Center(
                    child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: LayoutBuilder(builder: (context, constraints) {
                // Follow the window width, including split-screen, and allow
                // extra room when the user enlarges their text.
                final textScale =
                    MediaQuery.textScalerOf(context).scale(14) / 14;
                final wide = constraints.maxWidth >=
                    860 + (textScale - 1).clamp(0, 2) * 240;
                final bookingsSection =
                    _bookingsSection(context, active, attention);
                final quickActions = _quickActions(context, active, wide: wide);
                final overview = _overview(context, summary, todaysBookings);
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _header(context),
                      const SizedBox(height: 20),
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
                                  icon:
                                      const Icon(Icons.edit_outlined, size: 18),
                                  label: const Text('Set up my stall')),
                            ])),
                      ],
                      const SizedBox(height: 20),
                      if (wide)
                        Row(
                            key: const Key('dashboard-two-columns'),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 7, child: bookingsSection),
                              const SizedBox(width: 20),
                              Expanded(
                                  flex: 4,
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        quickActions,
                                        const SizedBox(height: 20),
                                        overview,
                                        if (reviewsCard != null) ...[
                                          const SizedBox(height: 20),
                                          reviewsCard!,
                                        ],
                                      ])),
                            ])
                      else
                        Column(
                            key: const Key('dashboard-single-column'),
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              quickActions,
                              const SizedBox(height: 20),
                              bookingsSection,
                              const SizedBox(height: 20),
                              overview,
                              if (reviewsCard != null) ...[
                                const SizedBox(height: 20),
                                reviewsCard!,
                              ],
                            ]),
                    ]);
              }),
            ))),
          )
        ],
      ),
    );
  }

  Widget _quickActions(BuildContext context, List<DemoOrder> active,
      {required bool wide}) {
    final menu = _QuickAction(
        label: 'Menu', icon: Icons.restaurant_menu_rounded, onTap: onMenu);
    final stock = _QuickAction(
        label: 'Stock', icon: Icons.inventory_2_outlined, onTap: onStock);
    final bookingsAction = _QuickAction(
        label: 'Bookings',
        icon: Icons.receipt_long_outlined,
        count: bookingsError || bookingsLoading
            ? 0
            : active.where((b) => b.vendorNeedsAttention).length,
        onTap: onBookings,
        horizontal: wide);
    return _DashboardCard(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _heading(context, 'Quick actions'),
      const SizedBox(height: 14),
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: menu),
        const SizedBox(width: 10),
        Expanded(child: stock),
        if (!wide) ...[
          const SizedBox(width: 10),
          Expanded(child: bookingsAction)
        ],
      ]),
      if (wide) ...[const SizedBox(height: 10), bookingsAction],
    ]));
  }

  Widget _bookingsSection(
          BuildContext context, List<DemoOrder> active, int attention) =>
      _DashboardCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                _heading(context, 'Active bookings'),
                if (!bookingsLoading && !bookingsError && attention > 0) ...[
                  const SizedBox(height: 8),
                  _StatusBadge(
                      label: attention == 1
                          ? '1 needs action'
                          : '$attention need action',
                      color: AppColors.primary),
                ],
              ])),
          TextButton(onPressed: onBookings, child: const Text('View all')),
        ]),
        const SizedBox(height: 14),
        if (bookingsLoading)
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Column(children: [
                LinearProgressIndicator(),
                SizedBox(height: 12),
                Text('Loading bookings…'),
              ]))
        else if (bookingsError)
          Column(children: [
            const Icon(Icons.wifi_off_outlined, color: AppColors.textMuted),
            const SizedBox(height: 8),
            const Text('Could not load bookings.', textAlign: TextAlign.center),
            TextButton(onPressed: onRefresh, child: const Text('Retry')),
          ])
        else if (active.isEmpty)
          const Padding(
              padding: EdgeInsets.symmetric(vertical: 28),
              child: Column(children: [
                Icon(Icons.receipt_long_outlined,
                    size: 36, color: AppColors.primary),
                SizedBox(height: 12),
                Text('No active bookings',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                SizedBox(height: 6),
                Text('New bookings will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted)),
              ]))
        else ...[
          for (final booking in active.take(3))
            Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _bookingCard(context, booking)),
          if (active.length > 3)
            TextButton(
                onPressed: onBookings,
                child: Text('View ${active.length - 3} more active bookings')),
        ],
      ]));

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
    final actions = Wrap(spacing: 10, runSpacing: 10, children: [
      _headerAction('Preview', Icons.visibility_outlined,
          vendor == null ? null : onPreview),
      _headerAction('Edit stall', Icons.edit_outlined, onEditStall),
    ]);
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 700 ||
          MediaQuery.textScalerOf(context).scale(14) > 19) {
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          identity,
          const SizedBox(height: 16),
          actions,
        ]);
      }
      return Row(children: [
        Expanded(child: identity),
        const SizedBox(width: 24),
        actions
      ]);
    });
  }

  Widget _headerAction(String label, IconData icon, VoidCallback? onPressed) =>
      OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 19),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary),
          minimumSize: const Size(48, 46),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

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
    final openControl = Row(children: [
      Icon(Icons.circle, color: statusColor, size: 13),
      const SizedBox(width: 10),
      Expanded(
          child: Text(
              closedTemporarily
                  ? 'Temporarily closed'
                  : open
                      ? 'Stall open'
                      : 'Stall closed',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700))),
      const SizedBox(width: 6),
      Semantics(
          label: 'Open stall',
          child: Switch.adaptive(
              activeTrackColor: AppColors.openGreen,
              value: open,
              onChanged: saving || closedTemporarily ? null : onToggleOpen)),
    ]);
    final location =
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(
          open && locationError != null
              ? Icons.location_off_outlined
              : Icons.location_on_outlined,
          size: 24,
          color: AppColors.primary),
      const SizedBox(width: 10),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(locationLabel,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(
            !open
                ? 'Open your stall to share its location'
                : locationSharing && locationError == null
                    ? 'Customers can find your stall'
                    : 'Check your location to stay visible',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        if (open && (!locationSharing || locationError != null))
          TextButton.icon(
              onPressed: saving ? null : onResumeLocation,
              icon: const Icon(Icons.my_location, size: 18),
              label:
                  Text(locationSharing ? 'Retry location' : 'Resume sharing')),
      ])),
    ]);
    final collectControl = Row(children: [
      const Icon(Icons.shopping_bag_outlined,
          size: 24, color: AppColors.primary),
      const SizedBox(width: 10),
      const Expanded(
          child: Text('Self-collect bookings',
              style: TextStyle(fontWeight: FontWeight.w600))),
      const SizedBox(width: 6),
      Semantics(
          label: 'Self-collect bookings',
          child: Switch.adaptive(
              activeTrackColor: AppColors.openGreen,
              value: vendor?.selfCollectEnabled ?? false,
              onChanged: saving ? null : onToggleSelfCollect)),
    ]);
    return _DashboardCard(
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth >= 820 &&
            MediaQuery.textScalerOf(context).scale(14) <= 19) {
          return IntrinsicHeight(
              child: Row(children: [
            Expanded(child: openControl),
            const VerticalDivider(width: 32),
            Expanded(child: location),
            const VerticalDivider(width: 32),
            Expanded(child: collectControl),
          ]));
        }
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              openControl,
              const SizedBox(height: 10),
              location,
              const Divider(height: 28),
              collectControl,
            ]);
      }),
      if (closedTemporarily)
        Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
                onPressed: onEditStall,
                child: const Text('Manage temporary closure'))),
      if (saving) ...[
        const SizedBox(height: 8),
        const LinearProgressIndicator()
      ],
    ]));
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
    final button = review || booking.canPrepare
        ? FilledButton(
            onPressed: action,
            style: _bookingButtonStyle(),
            child: Text(busy ? 'Updating…' : label))
        : OutlinedButton(
            onPressed: action,
            style: _bookingButtonStyle(),
            child: Text(busy ? 'Updating…' : label));
    final details =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(booking.customerName,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            _StatusBadge(
                label: review ? 'New' : bookingStatusLabel(booking),
                color: color),
          ]),
      const SizedBox(height: 8),
      Text(
          booking.items
              .map((item) => '${item.quantity} × ${item.name}')
              .join(', '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis),
      if (timeLabel != null) ...[
        const SizedBox(height: 6),
        Text('Booked ${time!.day}/${time.month} at $timeLabel · MYT',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
      if (booking.hasTestPayment) ...[
        const SizedBox(height: 4),
        Text(bookingPaymentLabel(booking),
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ],
    ]);
    final amount = Text('RM ${(booking.totalCents / 100).toStringAsFixed(2)}',
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w700));
    final avatar = CircleAvatar(
        radius: 22,
        backgroundColor: color.withValues(alpha: .12),
        foregroundColor: color,
        child: Text(
            booking.customerName.trim().isEmpty
                ? '?'
                : booking.customerName.trim().characters.first.toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.w700)));
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(16)),
      child: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth >= 500 &&
            MediaQuery.textScalerOf(context).scale(14) <= 19) {
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            avatar,
            const SizedBox(width: 12),
            Expanded(child: details),
            const SizedBox(width: 14),
            SizedBox(
                width: 166,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(alignment: Alignment.centerRight, child: amount),
                      const SizedBox(height: 12),
                      button,
                    ])),
          ]);
        }
        return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                avatar,
                const SizedBox(width: 10),
                Expanded(child: details)
              ]),
              const SizedBox(height: 12),
              Align(alignment: Alignment.centerRight, child: amount),
              const SizedBox(height: 10),
              button,
            ]);
      }),
    );
  }

  ButtonStyle _bookingButtonStyle() => TextButton.styleFrom(
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)));

  Widget _overview(
      BuildContext context, DemoSalesSummary summary, int todaysBookings) {
    return _DashboardCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _heading(context, 'Today’s overview'),
        const SizedBox(height: 4),
        const Text('Malaysia time',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 20),
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
        const Divider(height: 20),
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
      this.count = 0,
      this.horizontal = false});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final int count;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final iconWidget = Badge(
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        backgroundColor: AppColors.primary,
        textColor: Colors.white,
        child: Icon(icon, color: AppColors.primary, size: 27));
    final text = Text(label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.w600));
    return Material(
      color: AppColors.background,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: horizontal ? 14 : 6, vertical: 18),
            child: horizontal
                ? Row(children: [
                    iconWidget,
                    const SizedBox(width: 12),
                    Expanded(
                        child: Align(
                            alignment: Alignment.centerLeft, child: text)),
                    const Icon(Icons.chevron_right,
                        size: 20, color: AppColors.primary)
                  ])
                : Column(
                    children: [iconWidget, const SizedBox(height: 12), text]),
          )),
    );
  }
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
