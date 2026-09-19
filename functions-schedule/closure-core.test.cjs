'use strict';

const {test} = require('node:test');
const assert = require('node:assert/strict');
const {isActiveClosure, closeScheduledStalls} = require('./closure-core.cjs');

const timestamp = (millis) => ({toMillis: () => millis});
const closure = (start, end) => ({
  startAt: timestamp(start), endAt: timestamp(end),
});

function fakeDb(docs) {
  const committed = [];
  return {
    committed,
    collection(name) {
      assert.equal(name, 'vendors');
      return {where(field, op, value) {
        assert.deepEqual([field, op, value], ['isOpen', '==', true]);
        return {get: async () => ({docs})};
      }};
    },
    batch() {
      const writes = [];
      return {
        update(ref, data) { writes.push({ref, data}); },
        async commit() { committed.push(writes); },
      };
    },
  };
}

test('closure includes its start and excludes its end', () => {
  const ranges = [closure(1000, 2000)];
  assert.equal(isActiveClosure(ranges, 999), false);
  assert.equal(isActiveClosure(ranges, 1000), true);
  assert.equal(isActiveClosure(ranges, 1999), true);
  assert.equal(isActiveClosure(ranges, 2000), false);
  assert.equal(isActiveClosure([{startAt: 'bad'}], 1500), false);
});

test('scheduled job closes only stalls in an active break', async () => {
  const docs = [
    {ref: 'active', data: () => ({temporaryClosures: [closure(1000, 2000)]})},
    {ref: 'future', data: () => ({temporaryClosures: [closure(3000, 4000)]})},
    {ref: 'missing', data: () => ({})},
  ];
  const db = fakeDb(docs);
  assert.equal(await closeScheduledStalls(db, 1500), 1);
  assert.deepEqual(db.committed, [[{
    ref: 'active',
    data: {isOpen: false, locationSharingActive: false},
  }]]);
});

test('scheduled job batches more than 400 closures safely', async () => {
  const docs = Array.from({length: 401}, (_, index) => ({
    ref: `vendor-${index}`,
    data: () => ({temporaryClosures: [closure(1000, 2000)]}),
  }));
  const db = fakeDb(docs);
  assert.equal(await closeScheduledStalls(db, 1500), 401);
  assert.deepEqual(db.committed.map((writes) => writes.length), [400, 1]);
});
