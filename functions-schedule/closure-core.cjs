'use strict';

function isActiveClosure(closures, nowMs) {
  return Array.isArray(closures) && closures.some((closure) => {
    const start = closure?.startAt?.toMillis?.();
    const end = closure?.endAt?.toMillis?.();
    return Number.isFinite(start) && Number.isFinite(end) &&
        start <= nowMs && nowMs < end;
  });
}

async function closeScheduledStalls(db, nowMs) {
  const openVendors = await db.collection('vendors')
      .where('isOpen', '==', true).get();
  let batch = db.batch();
  let pending = 0;
  let closed = 0;
  for (const doc of openVendors.docs) {
    if (!isActiveClosure(doc.data().temporaryClosures, nowMs)) continue;
    batch.update(doc.ref, {isOpen: false, locationSharingActive: false});
    pending++;
    closed++;
    if (pending === 400) {
      await batch.commit();
      batch = db.batch();
      pending = 0;
    }
  }
  if (pending > 0) await batch.commit();
  return closed;
}

module.exports = {isActiveClosure, closeScheduledStalls};
