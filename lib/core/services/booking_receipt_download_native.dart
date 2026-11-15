import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'booking_receipt_service.dart';

Future<String?> downloadBookingReceipt(BookingReceiptFile receipt) async {
  if (Platform.isAndroid || Platform.isIOS) {
    const channel = MethodChannel('stallseeker/receipt_download');
    final saved = await channel.invokeMethod<bool>('savePdf', {
      'bytes': receipt.bytes,
      'filename': receipt.filename,
    });
    return saved == true ? 'Receipt saved.' : null;
  }

  final downloads = await getDownloadsDirectory();
  if (downloads == null) throw StateError('Downloads folder unavailable.');
  await downloads.create(recursive: true);
  final file =
      File('${downloads.path}${Platform.pathSeparator}${receipt.filename}');
  await file.writeAsBytes(receipt.bytes, flush: true);
  return 'Receipt saved to Downloads.';
}
