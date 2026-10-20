'use strict';

const {test} = require('node:test');
const assert = require('node:assert/strict');
const {Timestamp} = require('firebase-admin/firestore');
const {requireTestKey, assertPayable, assertSession, sessionPatch} = require('./stripe-payment-core.cjs');
const {paymentService} = require('./stripe-payment-service.cjs');

function fixture({checkoutFirst = false} = {}) {
  let time = Date.parse('2026-10-20T09:00:00Z');
  const stamp = () => Timestamp.fromMillis(time);
  const booking = {customerId: 'buyer', vendorId: 'seller', stallName: 'Test stall',
    status: 'confirmed', totalCents: 1250, paymentMode: 'test',
    paymentStatus: 'awaiting_payment', paymentExpiresAt: Timestamp.fromMillis(time + 600000),
    checkoutFirst, vendorUnseenRequest: false};
  const data = new Map([['bookings/order', booking]]);
  const copy = (value) => value instanceof Timestamp ? value : Array.isArray(value) ?
    value.map(copy) : value && typeof value === 'object' ?
      Object.fromEntries(Object.entries(value).map(([k, v]) => [k, copy(v)])) : value;
  const ref = (path) => ({path, get: async () => ({data: () => copy(data.get(path))}),
    update: async (patch) => { data.set(path, {...data.get(path), ...copy(patch)}); }});
  let queue = Promise.resolve();
  const db = {collection: (name) => ({doc: (id) => ref(`${name}/${id}`)}),
    runTransaction: (fn) => {
      const result = queue.then(() => fn({get: (doc) => doc.get(),
        update: (doc, patch) => doc.update(patch),
        create: (doc, value) => { assert(!data.has(doc.path)); data.set(doc.path, copy(value)); },
        set: (doc, value) => {data.set(doc.path, {...data.get(doc.path), ...copy(value)});},
      }));
      queue = result.catch(() => {});
      return result;
    }};
  const sessions = new Map();
  const intents = new Map();
  const refunds = new Map();
  let creates = 0;
  let refundCalls = 0;
  let onCreate;
  let onExpire;
  const stripe = {
    checkout: {sessions: {
      create: async (params, options) => {
        if (sessions.has(options.idempotencyKey)) return copy(sessions.get(options.idempotencyKey));
        creates++;
        const session = {id: 'cs_test_123', livemode: false, mode: 'payment',
          currency: 'myr', amount_total: params.line_items[0].price_data.unit_amount,
          client_reference_id: params.client_reference_id, metadata: params.metadata,
          status: 'open', payment_status: 'unpaid', url: 'https://checkout.stripe.com/test',
          payment_intent: null};
        sessions.set(options.idempotencyKey, session);
        sessions.set(session.id, session);
        if (onCreate) await onCreate();
        return copy(session);
      },
      retrieve: async (id) => copy(sessions.get(id)),
      expire: async (id) => {
        if (onExpire) await onExpire();
        const session = sessions.get(id);
        if (session.status !== 'open') throw new Error('Not open');
        session.status = 'expired';
        return copy(session);
      },
    }},
    paymentIntents: {retrieve: async (id) => copy(intents.get(id))},
    refunds: {
      create: async ({payment_intent}, {idempotencyKey}) => {
        if (refunds.has(idempotencyKey)) return copy(refunds.get(idempotencyKey));
        refundCalls++;
        const refund = {id: 're_test_123', status: 'succeeded'};
        refunds.set(idempotencyKey, refund);
        refunds.set(refund.id, refund);
        intents.get(payment_intent).latest_charge.refunded = true;
        return copy(refund);
      },
      retrieve: async (id) => copy(refunds.get(id)),
    },
  };
  const service = paymentService({db, stripe, Timestamp, now: () => time,
    returnUrl: 'https://example.com/return'});
  const pay = () => {
    const session = sessions.get('cs_test_123');
    Object.assign(session, {status: 'complete', payment_status: 'paid', payment_intent: 'pi_test_123'});
    intents.set('pi_test_123', {id: 'pi_test_123', livemode: false, amount: 1250,
      currency: 'myr', metadata: {bookingId: 'order'},
      latest_charge: {refunded: false, amount_refunded: 0}});
  };
  return {service, stripe, data, sessions, intents, refunds, pay, stamp,
    booking: () => data.get('bookings/order'),
    moveTime: (ms) => {time += ms;},
    onCreate: (fn) => {onCreate = fn;}, onExpire: (fn) => {onExpire = fn;},
    creates: () => creates, refundCalls: () => refundCalls};
}

test('only sandbox keys are accepted', () => {
  assert.equal(requireTestKey(' sk_test_example '), 'sk_test_example');
  assert.equal(requireTestKey('rk_test_example'), 'rk_test_example');
  for (const key of [undefined, '', 'sk_live_example', 'pk_test_example']) {
    assert.throws(() => requireTestKey(key));
  }
});

test('checkout rejects wrong owner, ineligible bookings, small totals and expired deadlines', () => {
  const f = fixture();
  const booking = f.booking();
  const time = f.stamp().toMillis();
  assert.doesNotThrow(() => assertPayable(booking, 'buyer', time));
  assert.throws(() => assertPayable(booking, 'other', time));
  for (const patch of [{status: 'requested'}, {paymentStatus: 'paid'},
    {paymentMode: 'live'}, {totalCents: 199}, {totalCents: 1250.5}, {paymentExpiresAt: null}]) {
    assert.throws(() => assertPayable({...booking, ...patch}, 'buyer', time));
  }
  assert.throws(() => assertPayable(booking, 'buyer', time + 600001));
});

test('payment validation checks mode, amount, currency, buyer, vendor, attempt and session', async () => {
  const f = fixture();
  await f.service.checkout('order', 'buyer');
  const payment = f.data.get('bookingPayments/order');
  const session = f.sessions.get('cs_test_123');
  for (const patch of [{livemode: true}, {currency: 'usd'}, {amount_total: 1},
    {id: 'cs_other'}, {client_reference_id: 'other'},
    {metadata: {...session.metadata, vendorId: 'other'}},
    {metadata: {...session.metadata, customerId: 'other'}},
    {metadata: {...session.metadata, attemptId: 'other'}}]) {
    assert.throws(() => assertSession('order', f.booking(), payment, {...session, ...patch}));
  }
});

test('simultaneous pay clicks and retries reuse one checkout', async () => {
  const f = fixture();
  const results = await Promise.all([
    f.service.checkout('order', 'buyer'), f.service.checkout('order', 'buyer'),
  ]);
  assert.equal(results[0].checkoutUrl, results[1].checkoutUrl);
  assert.equal(f.creates(), 1);
  const params = f.data.get('bookingPayments/order').parameters;
  assert.deepEqual(params.allowed_payment_method_types, ['card']);
  assert.equal(params.payment_method_types, undefined);
  await f.service.sync('order', {failed: true});
  assert.equal(f.booking().paymentStatus, 'failed');
  await f.service.checkout('order', 'buyer');
  assert.equal(f.creates(), 1);
});

test('uncreated attempts rejected by the retired Stripe parameter recover without a second attempt', async () => {
  const f = fixture();
  const attemptId = 'original_attempt';
  f.data.set('bookingPayments/order', {attemptId, createdAt: f.stamp(), parameters: {
    mode: 'payment', payment_method_types: ['card'], client_reference_id: 'order',
    metadata: {bookingId: 'order', customerId: 'buyer', vendorId: 'seller', attemptId},
    line_items: [{quantity: 1, price_data: {currency: 'myr', unit_amount: 1250}}],
  }});
  await f.service.checkout('order', 'buyer');
  const saved = f.data.get('bookingPayments/order');
  assert.equal(saved.attemptId, attemptId);
  assert.equal(saved.parameters.payment_method_types, undefined);
  assert.deepEqual(saved.parameters.allowed_payment_method_types, ['card']);
  assert.equal(f.creates(), 1);
  assert(f.sessions.has(`booking-order-${attemptId}`));
});

test('verified payment is applied once and stale unpaid events do not undo it', async () => {
  const f = fixture();
  await f.service.checkout('order', 'buyer');
  f.pay();
  await f.service.sync('order');
  const paidAt = f.booking().paymentPaidAt;
  f.moveTime(30000);
  await f.service.sync('order', {failed: true});
  assert.equal(f.booking().paymentStatus, 'paid');
  assert.equal(f.booking().paymentPaidAt.toMillis(), paidAt.toMillis());
  assert.deepEqual(sessionPatch(f.booking(), {payment_status: 'unpaid', status: 'expired'}, f.stamp()), {});
  await assert.rejects(f.service.checkout('order', 'buyer'));
});

test('checkout-first booking becomes visible to the vendor only after verified payment', async () => {
  const f = fixture({checkoutFirst: true});
  assert.equal(f.booking().vendorUnseenRequest, false);
  await f.service.checkout('order', 'buyer');
  assert.equal(f.booking().vendorUnseenRequest, false);
  f.pay();
  await f.service.sync('order');
  assert.equal(f.booking().paymentStatus, 'paid');
  assert.equal(f.booking().vendorUnseenRequest, true);
  await f.service.sync('order');
  assert.equal(f.booking().vendorUnseenRequest, true);
});

test('paid checkout-first cancellation requests one full refund', async () => {
  const f = fixture({checkoutFirst: true});
  await f.service.checkout('order', 'buyer');
  f.pay();
  await f.service.sync('order');
  Object.assign(f.booking(), {status: 'cancelled', paymentStatus: 'refund_pending',
    vendorUnseenRequest: false});
  await Promise.all([f.service.sync('order'), f.service.sync('order')]);
  assert.equal(f.booking().paymentStatus, 'refunded');
  assert.equal(f.booking().paymentRefundedCents, f.booking().totalCents);
  assert.equal(f.refundCalls(), 1);
});

test('cancelling while checkout is created closes the session and never returns a pay URL', async () => {
  const f = fixture();
  f.onCreate(() => { f.booking().status = 'cancelled'; });
  await assert.rejects(f.service.checkout('order', 'buyer'));
  assert.equal(f.sessions.get('cs_test_123').status, 'expired');
  assert.equal(f.booking().status, 'cancelled');
});

test('deadline expires unpaid sessions and bookings without checkouts', async () => {
  const f = fixture();
  await f.service.checkout('order', 'buyer');
  f.moveTime(600001);
  await f.service.sync('order');
  assert.equal(f.booking().status, 'expired');
  assert.equal(f.sessions.get('cs_test_123').status, 'expired');
  const empty = fixture();
  empty.moveTime(600001);
  await empty.service.sync('order');
  assert.equal(empty.booking().status, 'expired');
});

test('a payment winning the expiry race remains paid', async () => {
  const f = fixture();
  await f.service.checkout('order', 'buyer');
  f.moveTime(600001);
  f.onExpire(() => f.pay());
  await f.service.sync('order');
  assert.equal(f.booking().paymentStatus, 'paid');
  assert.equal(f.booking().status, 'confirmed');
});

test('late paid notification on a cancelled booking refunds exactly once', async () => {
  const f = fixture();
  await f.service.checkout('order', 'buyer');
  f.booking().status = 'cancelled';
  f.pay();
  await Promise.all([f.service.sync('order'), f.service.sync('order')]);
  assert.equal(f.booking().paymentStatus, 'refunded');
  assert.equal(f.booking().paymentRefundedCents, 1250);
  assert.equal(f.refundCalls(), 1);
  await f.service.sync('order');
  assert.equal(f.refundCalls(), 1);
});

test('dashboard refunds are reflected without counting refunded money as sales', async () => {
  const f = fixture();
  await f.service.checkout('order', 'buyer');
  f.pay();
  await f.service.sync('order');
  f.intents.get('pi_test_123').latest_charge = {refunded: true, amount_refunded: 1250};
  await f.service.sync('order');
  assert.equal(f.booking().paymentStatus, 'refunded');
  assert.equal(f.booking().paymentRefundedCents, 1250);
  assert.equal(f.booking().status, 'cancelled');
});
