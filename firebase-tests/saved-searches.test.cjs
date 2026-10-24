'use strict';
const {before, after, beforeEach, test} = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {initializeTestEnvironment, assertFails, assertSucceeds} = require('@firebase/rules-unit-testing');
const {doc, collection, setDoc, getDoc, getDocs, updateDoc, deleteDoc, serverTimestamp} = require('firebase/firestore');
let env;
const client = (uid, verified = true, anonymous = false) => env.authenticatedContext(uid, {
  email_verified: verified, firebase: {sign_in_provider: anonymous ? 'anonymous' : 'password'},
}).firestore();
const filters = (overrides = {}) => ({query: 'burgers', category: 'Burger',
  minimum: null, maximum: 10, radius: 5, status: 'Open', sort: 'price',
  availableOnly: true, selfCollectOnly: false, recentOnly: false, listOnly: true,
  latitude: 3.139, longitude: 101.6869, openingStart: null, openingEnd: null,
  openingLabel: null, ...overrides});
const search = (extra = {}) => ({name: 'Burgers under RM10', filters: filters(),
  savedAt: serverTimestamp(), ...extra});
before(async () => {
  env = await initializeTestEnvironment({projectId: 'demo-stallseeker-saved-searches',
    firestore: {rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8')}});
});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async context => {
    for (const [uid, role] of [['a', 'customer'], ['b', 'customer'], ['v', 'vendor']]) {
      await setDoc(doc(context.firestore(), 'users', uid), {uid, role});
    }
  });
});
after(async () => { if (env) await env.cleanup(); });

test('a customer can save, restore, rename and delete their own search', async () => {
  const db = client('a');
  const ref = doc(db, 'users/a/savedSearches/burgers');
  await assertSucceeds(setDoc(ref, search()));
  await assertSucceeds(getDoc(ref));
  await assertSucceeds(getDocs(collection(db, 'users/a/savedSearches')));
  await assertSucceeds(updateDoc(ref, {name: 'Lunch', savedAt: serverTimestamp()}));
  await assertSucceeds(deleteDoc(ref));
});
test('signed-out, guest, unverified, vendor and other accounts cannot access saved searches', async () => {
  await assertSucceeds(setDoc(doc(client('a'), 'users/a/savedSearches/burgers'), search()));
  for (const db of [client('b'), client('a', false), client('a', true, true),
    env.unauthenticatedContext().firestore()]) {
    const ref = doc(db, 'users/a/savedSearches/burgers');
    await assertFails(getDoc(ref));
    await assertFails(setDoc(ref, search()));
    await assertFails(deleteDoc(ref));
    await assertFails(getDocs(collection(db, 'users/a/savedSearches')));
  }
  await assertFails(setDoc(doc(client('v'), 'users/v/savedSearches/burgers'), search()));
});
test('both create and update validate the saved combination', async () => {
  const db = client('a');
  const ref = doc(db, 'users/a/savedSearches/burgers');
  await assertSucceeds(setDoc(ref, search()));
  for (const invalid of [{query: 'x'.repeat(101)}, {radius: -1}, {sort: 'bad'},
    {minimum: 15, maximum: 10}, {availableOnly: 'true'}, {latitude: 95},
    {longitude: null}, {openingStart: 1000, openingEnd: 999, openingLabel: 'Bad'},
    {extra: true}]) {
    await assertFails(setDoc(doc(db, 'users/a/savedSearches/new'), search({filters: filters(invalid)})));
    await assertFails(updateDoc(ref, {filters: filters(invalid), savedAt: serverTimestamp()}));
  }
});
