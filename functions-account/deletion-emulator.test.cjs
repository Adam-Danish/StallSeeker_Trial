'use strict';

const {test} = require('node:test');
const assert = require('node:assert/strict');

test('customer and vendor deletion release the email before cleanup; retries preserve the replacement', {
  skip: !process.env.FIREBASE_AUTH_EMULATOR_HOST || !process.env.FIRESTORE_EMULATOR_HOST,
}, async () => {
  // This test must never address production services.
  assert.match(process.env.GCLOUD_PROJECT ?? '', /^demo-/);
  const {getAuth} = require('firebase-admin/auth');
  const {getFirestore, FieldValue} = require('firebase-admin/firestore');
  const functions = require('./index.js');
  const {createAccountDeletionService} = require('./account-deletion.cjs');
  const auth = getAuth();
  const db = getFirestore();
  const service = createAccountDeletionService({db, auth,
    bucket: {file: () => ({delete: async () => {}}), deleteFiles: async () => {}},
    timestamp: () => FieldValue.serverTimestamp(),
  });
  try {
    await assert.rejects(functions.deleteAccount.run({}), {code: 'unauthenticated'});
    await assert.rejects(functions.deleteAccount.run({auth: {uid: 'stale', token: {auth_time: 1}}}),
        {code: 'failed-precondition'});
    for (const role of ['customer', 'vendor']) {
      const email = `${role}-${Date.now()}@example.com`;
      const old = await auth.createUser({email, password: 'Test-password-123'});
      await db.doc(`users/${old.uid}`).set({role, email});
      if (role === 'vendor') await db.doc(`vendors/${old.uid}`).set({vendorId: old.uid});
      const result = await functions.deleteAccount.run({auth: {
        uid: old.uid, token: {auth_time: Math.floor(Date.now() / 1000)},
      }});
      assert.deepEqual(result, {deleted: true});
      await assert.rejects(auth.getUser(old.uid), {code: 'auth/user-not-found'});
      assert.equal((await db.doc(`users/${old.uid}`).get()).exists, false);
      assert.equal((await db.doc(`_accountDeletions/${old.uid}`).get()).exists, true);
      const replacement = await auth.createUser({email, password: 'New-password-123'});
      await db.doc(`users/${replacement.uid}`).set({role, email});
      assert.notEqual(replacement.uid, old.uid);
      await service.finishDeletion(old.uid);
      await service.finishDeletion(old.uid);
      assert.equal((await auth.getUserByEmail(email)).uid, replacement.uid);
      assert.equal((await db.doc(`users/${replacement.uid}`).get()).data().role, role);
    }

    // A profile-only admin deletion removes the associated sign-in identity.
    const adminDeleted = await auth.createUser({email: `admin-delete-${Date.now()}@example.com`});
    await functions.onAccountProfileDeleted.run({params: {uid: adminDeleted.uid}});
    await assert.rejects(auth.getUser(adminDeleted.uid), {code: 'auth/user-not-found'});
    await service.finishDeletion(adminDeleted.uid);
  } finally {
    await Promise.all(require('firebase-admin/app').getApps().map((app) => app.delete()));
  }
});
