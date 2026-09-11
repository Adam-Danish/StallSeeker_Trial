import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/models/vendor_model.dart';
import '../../../core/services/vendor_service.dart';
import '../../../core/services/vendor_location_service.dart';
import '../profile/edit_stall_screen.dart';
import '../menu/vendor_menu_screen.dart';
import '../../shared/manual_location_dialog.dart';

class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});
  @override
  VendorDashboardScreenState createState() => VendorDashboardScreenState();
}

class VendorDashboardScreenState extends State<VendorDashboardScreen> {
  final _vendorService = VendorService();
  final _location = VendorLocationService.instance;
  StreamSubscription<VendorModel?>? _subscription;
  VendorModel? _vendor;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
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

  void _message(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(_error!, textAlign: TextAlign.center),
        TextButton(onPressed: fetchVendorDetails, child: const Text('Retry')),
      ]));
    }
    final open = _vendor?.isOpen ?? false;
    return RefreshIndicator(
      onRefresh: fetchVendorDetails,
      child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Text(
                _vendor?.stallName.isNotEmpty == true
                    ? _vendor!.stallName
                    : 'Set up your stall',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(open ? 'Stall open' : 'Stall closed'),
                              subtitle: const Text(
                                  'Control whether customers can find you on the live map'),
                              value: open,
                              onChanged: _saving ? null : _toggle),
                          if (_saving) const LinearProgressIndicator(),
                          const Divider(),
                          Text(!open
                              ? 'Location sharing off'
                              : _location.error ??
                                  (_location.isSharing
                                      ? 'Location sharing active in the background'
                                      : 'Location sharing paused')),
                          if (open && !_location.isSharing)
                            TextButton.icon(
                                onPressed: _saving ? null : _resume,
                                icon: const Icon(Icons.my_location),
                                label: const Text('Resume sharing')),
                        ]))),
            const SizedBox(height: 16),
            FilledButton.icon(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const VendorMenuScreen())),
                icon: const Icon(Icons.restaurant_menu),
                label: const Text('Manage menu & stock')),
            const SizedBox(height: 16),
            Card(
                child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Stall information',
                              style: Theme.of(context).textTheme.titleMedium),
                          const SizedBox(height: 8),
                          Text(_vendor?.category ?? 'Choose a food category'),
                          Text(_vendor?.openingHours ??
                              'Add your opening hours'),
                          const SizedBox(height: 8),
                          Text(_vendor?.description ??
                              'Tell customers what you sell.'),
                          TextButton.icon(
                              onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const EditStallScreen())),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit stall')),
                        ]))),
          ]),
    );
  }
}
