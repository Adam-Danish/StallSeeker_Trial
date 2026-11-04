'use strict';
const {onDocumentWritten, onDocumentCreated} = require('firebase-functions/v2/firestore');
const {onSchedule} = require('firebase-functions/v2/scheduler');
const {defineSecret} = require('firebase-functions/params');
const {getFirestore, Timestamp, FieldValue} = require('firebase-admin/firestore');
const {getAuth} = require('firebase-admin/auth');
const nodemailer = require('nodemailer');
const {transactionChanged, eventKey, emailDelivery} = require('./transaction-email-core.cjs');

const smtpUrl = defineSecret('TRANSACTION_SMTP_URL');
const sender = defineSecret('TRANSACTION_EMAIL_FROM');
const db = getFirestore();
const workerOptions = {secrets: [smtpUrl, sender], timeoutSeconds: 120, maxInstances: 3};

function worker() {
  const url = new URL(smtpUrl.value());
  if (!['smtp:', 'smtps:'].includes(url.protocol)) throw new Error('SMTP URL required.');
  const secure = url.protocol === 'smtps:';
  const transport = nodemailer.createTransport({
    host: url.hostname, port: Number(url.port || (secure ? 465 : 587)), secure,
    requireTLS: !secure,
    auth: {user: decodeURIComponent(url.username), pass: decodeURIComponent(url.password)},
    connectionTimeout: 20000, greetingTimeout: 20000, socketTimeout: 30000,
    disableFileAccess: true, disableUrlAccess: true,
  });
  return emailDelivery({db, Timestamp, FieldValue, from: sender.value(),
    sendMail: (message) => transport.sendMail(message)});
}

exports.queueTransactionEmail = onDocumentWritten({document: 'bookings/{bookingId}',
  retry: true}, async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (!transactionChanged(before, after)) return;
  const id = eventKey(event.id);
  const ref = db.doc(`transactionEmailOutbox/${id}`);
  const existing = await ref.get();
  if (existing.exists) {
    await emailDelivery({db, Timestamp, FieldValue}).summary({...existing.data(), id}, existing.data().status);
    return;
  }
  // Firebase Auth is the trusted source of the customer's verified email.
  let user;
  try { user = await getAuth().getUser(after.customerId); }
  catch (error) { if (error.code === 'auth/user-not-found') return; throw error; }
  if (!user.email || !user.emailVerified || user.disabled) {
    console.error('Transaction email recipient unavailable', {bookingId: event.params.bookingId});
    await emailDelivery({db, Timestamp, FieldValue}).summary({id,
      bookingId: event.params.bookingId, eventAt: Date.parse(event.time)}, 'recipient_unavailable');
    return;
  }
  const job = {id, bookingId: event.params.bookingId, booking: after,
    to: user.email, eventAt: Date.parse(event.time), status: 'queued', attempts: 0,
    createdAt: Timestamp.now(), nextAttemptAt: Timestamp.now()};
  await db.runTransaction(async (tx) => {
    if ((await tx.get(ref)).exists) return;
    tx.create(ref, job);
  });
  await emailDelivery({db, Timestamp, FieldValue}).summary(job, 'queued');
});

exports.sendTransactionEmail = onDocumentCreated({...workerOptions,
  document: 'transactionEmailOutbox/{emailId}', retry: true}, async (event) => {
  await worker().deliver(event.params.emailId);
});

exports.retryTransactionEmails = onSchedule({...workerOptions,
  schedule: 'every 5 minutes'}, async () => {
  const due = await db.collection('transactionEmailOutbox')
    .where('nextAttemptAt', '<=', Timestamp.now()).limit(50).get();
  const delivery = worker();
  for (const doc of due.docs) {
    try { await delivery.deliver(doc.id); }
    catch (_) { console.error('Transaction email retry pending', {emailId: doc.id}); }
  }
});
