'use strict';

const {onCall, HttpsError} = require('firebase-functions/v2/https');
const {onSchedule} = require('firebase-functions/v2/scheduler');
const {getApps, initializeApp} = require('firebase-admin/app');
const {getFirestore, Timestamp, FieldValue} = require('firebase-admin/firestore');
const {getMessaging} = require('firebase-admin/messaging');
const {vendorAvailable, bookingItems, nextStatus} = require('./booking-core.cjs');

if (!getApps().length) initializeApp();
const db = getFirestore();
const orders = db.collection('bookings');

function actor(request) {
  const uid = request.auth?.uid;
  if (!uid || request.auth.token.firebase?.sign_in_provider === 'anonymous' ||
      request.auth.token.email_verified !== true) {
    throw new HttpsError('unauthenticated', 'Sign in with a verified account.');
  }
  return uid;
}

function idFrom(data) {
  const id = data?.bookingId;
  if (typeof id !== 'string' || !/^[A-Za-z0-9_-]{1,150}$/.test(id)) {
    throw new HttpsError('invalid-argument', 'Invalid booking.');
  }
  return id;
}

async function push(uid, role, bookingId, status, stallName) {
  try {
    const profile = (await db.collection('users').doc(uid).get()).data();
    if (!profile?.fcmToken || profile.notificationsEnabled === false) return;
    const message = role === 'vendor'
      ? status === 'requested'
        ? {title: 'New self-collect booking', body: 'Open StallSeeker to answer it.'}
        : {title: 'Booking cancelled', body: 'A customer cancelled their request.'}
      : status === 'ready'
        ? {title: 'Ready for collection', body: `${stallName} has your booking ready.`}
        : {title: 'Booking update', body: `Your booking at ${stallName} is ${status}.`};
    await getMessaging().send({token: profile.fcmToken,
      notification: message,
      data: {type: 'booking', bookingId, status, recipientId: uid, role}});
  } catch (error) {
    console.error('Booking push unavailable', {bookingId, role, error});
  }
}

exports.createBooking = onCall(async (request) => {
  const uid = actor(request);
  const vendorId = request.data?.vendorId;
  const requestKey = request.data?.requestKey;
  const selected = request.data?.items;
  if (typeof vendorId !== 'string' || !/^[^/]{1,128}$/.test(vendorId) ||
      vendorId === uid || typeof requestKey !== 'string' ||
      !/^[A-Za-z0-9_-]{12,80}$/.test(requestKey) ||
      !Array.isArray(selected)) {
    throw new HttpsError('invalid-argument', 'Invalid booking request.');
  }
  const bookingId = `${uid}_${requestKey}`;
  const bookingRef = orders.doc(bookingId);
  const customerRef = db.collection('users').doc(uid);
  const vendorRef = db.collection('vendors').doc(vendorId);
  const vendorUserRef = db.collection('users').doc(vendorId);
  const itemIds = selected.map((entry) => entry?.itemId);
  if (itemIds.length < 1 || itemIds.length > 20 ||
      itemIds.some((id) => typeof id !== 'string' || !/^[^/]{1,128}$/.test(id)) ||
      new Set(itemIds).size !== itemIds.length) {
    throw new HttpsError('invalid-argument', 'Choose valid dishes.');
  }
  const now = Date.now();
  let created = false;
  let stallName = '';
  await db.runTransaction(async (tx) => {
    created = false;
    const [existing, customer, vendor, vendorUser, ...menu] = await Promise.all([
      tx.get(bookingRef), tx.get(customerRef), tx.get(vendorRef),
      tx.get(vendorUserRef),
      ...itemIds.map((id) => tx.get(vendorRef.collection('menu').doc(id))),
    ]);
    if (existing.exists) return;
    if (customer.data()?.role !== 'customer' ||
        vendorUser.data()?.role !== 'vendor') {
      throw new HttpsError('permission-denied', 'Customer and vendor accounts required.');
    }
    const stall = vendor.data();
    if (!vendorAvailable(stall, now)) {
      throw new HttpsError('failed-precondition', 'This stall is not accepting bookings.');
    }
    const menuById = new Map(menu.map((doc) => [doc.id, doc.data()]));
    let priced;
    try {
      priced = bookingItems(selected, menuById);
    } catch (error) {
      throw new HttpsError('failed-precondition', error.message);
    }
    stallName = String(stall.stallName || 'Stall').slice(0, 120);
    const name = String(customer.data()?.fullName || 'Customer').trim().slice(0, 80);
    tx.create(bookingRef, {
      customerId: uid, vendorId, customerName: name || 'Customer', stallName,
      status: 'requested', items: priced.items, totalCents: priced.totalCents,
      pickupLatitude: stall.latitude, pickupLongitude: stall.longitude,
      createdAt: Timestamp.fromMillis(now), updatedAt: Timestamp.fromMillis(now),
      expiresAt: Timestamp.fromMillis(now + 10 * 60 * 1000),
      vendorUnseenRequest: true, customerUnseenReady: false,
    });
    created = true;
  });
  if (created) await push(vendorId, 'vendor', bookingId, 'requested', stallName);
  return {bookingId};
});

exports.updateBooking = onCall(async (request) => {
  const uid = actor(request);
  const bookingId = idFrom(request.data);
  const action = request.data?.action;
  if (!['accept', 'reject', 'startPreparing', 'markReady', 'markCollected',
    'cancel'].includes(action)) {
    throw new HttpsError('invalid-argument', 'Invalid booking action.');
  }
  const ref = orders.doc(bookingId);
  let changed;
  await db.runTransaction(async (tx) => {
    changed = undefined;
    const [snap, profile] = await Promise.all([
      tx.get(ref), tx.get(db.collection('users').doc(uid)),
    ]);
    if (!snap.exists) throw new HttpsError('not-found', 'Booking not found.');
    const booking = snap.data();
    const role = uid === booking.customerId ? 'customer' :
      uid === booking.vendorId ? 'vendor' : null;
    if (!role || profile.data()?.role !== role) {
      throw new HttpsError('permission-denied', 'This is not your booking.');
    }
    const now = Date.now();
    let status;
    try {
      status = nextStatus(booking, action, uid, now);
    } catch (error) {
      throw new HttpsError('failed-precondition', error.message);
    }
    tx.update(ref, {
      status, updatedAt: Timestamp.fromMillis(now),
      vendorUnseenRequest: status === 'requested' && booking.vendorUnseenRequest === true,
      customerUnseenReady: status === 'ready' ||
        (status === 'collected' && booking.customerUnseenReady === true),
    });
    changed = {...booking, status};
  });
  if (changed?.status === 'ready' ||
      ['rejected', 'cancelled', 'expired'].includes(changed?.status)) {
    const recipient = changed.status === 'cancelled' && uid === changed.customerId
      ? changed.vendorId : changed.customerId;
    await push(recipient, recipient === changed.vendorId ? 'vendor' : 'customer',
      bookingId, changed.status, changed.stallName);
  }
  return {status: changed.status};
});

exports.markBookingViewed = onCall(async (request) => {
  const uid = actor(request);
  const ref = orders.doc(idFrom(request.data));
  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) throw new HttpsError('not-found', 'Booking not found.');
    const booking = snap.data();
    if (uid === booking.vendorId && booking.vendorUnseenRequest === true) {
      tx.update(ref, {vendorUnseenRequest: false});
    } else if (uid === booking.customerId && booking.customerUnseenReady === true) {
      tx.update(ref, {customerUnseenReady: false});
    } else if (uid !== booking.customerId && uid !== booking.vendorId) {
      throw new HttpsError('permission-denied', 'This is not your booking.');
    }
  });
  return {viewed: true};
});

exports.expireBookings = onSchedule({schedule: 'every 1 minutes'}, async () => {
  const now = Date.now();
  for (let page = 0; page < 5; page++) {
    const due = await orders.where('status', '==', 'requested')
      .where('expiresAt', '<=', Timestamp.fromMillis(now)).limit(100).get();
    if (due.empty) return;
    for (const doc of due.docs) {
      let expired;
      await db.runTransaction(async (tx) => {
        expired = undefined;
        const snap = await tx.get(doc.ref);
        const booking = snap.data();
        if (!booking || booking.status !== 'requested' ||
            booking.expiresAt?.toMillis?.() > Date.now()) return;
        tx.update(doc.ref, {status: 'expired', updatedAt: FieldValue.serverTimestamp(),
          vendorUnseenRequest: false});
        expired = booking;
      });
      if (expired) await push(expired.customerId, 'customer', doc.id,
        'expired', expired.stallName);
    }
    if (due.size < 100) return;
  }
});
