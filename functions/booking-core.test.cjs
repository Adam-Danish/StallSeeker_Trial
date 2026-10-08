'use strict';

const {test} = require('node:test');
const assert = require('node:assert/strict');
const {vendorAvailable, bookingItems, nextStatus} = require('./booking-core.cjs');

const now = Date.parse('2026-10-08T12:00:00Z');
const vendor = {selfCollectEnabled: true, isOpen: true,
  latitude: 3.1, longitude: 101.7};
const stamp = (value) => ({toMillis: () => value});

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
