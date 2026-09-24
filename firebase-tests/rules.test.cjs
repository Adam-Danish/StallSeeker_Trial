'use strict';

const {before, after, beforeEach, test} = require('node:test');
const fs = require('node:fs');
const path = require('node:path');
const {initializeTestEnvironment, assertFails, assertSucceeds} =
    require('@firebase/rules-unit-testing');
const {doc, setDoc, updateDoc, getDoc, serverTimestamp, writeBatch} =
    require('firebase/firestore');
const {ref, uploadBytes, deleteObject} = require('firebase/storage');

const root = path.join(__dirname, '..');
const projectId = 'demo-stallseeker-rules';
let env;

function client(uid, verified = true) {
  return env.authenticatedContext(uid, {
    email_verified: verified,
    firebase: {sign_in_provider: 'password'},
  });
}

function reviewData(uid, overrides = {}) {
  return {
    customerId: uid,
    customerName: 'Test Customer',
    rating: 5,
    text: 'Good food',
    photoUrls: [],
    updatedAt: serverTimestamp(),
    ...overrides,
  };
}

before(async () => {
  env = await initializeTestEnvironment({
    projectId,
    firestore: {rules: fs.readFileSync(path.join(root, 'firestore.rules'), 'utf8')},
    storage: {rules: fs.readFileSync(path.join(root, 'storage.rules'), 'utf8')},
  });
});

test('unverified accounts cannot publish stalls, menus, reviews or photos', async () => {
  const vendor = client('vendor-a', false).firestore();
  await assertSucceeds(setDoc(doc(vendor, 'vendors/vendor-a'),
      {vendorId: 'vendor-a', phoneNumber: '+60123456789', isOpen: false}));
  await assertFails(updateDoc(doc(vendor, 'vendors/vendor-a'), {isOpen: true}));
  await assertFails(setDoc(doc(vendor, 'vendors/vendor-a/menu/test'), {name: 'Burger'}));
  const customer = client('customer-a', false);
  await assertFails(setDoc(doc(customer.firestore(), 'stallReviews/vendor-a/entries/customer-a'), reviewData('customer-a')));
  await assertFails(setDoc(doc(customer.firestore(), 'follows/unverified'), {customerId: 'customer-a', vendorId: 'vendor-a'}));
  await assertFails(uploadBytes(ref(customer.storage(), 'review_images/vendor-a/customer-a/test.jpg'),
      new Uint8Array([1, 2, 3]), {contentType: 'image/jpeg'}));
  await assertFails(setDoc(doc(customer.firestore(), '_emailVerificationCodes/customer-a_registration'), {attempts: 0}));
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.clearStorage();
  await env.withSecurityRulesDisabled(async (context) => {
    for (const [uid, role] of [
      ['vendor-a', 'vendor'], ['vendor-b', 'vendor'],
      ['customer-a', 'customer'], ['customer-b', 'customer'],
    ]) {
      await setDoc(doc(context.firestore(), 'users', uid),
          {uid, role, fullName: uid});
    }
  });
});

after(async () => { if (env) await env.cleanup(); });

test('vendor documents and menu are writable only by the owning vendor', async () => {
  const owner = client('vendor-a').firestore();
  const other = client('vendor-b').firestore();
  const customer = client('customer-a').firestore();
  const guest = env.unauthenticatedContext().firestore();
  const vendorPath = 'vendors/vendor-a';
  await assertSucceeds(setDoc(doc(owner, vendorPath),
      {vendorId: 'vendor-a', stallName: 'Test Stall', isOpen: false}));
  await assertSucceeds(setDoc(doc(owner, vendorPath),
      {phoneNumber: '+60123456789'}, {merge: true}));
  await assertFails(setDoc(doc(other, vendorPath), {stallName: 'Hijacked'}));
  await assertFails(setDoc(doc(customer, vendorPath), {stallName: 'Hijacked'}));
  await assertFails(setDoc(doc(guest, vendorPath), {stallName: 'Hijacked'}));
  await assertSucceeds(setDoc(doc(owner, `${vendorPath}/menu/dish-1`),
      {name: 'Nasi', price: 5}));
  await assertSucceeds(updateDoc(doc(owner, `${vendorPath}/menu/dish-1`),
      {status: 'low_stock'}));
  await assertFails(setDoc(doc(other, `${vendorPath}/menu/dish-1`),
      {name: 'Changed', price: 1}));
  await assertFails(setDoc(doc(guest, `${vendorPath}/menu/dish-1`),
      {name: 'Changed', price: 1}));
  await assertSucceeds(getDoc(doc(guest, vendorPath)));
});

test('vendor signup can create user and stall in one batch', async () => {
  const vendor = client('new-vendor').firestore();
  const batch = writeBatch(vendor);
  batch.set(doc(vendor, 'users/new-vendor'),
      {uid: 'new-vendor', role: 'vendor', fullName: 'New Vendor'});
  batch.set(doc(vendor, 'vendors/new-vendor'),
      {vendorId: 'new-vendor', phoneNumber: '+60123456789', isOpen: false});
  await assertSucceeds(batch.commit());

  const customer = client('customer-a').firestore();
  await assertFails(setDoc(doc(customer, 'vendors/customer-a'),
      {vendorId: 'customer-a', stallName: 'Fake vendor'}));
});

test('profile role cannot change after account creation', async () => {
  const customer = client('customer-a').firestore();
  await assertSucceeds(updateDoc(doc(customer, 'users/customer-a'),
      {fullName: 'New Name'}));
  await assertFails(updateDoc(doc(customer, 'users/customer-a'),
      {role: 'vendor'}));
});

test('reviews require customer ownership, valid stars and at most five photos', async () => {
  const owner = client('customer-a').firestore();
  const other = client('customer-b').firestore();
  const vendor = client('vendor-a').firestore();
  const guest = env.unauthenticatedContext().firestore();
  const reviewPath = 'stallReviews/vendor-a/entries/customer-a';
  await assertSucceeds(setDoc(doc(owner, reviewPath),
      reviewData('customer-a')));
  await assertFails(setDoc(doc(other, reviewPath),
      reviewData('customer-a')));
  await assertFails(setDoc(doc(vendor, reviewPath),
      reviewData('customer-a')));
  await assertFails(setDoc(doc(guest, reviewPath),
      reviewData('customer-a')));
  await assertFails(setDoc(doc(owner, reviewPath),
      reviewData('customer-a', {rating: 0})));
  await assertFails(setDoc(doc(owner, reviewPath),
      reviewData('customer-a', {rating: 6})));
  await assertFails(setDoc(doc(owner, reviewPath),
      reviewData('customer-a', {photoUrls: Array(6).fill('x')})));
  await assertFails(setDoc(doc(owner, reviewPath),
      reviewData('customer-a', {photoUrls: [123]})));
  await assertFails(setDoc(doc(owner, reviewPath),
      reviewData('customer-a', {updatedAt: new Date('2100-01-01')})));
});

test('review photo writes require owner, image type and size limit', async () => {
  const bucket = `gs://${projectId}.appspot.com`;
  const owner = client('customer-a').storage(bucket);
  const other = client('customer-b').storage(bucket);
  const guest = env.unauthenticatedContext().storage(bucket);
  const photoPath = 'review_images/vendor-a/customer-a/photo.jpg';
  const bytes = new Uint8Array([1, 2, 3]);
  await assertSucceeds(uploadBytes(ref(owner, photoPath), bytes,
      {contentType: 'image/jpeg'}));
  await assertFails(uploadBytes(ref(other, photoPath), bytes,
      {contentType: 'image/jpeg'}));
  await assertFails(uploadBytes(ref(guest, photoPath), bytes,
      {contentType: 'image/jpeg'}));
  await assertFails(uploadBytes(ref(owner, photoPath), bytes,
      {contentType: 'text/plain'}));
  await assertFails(uploadBytes(ref(owner,
      'review_images/vendor-a/customer-a/too-large.jpg'),
  new Uint8Array(5 * 1024 * 1024), {contentType: 'image/jpeg'}));
  await assertFails(deleteObject(ref(other, photoPath)));
  await assertSucceeds(deleteObject(ref(owner, photoPath)));
});
