'use strict';
const {before, after, beforeEach, test} = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {initializeTestEnvironment, assertFails, assertSucceeds} = require('@firebase/rules-unit-testing');
const {doc, collection, collectionGroup, setDoc, getDoc, getDocs, updateDoc, deleteDoc,
  serverTimestamp, deleteField} = require('firebase/firestore');
let env;
const client = (uid, verified = true) => env.authenticatedContext(uid, {
  email_verified: verified, firebase: {sign_in_provider: 'password'},
}).firestore();
const pin = (overrides = {}) => ({name: 'Home', address: 'Kuala Lumpur',
  latitude: 3.139, longitude: 101.6869, isHome: true,
  updatedAt: serverTimestamp(), ...overrides});
before(async () => {
  env = await initializeTestEnvironment({projectId: 'demo-stallseeker-saved-locations',
    firestore: {rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8')}});
});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    for (const [uid, role] of [['customer-a', 'customer'], ['customer-b', 'customer'], ['vendor-a', 'vendor']]) {
      await setDoc(doc(context.firestore(), 'users', uid), {uid, role});
    }
  });
});
after(async () => { if (env) await env.cleanup(); });
test('owner can read a missing home, save, list, move and remove own pins', async () => {
  const db = client('customer-a');
  const home = doc(db, 'users/customer-a/savedLocations/home');
  await assertSucceeds(getDoc(home));
  await assertSucceeds(setDoc(home, pin()));
  await assertSucceeds(setDoc(doc(db, 'users/customer-a/savedLocations/work'),
    pin({name: 'Work', isHome: false})));
  await assertSucceeds(getDocs(collection(db, 'users/customer-a/savedLocations')));
  await assertSucceeds(updateDoc(home, {latitude: 1.5, updatedAt: serverTimestamp()}));
  await assertSucceeds(deleteDoc(home));
});
test('saved locations are private to verified customers', async () => {
  await assertSucceeds(setDoc(doc(client('customer-a'), 'users/customer-a/savedLocations/home'), pin()));
  for (const db of [client('customer-b'), client('customer-a', false), env.unauthenticatedContext().firestore()]) {
    const ref = doc(db, 'users/customer-a/savedLocations/home');
    await assertFails(getDoc(ref));
    await assertFails(setDoc(ref, pin()));
    await assertFails(deleteDoc(ref));
    await assertFails(getDocs(collection(db, 'users/customer-a/savedLocations')));
  }
  await assertFails(setDoc(doc(client('vendor-a'), 'users/vendor-a/savedLocations/home'), pin()));
  await assertFails(setDoc(doc(client('missing-user'), 'users/missing-user/savedLocations/home'), pin()));
  await assertFails(getDocs(collectionGroup(client('customer-a'), 'savedLocations')));
});
test('create and update both validate coordinate ranges, schema, text and home identity', async () => {
  const db = client('customer-a');
  const ref = doc(db, 'users/customer-a/savedLocations/home');
  await assertSucceeds(setDoc(ref, pin()));
  for (const invalid of [{latitude: 91}, {longitude: -181}, {latitude: '3.1'},
    {name: ''}, {name: 'x'.repeat(61)}, {address: ''}, {address: 'x'.repeat(501)},
    {isHome: false}, {name: 'Fake home'}, {extra: true}, {updatedAt: new Date(2000, 0, 1)}]) {
    await assertFails(setDoc(ref, pin(invalid)));
    await assertFails(updateDoc(ref, {...invalid, ...(invalid.updatedAt ? {} : {updatedAt: serverTimestamp()})}));
  }
  await assertFails(updateDoc(ref, {address: deleteField(), updatedAt: serverTimestamp()}));
  await assertFails(setDoc(doc(db, 'users/customer-a/savedLocations/another-home'), pin()));
});
