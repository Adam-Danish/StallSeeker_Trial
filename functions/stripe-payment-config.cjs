'use strict';

const Stripe = require('stripe');
const {defineSecret, defineString} = require('firebase-functions/params');
const {requireModeKey} = require('./stripe-payment-core.cjs');

const configuredMode = defineString('STRIPE_PAYMENT_MODE', {default: 'live'});
const apiKey = defineSecret('STRIPE_SECRET_KEY');
const signingKey = defineSecret('STRIPE_WEBHOOK_SECRET');

const apiSecrets = [apiKey];
const webhookSecrets = [apiKey, signingKey];

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

function stripeForMode(mode = currentPaymentMode()) {
  const activeMode = currentPaymentMode();
  if (mode !== activeMode) {
    throw new Error(`Configured Stripe key is for ${activeMode} mode, not ${mode}.`);
  }
  return new Stripe(requireModeKey(apiKey.value(), activeMode), {maxNetworkRetries: 2, timeout: 20000});
}

function signingKeyForMode(mode = currentPaymentMode()) {
  const activeMode = currentPaymentMode();
  if (mode !== activeMode) {
    throw new Error(`Configured Stripe webhook secret is for ${activeMode} mode, not ${mode}.`);
  }
  return signingKey.value();
}

module.exports = {apiSecrets, webhookSecrets, currentPaymentMode, stripeForMode,
  signingKeyForMode};
