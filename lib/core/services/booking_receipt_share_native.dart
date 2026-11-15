import 'dart:ui';

import 'package:printing/printing.dart';

import 'booking_receipt_service.dart';

Future<void> shareBookingReceipt(
    BookingReceiptFile receipt, Rect? bounds) async {
  final shared = await Printing.sharePdf(
      bytes: receipt.bytes, filename: receipt.filename, bounds: bounds);
  if (!shared) throw StateError('Could not open the PDF share sheet.');
}
