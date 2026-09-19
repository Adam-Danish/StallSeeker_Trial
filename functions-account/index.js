'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {initializeApp} = require('firebase-admin/app');
const {getAuth} = require('firebase-admin/auth');
const {getFirestore} = require('firebase-admin/firestore');
const {getStorage} = require('firebase-admin/storage');

initializeApp();

async function addQueryResults(targets, query) {
  const snapshot = await query.get();
  for (const document of snapshot.docs) {
    targets.set(document.path, document.ref);
  }
}

exports.deleteAccount = onCall(async (request) => {
  const uid = request.auth?.uid;
  if (!uid) {
    throw new HttpsError(
        'unauthenticated',
        'Sign in before deleting your account.',
    );
  }

  const authTime = Number(request.auth.token.auth_time ?? 0);
  if (!authTime || Date.now() / 1000 - authTime > 10 * 60) {
    throw new HttpsError(
        'failed-precondition',
        'Confirm your sign-in before deleting your account.',
    );
  }

  const db = getFirestore();
  const targets = new Map();
  const customerReviewVendorIds = new Set();
  const directTargets = [
    db.collection('users').doc(uid),
    db.collection('vendors').doc(uid),
    db.collection('stallReviews').doc(uid),
    db.collection('stalls').doc(uid),
    db.collection('_emailVerificationCodes').doc(`${uid}_registration`),
    db.collection('_emailVerificationCodes').doc(`${uid}_email_change`),
  ];
  for (const reference of directTargets) {
    targets.set(reference.path, reference);
  }

  await Promise.all([
    addQueryResults(
        targets,
        db.collection('follows').where('customerId', '==', uid),
    ),
    addQueryResults(
        targets,
        db.collection('follows').where('vendorId', '==', uid),
    ),
    addQueryResults(
        targets,
        db.collection('stalls').where('vendorId', '==', uid),
    ),
  ]);

  const customerReviews = await db.collectionGroup('entries')
      .where('customerId', '==', uid).get();
  for (const review of customerReviews.docs) {
    targets.set(review.ref.path, review.ref);
    const vendorId = review.ref.parent.parent?.id;
    if (vendorId) customerReviewVendorIds.add(vendorId);
  }

  try {
    for (const reference of targets.values()) {
      await db.recursiveDelete(reference);
    }

    const bucket = getStorage().bucket();
    await Promise.all([
      bucket.file(`stall_images/${uid}.jpg`).delete({ignoreNotFound: true}),
      bucket.deleteFiles({prefix: `menu_images/${uid}/`, force: true}),
      bucket.deleteFiles({prefix: `review_images/${uid}/`, force: true}),
      ...[...customerReviewVendorIds].map((vendorId) =>
        bucket.deleteFiles({prefix: `review_images/${vendorId}/${uid}/`, force: true})),
    ]);

    await getAuth().deleteUser(uid);
    return {deleted: true};
  } catch (error) {
    console.error('Account deletion failed', {uid, error});
    throw new HttpsError(
        'internal',
        'Account deletion could not be completed.',
    );
  }
});
