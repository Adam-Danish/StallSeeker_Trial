'use strict';
const { test } = require('node:test');
const assert = require('node:assert/strict');
const { openingAlert, eligibleCustomerId, createOnce } = require('./history-core.cjs');
const event = {
  eventId: 'event-1', vendorId: 'stall-1', before: { isOpen: false },
  after: { isOpen: true, stallName: 'Nasi Lemak Adam' },
  eventTime: '2026-09-06T08:00:00.000Z',
};
test('only opening a stall creates a history event', () => {
  assert.equal(openingAlert({ ...event, before: { isOpen: true } }), null);
  assert.equal(openingAlert({ ...event, after: { isOpen: false } }), null);
  assert.equal(openingAlert({ ...event, after: { isOpen: true, latitude: 3 }, before: { isOpen: true } }), null);
  assert.equal(openingAlert(event).title, 'Nasi Lemak Adam is open');
});
test('retries have a stable ID; later openings have a new ID', () => {
  assert.equal(openingAlert(event).id, openingAlert(event).id);
  assert.notEqual(openingAlert(event).id, openingAlert({ ...event, eventId: 'event-2' }).id);
});
test('duplicate creation preserves an existing read alert', async () => {
  let saved = null;
  const ref = { create: async (data) => {
    if (saved) throw Object.assign(new Error('Exists'), { code: 6 });
    saved = { ...data };
  } };
  assert.equal(await createOnce(ref, { title: 'Open', isRead: false }), true);
  saved.isRead = true;
  assert.equal(await createOnce(ref, { title: 'Changed', isRead: false }), false);
  assert.deepEqual(saved, { title: 'Open', isRead: true });
});
test('real write failures propagate so the trigger can retry', async () => {
  const failure = Object.assign(new Error('Unavailable'), { code: 14 });
  await assert.rejects(createOnce({ create: async () => { throw failure; } }, {}), failure);
});
test('rejects invalid account paths and followers added after the opening', () => {
  const opened = new Date(event.eventTime);
  assert.equal(eligibleCustomerId({ customerId: 'bad/path' }, opened), null);
  assert.equal(eligibleCustomerId({ customerId: '' }, opened), null);
  assert.equal(eligibleCustomerId({ customerId: 'customer-1', followedAt: { toDate: () => new Date('2026-09-06T09:00:00Z') } }, opened), null);
  assert.equal(eligibleCustomerId({ customerId: 'customer-1', followedAt: { toDate: () => new Date('2026-09-06T07:00:00Z') } }, opened), 'customer-1');
});
