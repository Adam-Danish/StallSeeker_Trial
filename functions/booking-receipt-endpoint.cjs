'use strict';
const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {getFirestore} = require('firebase-admin/firestore');
const {receiptPdf, paidReceipt, receiptFilename, receiptAllowed} = require('./booking-receipt.cjs');

exports.getBookingReceipt = onCall({timeoutSeconds: 60, maxInstances: 5}, async (request) => {
  const uid = request.auth?.uid;
  if (!uid || request.auth.token.email_verified !== true ||
      request.auth.token.firebase?.sign_in_provider === 'anonymous') {
    throw new HttpsError('unauthenticated', 'Sign in with a verified account.');
  }
  const id = request.data?.bookingId;
  if (typeof id !== 'string' || !/^[A-Za-z0-9_-]{1,150}$/.test(id)) {
    throw new HttpsError('invalid-argument', 'Invalid booking.');
  }
  const db = getFirestore();
  const [doc, profile] = await Promise.all([
    db.doc(`bookings/${id}`).get(), db.doc(`users/${uid}`).get(),
  ]);
  const booking = doc.data();
  if (!receiptAllowed(booking, uid, profile.data())) {
    throw new HttpsError('permission-denied', 'You cannot access this receipt.');
  }
  if (!paidReceipt(booking)) {
    throw new HttpsError('failed-precondition', 'Receipt available after payment.');
  }
  return {filename: receiptFilename(id), pdfBase64: (await receiptPdf(id, booking)).toString('base64')};
});
