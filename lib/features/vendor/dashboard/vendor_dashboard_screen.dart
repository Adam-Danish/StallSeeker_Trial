import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/models/demo_order.dart';
import '../../../core/services/demo_order_service.dart';
import '../../../core/services/vendor_service.dart';
import '../../../core/services/vendor_location_service.dart';
import '../profile/edit_stall_screen.dart';
import '../menu/vendor_menu_screen.dart';
import '../../shared/manual_location_dialog.dart';
import '../../shared/demo_orders_screen.dart';
import '../../shared/booking_detail_screen.dart';
import '../../customer/vendor_details/vendor_details_screen.dart';
import 'vendor_dashboard_view.dart';
import '../reviews/vendor_reviews_dashboard_card.dart';
import '../../../core/utils/vendor_phone.dart';
import 'vendor_demo_sales.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});
  @override
  VendorDashboardScreenState createState() => VendorDashboardScreenState();
}

class VendorDashboardScreenState extends State<VendorDashboardScreen> {
  final _vendorService = VendorService();
  final _orders = DemoOrderService();
  late Stream<List<DemoOrder>> _bookings;
  final _busyBookings = <String>{};
  Timer? _clock;
  final _location = VendorLocationService.instance;
  StreamSubscription<VendorModel?>? _subscription;
  VendorModel? _vendor;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _listenBookings();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
    _location.addListener(_locationChanged);
    fetchVendorDetails();
  }

  void _locationChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _location.removeListener(_locationChanged);
    _subscription?.cancel();
    _clock?.cancel();
    super.dispose();
  }

  Future<void> fetchVendorDetails() async {
    await _subscription?.cancel();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || !mounted) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    _subscription = _vendorService.watchVendorProfile(uid).listen((vendor) {
      if (!mounted) {
        return;
      }
      setState(() {
        _vendor = vendor;
        _loading = false;
        _error = null;
      });
      if (vendor?.isOpen != true && _location.isSharing) {
        unawaited(_location.pause());
      }
    }, onError: (Object error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error =
              'Could not load your stall. Check your connection and retry.';
        });
      }
    });
  }

  Future<Position> _position() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Turn on GPS before sharing your location.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw StateError('Allow location access in your phone settings.');
    }
    if (permission == LocationPermission.denied) {
      throw StateError('Location permission is required.');
    }
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).timeout(const Duration(seconds: 12));
  }

  Future<void> _toggle(bool open) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (_saving || uid == null) {
      return;
    }
    if (open && (_vendor?.stallName.trim().isEmpty ?? true)) {
      _message('Set up your stall name before opening.');
      return;
    }
    if (open && normalizeVendorPhone(_vendor?.phoneNumber ?? '') == null) {
      _message('Add a business phone number in My stall before opening.');
      return;
    }
    if (open && (_vendor?.isTemporarilyClosed ?? false)) {
      _message('Remove the active temporary closure before opening.');
      return;
    }
    if (open) {
      final agreed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
                title: const Text('Open stall and share location?'),
                content: const Text(
                    'Your location continues updating while your stall is open, even when you lock your phone or use another app. Android shows a persistent notification while sharing is active.'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel')),
                  FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Open stall')),
                ],
              ));
      if (agreed != true || !mounted) {
        return;
      }
    }
    setState(() => _saving = true);
    try {
      if (open) {
        double? latitude;
        double? longitude;
        var manualLocation = false;
        try {
          final position = await _position();
          latitude = position.latitude;
          longitude = position.longitude;
        } catch (_) {
          if (!mounted) {
            return;
          }
          final existing = _vendor?.hasValidLocation == true
              ? LatLng(_vendor!.latitude, _vendor!.longitude)
              : null;
          final selection = await showManualLocationDialog(context,
              initialLocation: existing, title: 'Set Stall Location Manually');
          if (selection == null || !mounted) {
            return;
          }
          latitude = selection.coordinates.latitude;
          longitude = selection.coordinates.longitude;
          manualLocation = true;
        }
        if (!mounted || FirebaseAuth.instance.currentUser?.uid != uid) {
          return;
        }
        await _vendorService.updateVendorLocation(uid, latitude, longitude,
            sharingActive: !manualLocation);
        await _vendorService.toggleStallStatus(uid, true);
        if (!manualLocation && mounted) {
          await _location.start(uid);
        }
        if (manualLocation) {
          _message('Your stall is open using the manually entered location.');
        }
      } else {
        await _location.pause();
        await _vendorService.toggleStallStatus(uid, false);
      }
      if (!open) {
        _message('Your stall is closed.');
      }
      if (open && _location.isSharing) {
        _message('Your stall is open.');
      }
    } catch (_) {
      _message(
          'Could not update your stall. Check GPS, location permission, and connection, then retry.');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _resume() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _saving) {
      return;
    }
    setState(() => _saving = true);
    try {
      await _position();
      if (mounted && FirebaseAuth.instance.currentUser?.uid == uid) {
        await _location.start(uid);
      }
    } catch (_) {
      _message('Could not share location. Check GPS and location permission.');
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _toggleDemoSelfCollect(bool enabled) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _saving) return;
    setState(() => _saving = true);
    try {
      await _vendorService.setSelfCollectEnabled(uid, enabled);
      _message(enabled
          ? 'Customers can now pay for self-collect bookings immediately.'
          : 'New self-collect bookings are off.');
    } catch (_) {
      _message('Could not save booking setting. Please retry.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  void _listenBookings() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    _bookings = uid == null
        ? Stream.value(<DemoOrder>[])
        : _orders.watchVendorOrders(uid);
  }

  Future<void> _refresh() async {
    setState(_listenBookings);
    await fetchVendorDetails();
  }

  void _push(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Future<void> _advanceBooking(DemoOrder booking) async {
    if (_busyBookings.contains(booking.id)) return;
    setState(() => _busyBookings.add(booking.id));
    try {
      await _orders.advance(booking.id, booking.effectiveStatus);
      _message(booking.effectiveStatus == 'preparing'
          ? 'Booking is ready for collection.'
          : 'Booking is now being prepared.');
    } catch (_) {
      _message('Could not update this booking. Please retry.');
    } finally {
      if (mounted) setState(() => _busyBookings.remove(booking.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
          child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!, textAlign: TextAlign.center),
          TextButton(onPressed: _refresh, child: const Text('Retry')),
        ]),
      ));
    }
    return StreamBuilder<List<DemoOrder>>(
      stream: _bookings,
      builder: (context, snapshot) => VendorDashboardView(
        vendor: _vendor,
        reviewsCard: _vendor == null
            ? null
            : VendorReviewsDashboardCard(
                key: ValueKey(_vendor!.vendorId),
                vendorId: _vendor!.vendorId,
                stallName: _vendor!.stallName),
        bookings: snapshot.data ?? const [],
        bookingsLoading: !snapshot.hasData && !snapshot.hasError,
        bookingsError: snapshot.hasError,
        saving: _saving,
        locationSharing: _location.isSharing,
        locationError: _location.error,
        busyBookings: _busyBookings,
        onRefresh: _refresh,
        onToggleOpen: _toggle,
        onToggleSelfCollect: _toggleDemoSelfCollect,
        onResumeLocation: _resume,
        onPreview: () {
          if (_vendor != null) {
            _push(VendorDetailsScreen(vendor: _vendor!, previewOnly: true));
          }
        },
        onEditStall: () => _push(const EditStallScreen()),
        onMenu: () => _push(const VendorMenuScreen()),
        onStock: () => _push(const VendorMenuScreen(stockOnly: true)),
        onBookings: () => _push(const DemoOrdersScreen(isVendor: true)),
        onPaymentHistory: () => _push(const VendorPaymentHistoryScreen()),
        onOpenBooking: (booking) =>
            _push(BookingDetailScreen(bookingId: booking.id, isVendor: true)),
        onAdvanceBooking: _advanceBooking,
      ),
    );
  }
}
