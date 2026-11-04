'use strict';
const {test} = require('node:test');
const assert = require('node:assert/strict');
const {WINDOW_MS, FIX_MS, reportInput, eligibleReports, assertCaseAction} = require('./moderation-core.cjs');
const {validCaller} = require('./moderation-core.cjs');
const now = Date.UTC(2026, 10, 4, 4);
const stamp = (value) => ({toMillis: () => value});
test('admin operations retain role-based sign-in; customer and vendor operations require verification', () => {
  const auth = {uid: 'signed-in-user', token: {email_verified: false, firebase: {sign_in_provider: 'password'}}};
  assert.equal(validCaller(auth), false);
  assert.equal(validCaller(auth, true), true);
  assert.equal(validCaller({...auth, token: {...auth.token, email_verified: true}}), true);
  assert.equal(validCaller(null, true), false);
  assert.equal(validCaller({uid: 'missing-token'}, true), false);
  assert.equal(validCaller({...auth, token: {...auth.token, firebase: {sign_in_provider: 'anonymous'}}}, true), false);
});
test('only distinct recent unconsumed verified complaints count', () => {
  const base = {status: 'verified', caseId: null, customerId: 'a', createdAt: stamp(now)};
  const reports = [base, {...base}, {...base, customerId: 'b', createdAt: stamp(now - WINDOW_MS)},
    {...base, customerId: 'c', createdAt: stamp(now - WINDOW_MS - 1)},
    {...base, customerId: 'd', status: 'pending'}, {...base, customerId: 'e', status: 'rejected'},
    {...base, customerId: 'f', caseId: 'old-warning'}, {...base, customerId: 'g', createdAt: stamp(now + 1)}];
  assert.deepEqual(eligibleReports(reports, now).map((report) => report.customerId), ['a', 'b']);
});
test('a future or stale observation is rejected; text is trimmed and required', () => {
  const report = {vendorId: 'vendor', requestKey: 'request-key', reason: 'wrong_location', details: ' Wrong pin ', observedAt: now};
  assert.equal(reportInput(report, now).details, 'Wrong pin');
  for (const observedAt of [now + 1, now - WINDOW_MS - 1, null]) {
    assert.throws(() => reportInput({...report, observedAt}, now), {code: 'invalid-argument'});
  }
  assert.throws(() => reportInput({...report, details: '  '}, now), {code: 'invalid-argument'});
});
test('suspension requires an overdue warning and correction rejection requires a response', () => {
  const warning = {status: 'warning', dueAt: stamp(now + FIX_MS), responseStatus: 'none'};
  assert.throws(() => assertCaseAction(warning, 'suspend', now + FIX_MS - 1), {code: 'failed-precondition'});
  assert.doesNotThrow(() => assertCaseAction(warning, 'suspend', now + FIX_MS));
  assert.throws(() => assertCaseAction(warning, 'rejectCorrection', now), {code: 'failed-precondition'});
  assert.doesNotThrow(() => assertCaseAction({...warning, responseStatus: 'pending'}, 'rejectCorrection', now));
  assert.throws(() => assertCaseAction({...warning, status: 'resolved'}, 'resolve', now), {code: 'failed-precondition'});
});
