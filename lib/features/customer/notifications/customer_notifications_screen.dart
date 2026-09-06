import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/notification_model.dart';
import '../../../core/services/notification_history_service.dart';
import '../../../core/services/vendor_service.dart';
import '../../auth/screens/login_screen.dart';
import '../vendor_details/vendor_details_screen.dart';

class CustomerNotificationsScreen extends StatefulWidget {
  const CustomerNotificationsScreen({super.key});
  @override
  State<CustomerNotificationsScreen> createState() => _CustomerNotificationsScreenState();
}

class _CustomerNotificationsScreenState extends State<CustomerNotificationsScreen> {
  final _history = NotificationHistoryService();
  final _vendors = VendorService();
  final _uid = FirebaseAuth.instance.currentUser?.uid;
  late Stream<List<NotificationModel>> _stream;
  final Set<String> _opening = {};
  int _limit = 50;
  bool _marking = false;
  bool _onlyUnread = false;

  @override
  void initState() { super.initState(); _listen(); }

  void _listen() {
    final uid = _uid;
    _stream = uid == null || FirebaseAuth.instance.currentUser?.isAnonymous == true
        ? Stream.value(<NotificationModel>[])
        : _history.watch(uid, limit: _limit);
  }

  void _message(String message) {
    if (mounted) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message))); }
  }

  Future<void> _open(NotificationModel item) async {
    final uid = _uid;
    if (uid == null || _opening.contains(item.id)) { return; }
    setState(() => _opening.add(item.id));
    try {
      if (!item.isRead) {
        try { await _history.markRead(uid, item.id); }
        catch (_) { _message('Could not mark this alert as read.'); }
      }
      if (item.vendorId.isEmpty) { _message('This alert has no stall link.'); return; }
      final vendor = await _vendors.getVendorProfile(item.vendorId)
          .timeout(const Duration(seconds: 10));
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != uid) { return; }
      if (vendor == null) { _message('This stall is unavailable or could not be loaded.'); return; }
      await Navigator.push(context, MaterialPageRoute(builder: (_) => VendorDetailsScreen(vendor: vendor)));
    } catch (_) {
      _message('Could not open the stall. Please retry.');
    } finally {
      if (mounted) { setState(() => _opening.remove(item.id)); }
    }
  }

  Future<void> _markRead(List<NotificationModel> items) async {
    final uid = _uid;
    if (uid == null || _marking) { return; }
    setState(() => _marking = true);
    try { await _history.markDisplayedRead(uid, items); }
    catch (_) { _message('Could not mark alerts as read. Please retry.'); }
    finally { if (mounted) { setState(() => _marking = false); } }
  }

  String _date(DateTime? value) {
    if (value == null) { return 'Date unavailable'; }
    final local = value.toLocal();
    final time = TimeOfDay.fromDateTime(local).format(context);
    return '${local.day}/${local.month}/${local.year} · $time';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      return _empty('Your stall updates, in one place',
        'Sign in and follow stalls to keep their updates here.', action: TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
          child: const Text('Sign in')));
    }
    return ColoredBox(color: const Color(0xFFF2F2F7), child: StreamBuilder<List<NotificationModel>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _errorState(snapshot.error!);
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snapshot.data ?? [];
        final visible = _onlyUnread ? all.where((item) => !item.isRead).toList() : all;
        return RefreshIndicator(onRefresh: () async { setState(_listen); }, child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 28), children: [
            Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8, runSpacing: 4, children: [
                CupertinoSlidingSegmentedControl<bool>(
                  groupValue: _onlyUnread,
                  children: const {
                    false: Padding(padding: EdgeInsets.symmetric(horizontal: 18), child: Text('All')),
                    true: Padding(padding: EdgeInsets.symmetric(horizontal: 18), child: Text('Unread')),
                  },
                  onValueChanged: (value) {
                    if (value != null) { setState(() => _onlyUnread = value); }
                  },
                ),
                TextButton(onPressed: _marking || !all.any((item) => !item.isRead) ? null : () => _markRead(all),
                  child: Text(_marking ? 'Updating…' : 'Mark shown as read')),
              ]),
            const Padding(padding: EdgeInsets.fromLTRB(8, 16, 8, 12),
              child: Text('STALL UPDATES', style: TextStyle(fontSize: 12, color: Color(0xFF8E8E93)))),
            if (visible.isEmpty) Padding(padding: const EdgeInsets.all(32), child: Column(children: [
              const Icon(Icons.notifications_none_rounded, size: 42, color: Color(0xFF8E8E93)),
              const SizedBox(height: 12),
              Text(_onlyUnread ? 'No unread updates in this list' : 'No notifications yet',
                textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Text('When a stall you follow opens, its new update will appear here.',
                textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF8E8E93))),
            ]))
            else Container(clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                for (var i = 0; i < visible.length; i++) ...[
                  if (i > 0) const Divider(height: .5, thickness: .5, color: Color(0xFFE5E5EA)),
                  _tile(visible[i]),
                ],
              ])),
            if (all.length >= _limit) Padding(padding: const EdgeInsets.only(top: 12),
              child: TextButton(onPressed: () => setState(() { _limit += 50; _listen(); }),
                child: const Text('Load older updates'))),
          ],
        ));
      },
    ));
  }

  Widget _tile(NotificationModel item) => Material(
    color: item.isRead ? Colors.white : const Color(0xFFFFFAF6),
    child: ListTile(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      leading: Icon(Icons.storefront_outlined,
        color: item.isRead ? const Color(0xFF8E8E93) : const Color(0xFFFF6E41)),
      title: Text(item.title, style: TextStyle(fontSize: 17, letterSpacing: 0,
        fontWeight: item.isRead ? FontWeight.w400 : FontWeight.w500)),
      subtitle: Padding(padding: const EdgeInsets.only(top: 5), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (item.body.isNotEmpty) Text(item.body, style: const TextStyle(fontSize: 14, letterSpacing: 0)),
          const SizedBox(height: 5),
          Text(_date(item.createdAt), style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
        ])),
      trailing: _opening.contains(item.id)
          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(item.isRead ? Icons.chevron_right : Icons.circle,
              size: item.isRead ? 20 : 8, color: item.isRead ? const Color(0xFFAEAEB2) : const Color(0xFFFF6E41)),
      onTap: () => _open(item),
    ),
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
        body = 'Your account cannot read notification history yet. Please contact support.';
        break;
      case 'unauthenticated':
        title = 'Please sign in again';
        body = 'Your session has expired. Sign out and sign in to load your updates.';
        break;
      case 'unavailable':
      case 'deadline-exceeded':
        title = 'Cannot reach notifications';
        body = 'Check your connection, then try again.';
        break;
      case 'failed-precondition':
        title = 'Notifications are not ready';
        body = 'Notification history needs a service update. Please contact support.';
        break;
      default:
        title = 'Could not load notifications';
        body = 'Try again. If this continues, share the error code with support.';
    }
    return _empty(title, body, action: Column(mainAxisSize: MainAxisSize.min, children: [
      TextButton(onPressed: () => setState(_listen), child: const Text('Retry')),
      SelectableText('Error: $code', textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93))),
    ]));
  }

  Widget _empty(String title, String body, {Widget? action}) => Center(child: Padding(
    padding: const EdgeInsets.all(28), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.notifications_none_rounded, size: 44, color: Color(0xFF8E8E93)),
      const SizedBox(height: 16), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8), Text(body, textAlign: TextAlign.center),
      if (action != null) action,
    ]),
  ));
}
