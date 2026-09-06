'use strict';
const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { getApps, initializeApp } = require('firebase-admin/app');
const { getFirestore, Timestamp } = require('firebase-admin/firestore');
const { openingAlert, eligibleCustomerId, createOnce } = require('./history-core.cjs');

if (getApps().length === 0) initializeApp();
const db = getFirestore();

// This only stores history. Keep your existing push-sending function in place;
// deploying this alongside it does not introduce a second push sender.
exports.recordVendorOpeningHistory = onDocumentUpdated({
  document: 'vendors/{vendorId}',
  retry: true,
}, async (event) => {
  if (!event.data) return;
  const alert = openingAlert({
    eventId: event.id,
    vendorId: event.params.vendorId,
    before: event.data.before.data(),
    after: event.data.after.data(),
    eventTime: event.time,
  });
  if (!alert) return;
  const { id, date, ...fields } = alert;
  const record = { ...fields, createdAt: Timestamp.fromDate(date) };
  const query = db.collection('follows').where('vendorId', '==', alert.vendorId).limit(200);
  let cursor = null;
  for (;;) {
    const page = await (cursor ? query.startAfter(cursor) : query).get();
    if (page.empty) break;
    const uids = [...new Set(page.docs
      .map((doc) => eligibleCustomerId(doc.data(), date)).filter(Boolean))];
    // Avoid creating inboxes for missing, deleted, or vendor accounts.
    for (let start = 0; start < uids.length; start += 20) {
      const customerDocs = await db.getAll(...uids.slice(start, start + 20)
        .map((uid) => db.collection('users').doc(uid)));
      await Promise.all(customerDocs.map(async (customer) => {
        if (!customer.exists || customer.data().role !== 'customer') return;
        await createOnce(customer.ref.collection('notifications').doc(id), record);
      }));
    }
    cursor = page.docs[page.docs.length - 1];
    if (page.size < 200) break;
  }
});
