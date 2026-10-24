'use strict';
const {before, after, beforeEach, test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {initializeTestEnvironment, assertFails, assertSucceeds} = require('@firebase/rules-unit-testing');
const {doc, collection, getDoc, getDocs, setDoc, updateDoc, deleteDoc, deleteField, serverTimestamp, Timestamp} = require('firebase/firestore');
let env;
const route = 'stallReviews/vendor/entries/customer';
const client = (uid, verified = true, anonymous = false) => env.authenticatedContext(uid, {
  email_verified: verified, firebase: {sign_in_provider: anonymous ? 'anonymous' : 'password'},
}).firestore();
const review = (extra = {}) => ({customerId: 'customer', customerName: 'Aina', customerAvatarUrl: '',
  rating: 3, text: 'Good food', photoUrls: [], createdAt: serverTimestamp(), updatedAt: serverTimestamp(), edited: false, ...extra});
async function reply(text = 'Thank you for your feedback', extra = {}) {
  const current = (await getDoc(doc(client('vendor'), route))).data();
  return {text, createdAt: serverTimestamp(), updatedAt: serverTimestamp(), edited: false,
    reviewUpdatedAt: current.updatedAt, ...extra};
}
before(async () => {
  env = await initializeTestEnvironment({projectId: 'demo-stallseeker-review-replies',
    firestore: {rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8')}});
});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async context => {
    for (const [uid, role] of [['customer','customer'], ['other','customer'], ['vendor','vendor'], ['otherVendor','vendor']]) {
      await setDoc(doc(context.firestore(), 'users', uid), {uid, role});
    }
    await setDoc(doc(context.firestore(), 'vendors/vendor'), {vendorId: 'vendor', stallName: 'Burger Pak Ali'});
  });
  await assertSucceeds(setDoc(doc(client('customer'), route), review()));
});
after(async () => { if (env) await env.cleanup(); });

test('only the verified stall owner can post the single official reply', async () => {
  const data = await reply();
  for (const db of [client('customer'), client('other'), client('otherVendor'), client('vendor', false),
    client('vendor', true, true), env.unauthenticatedContext().firestore()]) {
    await assertFails(updateDoc(doc(db, route), {vendorReply: data}));
  }
  await assertSucceeds(updateDoc(doc(client('vendor'), route), {vendorReply: data}));
  const publicReview = (await assertSucceeds(getDoc(doc(env.unauthenticatedContext().firestore(), route)))).data();
  assert.equal(publicReview.vendorReply.text, data.text);
  await assertSucceeds(getDocs(collection(env.unauthenticatedContext().firestore(), 'stallReviews/vendor/entries')));
});

test('a vendor cannot alter ratings, authors, photos or review text, or delete the review', async () => {
  const db = client('vendor');
  for (const changes of [{rating: 5}, {text: 'Rewritten'}, {customerId: 'vendor'}, {photoUrls: []},
    {updatedAt: serverTimestamp()}, {customerName: 'Forged'}]) {
    // Identical photo list is a no-op, so use a real modification.
    if ('photoUrls' in changes) changes.photoUrls = ['https://example.com/other.jpg'];
    await assertFails(updateDoc(doc(db, route), changes));
  }
  await assertFails(deleteDoc(doc(db, route)));
  await assertFails(setDoc(doc(db, 'stallReviews/vendor/entries/new'), review({customerId: 'new'})));
});

test('empty, whitespace-only, oversized, malformed, extra-field and future-context replies are denied', async () => {
  const db = client('vendor');
  for (const text of ['', '  \n\t ', 'x'.repeat(1001)]) {
    await assertFails(updateDoc(doc(db, route), {vendorReply: await reply(text)}));
  }
  for (const extra of [{edited: 'yes'}, {edited: true}, {unexpected: true}, {createdAt: Timestamp.fromMillis(0)},
    {reviewUpdatedAt: Timestamp.fromMillis(Date.now() + 86400000)}]) {
    await assertFails(updateDoc(doc(db, route), {vendorReply: await reply('Reply', extra)}));
  }
  await assertFails(updateDoc(doc(db, route), {vendorReply: 'Reply'}));
  await assertSucceeds(updateDoc(doc(db, route), {vendorReply: await reply('x'.repeat(1000))}));
});

test('customer edits preserve the owner reply and original creation time', async () => {
  await assertSucceeds(updateDoc(doc(client('vendor'), route), {vendorReply: await reply()}));
  const original = (await getDoc(doc(client('customer'), route))).data();
  await assertSucceeds(updateDoc(doc(client('customer'), route), {rating: 2, text: 'Updated feedback',
    updatedAt: serverTimestamp(), edited: true}));
  const updated = (await getDoc(doc(client('customer'), route))).data();
  assert.deepEqual(updated.vendorReply, original.vendorReply);
  assert.equal(updated.createdAt.toMillis(), original.createdAt.toMillis());
  assert(updated.updatedAt.toMillis() >= original.vendorReply.reviewUpdatedAt.toMillis());
  for (const changes of [{vendorReply: deleteField()}, {'vendorReply.text': 'Forged'},
    {createdAt: serverTimestamp()}, {edited: false}]) {
    await assertFails(updateDoc(doc(client('customer'), route), changes));
  }
  await assertFails(setDoc(doc(client('customer'), route), review()));
});

test('owner reply edits preserve creation time and do not touch customer timestamps', async () => {
  const db = client('vendor');
  await assertSucceeds(updateDoc(doc(db, route), {vendorReply: await reply()}));
  const original = (await getDoc(doc(db, route))).data();
  const edited = {text: 'Updated owner reply', createdAt: original.vendorReply.createdAt,
    updatedAt: serverTimestamp(), edited: true, reviewUpdatedAt: original.updatedAt};
  await assertSucceeds(updateDoc(doc(db, route), {vendorReply: edited}));
  const after = (await getDoc(doc(db, route))).data();
  assert.equal(after.vendorReply.edited, true);
  assert.equal(after.updatedAt.toMillis(), original.updatedAt.toMillis());
  await assertFails(updateDoc(doc(db, route), {vendorReply: {...edited, createdAt: serverTimestamp()}}));
  await assertFails(updateDoc(doc(db, route), {vendorReply: {...edited, edited: false}}));
});

test('deleting only a reply keeps the review, rating and dates', async () => {
  const db = client('vendor');
  await assertSucceeds(updateDoc(doc(db, route), {vendorReply: await reply()}));
  const original = (await getDoc(doc(db, route))).data();
  await assertFails(updateDoc(doc(client('otherVendor'), route), {vendorReply: deleteField()}));
  await assertSucceeds(updateDoc(doc(db, route), {vendorReply: deleteField()}));
  const after = (await getDoc(doc(db, route))).data();
  delete original.vendorReply; assert.deepEqual(after, original);
  await assertSucceeds(updateDoc(doc(db, route), {vendorReply: await reply('A fresh reply')}));
});

test('customer deletion removes both public review and reply; owner cannot recreate it', async () => {
  await assertSucceeds(updateDoc(doc(client('vendor'), route), {vendorReply: await reply()}));
  await assertFails(deleteDoc(doc(client('other'), route)));
  await assertFails(deleteDoc(doc(client('customer', false), route)));
  await assertSucceeds(deleteDoc(doc(client('customer'), route)));
  const snap = await assertSucceeds(getDoc(doc(env.unauthenticatedContext().firestore(), route)));
  assert.equal(snap.exists(), false);
  await assertFails(setDoc(doc(client('vendor'), route), review({vendorReply: {text: 'Resurrected'}})));
});

test('a legacy review can gain metadata without losing its existing owner reply', async () => {
  const old = Timestamp.fromMillis(1000000);
  await env.withSecurityRulesDisabled(async context => {
    const data = review({updatedAt: old}); delete data.createdAt; delete data.edited; delete data.customerAvatarUrl;
    await setDoc(doc(context.firestore(), route), data);
  });
  await assertSucceeds(updateDoc(doc(client('vendor'), route), {vendorReply: await reply()}));
  await assertSucceeds(updateDoc(doc(client('customer'), route), {
    createdAt: old, updatedAt: serverTimestamp(), edited: true, text: 'Edited legacy review', customerAvatarUrl: ''}));
  assert((await getDoc(doc(client('customer'), route))).data().vendorReply);
});
