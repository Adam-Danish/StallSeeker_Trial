'use strict';
const DAY_MS = 24 * 60 * 60 * 1000;
const WINDOW_MS = 30 * DAY_MS;
const FIX_MS = 48 * 60 * 60 * 1000;
const REASONS = ['wrong_location', 'opening_status', 'menu_prices', 'stall_details', 'other'];
// Admin identity is authorized again by the trusted profile role in the
// transaction. Existing dashboard admins do not require email verification.
function validCaller(auth, adminOperation = false) {
  return typeof auth?.uid === 'string' && auth.uid.length > 0 && !!auth.token
    && auth.token.firebase?.sign_in_provider !== 'anonymous'
    && (adminOperation || auth.token.email_verified === true);
}
function fail(code, message) { const error = new Error(message); error.code = code; throw error; }
function text(value, max, label) {
  if (typeof value !== 'string' || !value.trim() || value.trim().length > max) {
    fail('invalid-argument', `${label} is required (up to ${max} characters).`);
  }
  return value.trim();
}
function identifier(value) {
  if (typeof value !== 'string' || !/^[A-Za-z0-9_-]{1,150}$/.test(value)) fail('invalid-argument', 'Invalid identifier.');
  return value;
}
function reportInput(data, now) {
  if (!REASONS.includes(data?.reason)) fail('invalid-argument', 'Choose a report reason.');
  const observedAt = data.observedAt;
  if (!Number.isSafeInteger(observedAt) || observedAt > now || observedAt < now - WINDOW_MS) {
    fail('invalid-argument', 'Choose an observation time within the last 30 days.');
  }
  return {vendorId: identifier(data.vendorId), requestKey: identifier(data.requestKey),
    reason: data.reason, details: text(data.details, 1000, 'Explanation'), observedAt};
}
function eligibleReports(reports, now) {
  const customers = new Set();
  return reports.filter((report) => {
    const created = report.createdAt?.toMillis?.();
    if (report.status !== 'verified' || report.caseId || !Number.isFinite(created) ||
        created < now - WINDOW_MS || created > now || customers.has(report.customerId)) return false;
    customers.add(report.customerId);
    return true;
  });
}
function assertCaseAction(caseData, action, now) {
  if (!caseData || !['warning', 'suspended'].includes(caseData.status)) fail('failed-precondition', 'This case is already closed.');
  if (action === 'suspend' && (caseData.status !== 'warning' || now < caseData.dueAt.toMillis())) {
    fail('failed-precondition', 'A warning must be overdue before suspension.');
  }
  if (!['suspend', 'resolve', 'rejectCorrection'].includes(action)) fail('invalid-argument', 'Invalid moderation action.');
  if (action === 'rejectCorrection' && caseData.responseStatus !== 'pending') {
    fail('failed-precondition', 'There is no correction awaiting review.');
  }
}
module.exports = {WINDOW_MS, FIX_MS, REASONS, validCaller, fail, text, identifier, reportInput, eligibleReports, assertCaseAction};
