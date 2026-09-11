import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/models/menu_item_model.dart';
import '../../../core/services/menu_service.dart';
import '../../../core/services/follow_service.dart';
import '../../../core/services/vendor_service.dart';
import '../../auth/screens/login_screen.dart';

class VendorDetailsScreen extends StatefulWidget {
  final VendorModel vendor;

  const VendorDetailsScreen({super.key, required this.vendor});

  @override
  State<VendorDetailsScreen> createState() => _VendorDetailsScreenState();
}

class _VendorDetailsScreenState extends State<VendorDetailsScreen> {
  final _menuService = MenuService();
  final _followService = FollowService();
  final _vendorService = VendorService();

  // Local copy of the vendor, refreshable independently of the
  // instance passed in -- the one passed in is a snapshot from
  // whenever the customer tapped the marker/card, and doesn't update
  // on its own if the vendor changes their status while this screen
  // is open.
  late VendorModel _vendor;
  bool _isRefreshing = false;
  String? _vendorError;
  bool _vendorDeleted = false;
  bool _isFollowSaving = false;
  StreamSubscription<VendorModel?>? _vendorSub;
  Timer? _freshnessTimer;
  late Stream<List<MenuItemModel>> _menuStream;

  // Local follow state, kept in sync with Firestore via a listener but
  // updated OPTIMISTICALLY (immediately, before the write completes)
  // when the user taps the heart -- this is what makes the icon flip
  // instantly instead of waiting on a round-trip.
  bool _isFollowing = false;
  StreamSubscription<bool>? _followSub;

  @override
  void initState() {
    super.initState();
    _vendor = widget.vendor;
    _menuStream = _menuService.getMenuItems(_vendor.vendorId);
    _vendorSub = _vendorService.watchVendorProfile(_vendor.vendorId).listen(
      (vendor) {
        if (!mounted) { return; }
        setState(() {
          _vendorDeleted = vendor == null;
          if (vendor != null) { _vendor = vendor; }
          _vendorError = null;
        });
      },
      onError: (Object error) {
        if (mounted) { setState(() => _vendorError = 'Could not update this stall. Showing last known details.'); }
      },
    );
    _freshnessTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) { setState(() {}); }
    });

    final customerId = FirebaseAuth.instance.currentUser?.uid;
    if (customerId != null) {
      _followSub = _followService
          .isFollowing(customerId, _vendor.vendorId)
          .listen((value) {
        if (mounted) { setState(() => _isFollowing = value); }
      });
    }
  }

  @override
  void dispose() {
    _followSub?.cancel();
    _vendorSub?.cancel();
    _freshnessTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshVendor() async {
    setState(() => _isRefreshing = true);
    final updated = await _vendorService.getVendorProfile(_vendor.vendorId);
    if (mounted) {
      setState(() {
        if (updated != null) { _vendor = updated; }
        _isRefreshing = false;
      });
    }
  }

  Future<void> _toggleFollow(String customerId) async {
    if (_isFollowSaving) { return; }
    _isFollowSaving = true;
    final wasFollowing = _isFollowing;
    // Flip immediately -- don't wait for Firestore to confirm. If the
    // write fails for some reason, it gets reverted in the catch below.
    setState(() => _isFollowing = !wasFollowing);

    try {
      if (wasFollowing) {
        await _followService.unfollowVendor(customerId, _vendor.vendorId);
      } else {
        await _followService.followVendor(customerId, _vendor.vendorId);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isFollowing = wasFollowing);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not update following. Please retry.')),
        );
      }
    } finally {
      if (mounted) { setState(() => _isFollowSaving = false); }
    }
  }

  Future<void> _openNavigation() async {
    final coordinates = '${_vendor.latitude},${_vendor.longitude}';
    final isApplePlatform = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final googleMapsUri = isApplePlatform
        ? Uri.parse('comgooglemaps://?daddr=$coordinates&directionsmode=driving')
        : Uri.parse('google.navigation:q=$coordinates&mode=d');
    final wazeUri = Uri.parse('waze://?ll=$coordinates&navigate=yes');
    final browserUri = Uri.https(
      'www.google.com', '/maps/dir/', {'api': '1', 'destination': coordinates},
    );
    var googleMapsAvailable = false;
    var wazeAvailable = false;
    if (!kIsWeb) {
      try {
        googleMapsAvailable = await canLaunchUrl(googleMapsUri);
        wazeAvailable = await canLaunchUrl(wazeUri);
      } catch (_) {
        // The browser fallback remains available when app detection fails.
      }
    }
    if (!mounted) { return; }

    Future<void> launchNavigation(Uri uri) async {
      Navigator.pop(context);
      var launched = false;
      try { launched = await launchUrl(uri, mode: LaunchMode.externalApplication); }
      catch (_) { launched = false; }
      if (!launched && mounted) { ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open that navigation app.'))); }
    }

    await showModalBottomSheet<void>(context: context, showDragHandle: true,
      builder: (sheetContext) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(title: const Text('Choose navigation app'),
          subtitle: Text(_vendor.stallName.isEmpty ? 'Stall location' : _vendor.stallName)),
        if (googleMapsAvailable) ListTile(leading: const Icon(Icons.map_outlined),
          title: const Text('Google Maps'), onTap: () => launchNavigation(googleMapsUri)),
        if (wazeAvailable) ListTile(leading: const Icon(Icons.navigation_outlined),
          title: const Text('Waze'), onTap: () => launchNavigation(wazeUri)),
        ListTile(leading: const Icon(Icons.open_in_browser),
          title: const Text('Google Maps in browser'), onTap: () => launchNavigation(browserUri)),
        if (!googleMapsAvailable && !wazeAvailable) const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Text('Google Maps and Waze were not detected. Browser directions are still available.',
            style: TextStyle(color: Colors.grey))),
      ])));
  }

  void _showLoginRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create an Account'),
        content: const Text(
          'Following vendors requires an account. Log in or register to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Log In'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'available':
        return const Color(0xFF15803D);
      case 'low_stock':
        return const Color(0xFF92400E);
      case 'out_of_stock':
        return const Color(0xFFB42318);
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'available':
        return 'Available';
      case 'low_stock':
        return 'Low Stock';
      case 'out_of_stock':
        return 'Sold out';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final customerId = currentUser?.uid;
    final isGuest = currentUser?.isAnonymous ?? true;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text('Stall details'),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            tooltip: 'Refresh stall status',
            onPressed: _isRefreshing ? null : _refreshVendor,
          ),
          if (customerId != null)
            isGuest
                ? IconButton(
                    icon: const Icon(Icons.favorite_border),
                    tooltip: 'Follow',
                    onPressed: () => _showLoginRequiredDialog(context),
                  )
                : IconButton(
                    icon: Icon(
                      _isFollowing ? Icons.favorite : Icons.favorite_border,
                      color: _isFollowing ? Colors.red : null,
                    ),
                    tooltip: _isFollowing ? 'Unfollow' : 'Follow',
                    onPressed: _isFollowSaving || _vendorDeleted ? null : () => _toggleFollow(customerId),
                  ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          onPressed: !_vendorDeleted && _vendor.hasValidLocation ? _openNavigation : null,
          icon: const Icon(Icons.directions),
          label: const Text('Get directions'),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          if (_vendorDeleted || _vendorError != null)
            Padding(padding: const EdgeInsets.only(bottom: 12),
              child: Text(_vendorDeleted ? 'This stall is no longer available.' : _vendorError!)),
          ClipRRect(borderRadius: BorderRadius.circular(24),
            child: AspectRatio(aspectRatio: 1.8,
              child: _vendor.imageUrl.isNotEmpty
                  ? Image.network(_vendor.imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _photoPlaceholder())
                  : _photoPlaceholder())),
          const SizedBox(height: 20),
          Wrap(spacing: 8, runSpacing: 8, children: [
            _badge(_vendor.isOpen ? 'Open now' : 'Closed',
                _vendor.isOpen ? const Color(0xFF15803D) : const Color(0xFFB42318), Icons.circle),
            if (_vendor.category.isNotEmpty)
              _badge(_vendor.category, const Color(0xFF64748B), Icons.restaurant_outlined),
          ]),
          const SizedBox(height: 12),
          Text(_vendor.stallName.isEmpty ? 'Unnamed stall' : _vendor.stallName,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800,
              height: 1.2, color: Color(0xFF17202D))),
          if (_vendor.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(_vendor.description,
              style: const TextStyle(fontSize: 14, height: 1.5, color: Color(0xFF64748B))),
          ],
          const SizedBox(height: 18),
          Container(padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFE9ECF0))),
            child: Column(children: [
              _info(Icons.schedule_rounded, 'Opening hours',
                _vendor.openingHours.isEmpty ? 'Not provided by this vendor' : _vendor.openingHours),
              const Divider(height: 24, indent: 36),
              _info(Icons.location_on_outlined, _vendor.hasFreshLocation ? 'Location updated recently' : 'Last known location',
                _vendor.hasFreshLocation ? 'The vendor is sharing their location.'
                    : 'This location may be outdated. Check before travelling.'),
            ])),
          const SizedBox(height: 26),
          const Text('On the menu', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF17202D))),
          const SizedBox(height: 4),
          const Text('Availability is updated by the vendor', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
          const SizedBox(height: 14),
          StreamBuilder<List<MenuItemModel>>(
            stream: _menuStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Padding(padding: const EdgeInsets.all(20), child: Column(children: [
                  const Text('Could not load the menu.'),
                  TextButton(onPressed: () => setState(() => _menuStream = _menuService.getMenuItems(_vendor.vendorId)),
                    child: const Text('Retry')),
                ]));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Padding(padding: EdgeInsets.all(24), child: Text('The vendor has not added a menu yet.'));
              }
              return Column(children: items.map(_menuCard).toList());
            },
          ),
        ],
      ),
    );
  }

  Widget _photoPlaceholder() => Container(color: const Color(0xFFFFF0E7),
    alignment: Alignment.center,
    child: const Icon(Icons.storefront_rounded, size: 60, color: Color(0xFFC64B22)));

  Widget _badge(String text, Color color, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: color.withValues(alpha: .08), borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: color), const SizedBox(width: 5),
      Flexible(child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color))),
    ]),
  );

  Widget _info(IconData icon, String title, String detail) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, color: const Color(0xFF64748B), size: 21), const SizedBox(width: 14),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF17202D))),
      const SizedBox(height: 4),
      Text(detail, style: const TextStyle(fontSize: 12, height: 1.4, color: Color(0xFF64748B))),
    ])),
  ]);

  Widget _menuCard(MenuItemModel item) => Container(
    margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE9ECF0))),
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(borderRadius: BorderRadius.circular(14),
        child: SizedBox(width: 68, height: 68,
          child: item.imageUrl.isEmpty ? _photoPlaceholder()
              : Image.network(item.imageUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _photoPlaceholder()))),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF17202D))),
        const SizedBox(height: 4),
        Text('RM ${item.price.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFC64B22))),
        const SizedBox(height: 8),
        _badge(_statusLabel(item.status), _statusColor(item.status), Icons.circle),
      ])),
    ]),
  );
}
