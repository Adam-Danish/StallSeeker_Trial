'use strict';

const path = require('node:path');
const PDFDocument = require('pdfkit');

const money = (cents) => `RM ${(Number(cents || 0) / 100).toFixed(2)}`;
const paidReceipt = (booking) => booking?.paymentMode === 'test' && !!booking.paymentPaidAt;
const receiptFilename = (id) => `StallSeeker-receipt-${id}.pdf`;

async function receiptPdf(id, booking) {
  if (!paidReceipt(booking)) throw new Error('Receipt available after payment.');
  const doc = new PDFDocument({size: 'A4', margin: 48, bufferPages: true,
    info: {Title: 'StallSeeker payment receipt', Author: 'StallSeeker'}});
  const result = new Promise((resolve, reject) => {
    const chunks = [];
    doc.on('data', (chunk) => chunks.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);
  });
  const cjk = /[\u2e80-\u9fff\uac00-\ud7af]/.test([
    booking.customerName, booking.stallName, ...(booking.items || []).map((item) => item.name),
  ].join(' '));
  doc.registerFont('regular', path.join(__dirname, cjk
    ? 'assets/NotoSansCJKsc-Regular.otf' : 'assets/Poppins-Regular.ttf'));
  doc.registerFont('bold', path.join(__dirname, cjk
    ? 'assets/NotoSansCJKsc-Regular.otf' : 'assets/Poppins-SemiBold.ttf'));
  const text = (value, size = 10, bold = false) => {
    doc.font(bold ? 'bold' : 'regular').fontSize(size).fillColor('#292524')
      .text(String(value), {width: 499, lineGap: 4});
    doc.moveDown(0.45);
  };
  text('StallSeeker', 22, true);
  text('PAYMENT RECEIPT', 12, true);
  text('Stripe test payment - no live charge', 9);
  doc.moveDown();
  text(booking.stallName, 16, true);
  text(`Customer: ${booking.customerName}`);
  text(`Booking ID: ${id}`);
  const date = booking.paymentPaidAt.toDate?.() ?? new Date(booking.paymentPaidAt);
  text(`Paid on: ${date.toLocaleString('en-MY', {timeZone: 'Asia/Kuala_Lumpur'})} (MYT)`);
  if (booking.paymentReference) text(`Payment reference: ${booking.paymentReference}`);
  doc.moveDown();
  text('ITEMS', 11, true);
  for (const item of booking.items || []) {
    text(`${item.quantity} x ${item.name}`, 11, true);
    text(`${money(item.unitPriceCents)} each    |    ${money(item.unitPriceCents * item.quantity)}`, 10);
  }
  doc.moveDown();
  text(`Amount paid: ${money(booking.totalCents)}`, 14, true);
  if (booking.paymentRefundedCents > 0) {
    text(`Refunded: ${money(booking.paymentRefundedCents)}`);
    text(`Remaining paid: ${money(Math.max(0, booking.totalCents - booking.paymentRefundedCents))}`);
  }
  const status = booking.paymentStatus === 'paid' && booking.paymentRefundedCents > 0
    ? 'partially refunded' : String(booking.paymentStatus || 'paid').replaceAll('_', ' ');
  text(`Payment status: ${status}`);
  const range = doc.bufferedPageRange();
  for (let i = 0; i < range.count; i++) {
    doc.switchToPage(i);
    const bottom = doc.page.margins.bottom;
    doc.page.margins.bottom = 0;
    doc.font('regular').fontSize(8).fillColor('#78716c')
      .text(`StallSeeker | Page ${i + 1} of ${range.count}`, 48, 800,
        {width: 499, lineBreak: false});
    doc.page.margins.bottom = bottom;
  }
  doc.end();
  return result;
}

function receiptAllowed(booking, uid, profile) {
  return !!booking && (booking.customerId === uid && profile?.role === 'customer' ||
    String(profile?.role ?? profile?.userRole ?? profile?.type ?? '').toLowerCase() === 'admin');
}

module.exports = {receiptPdf, paidReceipt, receiptFilename, receiptAllowed, money};
