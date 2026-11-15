'use strict';

const {before, beforeEach, after, test} = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const {initializeTestEnvironment, assertFails, assertSucceeds} =
  require('@firebase/rules-unit-testing');
const {doc, collection, query, where, getDoc, getDocs, setDoc, updateDoc,
  deleteDoc, deleteField, serverTimestamp, Timestamp} =
  require('firebase/firestore');

let env;
const client = (uid, verified = true, anonymous = false) =>
  env.authenticatedContext(uid, {
    email_verified: verified,
    firebase: {sign_in_provider: anonymous ? 'anonymous' : 'password'},
  }).firestore();

const payoutDetails = (vendorId = 'vendor-a', overrides = {}) => ({
  vendorId,
  bankName: 'Maybank',
  accountHolderName: 'Aina Enterprise',
  accountNumber: '123456789012',
  duitNowId: '0123456789',
  notes: 'Primary business account',
  updatedAt: serverTimestamp(),
  ...overrides,
});

const pendingPayout = (vendorId = 'vendor-a', overrides = {}) => ({
  vendorId,
  stallName: 'Burger Pak Ali',
  amountCents: 12550,
  status: 'pending',
  bankName: 'Maybank',
  accountHolderName: 'Aina Enterprise',
  accountNumber: '123456789012',
  duitNowId: '0123456789',
  vendorNote: 'Weekly payout',
  requestedBy: vendorId,
  requestedAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  ...overrides,
});

const directPaidPayout = (
  adminUid = 'admin-a',
  vendorId = 'vendor-a',
  overrides = {},
) => ({
  vendorId,
  stallName: 'Burger Pak Ali',
  amountCents: 25000,
  status: 'paid',
  bankName: 'Maybank',
  accountHolderName: 'Aina Enterprise',
  accountNumber: '123456789012',
  duitNowId: '',
  vendorNote: '',
  transferReference: 'MBB-20261115-001',
  adminNote: 'Direct monthly settlement',
  requestedBy: adminUid,
  requestedAt: serverTimestamp(),
  settledByUid: adminUid,
  settledByEmail: 'admin@stallseeker.test',
  settledAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  ...overrides,
});

before(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-stallseeker-vendor-payouts',
    firestore: {
      rules: fs.readFileSync(
        path.join(__dirname, '..', 'firestore.rules'),
        'utf8',
      ),
    },
  });
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    for (const [uid, role] of [
      ['vendor-a', 'vendor'],
      ['vendor-b', 'vendor'],
      ['customer-a', 'customer'],
      ['admin-a', 'admin'],
    ]) {
      await setDoc(doc(db, 'users', uid), {uid, role});
    }
  });
});

after(async () => {
  if (env) await env.cleanup();
});

test('owning verified vendor can read and write own vendorPayoutDetails', async () => {
  const vendor = client('vendor-a');
  const ref = doc(vendor, 'vendorPayoutDetails/vendor-a');

  const missing = await assertSucceeds(getDoc(ref));
  assert.equal(missing.exists(), false);

  await assertSucceeds(setDoc(ref, payoutDetails('vendor-a')));
  const saved = await assertSucceeds(getDoc(ref));
  assert.equal(saved.data().bankName, 'Maybank');

  await assertSucceeds(setDoc(ref, payoutDetails('vendor-a', {
    bankName: 'CIMB Bank',
    accountNumber: '8001234567',
  })));
  await assertSucceeds(updateDoc(ref, {
    notes: 'Updated payout account',
    updatedAt: serverTimestamp(),
  }));

  // Minimal payload without optional duitNowId or notes also succeeds.
  const minimal = payoutDetails('vendor-a');
  delete minimal.duitNowId;
  delete minimal.notes;
  await assertSucceeds(setDoc(ref, minimal));
});

test('vendorPayoutDetails blocks unauthenticated, unverified, customer, anonymous, deleted and other vendors', async () => {
  await assertSucceeds(setDoc(
    doc(client('vendor-a'), 'vendorPayoutDetails/vendor-a'),
    payoutDetails('vendor-a'),
  ));

  const guest = env.unauthenticatedContext().firestore();
  const unverifiedVendor = client('vendor-a', false);
  const anon = client('vendor-a', true, true);
  const customer = client('customer-a');
  const otherVendor = client('vendor-b');

  for (const db of [guest, unverifiedVendor, anon, customer, otherVendor]) {
    const ref = doc(db, 'vendorPayoutDetails/vendor-a');
    await assertFails(getDoc(ref));
    await assertFails(getDocs(collection(db, 'vendorPayoutDetails')));
    await assertFails(setDoc(ref, payoutDetails('vendor-a')));
    await assertFails(updateDoc(ref, {bankName: 'Hijacked', updatedAt: serverTimestamp()}));
    await assertFails(deleteDoc(ref));
  }

  // Vendors cannot list the collection or delete their own bank details.
  await assertFails(getDocs(collection(client('vendor-a'), 'vendorPayoutDetails')));
  await assertFails(deleteDoc(doc(client('vendor-a'), 'vendorPayoutDetails/vendor-a')));

  // Pending-deletion vendor cannot read or write own payout details.
  await env.withSecurityRulesDisabled(async (context) => {
    await setDoc(doc(context.firestore(), '_accountDeletions/vendor-a'), {
      requestedAt: Timestamp.now(),
    });
  });
  await assertFails(getDoc(doc(client('vendor-a'), 'vendorPayoutDetails/vendor-a')));
  await assertFails(updateDoc(doc(client('vendor-a'), 'vendorPayoutDetails/vendor-a'), {
    bankName: 'RHB Bank',
    updatedAt: serverTimestamp(),
  }));
});

test('admin can get and list vendorPayoutDetails but cannot create, update or delete them', async () => {
  await assertSucceeds(setDoc(
    doc(client('vendor-a'), 'vendorPayoutDetails/vendor-a'),
    payoutDetails('vendor-a'),
  ));
  await assertSucceeds(setDoc(
    doc(client('vendor-b'), 'vendorPayoutDetails/vendor-b'),
    payoutDetails('vendor-b', {bankName: 'Public Bank'}),
  ));

  const admin = client('admin-a');
  const existingAdmin = client('admin-a', false);
  for (const db of [admin, existingAdmin]) {
    const single = await assertSucceeds(getDoc(doc(db, 'vendorPayoutDetails/vendor-a')));
    assert.equal(single.data().accountNumber, '123456789012');
    const all = await assertSucceeds(getDocs(collection(db, 'vendorPayoutDetails')));
    assert.equal(all.size, 2);

    await assertFails(setDoc(
      doc(db, 'vendorPayoutDetails/vendor-c'),
      payoutDetails('vendor-c'),
    ));
    await assertFails(updateDoc(
      doc(db, 'vendorPayoutDetails/vendor-a'),
      {accountNumber: '99999999', updatedAt: serverTimestamp()},
    ));
    await assertFails(deleteDoc(doc(db, 'vendorPayoutDetails/vendor-a')));
  }
});

test('vendorPayoutDetails rejects invalid account numbers, blank names, mismatched vendorId, bad timestamps and extra fields', async () => {
  const vendor = client('vendor-a');
  const ref = doc(vendor, 'vendorPayoutDetails/vendor-a');

  const invalidPayloads = [
    {accountNumber: '12345'},
    {accountNumber: '1'.repeat(25)},
    {accountNumber: '1234-5678'},
    {accountNumber: '123456abc'},
    {accountNumber: 12345678},
    {bankName: ''},
    {bankName: '   '},
    {bankName: ' a '},
    {bankName: 'x'.repeat(81)},
    {accountHolderName: ''},
    {accountHolderName: '  '},
    {accountHolderName: ' a '},
    {accountHolderName: 'x'.repeat(121)},
    {vendorId: 'vendor-b'},
    {duitNowId: 'x'.repeat(65)},
    {notes: 'x'.repeat(201)},
    {updatedAt: Timestamp.now()},
    {extraField: 'malicious'},
  ];

  for (const invalid of invalidPayloads) {
    await assertFails(setDoc(ref, payoutDetails('vendor-a', invalid)));
  }

  // Create a valid doc, then verify update enforces the same validation and immutable vendorId.
  await assertSucceeds(setDoc(ref, payoutDetails('vendor-a')));
  for (const invalid of invalidPayloads) {
    await assertFails(updateDoc(ref, {
      ...invalid,
      ...(invalid.updatedAt ? {} : {updatedAt: serverTimestamp()}),
    }));
  }
  await assertFails(updateDoc(ref, {
    accountNumber: deleteField(),
    updatedAt: serverTimestamp(),
  }));
});

test('vendor can create pending payout request and query own vendorPayouts', async () => {
  const vendor = client('vendor-a');
  await assertSucceeds(setDoc(
    doc(vendor, 'vendorPayouts/payout-1'),
    pendingPayout('vendor-a'),
  ));

  // Optional fields omitted should also succeed.
  const minimal = pendingPayout('vendor-a');
  delete minimal.stallName;
  delete minimal.duitNowId;
  delete minimal.vendorNote;
  await assertSucceeds(setDoc(doc(vendor, 'vendorPayouts/payout-2'), minimal));

  const fetched = await assertSucceeds(getDoc(doc(vendor, 'vendorPayouts/payout-1')));
  assert.equal(fetched.data().status, 'pending');

  const ownQuery = query(
    collection(vendor, 'vendorPayouts'),
    where('vendorId', '==', 'vendor-a'),
  );
  const results = await assertSucceeds(getDocs(ownQuery));
  assert.equal(results.size, 2);
});

test('vendor cannot forge payout status, settlement fields, vendorId, amount or update/delete vendorPayouts', async () => {
  const vendor = client('vendor-a');
  await assertSucceeds(setDoc(
    doc(vendor, 'vendorPayouts/payout-1'),
    pendingPayout('vendor-a'),
  ));

  const forbiddenCreates = [
    {status: 'paid'},
    {status: 'rejected'},
    {settledAt: serverTimestamp()},
    {transferReference: 'FORGED-REF'},
    {settledByUid: 'vendor-a'},
    {settledByEmail: 'vendor@stallseeker.test'},
    {adminNote: 'Self-approved'},
    {vendorId: 'vendor-b'},
    {requestedBy: 'vendor-b'},
    {amountCents: 99},
    {amountCents: 0},
    {amountCents: -500},
    {amountCents: 50000001},
    {amountCents: 100.5},
    {amountCents: '1000'},
    {requestedAt: Timestamp.now()},
    {updatedAt: Timestamp.now()},
    {accountNumber: 'abc123'},
    {bankName: '   '},
    {accountHolderName: ' a '},
    {stallName: 'x'.repeat(161)},
    {duitNowId: 'x'.repeat(65)},
    {vendorNote: 'x'.repeat(241)},
    {unexpected: true},
  ];

  for (let i = 0; i < forbiddenCreates.length; i++) {
    await assertFails(setDoc(
      doc(vendor, `vendorPayouts/forged-${i}`),
      pendingPayout('vendor-a', forbiddenCreates[i]),
    ));
  }

  // Vendor cannot update or delete an existing payout.
  await assertFails(updateDoc(doc(vendor, 'vendorPayouts/payout-1'), {
    amountCents: 50000,
    updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(vendor, 'vendorPayouts/payout-1'), {
    status: 'paid',
    transferReference: 'MBB-123',
    settledByUid: 'vendor-a',
    settledAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
  await assertFails(deleteDoc(doc(vendor, 'vendorPayouts/payout-1')));
});

test('vendorPayouts blocks unauthenticated, unverified, anonymous, customer and cross-vendor reads and creates', async () => {
  await assertSucceeds(setDoc(
    doc(client('vendor-a'), 'vendorPayouts/payout-a'),
    pendingPayout('vendor-a'),
  ));

  const guest = env.unauthenticatedContext().firestore();
  const unverifiedVendor = client('vendor-a', false);
  const anon = client('vendor-a', true, true);
  const customer = client('customer-a');
  const otherVendor = client('vendor-b');

  for (const db of [guest, unverifiedVendor, anon, customer, otherVendor]) {
    await assertFails(getDoc(doc(db, 'vendorPayouts/payout-a')));
    await assertFails(getDocs(collection(db, 'vendorPayouts')));
    await assertFails(getDocs(query(
      collection(db, 'vendorPayouts'),
      where('vendorId', '==', 'vendor-a'),
    )));
  }

  // Customer cannot even query for their own UID or create a payout request.
  await assertFails(getDocs(query(
    collection(customer, 'vendorPayouts'),
    where('vendorId', '==', 'customer-a'),
  )));
  await assertFails(setDoc(
    doc(customer, 'vendorPayouts/customer-forged'),
    pendingPayout('customer-a'),
  ));

  // Unverified vendor and anonymous context cannot create payouts.
  await assertFails(setDoc(
    doc(unverifiedVendor, 'vendorPayouts/unverified-forged'),
    pendingPayout('vendor-a'),
  ));
  await assertFails(setDoc(
    doc(anon, 'vendorPayouts/anon-forged'),
    pendingPayout('vendor-a'),
  ));

  // Owning verified vendor cannot run an unfiltered list query.
  await assertFails(getDocs(collection(client('vendor-a'), 'vendorPayouts')));
});

test('admin can list, settle pending -> paid, reject pending -> rejected, and create direct paid payouts', async () => {
  const vendor = client('vendor-a');
  const admin = client('admin-a');

  await assertSucceeds(setDoc(
    doc(vendor, 'vendorPayouts/payout-settle'),
    pendingPayout('vendor-a'),
  ));
  await assertSucceeds(setDoc(
    doc(vendor, 'vendorPayouts/payout-reject-1'),
    pendingPayout('vendor-a'),
  ));
  await assertSucceeds(setDoc(
    doc(vendor, 'vendorPayouts/payout-reject-2'),
    pendingPayout('vendor-a'),
  ));

  // Settle pending -> paid.
  await assertSucceeds(updateDoc(doc(admin, 'vendorPayouts/payout-settle'), {
    status: 'paid',
    transferReference: 'MBB-20261115-888',
    adminNote: 'Transferred via DuitNow',
    settledByUid: 'admin-a',
    settledByEmail: 'admin@stallseeker.test',
    settledAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));

  // Reject pending -> rejected (omitted transferReference).
  await assertSucceeds(updateDoc(doc(admin, 'vendorPayouts/payout-reject-1'), {
    status: 'rejected',
    adminNote: 'Account holder name mismatch',
    settledByUid: 'admin-a',
    settledByEmail: 'admin@stallseeker.test',
    settledAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));

  // Reject pending -> rejected (explicit empty transferReference).
  await assertSucceeds(updateDoc(doc(admin, 'vendorPayouts/payout-reject-2'), {
    status: 'rejected',
    transferReference: '',
    adminNote: 'Please re-enter bank account number',
    settledByUid: 'admin-a',
    settledAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));

  // Admin creates a direct paid payout without a pending request.
  await assertSucceeds(setDoc(
    doc(admin, 'vendorPayouts/payout-direct'),
    directPaidPayout('admin-a', 'vendor-a'),
  ));

  // Admin can list all payouts and vendor can read the direct paid payout.
  const allPayouts = await assertSucceeds(getDocs(collection(admin, 'vendorPayouts')));
  assert.equal(allPayouts.size, 4);
  const directForVendor = await assertSucceeds(getDoc(doc(vendor, 'vendorPayouts/payout-direct')));
  assert.equal(directForVendor.data().status, 'paid');
});

test('admin payout validation blocks terminal mutations, field tampering and invalid settlements', async () => {
  const vendor = client('vendor-a');
  const admin = client('admin-a');

  await assertSucceeds(setDoc(
    doc(vendor, 'vendorPayouts/payout-pending'),
    pendingPayout('vendor-a'),
  ));
  await assertSucceeds(setDoc(
    doc(vendor, 'vendorPayouts/payout-paid'),
    pendingPayout('vendor-a'),
  ));
  await assertSucceeds(setDoc(
    doc(vendor, 'vendorPayouts/payout-rejected'),
    pendingPayout('vendor-a'),
  ));

  await assertSucceeds(updateDoc(doc(admin, 'vendorPayouts/payout-paid'), {
    status: 'paid',
    transferReference: 'MBB-20261115-999',
    settledByUid: 'admin-a',
    settledAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
  await assertSucceeds(updateDoc(doc(admin, 'vendorPayouts/payout-rejected'), {
    status: 'rejected',
    adminNote: 'Bank details invalid',
    settledByUid: 'admin-a',
    settledAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));

  // Cannot update once no longer pending.
  await assertFails(updateDoc(doc(admin, 'vendorPayouts/payout-paid'), {
    status: 'rejected',
    adminNote: 'Reversing paid payout',
    transferReference: '',
    settledByUid: 'admin-a',
    settledAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(admin, 'vendorPayouts/payout-rejected'), {
    status: 'paid',
    transferReference: 'MBB-20261115-RETRY',
    settledByUid: 'admin-a',
    settledAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));

  // Cannot mutate immutable snapshot fields during settlement.
  const settleBase = {
    status: 'paid',
    transferReference: 'MBB-20261115-777',
    settledByUid: 'admin-a',
    settledAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  };
  for (const tampered of [
    {amountCents: 99999},
    {vendorId: 'vendor-b'},
    {accountNumber: '999988887777'},
    {bankName: 'Public Bank'},
    {accountHolderName: 'Tampered Name'},
    {requestedBy: 'admin-a'},
    {requestedAt: Timestamp.fromMillis(1000000)},
    {status: 'pending'},
    {transferReference: ' '},
    {transferReference: 'x'},
    {transferReference: 'x'.repeat(121)},
    {settledByUid: 'other-admin'},
    {settledAt: Timestamp.now()},
    {updatedAt: Timestamp.now()},
    {extraField: 'hack'},
  ]) {
    await assertFails(updateDoc(doc(admin, 'vendorPayouts/payout-pending'), {
      ...settleBase,
      ...tampered,
    }));
  }

  // Cannot settle to paid without transferReference.
  await assertFails(updateDoc(doc(admin, 'vendorPayouts/payout-pending'), {
    status: 'paid',
    settledByUid: 'admin-a',
    settledAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));

  // Cannot reject without valid adminNote or with a non-empty transferReference.
  await assertFails(updateDoc(doc(admin, 'vendorPayouts/payout-pending'), {
    status: 'rejected',
    settledByUid: 'admin-a',
    settledAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(admin, 'vendorPayouts/payout-pending'), {
    status: 'rejected',
    adminNote: ' ',
    settledByUid: 'admin-a',
    settledAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));
  await assertFails(updateDoc(doc(admin, 'vendorPayouts/payout-pending'), {
    status: 'rejected',
    adminNote: 'Valid reason',
    transferReference: 'FORGED-REF',
    settledByUid: 'admin-a',
    settledAt: serverTimestamp(),
    updatedAt: serverTimestamp(),
  }));

  // Admin cannot create pending or rejected directly, or create direct paid with bad data.
  await assertFails(setDoc(
    doc(admin, 'vendorPayouts/admin-pending'),
    pendingPayout('vendor-a', {requestedBy: 'admin-a'}),
  ));
  await assertFails(setDoc(
    doc(admin, 'vendorPayouts/admin-rejected'),
    directPaidPayout('admin-a', 'vendor-a', {status: 'rejected'}),
  ));
  await assertFails(setDoc(
    doc(admin, 'vendorPayouts/admin-bad-ref'),
    directPaidPayout('admin-a', 'vendor-a', {transferReference: ' '}),
  ));
  await assertFails(setDoc(
    doc(admin, 'vendorPayouts/admin-bad-uid'),
    directPaidPayout('admin-a', 'vendor-a', {settledByUid: 'other-admin'}),
  ));

  // Admin cannot delete payout records.
  await assertFails(deleteDoc(doc(admin, 'vendorPayouts/payout-paid')));
});
