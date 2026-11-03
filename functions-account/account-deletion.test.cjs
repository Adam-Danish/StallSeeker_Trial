'use strict';

const {test} = require('node:test');
const assert = require('node:assert/strict');
const {createAccountDeletionService} = require('./account-deletion.cjs');

function fixture() {
  const documents = new Map([
    ['users/old', {role: 'customer'}],
    ['vendors/old', {vendorId: 'old'}],
    ['follows/one', {customerId: 'old', vendorId: 'other'}],
    ['follows/two', {customerId: 'other', vendorId: 'old'}],
    ['users/other/dishFollows/old:item', {vendorId: 'old'}],
    ['bookings/one', {customerId: 'old', vendorId: 'other'}],
    ['stallReviews/other/entries/old', {customerId: 'old'}],
    ['users/old/savedLocations/home', {name: 'Home'}],
    ['users/unrelated', {role: 'customer'}],
  ]);
  const identities = new Map([['old', 'reusable@example.com']]);
  const files = new Set(['stall_images/old.jpg', 'menu_images/old/item.jpg',
    'review_images/other/old/photo.jpg', 'review_images/other/unrelated/photo.jpg']);
  let storageFailure = false;
  let queryFailure = false;
  let authFailure = false;
  const ref = (path) => ({
    path,
    parent: {parent: {id: path.split('/').at(-3)}},
    async create(data) {
      if (documents.has(path)) throw Object.assign(new Error('exists'), {code: 6});
      documents.set(path, data);
    },
    async update(data) { documents.set(path, {...documents.get(path), ...data}); },
    async delete() { documents.delete(path); },
  });
  const query = (collection, group = false) => ({
    where(field, op, value) {
      assert.equal(op, '==');
      return {async get() {
        if (queryFailure) throw new Error('index unavailable');
        return {docs: [...documents].filter(([path, data]) =>
          (group ? path.split('/').at(-2) === collection :
            path.split('/').length === 2 && path.startsWith(`${collection}/`)) &&
          data[field] === value).map(([path]) => ({ref: ref(path)}))};
      }};
    },
    doc(id) { return ref(`${collection}/${id}`); },
  });
  const service = createAccountDeletionService({
    db: {
      collection: (name) => query(name),
      collectionGroup: (name) => query(name, true), doc: ref,
      async recursiveDelete(reference) {
        for (const path of documents.keys()) {
          if (path === reference.path || path.startsWith(`${reference.path}/`)) documents.delete(path);
        }
      },
    },
    auth: {async deleteUser(uid) {
      if (authFailure) throw new Error('auth unavailable');
      if (!identities.delete(uid)) throw Object.assign(new Error('missing'), {code: 'auth/user-not-found'});
    }},
    bucket: {
      file: (path) => ({async delete() { files.delete(path); }}),
      async deleteFiles({prefix}) {
        if (storageFailure) throw new Error('storage unavailable');
        for (const path of files) if (path.startsWith(prefix)) files.delete(path);
      },
    }, timestamp: () => 'timestamp',
  });
  return {service, documents, identities, files,
    failStorage: (value) => { storageFailure = value; },
    failQueries: (value) => { queryFailure = value; },
    failAuth: (value) => { authFailure = value; },
  };
}

test('deletion removes identity and profile even when indexed cleanup queries fail', async () => {
  const f = fixture();
  await f.service.requestDeletion('old');
  f.failQueries(true);
  await assert.rejects(f.service.finishDeletion('old'), /index unavailable/);
  assert.equal(f.identities.has('old'), false);
  assert.equal(f.documents.has('users/old'), false);
  assert.equal(f.documents.has('_accountDeletions/old'), true);
  f.failQueries(false);
  await f.service.finishDeletion('old');
  assert.ok(f.documents.get('_accountDeletions/old').completedAt);
});

test('photo failures retain review paths for a complete retry', async () => {
  const f = fixture();
  await f.service.requestDeletion('old');
  f.failStorage(true);
  await assert.rejects(f.service.finishDeletion('old'), /storage unavailable/);
  assert.equal(f.identities.size, 0);
  assert.ok(f.documents.has('stallReviews/other/entries/old'));
  f.failStorage(false);
  await f.service.finishDeletion('old');
  assert.deepEqual([...f.files], ['review_images/other/unrelated/photo.jpg']);
  assert.deepEqual([...f.documents.keys()].sort(), ['_accountDeletions/old', 'users/unrelated']);
});

test('duplicate deletion events and retries never touch a new account reusing the email', async () => {
  const f = fixture();
  await f.service.requestDeletion('old');
  await f.service.deleteIdentity('old');
  assert.equal([...f.identities.values()].includes('reusable@example.com'), false);
  f.identities.set('new', 'reusable@example.com');
  f.documents.set('users/new', {role: 'vendor'});
  await f.service.requestDeletion('old');
  await f.service.finishDeletion('old');
  await f.service.finishDeletion('old');
  assert.equal(f.identities.get('new'), 'reusable@example.com');
  assert.deepEqual(f.documents.get('users/new'), {role: 'vendor'});
});

test('an auth outage leaves a durable job and never reports cleanup complete', async () => {
  const f = fixture();
  await f.service.requestDeletion('old');
  f.failAuth(true);
  await assert.rejects(f.service.finishDeletion('old'), /auth unavailable/);
  assert.equal(f.documents.get('_accountDeletions/old').completedAt, undefined);
  assert.equal(f.identities.has('old'), true);
  f.failAuth(false);
  await f.service.finishDeletion('old');
  assert.equal(f.identities.has('old'), false);
});
