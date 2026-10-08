import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/demo_order.dart';
import '../models/vendor_model.dart';

/// Device-only self-collect bookings for the prototype APK.
/// Nothing here sends a booking to another phone or charges a customer.
class LocalDemoBookingService {
  LocalDemoBookingService({String? actorId}) : _testActorId = actorId;

  static const _bookingsKey = 'self_collect_bookings_v1';
  static const _enabledPrefix = 'self_collect_enabled_v1_';
  static final _changed = StreamController<void>.broadcast();

  final String? _testActorId;

  String? get _actorId =>
      _testActorId ?? FirebaseAuth.instance.currentUser?.uid;

  Future<bool> isSelfCollectEnabled(String vendorId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_enabledPrefix$vendorId') ?? false;
  }

  Future<void> setSelfCollectEnabled(String vendorId, bool enabled) async {
    if (_actorId != vendorId) throw StateError('Vendor account required.');
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setBool('$_enabledPrefix$vendorId', enabled)) {
      throw StateError('Could not save booking preference.');
    }
    _changed.add(null);
  }

  Stream<List<DemoOrder>> watchCustomerOrders(String customerId) =>
      _watch((booking) => booking.customerId == customerId);

  Stream<List<DemoOrder>> watchVendorOrders(String vendorId) =>
      _watch((booking) => booking.vendorId == vendorId);

  Stream<List<DemoOrder>> _watch(bool Function(DemoOrder) include) async* {
    Future<List<DemoOrder>> current() async {
      final bookings = (await _load()).where(include).toList();
      bookings.sort((a, b) => (b.createdAt ?? DateTime(1970))
          .compareTo(a.createdAt ?? DateTime(1970)));
      return bookings;
    }

    yield await current();
    yield* _changed.stream.asyncMap((_) => current());
  }

  Future<String> requestOrder(VendorModel vendor, List<DemoOrderItem> items,
      {String? customerName}) async {
    final customerId = _actorId;
    if (customerId == null || customerId == vendor.vendorId) {
      throw StateError('Customer account required.');
    }
    if (!await isSelfCollectEnabled(vendor.vendorId)) {
      throw StateError('Self-collect booking is unavailable.');
    }
    if (items.isEmpty || items.any((item) => item.quantity < 1)) {
      throw ArgumentError('Choose at least one dish.');
    }
    final user =
        _testActorId == null ? FirebaseAuth.instance.currentUser : null;
    final name = customerName?.trim().isNotEmpty == true
        ? customerName!.trim()
        : (user?.displayName?.trim().isNotEmpty == true
            ? user!.displayName!.trim()
            : user?.email?.split('@').first ?? 'Customer');
    final now = DateTime.now();
    final booking = DemoOrder(
      id: '${now.microsecondsSinceEpoch}_$customerId',
      customerId: customerId,
      vendorId: vendor.vendorId,
      customerName: name,
      stallName: vendor.stallName,
      status: 'requested',
      items: items,
      totalCents: items.fold(0, (sum, item) => sum + item.subtotalCents),
      createdAt: now,
      pickupLatitude: vendor.hasValidLocation ? vendor.latitude : null,
      pickupLongitude: vendor.hasValidLocation ? vendor.longitude : null,
    );
    final bookings = await _load();
    bookings.insert(0, booking);
    await _save(bookings);
    return booking.id;
  }

  Future<void> removeAccountData(String accountId) async {
    final bookings = await _load();
    await _save(bookings
        .where((booking) =>
            booking.customerId != accountId && booking.vendorId != accountId)
        .toList());
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_enabledPrefix$accountId');
  }

  Future<void> respond(String bookingId, {required bool accept}) =>
      _update(bookingId, (booking) {
        if (_actorId != booking.vendorId ||
            booking.effectiveStatus != 'requested') {
          throw StateError('This booking can no longer be answered.');
        }
        return booking.withStatus(accept ? 'confirmed' : 'rejected');
      });

  Future<void> advance(String bookingId) => _update(bookingId, (booking) {
        if (_actorId != booking.vendorId) {
          throw StateError('Vendor account required.');
        }
        final next = switch (booking.effectiveStatus) {
          'confirmed' => 'preparing',
          'preparing' => 'ready',
          'ready' => 'collected',
          _ => null,
        };
        if (next == null) throw StateError('This booking cannot advance.');
        return booking.withStatus(next);
      });

  Future<void> cancel(String bookingId) => _update(bookingId, (booking) {
        final status = booking.effectiveStatus;
        final customerCanCancel =
            _actorId == booking.customerId && status == 'requested';
        final vendorCanCancel = _actorId == booking.vendorId &&
            {'requested', 'confirmed', 'preparing', 'ready'}.contains(status);
        if (!customerCanCancel && !vendorCanCancel) {
          throw StateError('This booking cannot be cancelled.');
        }
        return booking.withStatus('cancelled');
      });

  Future<void> _update(
      String bookingId, DemoOrder Function(DemoOrder) change) async {
    final bookings = await _load();
    final index = bookings.indexWhere((booking) => booking.id == bookingId);
    if (index < 0) throw StateError('Booking not found on this device.');
    bookings[index] = change(bookings[index]);
    await _save(bookings);
  }

  Future<List<DemoOrder>> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_bookingsKey);
    if (raw == null) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .whereType<Map>()
        .map((item) => DemoOrder.fromMap(Map<String, dynamic>.from(item)))
        .toList();
  }

  Future<void> _save(List<DemoOrder> bookings) async {
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(_bookingsKey,
        jsonEncode(bookings.map((booking) => booking.toMap()).toList()))) {
      throw StateError('Could not save booking on this device.');
    }
    _changed.add(null);
  }
}
