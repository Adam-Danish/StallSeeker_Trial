import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/demo_order.dart';
import 'booking_receipt_pdf.dart';

typedef BookingReceiptFile = ({Uint8List bytes, String filename});

class BookingReceiptService {
  BookingReceiptService({
    Future<BookingReceiptFile> Function(String)? fetchPdf,
    String? Function()? currentUserId,
  })  : _fetchPdf = fetchPdf ?? _serverPdf,
        _currentUserId = currentUserId ?? _verifiedCustomerId;

  final Future<BookingReceiptFile> Function(String) _fetchPdf;
  final String? Function() _currentUserId;

  static String? _verifiedCustomerId() {
    final user = FirebaseAuth.instance.currentUser;
    return user != null && !user.isAnonymous ? user.uid : null;
  }

  Future<BookingReceiptFile> preparePdf(DemoOrder booking) async {
    if (!booking.hasReceipt) {
      throw StateError('Receipt available after payment.');
    }

    try {
      return await _fetchPdf(booking.id);
    } catch (error) {
      if (error is FirebaseFunctionsException &&
          error.code == 'permission-denied') {
        rethrow;
      }
      final currentUid = _currentUserId();
      if (currentUid == null || currentUid != booking.customerId) {
        rethrow;
      }
      final bytes = await buildBookingReceiptPdf(booking);
      // The customer may have signed out while the PDF was being generated.
      if (_currentUserId() != booking.customerId) rethrow;
      return (bytes: bytes, filename: 'StallSeeker-receipt-${booking.id}.pdf');
    }
  }

  static Future<BookingReceiptFile> _serverPdf(String bookingId) async {
    final result = await FirebaseFunctions.instance
        .httpsCallable('getBookingReceipt',
            options: HttpsCallableOptions(timeout: const Duration(seconds: 8)))
        .call<Map<String, dynamic>>({'bookingId': bookingId});
    return (
      bytes: base64Decode(result.data['pdfBase64'] as String),
      filename: result.data['filename'] as String,
    );
  }
}
