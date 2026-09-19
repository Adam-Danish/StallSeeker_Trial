import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/models/menu_item_model.dart';
import '../../../core/models/stall_review.dart';
import '../../../core/services/menu_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/stall_review_service.dart';
import '../../../core/services/storage_service.dart';
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
  final _reviews = StallReviewService();

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
  late Stream<List<StallReview>> _reviewStream;
  final _dishSearch = TextEditingController();
  String _dishQuery = '';

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
    _reviewStream = _reviews.watchReviews(_vendor.vendorId);
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
    _dishSearch.dispose();
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

  void _showLoginRequiredDialog(BuildContext context,
      {String action = 'Following vendors'}) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create an Account'),
        content: Text(
          '$action requires an account. Log in or register to continue.',
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

  Future<void> _editReview(StallReview? existing) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      _showLoginRequiredDialog(context, action: 'Writing reviews');
      return;
    }
    final profile = await AuthService().getUserData(user.uid);
    if (!mounted) return;
    await showModalBottomSheet<void>(context: context, isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ReviewEditor(vendorId: _vendor.vendorId,
        customerId: user.uid, customerName: profile?.fullName ?? user.displayName ?? 'Customer',
        existing: existing));
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
            _badge(_vendor.isOpenNow ? 'Open now' : 'Closed',
                _vendor.isOpenNow ? const Color(0xFF15803D) : const Color(0xFFB42318), Icons.circle),
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
                _vendor.hoursToday.isEmpty ? 'Not provided by this vendor' : _vendor.hoursToday),
              if (_vendor.isTemporarilyClosed) ...[
                const Divider(height: 24, indent: 36),
                _info(Icons.event_busy_outlined, 'Temporary closure',
                  'This stall is temporarily closed.'),
              ],
              if (_vendor.phoneNumber.isNotEmpty) ...[
                const Divider(height: 24, indent: 36),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.call_outlined, color: Color(0xFF64748B)),
                  title: const Text('Vendor phone'),
                  subtitle: Text(_vendor.phoneNumber),
                  trailing: const Icon(Icons.call),
                  onTap: () => launchUrl(Uri(scheme: 'tel', path: _vendor.phoneNumber)),
                ),
              ],
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
          TextField(controller: _dishSearch,
            onChanged: (value) => setState(() => _dishQuery = value.trim().toLowerCase()),
            decoration: InputDecoration(hintText: 'Search dishes',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _dishQuery.isEmpty ? null : IconButton(
                tooltip: 'Clear dish search', icon: const Icon(Icons.close),
                onPressed: () { _dishSearch.clear(); setState(() => _dishQuery = ''); }),
              border: const OutlineInputBorder())),
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
              final filtered = items.where((item) => item.name.toLowerCase().contains(_dishQuery)).toList();
              if (filtered.isEmpty) {
                return const Padding(padding: EdgeInsets.all(20),
                  child: Text('No dishes match your search.'));
              }
              final sections = <String, List<MenuItemModel>>{};
              for (final item in filtered) {
                sections.putIfAbsent(item.section, () => []).add(item);
              }
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                for (final entry in sections.entries) ...[
                  Padding(padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(entry.key, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
                  ...entry.value.map(_menuCard),
                ],
              ]);
            },
          ),
          const SizedBox(height: 20),
          StreamBuilder<List<StallReview>>(
            stream: _reviewStream,
            builder: (context, snapshot) {
              if (snapshot.hasError) return const Text('Could not load reviews.');
              final reviews = snapshot.data ?? [];
              final uid = FirebaseAuth.instance.currentUser?.uid;
              StallReview? mine;
              for (final review in reviews) {
                if (review.customerId == uid) { mine = review; break; }
              }
              final average = reviews.isEmpty ? 0.0 :
                  reviews.fold<int>(0, (sum, review) => sum + review.rating) / reviews.length;
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('Reviews (${reviews.length})',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800))),
                  if (reviews.isNotEmpty) Text('${average.toStringAsFixed(1)} ★',
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 8),
                OutlinedButton.icon(onPressed: () => _editReview(mine),
                  icon: const Icon(Icons.rate_review_outlined),
                  label: Text(mine == null ? 'Write a review' : 'Edit your review')),
                if (reviews.isEmpty) const Padding(padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text('No reviews yet.')),
                for (final review in reviews) _reviewCard(review),
              ]);
            }),
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
        if (item.statusUpdatedAt != null) ...[
          const SizedBox(height: 5),
          Text('Stock updated ${_formatStockTime(item.statusUpdatedAt!)}',
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
        ],
      ])),
    ]),
  );

  String _formatStockTime(DateTime value) {
    final my = value.toUtc().add(const Duration(hours: 8));
    final hour = my.hour % 12 == 0 ? 12 : my.hour % 12;
    final minute = my.minute.toString().padLeft(2, '0');
    return '${my.day}/${my.month}/${my.year} $hour:$minute ${my.hour < 12 ? 'AM' : 'PM'}';
  }

  Widget _reviewCard(StallReview review) => Card(
    margin: const EdgeInsets.only(top: 10),
    child: Padding(padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(review.customerName,
          style: const TextStyle(fontWeight: FontWeight.w700))),
          Text('${review.rating} ★')]),
        if (review.text.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8),
          child: Text(review.text)),
        if (review.photoUrls.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 10),
          child: SizedBox(height: 90, child: ListView.separated(
            scrollDirection: Axis.horizontal, itemCount: review.photoUrls.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) => ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(review.photoUrls[index], width: 90, height: 90,
                fit: BoxFit.cover, errorBuilder: (_, __, ___) =>
                  const SizedBox(width: 90, child: Icon(Icons.broken_image_outlined))))))),
      ])));
}

class _ReviewEditor extends StatefulWidget {
  const _ReviewEditor({required this.vendorId, required this.customerId,
    required this.customerName, required this.existing});
  final String vendorId;
  final String customerId;
  final String customerName;
  final StallReview? existing;
  @override
  State<_ReviewEditor> createState() => _ReviewEditorState();
}

class _ReviewEditorState extends State<_ReviewEditor> {
  final _storage = StorageService();
  final _service = StallReviewService();
  final _text = TextEditingController();
  final _photos = <File>[];
  final _existingUrls = <String>[];
  int _rating = 0;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.existing?.rating ?? 0;
    _text.text = widget.existing?.text ?? '';
    _existingUrls.addAll(widget.existing?.photoUrls ?? []);
  }

  @override
  void dispose() { _text.dispose(); super.dispose(); }

  Future<void> _addPhotos() async {
    final remaining = 5 - _existingUrls.length - _photos.length;
    if (remaining <= 0) { return; }
    final picked = await _storage.pickReviewImages(remaining);
    if (mounted) setState(() => _photos.addAll(picked));
  }

  Future<void> _save() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a star rating.')));
      return;
    }
    setState(() => _saving = true);
    try {
      final urls = [..._existingUrls];
      for (var i = 0; i < _photos.length; i++) {
        urls.add(await _storage.uploadReviewImage(widget.vendorId,
          widget.customerId, '${DateTime.now().microsecondsSinceEpoch}_$i', _photos[i]));
      }
      await _service.saveReview(widget.vendorId, widget.customerId,
        widget.customerName, _rating, _text.text, urls);
      final removed = (widget.existing?.photoUrls ?? <String>[])
          .where((url) => !urls.contains(url));
      for (final url in removed) {
        try {
          await _storage.deleteReviewImageUrl(widget.vendorId, widget.customerId, url);
        } catch (_) {
          // The review was saved; account deletion also cleans up old photos.
        }
      }
      if (mounted) { Navigator.pop(context); }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not save your review. Please retry.')));
      }
    } finally {
      if (mounted) { setState(() => _saving = false); }
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(20, 20, 20,
      MediaQuery.of(context).viewInsets.bottom + 20),
    child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(widget.existing == null ? 'Review this stall' : 'Edit your review',
          style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(children: [for (var star = 1; star <= 5; star++)
          IconButton(tooltip: '$star stars', onPressed: _saving ? null :
            () => setState(() => _rating = star),
            icon: Icon(star <= _rating ? Icons.star : Icons.star_border,
              color: Colors.amber))]),
        TextField(controller: _text, maxLength: 1000, maxLines: 4,
          decoration: const InputDecoration(labelText: 'Your experience (optional)',
            border: OutlineInputBorder())),
        Text('Photos (${_existingUrls.length + _photos.length}/5)'),
        Wrap(spacing: 8, children: [
          for (var i = 0; i < _existingUrls.length; i++)
            InputChip(label: Text('Photo ${i + 1}'), onDeleted: _saving ? null :
              () => setState(() => _existingUrls.removeAt(i))),
          for (var i = 0; i < _photos.length; i++)
            InputChip(label: Text('New photo ${i + 1}'), onDeleted: _saving ? null :
              () => setState(() => _photos.removeAt(i))),
        ]),
        TextButton.icon(onPressed: _saving ? null : _addPhotos,
          icon: const Icon(Icons.add_photo_alternate_outlined),
          label: const Text('Add photos')),
        const SizedBox(height: 12),
        FilledButton(onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save review')),
      ])));
}
