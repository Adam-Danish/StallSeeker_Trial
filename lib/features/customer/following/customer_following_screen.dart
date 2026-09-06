import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/vendor_service.dart';
import '../../../core/services/follow_service.dart';
import '../../auth/screens/login_screen.dart';
import '../vendor_details/vendor_details_screen.dart';

class CustomerFollowingScreen extends StatefulWidget {
  const CustomerFollowingScreen({super.key});
  @override
  State<CustomerFollowingScreen> createState() => _CustomerFollowingScreenState();
}

class _CustomerFollowingScreenState extends State<CustomerFollowingScreen> {
  final _follows = FollowService();
  final _vendors = VendorService();
  final _profiles = <String, VendorModel>{};
  final _subscriptions = <String, StreamSubscription<VendorModel?>>{};
  final _pending = <String>{};
  final _failed = <String>{};
  StreamSubscription<List<String>>? _followSubscription;
  bool _loading = true;
  bool _loadFailed = false;
  bool _openOnly = false;
  bool _ascending = true;
  int _generation = 0;
  bool _restarting = false;

  @override
  void initState() { super.initState(); _listen(); }

  @override
  void dispose() {
    ++_generation;
    _followSubscription?.cancel();
    for (final sub in _subscriptions.values) { sub.cancel(); }
    super.dispose();
  }

  Future<void> _listen() async {
    if (_restarting) { return; }
    _restarting = true;
    try {
    final generation = ++_generation;
    await _followSubscription?.cancel();
    for (final sub in _subscriptions.values) { await sub.cancel(); }
    _subscriptions.clear();
    _pending.clear();
    _failed.clear();
    _profiles.clear();
    if (!mounted || generation != _generation) { return; }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) { setState(() => _loading = false); return; }
    setState(() { _loading = true; _loadFailed = false; });
    _followSubscription = _follows.getFollowedVendorIds(user.uid).listen((ids) {
      if (!mounted || generation != _generation) { return; }
      final active = ids.toSet();
      for (final id in _subscriptions.keys.toList()) {
        if (!active.contains(id)) {
          _subscriptions.remove(id)?.cancel();
          _profiles.remove(id);
          _pending.remove(id);
          _failed.remove(id);
        }
      }
      setState(() { _loading = false; _loadFailed = false; });
      for (final id in active) {
        if (_subscriptions.containsKey(id)) { continue; }
        _pending.add(id);
        _subscriptions[id] = _vendors.watchVendorProfile(id).listen((vendor) {
          if (!mounted || generation != _generation || !_subscriptions.containsKey(id)) { return; }
          setState(() {
            _pending.remove(id);
            _failed.remove(id);
            if (vendor == null) { _profiles.remove(id); } else { _profiles[id] = vendor; }
          });
        }, onError: (Object error) {
          if (!mounted || generation != _generation || !_subscriptions.containsKey(id)) { return; }
          setState(() { _pending.remove(id); _failed.add(id); _profiles.remove(id); });
        });
      }
    }, onError: (Object error) {
      if (mounted && generation == _generation) {
        setState(() { _loading = false; _loadFailed = true; });
      }
    });
    } finally { _restarting = false; }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final guest = user == null || user.isAnonymous;
    final sorted = _profiles.values.toList()..sort((a, b) {
      final comparison = a.stallName.toLowerCase().compareTo(b.stallName.toLowerCase());
      return _ascending ? comparison : -comparison;
    });
    final open = sorted.where((vendor) => vendor.isOpen).toList();
    final closed = sorted.where((vendor) => !vendor.isOpen).toList();
    return ColoredBox(color: const Color(0xFFF2F2F7), child: SafeArea(top: false, bottom: false,
      child: RefreshIndicator(onRefresh: _listen, child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 28), children: [
          Row(children: [
            IconButton(tooltip: _ascending ? 'Sort Z to A' : 'Sort A to Z',
              onPressed: () => setState(() => _ascending = !_ascending),
              icon: const Icon(Icons.sort_by_alpha_rounded, color: Color(0xFFFF6E41))),
            Expanded(child: Center(child: CupertinoSlidingSegmentedControl<bool>(
              groupValue: _openOnly,
              children: const {
                false: Padding(padding: EdgeInsets.symmetric(horizontal: 14), child: Text('All stalls')),
                true: Padding(padding: EdgeInsets.symmetric(horizontal: 14), child: Text('Open now')),
              },
              onValueChanged: (value) { if (value != null) { setState(() => _openOnly = value); } },
            ))),
            IconButton(tooltip: 'Refresh followed stalls', onPressed: _listen,
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFFFF6E41))),
          ]),
          const SizedBox(height: 24),
          if (guest) _notice('Keep your favourite stalls here',
            'Sign in, then tap Follow on a stall.', action: TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen())),
              child: const Text('Sign in')))
          else if (_loading || (_pending.isNotEmpty && sorted.isEmpty))
            const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))
          else if (_loadFailed) _notice('Could not load followed stalls', 'Check your connection and retry.',
            action: TextButton(onPressed: _listen, child: const Text('Retry')))
          else ...[
            if (_failed.isNotEmpty) _notice('Some stalls could not load', 'Pull down to retry.'),
            if (open.isNotEmpty) _group('OPEN NOW', open),
            if (!_openOnly && closed.isNotEmpty) _group('CLOSED', closed),
            if (_openOnly && open.isEmpty) _notice('No followed stalls are open', 'Check again later, or switch to All stalls.'),
            if (!_openOnly && sorted.isEmpty && _failed.isEmpty)
              _notice('No followed stalls yet', 'Find a stall on the map and tap Follow to save it here.'),
          ],
        ],
      )),
    ));
  }

  Widget _group(String label, List<VendorModel> vendors) => Padding(
    padding: const EdgeInsets.only(bottom: 30), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        child: Text('$label · ${vendors.length}', style: const TextStyle(fontSize: 12, color: Color(0xFF8E8E93)))),
      Container(clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14)),
        child: Column(children: [
          for (var index = 0; index < vendors.length; index++) ...[
            if (index > 0) const Divider(height: .5, thickness: .5, color: Color(0xFFE5E5EA)),
            _stallRow(vendors[index]),
          ],
        ])),
    ]),
  );

  Widget _stallRow(VendorModel vendor) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    leading: Icon(Icons.storefront_outlined, size: 24,
      color: vendor.isOpen ? const Color(0xFFFF6E41) : const Color(0xFF8E8E93)),
    title: Text(vendor.stallName.isEmpty ? 'Unnamed stall' : vendor.stallName,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w400, letterSpacing: 0)),
    subtitle: Padding(padding: const EdgeInsets.only(top: 4),
      child: Text(vendor.category, style: const TextStyle(fontSize: 14, color: Color(0xFF8E8E93), letterSpacing: 0))),
    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(vendor.isOpen ? 'Open' : 'Closed', style: TextStyle(fontSize: 12,
        color: vendor.isOpen ? const Color(0xFF15803D) : const Color(0xFF8E8E93))),
      const SizedBox(width: 6), const Icon(Icons.chevron_right, color: Color(0xFFAEAEB2), size: 20),
    ]),
    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => VendorDetailsScreen(vendor: vendor))),
  );

  Widget _notice(String title, String body, {Widget? action}) => Padding(
    padding: const EdgeInsets.all(24), child: Column(children: [
      Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
      const SizedBox(height: 8), Text(body, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF8E8E93))),
      if (action != null) action,
    ]),
  );
}
