'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const {receiptPdf, receiptAllowed} = require('./booking-receipt.cjs');
const {transactionChanged, emailMessage, emailDelivery} = require('./transaction-email-core.cjs');

const booking = {customerId: 'customer', vendorId: 'vendor', customerName: 'Adam',
  stallName: 'Nasi Lemak Kak Ani', paymentMode: 'test', paymentStatus: 'paid',
  paymentPaidAt: new Date('2026-11-04T02:00:00Z'), paymentReference: 'cs_test_123',
  totalCents: 1250, items: [{name: 'Nasi Lemak', quantity: 2, unitPriceCents: 625}]};

test('receipts allow their customer and admins, deny vendors and other accounts', () => {
  assert.equal(receiptAllowed(booking, 'customer', {role: 'customer'}), true);
  assert.equal(receiptAllowed(booking, 'admin', {role: 'admin'}), true);
  assert.equal(receiptAllowed(booking, 'vendor', {role: 'vendor'}), false);
  assert.equal(receiptAllowed(booking, 'other', {role: 'customer'}), false);
  assert.equal(receiptAllowed(undefined, 'admin', {role: 'admin'}), false);
});

test('PDF requires recorded payment and works for refunds and long receipts', async () => {
  await assert.rejects(receiptPdf('unpaid', {...booking, paymentPaidAt: null}));
  const short = await receiptPdf('booking-123', booking);
  assert.equal((short.toString('latin1').match(/\/Type \/Page\b/g) || []).length, 1);
  for (const status of ['paid', 'refund_pending', 'refunded']) {
    const pdf = await receiptPdf('booking-123', {...booking, paymentStatus: status,
      paymentRefundedCents: status === 'refunded' ? 1250 : 0,
      items: Array.from({length: 20}, () => ({...booking.items[0], name: 'Long menu item '.repeat(12)}))});
    assert.equal(pdf.subarray(0, 5).toString(), '%PDF-');
    assert.ok(pdf.length > 5000);
  }
});

test('only transaction changes queue emails, including partial refunds', () => {
  assert.equal(transactionChanged(null, booking), true);
  assert.equal(transactionChanged(booking, {...booking, status: 'ready'}), false);
  for (const paymentStatus of ['failed', 'expired', 'cancelled', 'refund_pending', 'refund_failed', 'refunded']) {
    assert.equal(transactionChanged(booking, {...booking, paymentStatus}), true);
  }
  assert.equal(transactionChanged(booking, {...booking, paymentRefundedCents: 250}), true);
  assert.equal(transactionChanged(null, {...booking, paymentMode: null}), false);
});

test('paid email attaches PDF, unpaid update explains status without a receipt', async () => {
  const paid = await emailMessage('booking-123', booking, 'customer@example.com', 'sender@example.com');
  assert.equal(paid.to, 'customer@example.com');
  assert.equal(paid.attachments[0].contentType, 'application/pdf');
  assert.match(paid.text, /RM 12.50/);
  const failed = await emailMessage('booking-123', {...booking, paymentStatus: 'failed', paymentPaidAt: null}, 'customer@example.com', 'sender@example.com');
  assert.equal(failed.attachments.length, 0);
  assert.match(failed.subject, /Payment failed/);
});

test('SMTP message encodes the PDF attachment without contacting an email server', async () => {
  const transport = require('nodemailer').createTransport({streamTransport: true, buffer: true});
  const message = await emailMessage('booking-123', booking, 'customer@example.invalid', 'sender@example.invalid');
  const result = await transport.sendMail(message);
  assert.match(result.message.toString(), /Content-Type: application\/pdf/);
  assert.match(result.message.toString(), /StallSeeker-receipt-booking-123.pdf/);
  assert.match(result.message.toString(), /To: customer@example.invalid/);
});

test('failed mail retries durably and a delivered event does not send again', async () => {
  let currentTime = 1000;
  const stamp = (value) => ({toMillis: () => value});
  const deleted = Symbol('delete');
  const values = new Map([
    ['bookings/booking-123', {...booking}],
    ['transactionEmailOutbox/event', {bookingId: 'booking-123', booking,
      to: 'customer@example.com', eventAt: 1, status: 'queued', attempts: 0,
      nextAttemptAt: stamp(0)}],
  ]);
  const update = (key, patch) => {
    const value = values.get(key);
    for (const [field, next] of Object.entries(patch)) {
      if (next === deleted) delete value[field]; else value[field] = next;
    }
  };
  const db = {
    doc: (key) => ({key, update: async (patch) => update(key, patch)}),
    runTransaction: async (run) => run({
      get: async (ref) => ({data: () => values.get(ref.key)}),
      update: (ref, patch) => update(ref.key, patch),
    }),
  };
  let sends = 0;
  const worker = emailDelivery({db, Timestamp: {fromMillis: stamp},
    FieldValue: {delete: () => deleted}, from: 'sender@example.com', now: () => currentTime,
    sendMail: async () => { sends++; if (sends === 1) throw new Error('Temporary SMTP failure');
      return {accepted: ['customer@example.com']}; },
  });
  await assert.rejects(worker.deliver('event'));
  assert.equal(values.get('bookings/booking-123').transactionEmailStatus, 'failed');
  await worker.deliver('event');
  assert.equal(sends, 1); // Retry waits for its due time.
  currentTime += 60_001;
  await worker.deliver('event');
  await worker.deliver('event');
  assert.equal(sends, 2);
  assert.equal(values.get('transactionEmailOutbox/event').status, 'sent');
  assert.equal(values.get('bookings/booking-123').transactionEmailStatus, 'sent');
  await worker.summary({...values.get('transactionEmailOutbox/event'), id: 'event'}, 'queued');
  assert.equal(values.get('bookings/booking-123').transactionEmailStatus, 'sent');
});

test('Chinese customer and item names produce a valid embedded-font PDF', async () => {
  const pdf = await receiptPdf('booking-cjk', {...booking, customerName: '陈小明',
    items: [{name: '海南鸡饭', quantity: 1, unitPriceCents: 1250}]});
  assert.equal(pdf.subarray(0, 5).toString(), '%PDF-');
});
