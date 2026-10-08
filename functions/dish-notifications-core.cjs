'use strict';

const {createHash} = require('node:crypto');
const {createOnce} = require('./history-core.cjs');

function dishAvailabilityAlert({eventId, vendorId, itemId, before, after,
  eventTime, stallName}) {
  if (before?.status !== 'out_of_stock' ||
      !['available', 'low_stock'].includes(after?.status)) return null;
  const date = new Date(eventTime);
  if (!eventId || !vendorId || !itemId || !Number.isFinite(date.getTime())) {
    throw new Error('Missing stable dish event identity or time');
  }
  const dishName = typeof after.name === 'string' && after.name.trim()
    ? after.name.trim().slice(0, 100) : 'A dish you follow';
  const vendorName = typeof stallName === 'string' && stallName.trim()
    ? stallName.trim().slice(0, 100) : 'the stall';
  return {
    id: createHash('sha256').update(`dish:${vendorId}:${itemId}:${eventId}`)
      .digest('hex'),
    vendorId,
    itemId,
    title: `${dishName} is available`,
    body: `${vendorName} has restocked this dish. Check the menu before visiting.`,
    type: 'dish_available',
    isRead: false,
    date,
  };
}

function eligibleDishFollower(follow, uid, alert) {
  if (typeof uid !== 'string' || !uid || uid.length > 128 || uid.includes('/') ||
      follow.customerId !== uid || follow.vendorId !== alert.vendorId ||
      follow.itemId !== alert.itemId) return false;
  const followedAt = follow.followedAt?.toDate?.();
  // Malformed subscriptions and people who followed after the restock do not
  // receive a delayed/retried event.
  return followedAt instanceof Date && Number.isFinite(followedAt.getTime()) &&
    followedAt <= alert.date;
}

const INVALID_TOKEN_CODES = new Set([
  'messaging/registration-token-not-registered',
  'messaging/invalid-registration-token',
]);

async function sendDishPushes({recipients, messaging, notification, data,
  removeInvalidToken, markDeliveryState = async () => {}}) {
  const tokenOwners = new Map();
  for (const recipient of recipients) {
    if (recipient.role !== 'customer' || recipient.notificationsEnabled === false ||
        typeof recipient.fcmToken !== 'string' || !recipient.fcmToken.trim()) {
      await markDeliveryState(recipient.uid, 'skipped');
      continue;
    }
    const owners = tokenOwners.get(recipient.fcmToken) || [];
    owners.push(recipient.uid);
    tokenOwners.set(recipient.fcmToken, owners);
  }
  const tokens = [...tokenOwners.keys()];
  let transientFailure = false;
  for (let start = 0; start < tokens.length; start += 500) {
    const batch = tokens.slice(start, start + 500);
    const result = await messaging.sendEachForMulticast({tokens: batch,
      notification, data});
    await Promise.all(result.responses.map(async (response, index) => {
      const owners = tokenOwners.get(batch[index]);
      if (response.success === true) {
        await Promise.all(owners.map((uid) => markDeliveryState(uid, 'delivered')));
      } else if (INVALID_TOKEN_CODES.has(response.error?.code)) {
        await Promise.all(owners.map(async (uid) => {
          await removeInvalidToken(uid, batch[index]);
          await markDeliveryState(uid, 'discarded');
        }));
      } else {
        transientFailure = true;
      }
    }));
  }
  if (transientFailure) throw new Error('Some dish pushes failed; retry pending deliveries');
}

async function recordDishAlerts({customers, alert, record, historyReference}) {
  const recipients = [];
  for (const customer of customers) {
    if (!customer.exists || customer.data().role !== 'customer') continue;
    // Keep the inbox even when phone alerts are disabled. Creating it first
    // means retries cannot duplicate history or reset an alert's read state.
    const ref = historyReference(customer, alert.id);
    const created = await createOnce(ref, {...record, pushState: 'pending'});
    if (!created) {
      const existing = await ref.get();
      if (!existing.exists || existing.data().pushState !== 'pending') continue;
    }
    recipients.push({...customer.data(), uid: customer.id});
  }
  return recipients;
}

module.exports = {dishAvailabilityAlert, eligibleDishFollower, sendDishPushes,
  recordDishAlerts};
