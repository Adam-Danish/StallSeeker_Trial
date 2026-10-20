'use strict';

const {randomUUID} = require('node:crypto');
const {TERMINAL, assertPayable, assertSession, sessionPatch} =
  require('./stripe-payment-core.cjs');

// Dependencies are injected so the real transaction/retry workflow can be tested.
function paymentService({db, stripe, Timestamp, returnUrl, now = Date.now}) {
  const bookingRef = (id) => db.collection('bookings').doc(id);
  const paymentRef = (id) => db.collection('bookingPayments').doc(id);

  async function read(id) {
    const [booking, payment] = await Promise.all([
      bookingRef(id).get(), paymentRef(id).get(),
    ]);
    return {booking: booking.data(), payment: payment.data()};
  }

  async function sessionFor(id, booking, payment) {
    if (payment.sessionId) {
      return stripe.checkout.sessions.retrieve(payment.sessionId,
        {expand: ['payment_intent.latest_charge']});
    }
    // Recover a timed-out create with the exact persisted parameters/key. Never
    // generate a second attempt for the same booking, including across devices.
    if (now() - payment.createdAt.toMillis() > 23 * 60 * 60 * 1000) {
      throw new Error('Checkout creation needs manual reconciliation.');
    }
    // The first sandbox deployment used a parameter Stripe now rejects before
    // creating a session. Repair those uncreated attempts using the same key.
    if (payment.parameters.payment_method_types) {
      payment.parameters = {...payment.parameters,
        allowed_payment_method_types: payment.parameters.payment_method_types};
      delete payment.parameters.payment_method_types;
      await paymentRef(id).update({parameters: payment.parameters});
    }
    const session = await stripe.checkout.sessions.create(payment.parameters,
      {idempotencyKey: `booking-${id}-${payment.attemptId}`});
    assertSession(id, booking, payment, session);
    await paymentRef(id).update({sessionId: session.id});
    return session;
  }

  async function record(id, session, options = {}) {
    await db.runTransaction(async (tx) => {
      const [bookingDoc, paymentDoc] = await Promise.all([
        tx.get(bookingRef(id)), tx.get(paymentRef(id)),
      ]);
      const booking = bookingDoc.data();
      const payment = paymentDoc.data();
      assertSession(id, booking, payment, session);
      const patch = sessionPatch(booking, session, Timestamp.fromMillis(now()), options);
      const intent = typeof session.payment_intent === 'string'
        ? session.payment_intent : session.payment_intent?.id;
      tx.set(paymentRef(id), {sessionId: session.id,
        ...(intent ? {paymentIntentId: intent} : {})}, {merge: true});
      // Avoid background-trigger loops from writes that change nothing.
      const changes = Object.fromEntries(Object.entries(patch).filter(([key, value]) =>
        booking[key]?.toMillis && value?.toMillis
          ? booking[key].toMillis() !== value.toMillis() : booking[key] !== value));
      if (Object.keys(changes).length) {
        tx.update(bookingRef(id), {...changes,
          ...(booking.checkoutFirst && changes.paymentStatus === 'paid' &&
            !TERMINAL.has(booking.status) ? {vendorUnseenRequest: true} : {}),
          updatedAt: Timestamp.fromMillis(now())});
      }
    });
  }

  async function refund(id, session) {
    const {booking, payment} = await read(id);
    assertSession(id, booking, payment, session);
    if (booking.paymentStatus === 'refunded') return;
    const intent = typeof session.payment_intent === 'string'
      ? session.payment_intent : session.payment_intent?.id;
    if (!intent) throw new Error('Paid checkout is missing its payment reference.');
    // Read Stripe's current charge first; this also recognises dashboard refunds.
    const pi = await stripe.paymentIntents.retrieve(intent, {expand: ['latest_charge']});
    if (pi.livemode !== false || pi.amount !== booking.totalCents ||
        pi.currency !== 'myr' || pi.metadata?.bookingId !== id) {
      throw new Error('Refund does not match this sandbox booking.');
    }
    let result;
    if (pi.latest_charge?.refunded === true) {
      result = {status: 'succeeded', id: payment.refundId || null};
    } else if (payment.refundId) {
      result = await stripe.refunds.retrieve(payment.refundId);
    } else {
      result = await stripe.refunds.create({payment_intent: intent,
        metadata: {bookingId: id}}, {idempotencyKey: `refund-${id}-${session.id}`});
      await paymentRef(id).update({refundId: result.id});
    }
    const status = result.status === 'succeeded' ? 'refunded' :
      ['failed', 'canceled'].includes(result.status) ? 'refund_failed' : 'refund_pending';
    await db.runTransaction(async (tx) => {
      const current = (await tx.get(bookingRef(id))).data();
      if (!current || current.paymentStatus === 'refunded') return;
      if (current.paymentStatus !== status) {
        tx.update(bookingRef(id), {paymentStatus: status,
          ...(status === 'refunded' ? {paymentRefundedCents: current.totalCents} : {}),
          updatedAt: Timestamp.fromMillis(now())});
      }
    });
  }

  async function sync(id, {failed = false, close = false} = {}) {
    let {booking, payment} = await read(id);
    if (!booking || booking.paymentMode !== 'test') return;
    if (booking.paymentStatus === 'refunded') return;
    const due = booking.status === 'confirmed' &&
      booking.paymentExpiresAt?.toMillis() <= now() && booking.paymentStatus !== 'paid';
    if (!payment) {
      if (TERMINAL.has(booking.status) && !['cancelled', 'expired'].includes(booking.paymentStatus)) {
        await bookingRef(id).update({paymentStatus: booking.status === 'expired' ? 'expired' : 'cancelled'});
      }
      if (due) {
        await db.runTransaction(async (tx) => {
          const current = (await tx.get(bookingRef(id))).data();
          if (current?.status === 'confirmed' && current.paymentStatus !== 'paid' &&
              current.paymentExpiresAt?.toMillis() <= now()) {
            tx.update(bookingRef(id), {status: 'expired', paymentStatus: 'expired',
              updatedAt: Timestamp.fromMillis(now())});
          }
        });
      }
      return;
    }
    let session = await sessionFor(id, booking, payment);
    assertSession(id, booking, payment, session);
    // Refresh state after a potentially slow Stripe call (a vendor may cancel).
    ({booking} = await read(id));
    const shouldClose = close || due || TERMINAL.has(booking.status);
    if (shouldClose && session.status === 'open') {
      try {
        session = await stripe.checkout.sessions.expire(session.id);
      } catch (error) {
        // Payment may have completed while expiry was in flight. Check Stripe
        // again, and only suppress the error when the session really closed.
        session = await stripe.checkout.sessions.retrieve(session.id,
          {expand: ['payment_intent.latest_charge']});
        if (session.status === 'open') throw error;
      }
    }
    await record(id, session, {failed});
    ({booking} = await read(id));
    if (session.payment_status === 'paid' && TERMINAL.has(booking.status)) {
      await refund(id, session);
    } else if (session.payment_status === 'paid') {
      // Reflect refunds initiated from the Stripe sandbox dashboard as well.
      const intent = typeof session.payment_intent === 'object' ? session.payment_intent :
        await stripe.paymentIntents.retrieve(session.payment_intent, {expand: ['latest_charge']});
      const charge = intent?.latest_charge;
      if (intent?.livemode === false && charge?.amount_refunded > 0) {
        await db.runTransaction(async (tx) => {
          const current = (await tx.get(bookingRef(id))).data();
          if (!current) return;
          tx.update(bookingRef(id), {
            paymentRefundedCents: Math.max(current.paymentRefundedCents || 0, charge.amount_refunded),
            ...(charge.refunded ? {paymentStatus: 'refunded',
              ...(['confirmed', 'preparing', 'ready'].includes(current.status) ? {status: 'cancelled'} : {})} : {}),
            updatedAt: Timestamp.fromMillis(now()),
          });
        });
      }
    }
  }

  async function checkout(id, uid) {
    await sync(id);
    let payment;
    let booking;
    await db.runTransaction(async (tx) => {
      const [bookingDoc, paymentDoc] = await Promise.all([
        tx.get(bookingRef(id)), tx.get(paymentRef(id)),
      ]);
      booking = bookingDoc.data();
      assertPayable(booking, uid, now());
      payment = paymentDoc.data();
      if (payment) return;
      const attemptId = randomUUID();
      const metadata = {bookingId: id, customerId: booking.customerId,
        vendorId: booking.vendorId, attemptId};
      payment = {attemptId, createdAt: Timestamp.fromMillis(now()), parameters: {
        mode: 'payment', allowed_payment_method_types: ['card'],
        client_reference_id: id, metadata,
        payment_intent_data: {metadata},
        line_items: [{quantity: 1, price_data: {currency: 'myr',
          unit_amount: booking.totalCents,
          product_data: {name: `${booking.stallName} - self-collect booking`,
            description: 'StallSeeker prototype. Test payment only.'}}}],
        success_url: `${returnUrl}?result=success`,
        cancel_url: `${returnUrl}?result=cancelled`,
      }};
      tx.create(paymentRef(id), payment);
      tx.update(bookingRef(id), {paymentStatus: 'pending'});
    });
    const session = await sessionFor(id, booking, payment);
    // The booking may have been cancelled while the session was being created.
    await sync(id);
    const current = (await read(id)).booking;
    assertPayable(current, uid, now());
    if (session.status !== 'open' || typeof session.url !== 'string' ||
        !session.url.startsWith('https://checkout.stripe.com/')) {
      throw new Error('Checkout is no longer available. Refresh the booking.');
    }
    return {checkoutUrl: session.url};
  }

  return {checkout, sync};
}

module.exports = {paymentService};
