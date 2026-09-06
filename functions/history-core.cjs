'use strict';
const { createHash } = require('node:crypto');

function openingAlert({ eventId, vendorId, before, after, eventTime }) {
  if (!after || after.isOpen !== true || before?.isOpen === true) return null;
  if (!eventId || !vendorId || !Number.isFinite(new Date(eventTime).getTime())) {
    throw new Error('Missing stable event identity or time');
  }
  const name = typeof after.stallName === 'string' && after.stallName.trim()
    ? after.stallName.trim().slice(0, 100) : 'A followed stall';
  return {
    id: createHash('sha256').update(`${vendorId}:${eventId}`).digest('hex'),
    vendorId,
    title: `${name} is open`,
    body: 'Check the menu and current location before visiting.',
    type: 'vendor_opened',
    isRead: false,
    date: new Date(eventTime),
  };
}

function eligibleCustomerId(follow, openedAt) {
  const uid = follow.customerId;
  if (typeof uid !== 'string' || !uid || uid.length > 128 || uid.includes('/')) return null;
  // A delayed event must not notify someone who followed after that opening.
  const followedAt = follow.followedAt?.toDate?.();
  if (followedAt instanceof Date && followedAt > openedAt) return null;
  return uid;
}

async function createOnce(ref, data) {
  try {
    await ref.create(data);
    return true;
  } catch (error) {
    // A retry cannot duplicate an alert or reset its existing read state.
    if ([6, '6', 'already-exists', 'ALREADY_EXISTS'].includes(error.code)) return false;
    throw error;
  }
}

module.exports = { openingAlert, eligibleCustomerId, createOnce };
