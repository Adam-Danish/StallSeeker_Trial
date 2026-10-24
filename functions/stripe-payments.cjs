'use strict';

const Stripe = require('stripe');
const {onCall, onRequest, HttpsError} = require('firebase-functions/v2/https');
const {onDocumentUpdated} = require('firebase-functions/v2/firestore');
const {onSchedule} = require('firebase-functions/v2/scheduler');
const {defineSecret} = require('firebase-functions/params');
const {getFirestore, Timestamp} = require('firebase-admin/firestore');
const {requireTestKey, TERMINAL} = require('./stripe-payment-core.cjs');
const {paymentService} = require('./stripe-payment-service.cjs');

const apiKey = defineSecret('STRIPE_SECRET_KEY');
const signingKey = defineSecret('STRIPE_WEBHOOK_SECRET');
const db = getFirestore();
const options = {secrets: [apiKey], timeoutSeconds: 120, maxInstances: 5};

function client() {
  return new Stripe(requireTestKey(apiKey.value()), {maxNetworkRetries: 2, timeout: 20000});
}

function service() {
  const project = process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT;
  if (!project) throw new Error('Firebase project configuration is missing.');
  return paymentService({db, stripe: client(), Timestamp,
    returnUrl: `https://us-central1-${project}.cloudfunctions.net/stripePaymentReturn`});
}

async function participant(request, {customerOnly = false} = {}) {
  const uid = request.auth?.uid;
  const id = request.data?.bookingId;
  if (!uid || request.auth.token.email_verified !== true ||
      request.auth.token.firebase?.sign_in_provider === 'anonymous') {
    throw new HttpsError('unauthenticated', 'Sign in with a verified account.');
  }
  if (typeof id !== 'string' || !/^[A-Za-z0-9_-]{1,150}$/.test(id)) {
    throw new HttpsError('invalid-argument', 'Invalid booking.');
  }
  const [doc, profile] = await Promise.all([
    db.collection('bookings').doc(id).get(), db.collection('users').doc(uid).get(),
  ]);
  const booking = doc.data();
  const role = booking?.customerId === uid ? 'customer' :
    booking?.vendorId === uid ? 'vendor' : null;
  if (!role || profile.data()?.role !== role || (customerOnly && role !== 'customer')) {
    throw new HttpsError('permission-denied', 'This is not your booking.');
  }
  return {id, uid};
}

exports.createStripeCheckout = onCall(options, async (request) => {
  const {id, uid} = await participant(request, {customerOnly: true});
  try {
    return await service().checkout(id, uid);
  } catch (error) {
    console.error('Test checkout unavailable', {bookingId: id, type: error.type || error.name});
    throw new HttpsError('failed-precondition',
      'Payment could not open. Refresh the booking and try again while the payment window is open.');
  }
});

exports.refreshStripePayment = onCall(options, async (request) => {
  const {id} = await participant(request);
  try {
    await service().sync(id);
    return {refreshed: true};
  } catch (error) {
    console.error('Test payment refresh unavailable', {bookingId: id, type: error.type || error.name});
    throw new HttpsError('unavailable', 'Payment status could not refresh. Please try again.');
  }
});

exports.stripeWebhook = onRequest({...options, secrets: [apiKey, signingKey],
  invoker: 'public'}, async (req, res) => {
  if (req.method !== 'POST') return res.status(405).send('POST required');
  let event;
  try {
    event = client().webhooks.constructEvent(req.rawBody,
      req.get('stripe-signature'), signingKey.value());
  } catch (_) {
    return res.status(400).send('Invalid signature');
  }
  if (event.livemode !== false) return res.status(400).send('Sandbox events only');
  const supported = new Set(['checkout.session.completed',
    'checkout.session.async_payment_succeeded', 'checkout.session.async_payment_failed',
    'checkout.session.expired', 'payment_intent.payment_failed', 'charge.refunded', 'refund.updated']);
  const id = event.data.object.metadata?.bookingId;
  if (!supported.has(event.type) || !id || !/^[A-Za-z0-9_-]{1,150}$/.test(id)) {
    return res.json({received: true});
  }
  try {
    // Re-read Stripe's current state instead of trusting event delivery order.
    await service().sync(id, {failed: event.type.endsWith('payment_failed')});
    return res.json({received: true});
  } catch (error) {
    console.error('Stripe webhook retry needed', {eventId: event.id,
      bookingId: id, type: error.type || error.name});
    return res.status(500).send('Retry required');
  }
});

exports.closeCancelledStripePayment = onDocumentUpdated({...options,
  document: 'bookings/{bookingId}', retry: true}, async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (after.paymentMode !== 'test' || !TERMINAL.has(after.status) ||
      ['refunded', 'refund_failed'].includes(after.paymentStatus) ||
      (before.status === after.status && before.paymentStatus === after.paymentStatus)) return;
  await service().sync(event.params.bookingId, {close: true});
});

exports.expireStripePayments = onSchedule({...options, schedule: 'every 1 minutes'}, async () => {
  const due = await db.collection('bookings').where('status', '==', 'confirmed')
    .where('paymentStatus', 'in', ['awaiting_payment', 'pending', 'failed'])
    .where('paymentExpiresAt', '<=', Timestamp.now()).limit(100).get();
  for (const doc of due.docs) {
    if (doc.data().paymentMode !== 'test' || doc.data().paymentStatus === 'paid') continue;
    try {
      await service().sync(doc.id);
    } catch (error) {
      console.error('Payment expiry will retry', {bookingId: doc.id, type: error.type || error.name});
    }
  }
});

exports.stripePaymentReturn = onRequest({invoker: 'public', maxInstances: 5}, (req, res) => {
  res.set('Cache-Control', 'no-store');
  res.set('Content-Security-Policy', "default-src 'none'; style-src 'unsafe-inline'; base-uri 'none'; frame-ancestors 'none'");
  res.type('html').send(`<!doctype html><html lang="en"><head>
<meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1">
<title>Return to StallSeeker</title><style>
body{font-family:system-ui,sans-serif;background:#fff8f2;color:#242424;margin:0;padding:32px 20px}
main{max-width:440px;margin:10vh auto;background:white;border-radius:24px;padding:32px;box-shadow:0 8px 40px #0000000d}
small{color:#80532c}h1{font-size:28px}p{line-height:1.6}
</style></head><body><main><small>STALLSEEKER</small>
<h1>Return to your booking</h1><p>You can close this page and return to StallSeeker.
Your booking will show the verified payment status. Tap <strong>Check payment</strong>
if it has not updated yet.</p>
</main></body></html>`);
});
