import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../core/models/dish_follow_model.dart';
import '../../../core/models/menu_item_model.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/dish_follow_service.dart';
import '../../../core/services/vendor_service.dart';
import '../vendor_details/vendor_details_screen.dart';

class FollowedDishesList extends StatefulWidget {
  const FollowedDishesList({super.key, required this.uid});
  final String uid;

  @override
  State<FollowedDishesList> createState() => _FollowedDishesListState();
}

class _FollowedDishesListState extends State<FollowedDishesList> {
  final _service = DishFollowService();
  Stream<List<DishFollowModel>>? _stream;

  @override
  void initState() {
    super.initState();
    _listen();
  }

  @override
  void didUpdateWidget(FollowedDishesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.uid != widget.uid) _listen();
  }

  void _listen() {
    final user = FirebaseAuth.instance.currentUser;
    _stream = user?.uid == widget.uid && user?.emailVerified == true
        ? _service.watch(widget.uid)
        : null;
  }

  @override
  Widget build(BuildContext context) {
    if (FirebaseAuth.instance.currentUser?.emailVerified != true) {
      return const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
              'Verify your email to follow dishes and get restock alerts.',
              textAlign: TextAlign.center));
    }
    return StreamBuilder<List<DishFollowModel>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                const Text('Could not load followed dishes.',
                    textAlign: TextAlign.center),
                TextButton(
                    onPressed: () => setState(_listen),
                    child: const Text('Retry')),
              ]));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()));
        }
        final follows = [...?snapshot.data]..sort((a, b) =>
            (b.followedAt ?? DateTime(1970))
                .compareTo(a.followedAt ?? DateTime(1970)));
        if (follows.isEmpty) {
          return const Padding(
              padding: EdgeInsets.all(24),
              child: Column(children: [
                Text('No followed dishes yet',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                SizedBox(height: 8),
                Text(
                    'Open a stall’s menu and tap Follow dish. Your dishes will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFF8E8E93))),
              ]));
        }
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text('Alerts arrive when a sold-out dish is restocked.',
                  style: TextStyle(fontSize: 13, color: Color(0xFF8E8E93)))),
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Text('FOLLOWED DISHES · ${follows.length}',
                  style:
                      const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)))),
          Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                for (var index = 0; index < follows.length; index++) ...[
                  if (index > 0)
                    const Divider(
                        height: .5, thickness: .5, color: Color(0xFFE5E5EA)),
                  _FollowedDishRow(
                      key: ValueKey(follows[index].id),
                      uid: widget.uid,
                      follow: follows[index]),
                ],
              ])),
        ]);
      },
    );
  }
}

class _FollowedDishRow extends StatefulWidget {
  const _FollowedDishRow({super.key, required this.uid, required this.follow});
  final String uid;
  final DishFollowModel follow;
  @override
  State<_FollowedDishRow> createState() => _FollowedDishRowState();
}

class _FollowedDishRowState extends State<_FollowedDishRow> {
  final _service = DishFollowService();
  final _vendors = VendorService();
  late Stream<MenuItemModel?> _dish;
  late Stream<VendorModel?> _vendor;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _dish = _service.watchDish(widget.follow.vendorId, widget.follow.itemId);
    _vendor = _vendors.watchVendorProfile(widget.follow.vendorId);
  }

  Future<void> _unfollow() async {
    if (_saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.unfollow(
          widget.uid, widget.follow.vendorId, widget.follow.itemId);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Could not unfollow this dish. Please retry.')));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<MenuItemModel?>(
        stream: _dish,
        builder: (context, dishSnapshot) => StreamBuilder<VendorModel?>(
            stream: _vendor,
            builder: (context, vendorSnapshot) {
              final dish = dishSnapshot.data;
              final vendor = vendorSnapshot.data;
              final loading =
                  dishSnapshot.connectionState == ConnectionState.waiting ||
                      vendorSnapshot.connectionState == ConnectionState.waiting;
              final error = dishSnapshot.hasError || vendorSnapshot.hasError;
              final available = dish != null && dish.status != 'out_of_stock';
              final status = loading
                  ? 'Loading…'
                  : error
                      ? 'Could not refresh this dish'
                      : dish == null || vendor == null
                          ? 'No longer available'
                          : dish.status == 'low_stock'
                              ? 'Low stock'
                              : available
                                  ? 'Available'
                                  : 'Sold out · waiting for restock';
              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                leading: Icon(Icons.restaurant_outlined,
                    color: available
                        ? const Color(0xFFFF6E41)
                        : const Color(0xFF8E8E93)),
                title: Text(
                    dish?.name ??
                        (loading ? 'Loading dish…' : 'Unavailable dish'),
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0)),
                subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (vendor != null)
                            Text(vendor.stallName,
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF8E8E93),
                                    letterSpacing: 0)),
                          const SizedBox(height: 3),
                          Text(
                              dish != null && !error && !loading
                                  ? '$status · RM ${dish.price.toStringAsFixed(2)}'
                                  : status,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: available && !error
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFF8E8E93))),
                        ])),
                trailing: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : IconButton(
                        tooltip: 'Unfollow dish',
                        onPressed: _unfollow,
                        icon: const Icon(Icons.notifications_active_outlined,
                            color: Color(0xFFFF6E41))),
                onTap: vendor == null || loading || error
                    ? null
                    : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => VendorDetailsScreen(
                                vendor: vendor,
                                initialDishId: widget.follow.itemId))),
              );
            }),
      );
}
