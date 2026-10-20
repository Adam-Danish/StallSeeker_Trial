'use strict';

const {test} = require('node:test');
const assert = require('node:assert/strict');
const {vendorAvailable, bookingItems, nextStatus,
  paidCheckoutBecameVisible} = require('./booking-core.cjs');

const now = Date.parse('2026-10-08T12:00:00Z');
const vendor = {selfCollectEnabled: true, isOpen: true,
  latitude: 3.1, longitude: 101.7};
const stamp = (value) => ({toMillis: () => value});

test('self-collect can be cancelled by either party before collection and preparation requires payment', () => {
  const booking = {customerId: 'customer', vendorId: 'vendor', status: 'confirmed',
    paymentMode: 'test', paymentStatus: 'pending'};
  for (const paymentStatus of ['unpaid', 'pending', 'failed', 'refunded', 'refund_pending']) {
    assert.throws(() => nextStatus({...booking, paymentStatus}, 'startPreparing', 'vendor', now));
  }
  assert.equal(nextStatus({...booking, paymentStatus: 'paid'}, 'startPreparing', 'vendor', now), 'preparing');
  assert.equal(nextStatus(booking, 'cancel', 'customer', now), 'cancelled');
  for (const status of ['confirmed', 'preparing', 'ready']) {
    assert.equal(nextStatus({...booking, status, paymentStatus: 'paid'},
      'cancel', 'customer', now), 'cancelled');
    assert.equal(nextStatus({...booking, status, paymentStatus: 'paid'},
      'cancel', 'vendor', now), 'cancelled');
  }
  assert.throws(() => nextStatus({...booking, status: 'collected', paymentStatus: 'paid'},
    'cancel', 'customer', now));
});

test('vendor notification is due only for a new paid checkout-first booking', () => {
  const before = {paymentStatus: 'pending'};
  const paid = {checkoutFirst: true, paymentStatus: 'paid', status: 'confirmed'};
  assert.equal(paidCheckoutBecameVisible(before, paid), true);
  assert.equal(paidCheckoutBecameVisible({paymentStatus: 'paid'}, paid), false);
  assert.equal(paidCheckoutBecameVisible(before, {...paid, status: 'cancelled'}), false);
  assert.equal(paidCheckoutBecameVisible(before, {...paid, checkoutFirst: false}), false);
});

test('vendor must opt in, be open, have a location, and have no active closure', () => {
  assert.equal(vendorAvailable(vendor, now), true);
  assert.equal(vendorAvailable({...vendor, selfCollectEnabled: false}, now), false);
  assert.equal(vendorAvailable({...vendor, isOpen: false}, now), false);
  assert.equal(vendorAvailable({...vendor, latitude: 0, longitude: 0}, now), false);
  assert.equal(vendorAvailable({...vendor, temporaryClosures: [{
    startAt: stamp(now - 1000), endAt: stamp(now + 1000)}]}, now), false);
});

test('server snapshots menu names/prices and rejects stale or forged choices', () => {
  const menu = new Map([['dish-a', {name: 'Nasi Lemak', price: 6.5,
    status: 'available'}], ['dish-b', {name: 'Tea', price: 2,
    status: 'out_of_stock'}]]);
  const result = bookingItems([{itemId: 'dish-a', quantity: 2,
    unitPriceCents: 1}], menu);
  assert.equal(result.totalCents, 1300);
  assert.deepEqual(result.items[0], {itemId: 'dish-a', name: 'Nasi Lemak',
    unitPriceCents: 650, quantity: 2});
  for (const items of [[], [{itemId: 'dish-b', quantity: 1}],
    [{itemId: 'missing', quantity: 1}],
    [{itemId: 'dish-a', quantity: 0}],
    [{itemId: 'dish-a', quantity: 21}],
    [{itemId: 'dish-a', quantity: 1}, {itemId: 'dish-a', quantity: 1}]]) {
    assert.throws(() => bookingItems(items, menu));
  }
});

test('only allowed actors advance the booking and unanswered requests expire', () => {
  const order = {customerId: 'customer', vendorId: 'vendor',
    status: 'requested', expiresAt: stamp(now + 1000)};
  assert.equal(nextStatus(order, 'accept', 'vendor', now), 'confirmed');
  assert.equal(nextStatus(order, 'reject', 'vendor', now), 'rejected');
  assert.equal(nextStatus(order, 'cancel', 'customer', now), 'cancelled');
  assert.equal(nextStatus(order, 'accept', 'vendor', now + 1000), 'expired');
  assert.throws(() => nextStatus(order, 'accept', 'customer', now));
  assert.throws(() => nextStatus({...order, status: 'preparing'},
    'cancel', 'customer', now));
  assert.equal(nextStatus({...order, status: 'confirmed'},
    'startPreparing', 'vendor', now), 'preparing');
  assert.equal(nextStatus({...order, status: 'preparing'},
    'markReady', 'vendor', now), 'ready');
  assert.equal(nextStatus({...order, status: 'ready'},
    'markCollected', 'vendor', now), 'collected');
});
