'use strict';

const {before, beforeEach, after, test} = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {initializeTestEnvironment, assertFails, assertSucceeds} =
  require('@firebase/rules-unit-testing');
const {doc, collection, query, where, getDoc, getDocs, setDoc, updateDoc,
  deleteDoc, Timestamp} = require('firebase/firestore');

let env;
const client = (uid, verified = true) => env.authenticatedContext(uid, {
  email_verified: verified, firebase: {sign_in_provider: 'password'},
}).firestore();

before(async () => {
  env = await initializeTestEnvironment({projectId: 'demo-stallseeker-bookings',
    firestore: {rules: fs.readFileSync(path.join(__dirname, '..', 'firestore.rules'), 'utf8')}});
});
beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'users/customer-a'), {role: 'customer'});
    await setDoc(doc(db, 'users/customer-b'), {role: 'customer'});
    await setDoc(doc(db, 'users/vendor-a'), {role: 'vendor'});
    await setDoc(doc(db, 'vendors/vendor-a'),
      {vendorId: 'vendor-a', selfCollectEnabled: false, isOpen: true});
    await setDoc(doc(db, 'bookings/booking-a'), {
      customerId: 'customer-a', vendorId: 'vendor-a', status: 'requested',
      vendorUnseenRequest: true, customerUnseenReady: false,
      createdAt: Timestamp.now(),
    });
  });
});
after(async () => { if (env) await env.cleanup(); });

test('only participants can read live bookings and participant queries', async () => {
  const customer = client('customer-a');
  const vendor = client('vendor-a');
  const other = client('customer-b');
  const ref = 'bookings/booking-a';
  await assertSucceeds(getDoc(doc(customer, ref)));
  await assertSucceeds(getDoc(doc(vendor, ref)));
  await assertSucceeds(getDocs(query(collection(customer, 'bookings'),
    where('customerId', '==', 'customer-a'))));
  await assertSucceeds(getDocs(query(collection(vendor, 'bookings'),
    where('vendorId', '==', 'vendor-a'))));
  await assertFails(getDoc(doc(other, ref)));
  await assertFails(getDoc(doc(client('customer-a', false), ref)));
  await assertFails(getDoc(doc(env.unauthenticatedContext().firestore(), ref)));
  await assertFails(getDocs(collection(other, 'bookings')));
});

test('clients cannot forge prices, progress, or seen flags', async () => {
  const customer = client('customer-a');
  const vendor = client('vendor-a');
  const ref = 'bookings/booking-a';
  await assertFails(setDoc(doc(customer, 'bookings/forged'),
    {customerId: 'customer-a', status: 'ready'}));
  await assertFails(updateDoc(doc(customer, ref), {status: 'ready'}));
  await assertFails(updateDoc(doc(vendor, ref), {vendorUnseenRequest: false}));
  await assertFails(deleteDoc(doc(vendor, ref)));
});

test('vendor booking opt-in defaults off and accepts only owner boolean writes', async () => {
  const vendor = client('vendor-a');
  const other = client('customer-a');
  const ref = 'vendors/vendor-a';
  await assertSucceeds(updateDoc(doc(vendor, ref), {selfCollectEnabled: true}));
  await assertSucceeds(updateDoc(doc(vendor, ref), {selfCollectEnabled: false}));
  await assertFails(updateDoc(doc(vendor, ref), {selfCollectEnabled: 'yes'}));
  await assertFails(updateDoc(doc(other, ref), {selfCollectEnabled: true}));
});
