import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'booking_receipt_service.dart';

Future<String?> downloadBookingReceipt(BookingReceiptFile receipt) async {
  final body = web.document.body;
  if (body == null) throw StateError('The download page is unavailable.');

  final blob = web.Blob(
      [receipt.bytes.toJS].toJS, web.BlobPropertyBag(type: 'application/pdf'));
  final url = web.URL.createObjectURL(blob);
  final link = web.HTMLAnchorElement()
    ..href = url
    ..download = receipt.filename;
  try {
    body.append(link);
    link.click();
  } finally {
    link.remove();
    // Give the browser time to read the blob after the download starts.
    Timer(const Duration(minutes: 1), () => web.URL.revokeObjectURL(url));
  }
  return null;
}
