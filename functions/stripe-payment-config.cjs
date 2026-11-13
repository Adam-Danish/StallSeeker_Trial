'use strict';

const Stripe = require('stripe');
const {defineSecret, defineString} = require('firebase-functions/params');
const {requireModeKey} = require('./stripe-payment-core.cjs');

const configuredMode = defineString('STRIPE_PAYMENT_MODE', {default: 'test'});
const testApiKey = defineSecret('STRIPE_SECRET_KEY');
const testSigningKey = defineSecret('STRIPE_WEBHOOK_SECRET');
const liveApiKey = defineSecret('STRIPE_LIVE_SECRET_KEY');
const liveSigningKey = defineSecret('STRIPE_LIVE_WEBHOOK_SECRET');

const apiSecrets = [testApiKey, liveApiKey];
const webhookSecrets = [...apiSecrets, testSigningKey, liveSigningKey];

function currentPaymentMode() {
  const mode = configuredMode.value();
  if (mode !== 'test' && mode !== 'live') {
    throw new Error('STRIPE_PAYMENT_MODE must be either test or live.');
  }
  const project = process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT;
  if (project === 'stallseeker-c2ffe' && mode !== 'live') {
    throw new Error('StallSeeker production bookings must use Stripe live mode.');
  }
  return mode;
}

function stripeForMode(mode) {
  const key = mode === 'live' ? liveApiKey.value() :
    mode === 'test' ? testApiKey.value() : null;
  return new Stripe(requireModeKey(key, mode), {maxNetworkRetries: 2, timeout: 20000});
}

function signingKeyForMode(mode) {
  if (mode === 'live') return liveSigningKey.value();
  if (mode === 'test') return testSigningKey.value();
  throw new Error('Unknown Stripe payment mode.');
}

module.exports = {apiSecrets, webhookSecrets, currentPaymentMode, stripeForMode,
  signingKeyForMode};
