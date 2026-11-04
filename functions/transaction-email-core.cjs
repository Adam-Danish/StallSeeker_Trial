'use strict';
const {createHash} = require('node:crypto');
const {paidReceipt, receiptPdf, receiptFilename, money} = require('./booking-receipt.cjs');

const labels = {
  awaiting_payment: 'Awaiting payment', pending: 'Payment processing',
  paid: 'Payment received', failed: 'Payment failed', expired: 'Payment window expired',
  cancelled: 'Payment cancelled', refund_pending: 'Refund pending',
  refund_failed: 'Refund needs attention', refunded: 'Payment refunded',
};

function transactionChanged(before, after) {
  return after?.paymentMode === 'test' && !!labels[after.paymentStatus] &&
    (!before || before.paymentStatus !== after.paymentStatus ||
      (before.paymentRefundedCents || 0) !== (after.paymentRefundedCents || 0));
}

function eventKey(id) { return createHash('sha256').update(id).digest('hex'); }

async function emailMessage(id, booking, to, from, eventAt) {
  const label = booking.paymentStatus === 'paid' && booking.paymentRefundedCents > 0
    ? 'Partially refunded' : labels[booking.paymentStatus];
  const text = [
    `Hello ${booking.customerName},`, '', `${label} for your booking at ${booking.stallName}.`,
    `Booking ID: ${id}`, `Booking total: ${money(booking.totalCents)}`,
    `Payment status: ${label}`,
    ...(eventAt ? [`Update recorded: ${new Date(eventAt).toLocaleString('en-MY', {timeZone: 'Asia/Kuala_Lumpur'})} (MYT)`] : []),
    ...(booking.paymentReference ? [`Payment reference: ${booking.paymentReference}`] : []),
    ...(booking.paymentRefundedCents > 0 ? [`Refunded: ${money(booking.paymentRefundedCents)}`] : []),
    '', 'This is a Stripe test transaction. No live charge was made.',
    'Open My bookings in StallSeeker to see the latest status.',
  ].join('\n');
  return {from, to, subject: `StallSeeker: ${label} (${id})`, text,
    attachments: paidReceipt(booking) ? [{filename: receiptFilename(id),
      content: await receiptPdf(id, booking), contentType: 'application/pdf'}] : []};
}

// Durable outbox: failed sends remain eligible for the scheduled retry worker.
function emailDelivery({db, Timestamp, FieldValue, sendMail, from, now = Date.now}) {
  async function summary(job, status) {
    const ref = db.doc(`bookings/${job.bookingId}`);
    await db.runTransaction(async (tx) => {
      const current = (await tx.get(ref)).data();
      if (!current || (current.transactionEmailEventAt || 0) > job.eventAt ||
          (current.transactionEmailEventAt === job.eventAt &&
           current.transactionEmailEventId && current.transactionEmailEventId !== job.id)) return;
      if (current.transactionEmailEventId === job.id &&
          (current.transactionEmailStatus === 'sent' && status !== 'sent' ||
           status === 'queued' && current.transactionEmailStatus !== 'queued')) return;
      tx.update(ref, {transactionEmailStatus: status, transactionEmailEventId: job.id,
        transactionEmailEventAt: job.eventAt, transactionEmailUpdatedAt: Timestamp.fromMillis(now())});
    });
  }

  async function deliver(id) {
    const ref = db.doc(`transactionEmailOutbox/${id}`);
    const job = await db.runTransaction(async (tx) => {
      const value = (await tx.get(ref)).data();
      if (!value) return null;
      if (value.status === 'sent') return {...value, id, alreadySent: true};
      if (value.nextAttemptAt?.toMillis() > now()) return null;
      const claimed = {...value, id, attempts: (value.attempts || 0) + 1};
      tx.update(ref, {status: 'sending', attempts: claimed.attempts,
        nextAttemptAt: Timestamp.fromMillis(now() + 5 * 60 * 1000)});
      return claimed;
    });
    if (!job) return;
    if (job.alreadySent) { await summary(job, 'sent'); return; }
    try {
      const message = await emailMessage(job.bookingId, job.booking, job.to, from, job.eventAt);
      const info = await sendMail({...message, messageId: `<${id}@transactions.stallseeker.my>`});
      if (!info.accepted?.length) throw new Error('Recipient was not accepted.');
    } catch (error) {
      await ref.update({status: 'failed', lastError: String(error.code || 'delivery-failed'),
        nextAttemptAt: Timestamp.fromMillis(now() + Math.min(30 * 60 * 1000,
          60 * 1000 * 2 ** Math.min(job.attempts - 1, 5)))});
      await summary(job, 'failed');
      throw error;
    }
    await ref.update({status: 'sent', sentAt: Timestamp.fromMillis(now()),
      nextAttemptAt: FieldValue.delete(), lastError: FieldValue.delete()});
    await summary(job, 'sent');
  }
  return {deliver, summary};
}

module.exports = {transactionChanged, eventKey, emailMessage, emailDelivery};
