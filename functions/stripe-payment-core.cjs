'use strict';

const TERMINAL = new Set(['cancelled', 'expired', 'rejected']);
const PAYMENT_WINDOW_MS = 10 * 60 * 1000;

function requireTestKey(key) {
  if (typeof key !== 'string' || !/^(sk|rk)_test_\S+$/.test(key.trim())) {
    throw new Error('Stripe sandbox key required. Live payments are disabled.');
  }
  return key.trim();
}

function assertPayable(booking, uid, now) {
  if (!booking || booking.customerId !== uid) {
    throw new Error('This is not your booking.');
  }
  if (booking.paymentMode !== 'test' || booking.status !== 'confirmed' ||
      !['awaiting_payment', 'pending', 'failed'].includes(booking.paymentStatus)) {
    throw new Error('This booking is not awaiting payment.');
  }
  if (!Number.isSafeInteger(booking.totalCents) || booking.totalCents < 200) {
    throw new Error('Test card payments require a booking of at least RM2.00.');
  }
  if (!booking.paymentExpiresAt || booking.paymentExpiresAt.toMillis() <= now) {
    throw new Error('The payment window has ended. Please make a new booking.');
  }
}

function assertSession(bookingId, booking, payment, session) {
  if (!booking || booking.paymentMode !== 'test' || !payment ||
      session.livemode !== false || session.mode !== 'payment' ||
      session.currency !== 'myr' || session.amount_total !== booking.totalCents ||
      session.client_reference_id !== bookingId ||
      session.metadata?.bookingId !== bookingId ||
      session.metadata?.customerId !== booking.customerId ||
      session.metadata?.vendorId !== booking.vendorId ||
      session.metadata?.attemptId !== payment.attemptId ||
      (payment.sessionId && payment.sessionId !== session.id)) {
    throw new Error('Payment does not match this test booking.');
  }
}

function sessionPatch(booking, session, now, {failed = false} = {}) {
  // Stripe can deliver old/repeated events. Paid/refunded records never regress.
  if (['refunded', 'refund_pending'].includes(booking.paymentStatus)) return {};
  if (session.payment_status === 'paid') {
    return {
      paymentStatus: TERMINAL.has(booking.status) ? 'refund_pending' : 'paid',
      paymentReference: session.id,
      paymentPaidAt: booking.paymentPaidAt || now,
    };
  }
  if (booking.paymentStatus === 'paid') return {};
  if (session.status === 'expired') {
    return {paymentStatus: 'expired',
      ...(booking.status === 'confirmed' ? {status: 'expired'} : {})};
  }
  return {paymentStatus: failed ? 'failed' :
    booking.paymentStatus === 'failed' ? 'failed' : 'pending'};
}

module.exports = {TERMINAL, PAYMENT_WINDOW_MS, requireTestKey, assertPayable,
  assertSession, sessionPatch};
