import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/demo_order.dart';
import '../models/vendor_model.dart';

/// Live self-collect bookings shared between customer and vendor accounts.
/// The old same-phone demo is read separately by LocalDemoBookingService.
class DemoOrderService {
  DemoOrderService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : _db = firestore ?? FirebaseFirestore.instance,
        _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  Stream<List<DemoOrder>> watchCustomerOrders(String customerId) => _watch(_db
      .collection('bookings')
      .where('customerId', isEqualTo: customerId)
      .orderBy('createdAt', descending: true));

  Stream<List<DemoOrder>> watchVendorOrders(String vendorId) => _watch(_db
      .collection('bookings')
      .where('vendorId', isEqualTo: vendorId)
      .orderBy('createdAt', descending: true));

  Stream<List<DemoOrder>> _watch(Query<Map<String, dynamic>> query) => query
      .snapshots()
      .map((snapshot) => snapshot.docs.map(DemoOrder.fromDocument).toList());

  Stream<DemoOrder?> watchBooking(String bookingId) => _db
      .collection('bookings')
      .doc(bookingId)
      .snapshots()
      .map((doc) => doc.exists ? DemoOrder.fromDocument(doc) : null);

  Stream<int> watchUnseenCount(String uid, {required bool isVendor}) =>
      (isVendor ? watchVendorOrders(uid) : watchCustomerOrders(uid)).map(
          (orders) => orders
              .where((booking) => isVendor
                  ? booking.effectiveStatus == 'requested' &&
                      booking.vendorUnseenRequest
                  : booking.customerUnseenReady)
              .length);

  Future<String> requestOrder(
      VendorModel vendor, List<DemoOrderItem> items) async {
    final random = Random.secure();
    final key = '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
        '${random.nextInt(1 << 32).toRadixString(36).padLeft(7, '0')}'
        '${random.nextInt(1 << 32).toRadixString(36).padLeft(7, '0')}';
    final result = await _functions.httpsCallable('createBooking').call({
      'vendorId': vendor.vendorId,
      'requestKey': key,
      'items': [
        for (final item in items)
          {'itemId': item.itemId, 'quantity': item.quantity}
      ],
    });
    return (result.data as Map)['bookingId'] as String;
  }

  Future<void> respond(String bookingId, {required bool accept}) =>
      _action(bookingId, accept ? 'accept' : 'reject');

  Future<void> advance(String bookingId, String status) => _action(
        bookingId,
        switch (status) {
          'confirmed' => 'startPreparing',
          'preparing' => 'markReady',
          'ready' => 'markCollected',
          _ => throw StateError('Booking cannot advance.'),
        },
      );

  Future<void> cancel(String bookingId) => _action(bookingId, 'cancel');

  Future<void> markViewed(String bookingId) async {
    await _functions.httpsCallable('markBookingViewed').call({
      'bookingId': bookingId,
    });
  }

  Future<void> _action(String bookingId, String action) async {
    await _functions.httpsCallable('updateBooking').call({
      'bookingId': bookingId,
      'action': action,
    });
  }
}
