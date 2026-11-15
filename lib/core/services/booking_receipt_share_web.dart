import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:ui';

import 'package:printing/printing.dart';
import 'package:web/web.dart' as web;

import 'booking_receipt_service.dart';

Future<void> shareBookingReceipt(
    BookingReceiptFile receipt, Rect? bounds) async {
  final navigator = web.window.navigator;
  if (navigator.has('share') && navigator.has('canShare')) {
    final data = web.ShareData(
        files: [
      web.File([receipt.bytes.toJS].toJS, receipt.filename,
          web.FilePropertyBag(type: 'application/pdf')),
    ].toJS);
    if (navigator.canShare(data)) {
      try {
        final sharedOrCancelled = await navigator
            .share(data)
            .callMethod<JSPromise<JSBoolean>>(
              'then'.toJS,
              (() => true.toJS).toJS,
              ((JSAny? error) => (error != null &&
                      error.isA<JSObject>() &&
                      (error as JSObject)
                              .getProperty<JSString?>('name'.toJS)
                              ?.toDart ==
                          'AbortError')
                  .toJS).toJS,
            )
            .toDart;
        if (sharedOrCancelled.toDart) return;
      } catch (_) {
        // The browser download also works when the share API is restricted.
      }
    }
  }

  final downloaded =
      await Printing.sharePdf(bytes: receipt.bytes, filename: receipt.filename);
  if (!downloaded) throw StateError('Could not download the PDF receipt.');
}
