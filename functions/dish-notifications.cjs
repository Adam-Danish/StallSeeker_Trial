'use strict';

const {onDocumentUpdated, onDocumentDeleted} = require('firebase-functions/v2/firestore');
const {getApps, initializeApp} = require('firebase-admin/app');
const {getFirestore, Timestamp, FieldValue} = require('firebase-admin/firestore');
const {getMessaging} = require('firebase-admin/messaging');
const {dishAvailabilityAlert, eligibleDishFollower, sendDishPushes,
  recordDishAlerts} = require('./dish-notifications-core.cjs');

if (getApps().length === 0) initializeApp();
const db = getFirestore();

function subscriptions(vendorId, itemId) {
  return db.collectionGroup('dishFollows').where('vendorId', '==', vendorId)
    .where('itemId', '==', itemId);
}

async function removeInvalidToken(uid, token) {
  const ref = db.collection('users').doc(uid);
  await db.runTransaction(async (transaction) => {
    const user = await transaction.get(ref);
    // A token refresh may have happened while the push was being sent.
    if (user.exists && user.data().fcmToken === token) {
      transaction.update(ref, {fcmToken: FieldValue.delete()});
    }
  });
}

exports.notifyFollowersOnDishAvailable = onDocumentUpdated({
  document: 'vendors/{vendorId}/menu/{itemId}', retry: true,
}, async (event) => {
  if (!event.data) return;
  const {vendorId, itemId} = event.params;
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (before?.status !== 'out_of_stock' ||
      !['available', 'low_stock'].includes(after?.status)) return;
  const vendor = await db.collection('vendors').doc(vendorId).get();
  if (!vendor.exists) return;
  const alert = dishAvailabilityAlert({eventId: event.id, vendorId, itemId,
    before, after, eventTime: event.time, stallName: vendor.data().stallName});
  if (!alert) return;
  const {id, date, ...fields} = alert;
  const record = {...fields, createdAt: Timestamp.fromDate(date)};
  const query = subscriptions(vendorId, itemId).limit(200);
  let cursor = null;
  for (;;) {
    const page = await (cursor ? query.startAfter(cursor) : query).get();
    if (page.empty) break;
    const uids = [...new Set(page.docs.map((follow) => {
      const parent = follow.ref.parent.parent;
      if (!parent || parent.parent.id !== 'users') return null;
      return eligibleDishFollower(follow.data(), parent.id, alert) ? parent.id : null;
    }).filter(Boolean))];
    for (let start = 0; start < uids.length; start += 20) {
      const customers = await db.getAll(...uids.slice(start, start + 20)
        .map((uid) => db.collection('users').doc(uid)));
      const recipients = await recordDishAlerts({customers, alert, record,
        historyReference: (customer, alertId) => customer.ref.collection('notifications').doc(alertId)});
      // The same durable history record acts as the delivery outbox. A retry
      // continues pending attempts and skips pushes with confirmed success.
      await sendDishPushes({recipients, messaging: getMessaging(),
        notification: {title: alert.title, body: alert.body},
        data: {vendorId, itemId, notificationId: id, type: 'dish_available'},
        removeInvalidToken,
        markDeliveryState: (uid, state) => db.collection('users').doc(uid)
          .collection('notifications').doc(id).update({pushState: state})});
    }
    cursor = page.docs[page.docs.length - 1];
    if (page.size < 200) break;
  }
});

exports.cleanupDeletedDishFollows = onDocumentDeleted({
  document: 'vendors/{vendorId}/menu/{itemId}', retry: true,
}, async (event) => {
  const {vendorId, itemId} = event.params;
  for (;;) {
    const page = await subscriptions(vendorId, itemId).limit(400).get();
    if (page.empty) return;
    const batch = db.batch();
    for (const follow of page.docs) batch.delete(follow.ref);
    await batch.commit();
  }
});
