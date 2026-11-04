'use strict';
const {before, after, beforeEach, test} = require('node:test');
const assert = require('node:assert/strict');
const {createRequire} = require('node:module');
const path = require('node:path');
const functionsRequire = createRequire(path.join(__dirname, '../functions/package.json'));
const {initializeApp, deleteApp} = functionsRequire('firebase-admin/app');
const {getFirestore, Timestamp} = functionsRequire('firebase-admin/firestore');
const {moderationService} = require('../functions/moderation-service.cjs');
const {WINDOW_MS, FIX_MS} = require('../functions/moderation-core.cjs');
const {vendorAvailable} = require('../functions/booking-core.cjs');
const projectId = 'demo-stallseeker-moderation';
let app, db, service, time;
before(() => {
  assert.ok(process.env.FIRESTORE_EMULATOR_HOST, 'Run only against the Firestore emulator.');
  app = initializeApp({projectId}, 'moderation-tests');
  db = getFirestore(app);
  service = moderationService({db, Timestamp, now: () => time});
});
after(async () => { if (app) await deleteApp(app); });
beforeEach(async () => {
  const result = await fetch(`http://${process.env.FIRESTORE_EMULATOR_HOST}/emulator/v1/projects/${projectId}/databases/(default)/documents`, {method: 'DELETE'});
  assert.equal(result.ok, true);
  time = Date.now();
  for (const [uid, role] of [['vendor', 'vendor'], ['admin', 'admin'], ['a', 'customer'], ['b', 'customer'], ['c', 'customer'], ['d', 'customer']]) {
    await db.doc(`users/${uid}`).set({role, fullName: uid});
  }
  await db.doc('vendors/vendor').set({vendorId: 'vendor', stallName: 'Test Stall', isOpen: true,
    latitude: 3.1, longitude: 101.6, selfCollectEnabled: true, listingStatus: 'active', locationSharingActive: true});
});
async function report(uid, requestKey = `request-${uid}`) {
  return (await service.submit(uid, {vendorId: 'vendor', requestKey, reason: 'wrong_location',
    details: 'The stall was not at its listed pin.', observedAt: time - 60000})).reportId;
}
async function warning() {
  const ids = await Promise.all(['a', 'b', 'c'].map((uid) => report(uid)));
  for (const reportId of ids) await service.review('admin', {reportId, decision: 'verify', reason: 'Compared visit evidence with listed pin.'});
  return (await db.doc('vendorModeration/vendor').get()).data().currentCaseId;
}
test('third verified customer creates exactly one warning with a 48-hour deadline', async () => {
  const ids = await Promise.all(['a', 'b', 'c', 'd'].map((uid) => report(uid)));
  await service.review('admin', {reportId: ids[0], decision: 'verify', reason: 'Evidence checked.'});
  await service.review('admin', {reportId: ids[1], decision: 'verify', reason: 'Evidence checked.'});
  assert.equal((await db.collection('moderationCases').get()).size, 0);
  await Promise.all(ids.slice(2).map((reportId) => service.review('admin', {reportId, decision: 'verify', reason: 'Evidence checked.'})));
  const cases = await db.collection('moderationCases').get();
  assert.equal(cases.size, 1);
  assert.equal(cases.docs[0].data().dueAt.toMillis(), time + FIX_MS);
  assert.equal(cases.docs[0].data().summaries.length, 3);
  assert.equal((await db.collection('users/vendor/notifications').get()).size, 1);
  assert.equal((await db.collection('vendorReports').where('caseId', '==', cases.docs[0].id).get()).size, 4);
});
test('report retries are idempotent and repeated reporting is rate limited', async () => {
  const id = await report('a');
  assert.equal(await report('a'), id);
  assert.equal((await db.collection('vendorReports').get()).size, 1);
  await assert.rejects(report('a', 'another-key'), {code: 'resource-exhausted'});
  await service.review('admin', {reportId: id, decision: 'reject', reason: 'Insufficient evidence.'});
  assert.equal((await db.doc(`vendorReports/${id}`).get()).data().status, 'rejected');
});
test('stale reports and rejected complaints do not reach the threshold', async () => {
  const a = await report('a');
  await service.review('admin', {reportId: a, decision: 'verify', reason: 'Evidence checked.'});
  time += WINDOW_MS + 1;
  const b = await report('b');
  const c = await report('c');
  await service.review('admin', {reportId: b, decision: 'reject', reason: 'Incorrect allegation.'});
  await service.review('admin', {reportId: c, decision: 'verify', reason: 'Evidence checked.'});
  assert.equal((await db.collection('moderationCases').get()).size, 0);
});
test('correction, overdue suspension, and restoration preserve the agreed permissions', async () => {
  const caseId = await warning();
  await assert.rejects(service.decide('admin', {vendorId: 'vendor', caseId, action: 'suspend', reason: 'Not fixed.'}), {code: 'failed-precondition'});
  await service.correction('vendor', {caseId, note: 'I have updated the location.', requestKey: 'fix-1'});
  await service.correction('vendor', {caseId, note: 'I have updated the location.', requestKey: 'fix-1'});
  assert.equal((await db.collection(`moderationCases/${caseId}/responses`).get()).size, 1);
  time += FIX_MS;
  await service.decide('admin', {vendorId: 'vendor', caseId, action: 'rejectCorrection', reason: 'Pin is still incorrect.'});
  await service.decide('admin', {vendorId: 'vendor', caseId, action: 'suspend', reason: 'Correction deadline passed.'});
  let vendor = (await db.doc('vendors/vendor').get()).data();
  assert.equal(vendor.listingStatus, 'suspended');
  assert.equal(vendor.locationSharingActive, false);
  assert.equal(vendorAvailable({...vendor, isOpen: true}, time), false);
  await service.correction('vendor', {caseId, note: 'Corrected the pin again.', requestKey: 'fix-2'});
  await service.decide('admin', {vendorId: 'vendor', caseId, action: 'resolve', reason: 'Verified the corrected pin.'});
  vendor = (await db.doc('vendors/vendor').get()).data();
  assert.equal(vendor.listingStatus, 'active');
  assert.equal(vendor.isOpen, false);
  assert.equal((await db.doc('vendorModeration/vendor').get()).data().currentCaseId, null);
  assert.equal((await db.collection('vendorReports').where('status', '==', 'resolved').get()).size, 3);
  await assert.rejects(service.correction('vendor', {caseId, note: 'Late response', requestKey: 'fix-3'}), {code: 'failed-precondition'});
});
test('reports received during a case cannot be recycled into another warning', async () => {
  const caseId = await warning();
  const pending = await report('d');
  await service.decide('admin', {vendorId: 'vendor', caseId, action: 'resolve', reason: 'Verified correction.'});
  await service.review('admin', {reportId: pending, decision: 'verify', reason: 'Historical incident confirmed.'});
  assert.equal((await db.doc(`vendorReports/${pending}`).get()).data().status, 'resolved');
  assert.equal((await db.collection('moderationCases').get()).size, 1);
});
test('non-admin decisions and deletion-in-progress accounts are rejected', async () => {
  const id = await report('a');
  await assert.rejects(service.review('a', {reportId: id, decision: 'verify', reason: 'Pretend admin.'}), {code: 'permission-denied'});
  await db.doc('_accountDeletions/b').set({requestedAt: Timestamp.fromMillis(time)});
  await assert.rejects(report('b'), {code: 'permission-denied'});
  await db.doc('_accountDeletions/vendor').set({requestedAt: Timestamp.fromMillis(time)});
  await assert.rejects(service.review('admin', {reportId: id, decision: 'verify', reason: 'Evidence checked.'}), {code: 'not-found'});
});
