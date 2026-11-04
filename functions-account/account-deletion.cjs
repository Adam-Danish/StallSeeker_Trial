'use strict';

// Jobs are retained as UID tombstones. A new signup gets a new UID, even when
// reusing the email; retries only ever touch the old account's UID.
function createAccountDeletionService({db, auth, bucket, timestamp}) {
  async function requestDeletion(uid) {
    try {
      await db.collection('_accountDeletions').doc(uid).create({requestedAt: timestamp()});
    } catch (error) {
      if (error.code !== 6 && error.code !== 'already-exists') throw error;
    }
  }

  async function deleteIdentity(uid) {
    try {
      await auth.deleteUser(uid);
    } catch (error) {
      if (error.code !== 'auth/user-not-found') throw error;
    }
  }

  async function deleteProfile(uid) {
    await db.collection('users').doc(uid).delete();
  }

  async function finishDeletion(uid) {
    // Identity deletion must never wait for a query, index or Storage cleanup.
    await deleteIdentity(uid);
    await deleteProfile(uid);
    const targets = new Map();
    for (const path of [
      `users/${uid}`, `vendors/${uid}`, `stallReviews/${uid}`, `stalls/${uid}`,
      `vendorModeration/${uid}`,
      `_emailVerificationCodes/${uid}_registration`,
      `_emailVerificationCodes/${uid}_email_change`,
    ]) targets.set(path, db.doc(path));

    const queries = [
      db.collection('follows').where('customerId', '==', uid),
      db.collection('follows').where('vendorId', '==', uid),
      db.collectionGroup('dishFollows').where('vendorId', '==', uid),
      db.collection('stalls').where('vendorId', '==', uid),
      db.collection('bookings').where('customerId', '==', uid),
      db.collection('bookings').where('vendorId', '==', uid),
      db.collection('vendorReports').where('customerId', '==', uid),
      db.collection('vendorReports').where('vendorId', '==', uid),
      db.collection('moderationRateLimits').where('customerId', '==', uid),
      db.collection('moderationRateLimits').where('vendorId', '==', uid),
      db.collection('moderationCases').where('vendorId', '==', uid),
      db.collection('transactionEmailOutbox').where('booking.customerId', '==', uid),
    ];
    for (const query of queries) {
      const snapshot = await query.get();
      for (const doc of snapshot.docs) targets.set(doc.ref.path, doc.ref);
    }
    const reviews = await db.collectionGroup('entries').where('customerId', '==', uid).get();
    const prefixes = new Set([`menu_images/${uid}/`, `review_images/${uid}/`]);
    for (const review of reviews.docs) {
      targets.set(review.ref.path, review.ref);
      const vendorId = review.ref.parent.parent?.id;
      if (vendorId) prefixes.add(`review_images/${vendorId}/${uid}/`);
    }

    // Keep review records until every photo is removed, so a retry can still
    // discover all photo paths after a partial Storage failure.
    await bucket.file(`stall_images/${uid}.jpg`).delete({ignoreNotFound: true});
    for (const prefix of prefixes) await bucket.deleteFiles({prefix, force: true});
    for (const ref of targets.values()) await db.recursiveDelete(ref);
    await db.collection('_accountDeletions').doc(uid).update({completedAt: timestamp()});
  }

  return {requestDeletion, deleteIdentity, deleteProfile, finishDeletion};
}

module.exports = {createAccountDeletionService};
