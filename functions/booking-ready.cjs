'use strict';

const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { getApps, initializeApp } = require('firebase-admin/app');
const { getFirestore, Timestamp, FieldValue } = require('firebase-admin/firestore');
const { createHash } = require('node:crypto');
const { getMessaging } = require('firebase-admin/messaging');

if (!getApps().length) initializeApp();
const db = getFirestore();

// Trigger when a booking's status becomes 'ready'. Generates pickup code & timestamps, notifies customer.
exports.handleReady = onDocumentUpdated({
  document: 'bookings/{bookingId}',
  region: 'asia-southeast1',
  retry: true,
}, async (event) => {
  const before = event.data?.before?.data();
  const after = event.data?.after?.data();
  if (!before || !after) return;
  if (before.status === 'ready' || after.status !== 'ready') return; // only on transition to ready

  const now = Timestamp.now();
  // 4‑digit code
  const code = (Math.floor(1000 + Math.random() * 9000)).toString();
  const codeHash = createHash('sha256').update(code).digest('hex');
  const autoCompleteAt = Timestamp.fromMillis(now.toMillis() + 2 * 60 * 60 * 1000); // 2 h

  // Update the booking with generated data
  await db.collection('bookings').doc(event.params.bookingId).update({
    readyAt: now,
    autoCompleteAt,
    pickupCodeHash: codeHash,
    // optionally store plain code for debugging (remove in prod)
    // pickupCode: code,
  });

  // Notify the customer via FCM
  try {
    const customerId = after.customerId;
    const userDoc = await db.collection('users').doc(customerId).get();
    const profile = userDoc.data();
    const tokens = [];
    // Reuse notificationTokens helper if available
    const { notificationTokens } = require('./notification-tokens.cjs');
    if (typeof notificationTokens === 'function') {
      tokens.push(...notificationTokens(profile));
    }
    if (tokens.length) {
      const message = {
        title: 'Ready for collection',
        body: `Your order is ready. Code: ${code}`,
      };
      await getMessaging().sendEachForMulticast({
        tokens,
        notification: message,
        data: {
          type: 'booking',
          bookingId: event.params.bookingId,
          status: 'ready',
        },
      });
    }
  } catch (e) {
    console.error('Failed to send ready notification', e);
  }
});
