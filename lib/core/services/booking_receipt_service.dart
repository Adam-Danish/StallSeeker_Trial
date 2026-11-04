import 'dart:convert';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:printing/printing.dart';

class BookingReceiptService {
  Future<void> exportPdf(String bookingId) async {
    final result = await FirebaseFunctions.instance
        .httpsCallable('getBookingReceipt')
        .call({'bookingId': bookingId});
    final data = Map<String, dynamic>.from(result.data as Map);
    final bytes = base64Decode(data['pdfBase64'] as String);
    final shared = await Printing.sharePdf(
      bytes: bytes,
      filename: data['filename'] as String,
    );
    if (!shared) throw StateError('Could not save the PDF receipt.');
  }
}
