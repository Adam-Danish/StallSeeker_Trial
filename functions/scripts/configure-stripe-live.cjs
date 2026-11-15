'use strict';

// Run locally to store STRIPE_SECRET_KEY (live) and create/sync
// the live Stripe webhook signing secret in STRIPE_WEBHOOK_SECRET.
// Secrets stay in process memory and are never printed or logged.
const path = require('node:path');
const Stripe = require('stripe');
const {requireModeKey} = require('../stripe-payment-core.cjs');
const project = 'stallseeker-c2ffe';

async function setSecretValue(sm, name, value) {
  const exists = await sm.secretExists(project, name);
  if (!exists) {
    await sm.createSecret(project, name, sm.labels('functions'));
  }
  return sm.addVersion(project, name, value);
}

async function liveClients({storeKey = true} = {}) {
  const cliRoot = process.env.FIREBASE_TOOLS_ROOT ||
    path.join(process.env.APPDATA, 'npm', 'node_modules', 'firebase-tools');
  const cli = (name) => require(path.join(cliRoot, 'lib', name));
  cli('logger').logger.silent = true;
  const account = cli('auth').getProjectDefaultAccount(process.cwd());
  await cli('requireAuth').requireAuth({project, ...account});
  const sm = cli('gcp/secretManager');
  const secrets = new (cli('apiv2').Client)({
    urlPrefix: 'https://secretmanager.googleapis.com', apiVersion: 'v1'});
  const privateRequest = {skipLog: {body: true, resBody: true}};

  let key;
  if (process.env.STRIPE_LIVE_SECRET_KEY_INPUT) {
    key = requireModeKey(process.env.STRIPE_LIVE_SECRET_KEY_INPUT, 'live');
    if (storeKey) {
      await setSecretValue(sm, 'STRIPE_SECRET_KEY', key);
    }
  } else {
    const rawKey = await sm.accessSecretVersion(project, 'STRIPE_SECRET_KEY', 'latest');
    key = requireModeKey(rawKey, 'live');
  }

  return {stripe: new Stripe(key, {maxNetworkRetries: 2, timeout: 20000}), sm, secrets, privateRequest};
}

async function main() {
  const {stripe, sm} = await liveClients({storeKey: true});
  const url = `https://us-central1-${project}.cloudfunctions.net/stripeWebhook`;
  const existing = await stripe.webhookEndpoints.list({limit: 100});
  for (const endpoint of existing.data) {
    if (endpoint.url === url) {
      await stripe.webhookEndpoints.del(endpoint.id);
    }
  }
  const endpoint = await stripe.webhookEndpoints.create({
    url,
    description: 'StallSeeker live payment notifications',
    enabled_events: [
      'checkout.session.completed',
      'checkout.session.async_payment_succeeded',
      'checkout.session.async_payment_failed',
      'checkout.session.expired',
      'payment_intent.payment_failed',
      'charge.refunded',
      'refund.updated',
    ],
  });
  if (endpoint.livemode !== true || !endpoint.secret?.startsWith('whsec_')) {
    throw new Error('Expected a live webhook with a signing secret.');
  }
  let version;
  try {
    version = await setSecretValue(sm, 'STRIPE_WEBHOOK_SECRET', endpoint.secret);
  } catch (error) {
    await stripe.webhookEndpoints.del(endpoint.id);
    throw error;
  }
  if (process.env.VERIFY_AFTER_SETUP === '1') {
    const firestore = new (require(path.join(process.env.APPDATA, 'npm', 'node_modules', 'firebase-tools', 'lib', 'apiv2')).Client)({
      urlPrefix: 'https://firestore.googleapis.com', apiVersion: 'v1'});
    const indexes = await firestore.get(`projects/${project}/databases/(default)/collectionGroups/bookings/indexes`);
    const expiryIndex = indexes.body.indexes?.find((index) =>
      ['status', 'paymentStatus', 'paymentExpiresAt'].every((field) =>
        index.fields.some((item) => item.fieldPath === field)));
    console.log(JSON.stringify({
      webhookId: endpoint.id,
      url,
      mode: 'live',
      signingSecretStored: true,
      secretVersion: version?.versionId,
      expiryIndex: expiryIndex?.state,
    }));
    return;
  }
  console.log(JSON.stringify({
    webhookId: endpoint.id,
    url,
    mode: 'live',
    signingSecretStored: true,
    secretVersion: version?.versionId,
  }));
}

if (require.main === module) main().catch((error) => {
  console.error(`Live setup failed (${error.type || error.name}, status ${error.status || error.statusCode || 'unknown'}). No credentials printed.`);
  process.exitCode = 1;
});

module.exports = {liveClients, project};
