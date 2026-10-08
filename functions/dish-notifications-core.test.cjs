'use strict';

const {test} = require('node:test');
const assert = require('node:assert/strict');
const {dishAvailabilityAlert, eligibleDishFollower, sendDishPushes,
  recordDishAlerts} = require('./dish-notifications-core.cjs');

const event = {eventId: 'restock-1', vendorId: 'stall-a', itemId: 'dish-a',
  before: {status: 'out_of_stock'}, after: {status: 'available', name: 'Laksa'},
  stallName: 'Adam Stall', eventTime: '2026-10-04T04:00:00Z'};

test('only sold-out to available/low-stock changes notify dish followers', () => {
  assert.equal(dishAvailabilityAlert(event).title, 'Laksa is available');
  assert.ok(dishAvailabilityAlert({...event, after: {...event.after, status: 'low_stock'}}));
  for (const status of ['available', 'low_stock', undefined]) {
    assert.equal(dishAvailabilityAlert({...event, before: {status}}), null);
  }
  assert.equal(dishAvailabilityAlert({...event, after: {status: 'out_of_stock'}}), null);
});

test('restock IDs isolate dishes and preserve identity across retries', () => {
  assert.equal(dishAvailabilityAlert(event).id, dishAvailabilityAlert(event).id);
  assert.notEqual(dishAvailabilityAlert(event).id,
    dishAvailabilityAlert({...event, itemId: 'dish-b'}).id);
  assert.notEqual(dishAvailabilityAlert(event).id,
    dishAvailabilityAlert({...event, eventId: 'restock-2'}).id);
});

test('followers must own the subscription and predate the restock event', () => {
  const alert = dishAvailabilityAlert(event);
  const follow = {customerId: 'customer-a', vendorId: 'stall-a', itemId: 'dish-a',
    followedAt: {toDate: () => new Date('2026-10-04T03:00:00Z')}};
  assert.equal(eligibleDishFollower(follow, 'customer-a', alert), true);
  assert.equal(eligibleDishFollower(follow, 'customer-b', alert), false);
  assert.equal(eligibleDishFollower({...follow, itemId: 'dish-b'}, 'customer-a', alert), false);
  assert.equal(eligibleDishFollower({...follow, followedAt: null}, 'customer-a', alert), false);
  assert.equal(eligibleDishFollower({...follow,
    followedAt: {toDate: () => new Date('2026-10-04T05:00:00Z')}}, 'customer-a', alert), false);
});

test('push batches cap at 500, deduplicate tokens, respect settings and clean invalid tokens', async () => {
  const recipients = Array.from({length: 1001}, (_, i) =>
    ({uid: `customer-${i}`, role: 'customer', fcmToken: `token-${i}`}));
  recipients.push({uid: 'duplicate', role: 'customer', fcmToken: 'token-0'},
    {uid: 'muted', role: 'customer', fcmToken: 'muted-token', notificationsEnabled: false},
    {uid: 'vendor', role: 'vendor', fcmToken: 'vendor-token'});
  const sizes = [];
  const removed = [];
  await sendDishPushes({recipients, notification: {title: 'Available'},
    data: {vendorId: 'stall-a', itemId: 'dish-a'},
    messaging: {sendEachForMulticast: async ({tokens}) => {
      sizes.push(tokens.length);
      assert.ok(!tokens.includes('muted-token') && !tokens.includes('vendor-token'));
      return {responses: tokens.map((token) => token === 'token-0'
        ? {error: {code: 'messaging/registration-token-not-registered'}}
        : {success: true})};
    }}, removeInvalidToken: async (uid, token) => removed.push([uid, token])});
  assert.deepEqual(sizes, [500, 500, 1]);
  assert.deepEqual(removed, [['customer-0', 'token-0'], ['duplicate', 'token-0']]);
});

test('inbox creation is idempotent and excludes deleted/vendor users', async () => {
  const saved = new Map();
  const customers = [{id: 'customer-a', exists: true, data: () => ({role: 'customer'})},
    {id: 'vendor-a', exists: true, data: () => ({role: 'vendor'})},
    {id: 'deleted', exists: false}];
  const args = {customers, alert: dishAvailabilityAlert(event), record: {isRead: false},
    historyReference: (customer, id) => ({create: async (record) => {
      const key = `${customer.id}/${id}`;
      if (saved.has(key)) throw Object.assign(new Error('Exists'), {code: 6});
      saved.set(key, record);
    }, get: async () => ({exists: saved.has(`${customer.id}/${id}`),
      data: () => saved.get(`${customer.id}/${id}`)})})};
  assert.equal((await recordDishAlerts(args)).length, 1);
  saved.values().next().value.isRead = true;
  saved.values().next().value.pushState = 'delivered';
  assert.deepEqual(await recordDishAlerts(args), []);
  assert.equal(saved.size, 1);
  assert.equal(saved.values().next().value.isRead, true);
});

function deliveryHarness(count) {
  const saved = new Map();
  const customers = Array.from({length: count}, (_, index) => ({
    id: `customer-${index}`, exists: true,
    data: () => ({role: 'customer', fcmToken: `token-${index}`}),
  }));
  const args = {customers, alert: dishAvailabilityAlert(event), record: {isRead: false},
    historyReference: (customer) => ({create: async (record) => {
      if (saved.has(customer.id)) throw Object.assign(new Error('Exists'), {code: 6});
      saved.set(customer.id, {...record});
    }, get: async () => ({exists: saved.has(customer.id), data: () => saved.get(customer.id)})})};
  const markDeliveryState = async (uid, state) => { saved.get(uid).pushState = state; };
  return {saved, args, markDeliveryState};
}

test('FCM failure after history creation is retried without resetting read state', async () => {
  const {saved, args, markDeliveryState} = deliveryHarness(1);
  const pushArgs = {notification: {title: 'Restocked'}, data: {},
    removeInvalidToken: async () => {}, markDeliveryState};
  let recipients = await recordDishAlerts(args);
  await assert.rejects(sendDishPushes({...pushArgs, recipients,
    messaging: {sendEachForMulticast: async () => { throw new Error('Unavailable'); }}}));
  assert.equal(saved.get('customer-0').pushState, 'pending');
  saved.get('customer-0').isRead = true;
  recipients = await recordDishAlerts(args);
  assert.equal(recipients.length, 1);
  await sendDishPushes({...pushArgs, recipients,
    messaging: {sendEachForMulticast: async () => ({responses: [{success: true}]})}});
  assert.equal(saved.size, 1);
  assert.equal(saved.get('customer-0').isRead, true);
  assert.equal(saved.get('customer-0').pushState, 'delivered');
  assert.deepEqual(await recordDishAlerts(args), []);
});

test('partial FCM failures retry only unfinished pushes and persist permanent failures', async () => {
  const {saved, args, markDeliveryState} = deliveryHarness(3);
  const pushArgs = {notification: {title: 'Restocked'}, data: {},
    removeInvalidToken: async () => {}, markDeliveryState};
  const recipients = await recordDishAlerts(args);
  await assert.rejects(sendDishPushes({...pushArgs, recipients,
    messaging: {sendEachForMulticast: async () => ({responses: [
      {success: true}, {error: {code: 'messaging/internal-error'}},
      {error: {code: 'messaging/invalid-registration-token'}},
    ]})}}), /retry pending deliveries/);
  assert.equal(saved.get('customer-0').pushState, 'delivered');
  assert.equal(saved.get('customer-1').pushState, 'pending');
  assert.equal(saved.get('customer-2').pushState, 'discarded');
  const retried = await recordDishAlerts(args);
  assert.deepEqual(retried.map((item) => item.uid), ['customer-1']);
  await sendDishPushes({...pushArgs, recipients: retried,
    messaging: {sendEachForMulticast: async ({tokens}) => {
      assert.deepEqual(tokens, ['token-1']);
      return {responses: [{success: true}]};
    }}});
  assert.deepEqual(await recordDishAlerts(args), []);
});

test('muted or unregistered customers keep inbox updates without replaying old pushes', async () => {
  const {saved, args, markDeliveryState} = deliveryHarness(2);
  args.customers[0].data = () => ({role: 'customer', fcmToken: 'muted-token', notificationsEnabled: false});
  args.customers[1].data = () => ({role: 'customer'});
  const recipients = await recordDishAlerts(args);
  await sendDishPushes({recipients, notification: {}, data: {}, markDeliveryState,
    removeInvalidToken: async () => {},
    messaging: {sendEachForMulticast: async () => { assert.fail('No push should be sent'); }}});
  assert.equal(saved.size, 2);
  assert.equal(saved.get('customer-0').pushState, 'skipped');
  assert.equal(saved.get('customer-1').pushState, 'skipped');
  assert.deepEqual(await recordDishAlerts(args), []);
});
