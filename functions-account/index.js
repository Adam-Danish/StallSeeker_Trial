'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');
const functionsV1 = require('firebase-functions/v1');
const {onDocumentCreated, onDocumentDeleted} = require('firebase-functions/v2/firestore');
const {initializeApp} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const {getFirestore, FieldValue} = require('firebase-admin/firestore');
const {getStorage} = require('firebase-admin/storage');
const {createAccountDeletionService} = require('./account-deletion.cjs');

initializeApp();
const service = createAccountDeletionService({
  db: getFirestore(), auth: getAuth(),
  bucket: getStorage().bucket(), timestamp: () => FieldValue.serverTimestamp(),
});

exports.deleteAccount = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in before deleting your account.');
  const authTime = Number(request.auth.token.auth_time ?? 0);
  if (!authTime || Date.now() / 1000 - authTime > 10 * 60) {
    throw new HttpsError('failed-precondition', 'Confirm your sign-in before deleting your account.');
  }
  try {
    await service.requestDeletion(uid);
    // Success means the sign-in identity is gone and the email is available.
    // The durable job finishes data/photo cleanup independently of this request.
    await service.deleteIdentity(uid);
    await service.deleteProfile(uid);
    return {deleted: true};
  } catch (error) {
    console.error('Account deletion failed', {uid, error});
    throw new HttpsError('internal', 'Account deletion could not be completed.');
  }
});

// Also handles an administrator deleting just the Firestore profile.
exports.onAccountProfileDeleted = onDocumentDeleted({
  document: 'users/{uid}', region: 'asia-southeast1', retry: true,
}, async (event) => {
  await service.requestDeletion(event.params.uid);
  await service.deleteIdentity(event.params.uid);
});

// Auth deletion events cover admin actions that remove a vendor record rather
// than users/{uid}, and deletions made directly in Firebase Authentication.
exports.onAuthAccountDeleted = functionsV1.runWith({failurePolicy: true}).auth.user().onDelete(async (user) => {
  await service.requestDeletion(user.uid);
});

exports.cleanupDeletedAccount = onDocumentCreated({
  document: '_accountDeletions/{uid}', region: 'asia-southeast1', retry: true, timeoutSeconds: 540,
}, async (event) => {
  await service.finishDeletion(event.params.uid);
});
