'use strict';

// Run locally after STRIPE_SECRET_KEY is stored. Secrets stay in process memory
// and sent only to Google Secret Manager / Stripe; never print or log payloads.
const path = require('node:path');
const Stripe = require('stripe');
const {requireTestKey} = require('../stripe-payment-core.cjs');
const project = 'stallseeker-c2ffe';

async function sandboxClients() {
  // Reuse the installed Firebase CLI's normal signed-in account. Suppress its
  // logger entirely, including debug output, before making credential requests.
  const cliRoot = process.env.FIREBASE_TOOLS_ROOT ||
    path.join(process.env.APPDATA, 'npm', 'node_modules', 'firebase-tools');
  const cli = (name) => require(path.join(cliRoot, 'lib', name));
  cli('logger').logger.silent = true;
  const account = cli('auth').getProjectDefaultAccount(process.cwd());
  await cli('requireAuth').requireAuth({project, ...account});
  const secrets = new (cli('apiv2').Client)({
    urlPrefix: 'https://secretmanager.googleapis.com', apiVersion: 'v1'});
  const privateRequest = {skipLog: {body: true, resBody: true}};
  const result = await secrets.get(
    `projects/${project}/secrets/STRIPE_SECRET_KEY/versions/latest:access`, privateRequest);
  const key = requireTestKey(Buffer.from(result.body.payload.data, 'base64').toString());
  return {stripe: new Stripe(key, {maxNetworkRetries: 2, timeout: 20000}), secrets, privateRequest};
}

async function main() {
  const {stripe, secrets, privateRequest} = await sandboxClients();
  const url = `https://us-central1-${project}.cloudfunctions.net/stripeWebhook`;
  const existing = await stripe.webhookEndpoints.list({limit: 100});
  if (existing.data.some((endpoint) => endpoint.url === url)) {
    console.log('Sandbox webhook already exists. Keep its existing signing secret.');
    return;
  }
  const endpoint = await stripe.webhookEndpoints.create({url,
    description: 'StallSeeker prototype sandbox payment notifications',
    enabled_events: ['checkout.session.completed', 'checkout.session.async_payment_succeeded',
      'checkout.session.async_payment_failed', 'checkout.session.expired',
      'payment_intent.payment_failed', 'charge.refunded', 'refund.updated'],
  });
  if (endpoint.livemode !== false || !endpoint.secret?.startsWith('whsec_')) {
    throw new Error('Expected a sandbox webhook with a signing secret.');
  }
  try {
    try {
      await secrets.post(`projects/${project}/secrets`, {
        replication: {automatic: {}}, labels: {'firebase-managed': 'functions'},
      }, {...privateRequest, queryParams: {secretId: 'STRIPE_WEBHOOK_SECRET'}});
    } catch (error) {
      if (error.status !== 409) throw error;
    }
    await secrets.post(`projects/${project}/secrets/STRIPE_WEBHOOK_SECRET:addVersion`, {
      payload: {data: Buffer.from(endpoint.secret).toString('base64')},
    }, privateRequest);
  } catch (error) {
    // Roll back only the endpoint this invocation just created; a retry can
    // safely obtain a new signing secret without leaving an unusable endpoint.
    await stripe.webhookEndpoints.del(endpoint.id);
    throw error;
  }
  console.log(JSON.stringify({webhookId: endpoint.id, url, mode: 'test', signingSecretStored: true}));
}

if (require.main === module) main().catch((error) => {
  // Stripe error objects can include request headers; never log the object.
  console.error(`Sandbox setup failed (${error.type || error.name}, status ${error.status || error.statusCode || 'unknown'}). No credentials printed.`);
  process.exitCode = 1;
});

module.exports = {sandboxClients, project};
