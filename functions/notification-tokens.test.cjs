'use strict';
const {test} = require('node:test');
const assert = require('node:assert/strict');
const {notificationTokens} = require('./notification-tokens.cjs');
const {sendDishPushes} = require('./dish-notifications-core.cjs');

test('phone and browser registrations coexist and duplicate tokens are sent once', () => {
  assert.deepEqual(notificationTokens({fcmToken: 'phone', fcmTokens: ['phone', 'browser', null, '']}), ['phone', 'browser']);
  assert.deepEqual(notificationTokens({fcmToken: 'phone', fcmTokens: ['browser'], notificationsEnabled: false}), []);
  assert.deepEqual(notificationTokens(undefined), []);
  assert.deepEqual(notificationTokens({fcmTokens: 'malformed'}), []);
  assert.equal(notificationTokens({fcmTokens: Array.from({length: 30}, (_, i) => `token-${i}`)}).length, 20);
});

test('one failed browser delivery keeps a successful phone delivery eligible for retry', async () => {
  const states = [];
  const recipient = {uid: 'customer', role: 'customer', fcmToken: 'phone', fcmTokens: ['browser']};
  await assert.rejects(sendDishPushes({
    recipients: [recipient],
    messaging: {sendEachForMulticast: async ({tokens}) => {
      assert.deepEqual(tokens, ['phone', 'browser']);
      return {responses: [{success: true}, {success: false, error: {code: 'messaging/internal-error'}}]};
    }},
    notification: {}, data: {}, removeInvalidToken: async () => {},
    markDeliveryState: async (uid, state) => states.push(state),
  }), /retry/);
  assert.deepEqual(states, []);
});

test('an invalid browser token is removed while phone delivery marks the alert delivered', async () => {
  const removed = [], states = [];
  await sendDishPushes({
    recipients: [{uid: 'customer', role: 'customer', fcmToken: 'phone', fcmTokens: ['browser']}],
    messaging: {sendEachForMulticast: async () => ({responses: [
      {success: true}, {success: false, error: {code: 'messaging/registration-token-not-registered'}},
    ]})},
    notification: {}, data: {},
    removeInvalidToken: async (uid, token) => removed.push(token),
    markDeliveryState: async (uid, state) => states.push(state),
  });
  assert.deepEqual(removed, ['browser']);
  assert.deepEqual(states, ['delivered']);
});
