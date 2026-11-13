'use strict';

const TERMINAL = new Set(['cancelled', 'expired', 'rejected']);
const PAYMENT_WINDOW_MS = 10 * 60 * 1000;

function requireModeKey(key, mode) {
  const suffix = mode === 'live' ? 'live' : mode === 'test' ? 'test' : null;
  if (!suffix || typeof key !== 'string' ||
      !new RegExp(`^(sk|rk)_${suffix}_\\S+$`).test(key.trim())) {
    throw new Error(`A Stripe ${suffix || 'valid'} mode key is required.`);
  }
  return key.trim();
}

function requireTestKey(key) { return requireModeKey(key, 'test'); }

function isStripePaymentMode(mode) {
  return mode === 'test' || mode === 'live';
}

function assertPayable(booking, uid, now) {
  if (!booking || booking.customerId !== uid) {
    throw new Error('This is not your booking.');
  }
  if (!isStripePaymentMode(booking.paymentMode) || booking.status !== 'confirmed' ||
      !['awaiting_payment', 'pending', 'failed'].includes(booking.paymentStatus)) {
    throw new Error('This booking is not awaiting payment.');
  }
  if (!Number.isSafeInteger(booking.totalCents) || booking.totalCents < 200) {
    throw new Error('Card payments require a booking of at least RM2.00.');
  }
  if (!booking.paymentExpiresAt || booking.paymentExpiresAt.toMillis() <= now) {
    throw new Error('The payment window has ended. Please make a new booking.');
  }
}

function assertSession(bookingId, booking, payment, session) {
  const expectedLive = booking?.paymentMode === 'live';
  if (!booking || !isStripePaymentMode(booking.paymentMode) || !payment ||
      session.livemode !== expectedLive || session.mode !== 'payment' ||
      session.currency !== 'myr' || session.amount_total !== booking.totalCents ||
      session.client_reference_id !== bookingId ||
      session.metadata?.bookingId !== bookingId ||
      session.metadata?.customerId !== booking.customerId ||
      session.metadata?.vendorId !== booking.vendorId ||
      session.metadata?.attemptId !== payment.attemptId ||
      (session.metadata?.paymentMode &&
        session.metadata.paymentMode !== booking.paymentMode) ||
      (payment.paymentMode && payment.paymentMode !== booking.paymentMode) ||
      (payment.sessionId && payment.sessionId !== session.id)) {
    throw new Error('Payment does not match this booking.');
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

module.exports = {TERMINAL, PAYMENT_WINDOW_MS, requireModeKey, requireTestKey,
  isStripePaymentMode, assertPayable, assertSession, sessionPatch};
