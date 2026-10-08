'use strict';

const ACTIVE = new Set(['requested', 'confirmed', 'preparing', 'ready']);
const TERMINAL = new Set(['collected', 'rejected', 'cancelled', 'expired']);

function vendorAvailable(vendor, now) {
  if (vendor?.selfCollectEnabled !== true || vendor.isOpen !== true) return false;
  const lat = vendor.latitude;
  const lng = vendor.longitude;
  if (!Number.isFinite(lat) || !Number.isFinite(lng) ||
      Math.abs(lat) > 90 || Math.abs(lng) > 180 || (lat === 0 && lng === 0)) {
    return false;
  }
  return !(Array.isArray(vendor.temporaryClosures) &&
    vendor.temporaryClosures.some((closure) => {
      const start = closure?.startAt?.toMillis?.();
      const end = closure?.endAt?.toMillis?.();
      return Number.isFinite(start) && Number.isFinite(end) &&
        start <= now && now < end;
    }));
}

function bookingItems(requested, menu) {
  if (!Array.isArray(requested) || requested.length < 1 || requested.length > 20) {
    throw new Error('Choose between 1 and 20 dishes.');
  }
  const seen = new Set();
  let totalCents = 0;
  const items = requested.map((entry) => {
    const id = entry?.itemId;
    const quantity = entry?.quantity;
    if (typeof id !== 'string' || !/^[^/]{1,128}$/.test(id) ||
        seen.has(id) || !Number.isInteger(quantity) || quantity < 1 || quantity > 20) {
      throw new Error('Invalid dish selection.');
    }
    seen.add(id);
    const dish = menu.get(id);
    if (!dish || dish.status === 'out_of_stock' ||
        typeof dish.name !== 'string' || !dish.name.trim() ||
        typeof dish.price !== 'number' || !Number.isFinite(dish.price) ||
        dish.price < 0 || dish.price > 10000) {
      throw new Error('A selected dish is unavailable.');
    }
    const unitPriceCents = Math.round(dish.price * 100);
    totalCents += unitPriceCents * quantity;
    return {itemId: id, name: dish.name.trim().slice(0, 120),
      unitPriceCents, quantity};
  });
  return {items, totalCents};
}

function nextStatus(booking, action, uid, now) {
  const {status, customerId, vendorId} = booking;
  const expires = booking.expiresAt?.toMillis?.();
  if (status === 'requested' && Number.isFinite(expires) && now >= expires) {
    return 'expired';
  }
  if (uid === customerId && action === 'cancel' && status === 'requested') {
    return 'cancelled';
  }
  if (uid !== vendorId) throw new Error('You cannot update this booking.');
  const transitions = {
    requested: {accept: 'confirmed', reject: 'rejected', cancel: 'cancelled'},
    confirmed: {startPreparing: 'preparing', cancel: 'cancelled'},
    preparing: {markReady: 'ready', cancel: 'cancelled'},
    ready: {markCollected: 'collected', cancel: 'cancelled'},
  };
  const next = transitions[status]?.[action];
  if (!next) throw new Error('This booking cannot be updated now.');
  return next;
}

module.exports = {ACTIVE, TERMINAL, vendorAvailable, bookingItems, nextStatus};
