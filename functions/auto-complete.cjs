'use strict';

const { onSchedule } = require('firebase-functions/v2/scheduler');
const { getApps, initializeApp } = require('firebase-admin/app');
const { getFirestore, Timestamp, FieldValue } = require('firebase-admin/firestore');

if (!getApps().length) initializeApp();
const db = getFirestore();
const bookings = db.collection('bookings');

// Runs every 15 minutes to auto‑complete ready bookings whose deadline passed.
exports.autoCompleteBookings = onSchedule('*/15 * * * *', async (event) => {
  const now = Timestamp.now();
  const snapshot = await bookings
    .where('status', '==', 'ready')
    .where('autoCompleteAt', '<=', now)
    .get();

  if (snapshot.empty) {
    console.log('No bookings to auto‑complete at this time.');
    return;
  }

  const batch = db.batch();
  snapshot.forEach((doc) => {
    const ref = doc.ref;
    batch.update(ref, {
      status: 'completed',
      collectedAt: FieldValue.serverTimestamp(),
    });
  });

  await batch.commit();
  console.log(`Auto‑completed ${snapshot.size} booking(s).`);
});
