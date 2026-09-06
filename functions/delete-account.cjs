'use strict';

const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { getApps, initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');

if (getApps().length === 0) initializeApp();
const db = getFirestore();

async function addQueryResults(targets, query) {
  const snapshot = await query.get();
  for (const document of snapshot.docs) targets.set(document.path, document.ref);
}

exports.deleteAccount = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) throw new HttpsError('unauthenticated', 'Sign in before deleting your account.');
  const authTime = Number(request.auth.token.auth_time ?? 0);
  if (!authTime || Date.now() / 1000 - authTime > 10 * 60) {
    throw new HttpsError('failed-precondition', 'Confirm your sign-in before deleting your account.');
  }

  const targets = new Map();
  const userRef = db.collection('users').doc(uid);
  const vendorRef = db.collection('vendors').doc(uid);
  const stallRef = db.collection('stalls').doc(uid);
  targets.set(userRef.path, userRef);
  targets.set(vendorRef.path, vendorRef);
  targets.set(stallRef.path, stallRef);

  await Promise.all([
    addQueryResults(targets, db.collection('follows').where('customerId', '==', uid)),
    addQueryResults(targets, db.collection('follows').where('vendorId', '==', uid)),
    addQueryResults(targets, db.collection('stalls').where('vendorId', '==', uid)),
  ]);

  try {
    for (const ref of targets.values()) await db.recursiveDelete(ref);
    await getAuth().deleteUser(uid);
    return { deleted: true };
  } catch (error) {
    console.error('Account deletion failed', { uid, error });
    throw new HttpsError('internal', 'Account deletion could not be completed.');
  }
});
