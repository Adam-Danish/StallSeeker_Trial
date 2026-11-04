'use strict';
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {onDocumentCreated, onDocumentUpdated} = require('firebase-functions/v2/firestore');
const {getFirestore, Timestamp} = require('firebase-admin/firestore');
const {getMessaging} = require('firebase-admin/messaging');
const {moderationService} = require('./moderation-service.cjs');
const {validCaller} = require('./moderation-core.cjs');
const {notificationTokens} = require('./notification-tokens.cjs');
const db = getFirestore();
const service = moderationService({db, Timestamp});
function callable(method, adminOperation = false) {
  return onCall({region: 'asia-southeast1'}, async (request) => {
    const uid = request.auth?.uid;
    if (!validCaller(request.auth, adminOperation)) {
      throw new HttpsError('unauthenticated', adminOperation ? 'Sign in with an administrator account.' : 'Sign in with a verified account.');
    }
    try { return await service[method](uid, request.data); }
    catch (error) {
      const codes = ['invalid-argument', 'permission-denied', 'not-found', 'resource-exhausted', 'failed-precondition'];
      if (codes.includes(error.code)) throw new HttpsError(error.code, error.message);
      console.error('Moderation operation failed', {method, code: error.code});
      throw new HttpsError('internal', 'Could not save this change. Please retry.');
    }
  });
}
exports.submitVendorReport = callable('submit');
exports.reviewVendorReport = callable('review', true);
exports.submitVendorCorrection = callable('correction');
exports.decideVendorModeration = callable('decide', true);
exports.finishResolvedVendorReports = onDocumentUpdated({region: 'asia-southeast1',
  document: 'moderationCases/{caseId}', retry: true}, async (event) => {
  if (event.data?.after.data().status !== 'resolved') return;
  for (;;) {
    const page = await db.collection('vendorReports').where('caseId', '==', event.params.caseId)
      .where('status', '==', 'verified').limit(400).get();
    if (page.empty) return;
    // Re-read each report in the transaction so deletion cannot recreate data.
    await db.runTransaction(async (tx) => {
      const docs = await Promise.all(page.docs.map((doc) => tx.get(doc.ref)));
      for (const doc of docs) {
        if (doc.exists && doc.data().status === 'verified') tx.update(doc.ref, {status: 'resolved', updatedAt: Timestamp.now()});
      }
    });
  }
});
exports.notifyVendorModeration = onDocumentCreated({region: 'asia-southeast1',
  document: 'users/{uid}/notifications/{notificationId}'}, async (event) => {
  const notice = event.data?.data();
  if (notice?.type !== 'moderation') return;
  // The durable inbox and case banner are authoritative if delivery fails.
  try {
    const user = (await db.doc(`users/${event.params.uid}`).get()).data();
    if (!user || user.notificationsEnabled === false) return;
    const tokens = notificationTokens(user);
    if (!tokens.length) return;
    await getMessaging().sendEachForMulticast({tokens,
      notification: {title: notice.title, body: notice.body},
      data: {type: 'moderation', caseId: notice.caseId, recipientId: event.params.uid, role: 'vendor'}});
    await event.data.ref.update({pushStatus: 'sent'});
  } catch (error) {
    console.error('Moderation push unavailable', {code: error.code});
    await event.data.ref.update({pushStatus: 'failed'});
  }
});
