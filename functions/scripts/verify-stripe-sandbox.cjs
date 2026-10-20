'use strict';

// No credentials, Checkout URLs, or request headers are printed.
const assert = require('node:assert/strict');
const {randomUUID} = require('node:crypto');
const {sandboxClients, project} = require('./configure-stripe-sandbox.cjs');

async function main() {
  const {stripe, secrets, privateRequest} = await sandboxClients();
  const firestore = new secrets.constructor({urlPrefix: 'https://firestore.googleapis.com', apiVersion: 'v1'});
  const indexes = await firestore.get(`projects/${project}/databases/(default)/collectionGroups/bookings/indexes`);
  const expiryIndex = indexes.body.indexes?.find((index) =>
    ['status', 'paymentStatus', 'paymentExpiresAt'].every((field) =>
      index.fields.some((item) => item.fieldPath === field)));
  assert.equal(expiryIndex?.state, 'READY', 'Payment expiry index must be ready');
  const base = `https://us-central1-${project}.cloudfunctions.net`;
  const endpoints = await stripe.webhookEndpoints.list({limit: 100});
  const endpoint = endpoints.data.find((item) => item.url === `${base}/stripeWebhook`);
  assert(endpoint && endpoint.livemode === false && endpoint.status === 'enabled');
  const result = await secrets.get(
    `projects/${project}/secrets/STRIPE_WEBHOOK_SECRET/versions/latest:access`, privateRequest);
  const secret = Buffer.from(result.body.payload.data, 'base64').toString();
  const payload = JSON.stringify({id: `evt_stallseeker_smoke_${randomUUID()}`,
    object: 'event', livemode: false, type: 'stallseeker.smoke', data: {object: {}}});
  const request = async (route, options = {}) => fetch(`${base}/${route}`, {
    ...options, signal: AbortSignal.timeout(120000)});
  const signature = stripe.webhooks.generateTestHeaderString({payload, secret});
  const signed = await request('stripeWebhook', {method: 'POST',
    headers: {'Content-Type': 'application/json', 'stripe-signature': signature}, body: payload});
  assert.equal(signed.status, 200, 'Signed sandbox callback must be accepted');
  const invalid = await request('stripeWebhook', {method: 'POST',
    headers: {'Content-Type': 'application/json'}, body: payload});
  assert.equal(invalid.status, 400, 'Unsigned callback must be rejected');
  const unauthenticated = await request('createStripeCheckout', {method: 'POST',
    headers: {'Content-Type': 'application/json'}, body: JSON.stringify({data: {bookingId: 'smoke'}})});
  assert.equal(unauthenticated.status, 401, 'Checkout must require authentication');
  const returnPage = await request('stripePaymentReturn');
  assert.equal(returnPage.status, 200);
  assert((await returnPage.text()).includes('Return to your booking'));

  let session;
  try {
    session = await stripe.checkout.sessions.create({mode: 'payment',
      allowed_payment_method_types: ['card'], metadata: {purpose: 'StallSeeker sandbox deployment check'},
      line_items: [{quantity: 1, price_data: {currency: 'myr', unit_amount: 200,
        product_data: {name: 'StallSeeker sandbox deployment check'}}}],
      success_url: `${base}/stripePaymentReturn`, cancel_url: `${base}/stripePaymentReturn`,
    });
    assert.equal(session.livemode, false);
    assert.equal(session.amount_total, 200);
    assert(session.url.startsWith('https://checkout.stripe.com/'));
  } finally {
    if (session?.status === 'open') await stripe.checkout.sessions.expire(session.id);
  }
  console.log(JSON.stringify({sandboxWebhookEnabled: true, signedWebhook: signed.status,
    unsignedWebhook: invalid.status, unauthenticatedCheckout: unauthenticated.status,
    returnPage: returnPage.status, expiryIndex: expiryIndex.state,
    testCheckoutCreatedAndExpired: true, charged: false}));
}

main().catch((error) => {
  console.error(`Sandbox verification failed (${error.type || error.name}, status ${error.status || error.statusCode || 'unknown'}).`);
  if (error.type === 'StripeInvalidRequestError') {
    const safe = String(error.message).replace(/(?:sk|rk|pk)_(?:test|live)_\S+|whsec_\S+/g, '[redacted]');
    console.error(safe);
  }
  if (error.code === 'ERR_ASSERTION') console.error(error.message);
  process.exitCode = 1;
});
