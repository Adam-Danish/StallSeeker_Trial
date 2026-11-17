import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pdf;

import '../models/demo_order.dart';

Future<Uint8List> buildBookingReceiptPdf(DemoOrder booking) async {
  final paidAt = booking.paymentPaidAt;
  if (!booking.hasReceipt || paidAt == null) {
    throw StateError('Receipt available after payment.');
  }

  const fontSize = 11.0;
  const margin = 42.0;
  final width = PdfPageFormat.a4.width - 2 * margin;
  pdf.Font regular;
  pdf.Font bold;
  Map<int, int> glyphs = const {};
  try {
    final fontData = await rootBundle.load('assets/fonts/Poppins-Regular.ttf');
    glyphs = TtfParser(fontData).charToGlyphIndexMap;
    regular = pdf.Font.ttf(fontData);
    bold =
        pdf.Font.ttf(await rootBundle.load('assets/fonts/Poppins-SemiBold.ttf'));
  } catch (_) {
    regular = pdf.Font.helvetica();
    bold = pdf.Font.helveticaBold();
  }
  final content = <pdf.Widget>[];

  Future<void> addLine(String text,
      {double size = fontSize, bool strong = false}) async {
    if (text.runes.every((rune) => rune == 10 || glyphs.containsKey(rune))) {
      content.add(pdf.Text(text,
          style: pdf.TextStyle(font: strong ? bold : regular, fontSize: size)));
    } else {
      // Use Flutter's font fallback for names and dishes outside Poppins' glyph set.
      const scale = 3.0;
      final paragraph = (ui.ParagraphBuilder(ui.ParagraphStyle(
              textDirection: ui.TextDirection.ltr, fontSize: size * scale))
            ..pushStyle(ui.TextStyle(
                color: const ui.Color(0xff292524),
                fontWeight: strong ? ui.FontWeight.w600 : ui.FontWeight.w400))
            ..addText(text))
          .build()
        ..layout(ui.ParagraphConstraints(width: width * scale));
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawParagraph(paragraph, ui.Offset.zero);
      final picture = recorder.endRecording();
      final image = await picture.toImage(
          (width * scale).ceil(), paragraph.height.ceil());
      try {
        final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        content.add(pdf.Image(pdf.MemoryImage(Uint8List.sublistView(png)),
            width: image.width / scale, height: image.height / scale));
      } finally {
        image.dispose();
        picture.dispose();
      }
    }
    content.add(pdf.SizedBox(height: 5));
  }

  String money(int cents) => 'RM ${(cents / 100).toStringAsFixed(2)}';
  String two(int value) => value.toString().padLeft(2, '0');
  final malaysia = paidAt.toUtc().add(const Duration(hours: 8));
  final paidOn = '${two(malaysia.day)}/${two(malaysia.month)}/${malaysia.year} '
      '${two(malaysia.hour)}:${two(malaysia.minute)} MYT';
  final reference = booking.paymentReference;
  final refunded = booking.paymentRefundedCents;
  final paymentStatus = booking.paymentStatus ?? 'paid';
  final status = paymentStatus == 'paid' && refunded > 0
      ? 'partially refunded'
      : paymentStatus.replaceAll('_', ' ');

  await addLine('StallSeeker payment receipt', size: 21, strong: true);
  await addLine(booking.hasTestPayment
      ? 'Stripe checkout (no live charge)'
      : 'Stripe payment');
  await addLine('Generated from saved booking details', size: 9);
  content.add(pdf.Divider());
  await addLine(booking.stallName, size: 15, strong: true);
  await addLine('Customer: ${booking.customerName}');
  await addLine('Paid on: $paidOn');
  await addLine('Booking ID: ${booking.id}');
  if (!booking.hasTestPayment && reference != null && reference.isNotEmpty) {
    await addLine('Payment reference: $reference');
  }
  content.add(pdf.Divider());
  await addLine('Items', size: 14, strong: true);
  for (final item in booking.items) {
    await addLine('${item.quantity} x ${item.name}', strong: true);
    await addLine(
        '${money(item.unitPriceCents)} each  |  ${money(item.subtotalCents)}');
  }
  content.add(pdf.Divider());
  await addLine('Amount paid: ${money(booking.totalCents)}',
      size: 14, strong: true);
  if (refunded > 0) {
    await addLine('Refunded: ${money(refunded)}');
    await addLine(
        'Remaining paid: ${money((booking.totalCents - refunded).clamp(0, booking.totalCents))}');
  }
  await addLine('Payment status: $status');

  final document = pdf.Document(title: 'StallSeeker payment receipt');
  document.addPage(pdf.MultiPage(
    maxPages: 100,
    pageFormat: PdfPageFormat.a4,
    margin: const pdf.EdgeInsets.all(margin),
    build: (_) => content,
  ));
  return document.save();
}
