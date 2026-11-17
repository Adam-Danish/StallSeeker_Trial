import '../../auth/resume_navigation.dart';
import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/notification_history_service.dart';
import '../../../core/services/vendor_service.dart';
import '../../auth/screens/login_screen.dart';
import '../../shared/booking_detail_screen.dart';
import '../vendor_details/vendor_details_screen.dart';

class CustomerNotificationsScreen extends StatefulWidget {
  const CustomerNotificationsScreen({super.key});
  @override
  State<CustomerNotificationsScreen> createState() =>
      _CustomerNotificationsScreenState();
}

class _CustomerNotificationsScreenState
    extends State<CustomerNotificationsScreen> {
  final _history = NotificationHistoryService();
  final _vendors = VendorService();
  final _uid = FirebaseAuth.instance.currentUser?.uid;
  late Stream<List<NotificationModel>> _stream;
  final Set<String> _opening = {};
  final Set<String> _removedIds = {};
  int _limit = 50;
  bool _marking = false;
  bool _onlyUnread = false;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  void _listen() {
    final uid = _uid;
    _stream =
        uid == null || FirebaseAuth.instance.currentUser?.isAnonymous == true
            ? Stream.value(<NotificationModel>[])
            : _history.watch(uid, limit: _limit);
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _open(NotificationModel item) async {
    final uid = _uid;
    if (uid == null || _opening.contains(item.id)) {
      return;
    }
    setState(() => _opening.add(item.id));
    try {
      if (!item.isRead) {
        try {
          await _history.markRead(uid, item.id);
        } catch (_) {
          _message('Could not mark this alert as read.');
        }
      }
      if (item.bookingId != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            settings: ResumePage('booking', item.bookingId),
            builder: (_) => BookingDetailScreen(
                bookingId: item.bookingId!, isVendor: false),
          ),
        );
        return;
      }
      if (item.vendorId.isEmpty) {
        _message('This alert has no stall link.');
        return;
      }
      final vendor = await _vendors
          .getVendorProfile(item.vendorId)
          .timeout(const Duration(seconds: 10));
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != uid) {
        return;
      }
      if (vendor == null) {
        _message('This stall is unavailable or could not be loaded.');
        return;
      }
      await Navigator.push(
          context,
          MaterialPageRoute(
              settings: ResumePage('stall', vendor.vendorId, item.itemId),
              builder: (_) => VendorDetailsScreen(
                  vendor: vendor, initialDishId: item.itemId)));
    } catch (_) {
      _message('Could not open the stall. Please retry.');
    } finally {
      if (mounted) {
        setState(() => _opening.remove(item.id));
      }
    }
  }

  Future<void> _markRead(List<NotificationModel> items) async {
    final uid = _uid;
    if (uid == null || _marking) {
      return;
    }
    setState(() => _marking = true);
    try {
      await _history.markDisplayedRead(uid, items);
    } catch (_) {
      _message('Could not mark alerts as read. Please retry.');
    } finally {
      if (mounted) {
        setState(() => _marking = false);
      }
    }
  }

  Future<void> _remove(NotificationModel item) async {
    final uid = _uid;
    if (uid == null) return;
    setState(() => _removedIds.add(item.id));
    try {
      await _history.remove(uid, item.id);
    } catch (_) {
      if (mounted) {
        setState(() => _removedIds.remove(item.id));
        _message('Could not remove this notification. Please retry.');
      }
    }
  }

  String _date(DateTime? value) {
    if (value == null) {
      return 'Date unavailable';
    }
    final local = value.toLocal();
    final time = TimeOfDay.fromDateTime(local).format(context);
    return '${local.day}/${local.month}/${local.year} · $time';
  }

  @override
  Widget build(BuildContext context) {
    final horizontalInset =
        math.max(0.0, (MediaQuery.sizeOf(context).width - 960) / 2);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      return _empty('Your stall updates, in one place',
          'Sign in to track bookings and see updates from followed stalls and dishes.',
          action: TextButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      settings: const RouteSettings(name: '/login'),
                      builder: (_) => const LoginScreen())),
              child: const Text('Sign in')));
    }
    return ColoredBox(
        color: AppColors.background,
        child: StreamBuilder<List<NotificationModel>>(
          stream: _stream,
          builder: (context, snapshot) {
            final loading = !snapshot.hasData &&
                snapshot.connectionState == ConnectionState.waiting;
            final all = (snapshot.data ?? [])
                .where((item) => !_removedIds.contains(item.id))
                .toList();
            final visible =
                _onlyUnread ? all.where((item) => !item.isRead).toList() : all;
            return RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _listen();
                  });
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                      horizontalInset, 20, horizontalInset, 112),
                  children: [
                    const Padding(
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Text('STALL UPDATES',
                            style: TextStyle(
                                fontSize: 12, color: Color(0xFF8E8E93)))),
                    if (!snapshot.hasError)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              CupertinoSlidingSegmentedControl<bool>(
                                backgroundColor: const Color(0xFFE2E2E7),
                                thumbColor: Colors.white,
                                groupValue: _onlyUnread,
                                children: const {
                                  false: Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 18),
                                      child: Text('All')),
                                  true: Padding(
                                      padding:
                                          EdgeInsets.symmetric(horizontal: 18),
                                      child: Text('Unread')),
                                },
                                onValueChanged: (value) {
                                  if (value != null) {
                                    setState(() => _onlyUnread = value);
                                  }
                                },
                              ),
                              TextButton(
                                  onPressed: _marking ||
                                          !all.any((item) => !item.isRead)
                                      ? null
                                      : () => _markRead(all),
                                  child: Text(_marking
                                      ? 'Updating…'
                                      : 'Mark shown as read')),
                            ]),
                      ),
                    const SizedBox(height: 12),
                    if (snapshot.hasError)
                      _errorState(snapshot.error!)
                    else if (loading)
                      const LinearProgressIndicator()
                    else if (visible.isEmpty)
                      Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(children: [
                            const Icon(Icons.notifications_none_rounded,
                                size: 42, color: Color(0xFF8E8E93)),
                            const SizedBox(height: 12),
                            Text(
                                _onlyUnread
                                    ? 'No unread updates in this list'
                                    : 'No notifications yet',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            const Text(
                                'Updates from followed stalls and dishes, plus changes to your bookings, appear here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Color(0xFF8E8E93))),
                          ]))
                    else
                      for (final item in visible)
                        Dismissible(
                          key: ValueKey('notification-${item.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 24),
                            color: AppColors.closedRed,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.delete_outline_rounded,
                                    color: Colors.white),
                                SizedBox(width: 6),
                                Text('Remove',
                                    style: TextStyle(color: Colors.white)),
                              ],
                            ),
                          ),
                          onDismissed: (_) => _remove(item),
                          child: _tile(item),
                        ),
                    if (!snapshot.hasError && all.length >= _limit)
                      Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: TextButton(
                              onPressed: () => setState(() {
                                    _limit += 50;
                                    _listen();
                                  }),
                              child: const Text('Load older updates'))),
                  ],
                ));
          },
        ));
  }

  Widget _tile(NotificationModel item) => _NotificationRow(
        icon: item.type == 'dish_available'
            ? Icons.restaurant_rounded
            : item.bookingId != null
                ? Icons.receipt_long_rounded
                : Icons.storefront_rounded,
        title: item.title,
        body: TextSpan(text: item.body),
        caption: _date(item.createdAt),
        unread: !item.isRead,
        opening: _opening.contains(item.id),
        onTap: () => _open(item),
      );

  Widget _errorState(Object error) {
    final code = error is FirebaseException ? error.code : 'unknown';
    // Preserve the real error in the debug console instead of blaming Wi-Fi.
    debugPrint('Notification history [$code]: $error');
    String title;
    String body;
    switch (code) {
      case 'permission-denied':
        title = 'Notification access is blocked';
        body =
            'Your account cannot read notification history yet. Please contact support.';
        break;
      case 'unauthenticated':
        title = 'Please sign in again';
        body =
            'Your session has expired. Sign out and sign in to load your updates.';
        break;
      case 'unavailable':
      case 'deadline-exceeded':
        title = 'Cannot reach notifications';
        body = 'Check your connection, then try again.';
        break;
      case 'failed-precondition':
        title = 'Notifications are not ready';
        body =
            'Notification history needs a service update. Please contact support.';
        break;
      default:
        title = 'Could not load notifications';
        body =
            'Try again. If this continues, share the error code with support.';
    }
    return _empty(title, body,
        action: Column(mainAxisSize: MainAxisSize.min, children: [
          TextButton(
              onPressed: () => setState(_listen), child: const Text('Retry')),
          SelectableText('Error: $code',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
        ]));
  }

  Widget _empty(String title, String body, {Widget? action}) => Center(
          child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.notifications_none_rounded,
              size: 44, color: Color(0xFF8E8E93)),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text(body, textAlign: TextAlign.center),
          if (action != null) action,
        ]),
      ));
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.caption,
    required this.unread,
    required this.onTap,
    this.iconColor = AppColors.primary,
    this.opening = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final TextSpan body;
  final String caption;
  final bool unread;
  final bool opening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    // Reserve the same space for every row, including at larger text sizes.
    final height = 52 +
        1.35 * (scaler.scale(16) + 3 * scaler.scale(14) + scaler.scale(12));
    return Material(
      color: unread ? const Color(0xFFFFF5EC) : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: iconColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: 24, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textDark,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Flexible(
                              child: Text.rich(
                                body,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  height: 1.3,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (unread || opening)
                        Padding(
                          padding: const EdgeInsets.only(left: 8, top: 5),
                          child: opening
                              ? const SizedBox.square(
                                  dimension: 14,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: AppColors.primary,
                                  semanticLabel: 'Unread',
                                ),
                        ),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1, thickness: 1, color: AppColors.border),
            ],
          ),
        ),
      ),
    );
  }
}
