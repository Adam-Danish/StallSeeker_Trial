'use strict';
const {createHash} = require('node:crypto');
const {WINDOW_MS, FIX_MS, fail, text, identifier, reportInput, eligibleReports, assertCaseAction} = require('./moderation-core.cjs');

// All decisions run through transactions. vendorModeration is the per-vendor
// lock, preventing concurrent report reviews from creating two warning cases.
function moderationService({db, Timestamp, now = Date.now}) {
  const stamp = (time = now()) => Timestamp.fromMillis(time);
  const stateRef = (id) => db.doc(`vendorModeration/${id}`);
  async function actor(tx, uid, role) {
    const [profile, deletion] = await Promise.all([
      tx.get(db.doc(`users/${uid}`)), tx.get(db.doc(`_accountDeletions/${uid}`)),
    ]);
    const data = profile.data();
    const actual = String(data?.role ?? data?.userRole ?? data?.type ?? '').toLowerCase();
    if (deletion.exists || actual !== role) fail('permission-denied', `${role} access is required.`);
    return String(data.fullName || data.displayName || 'Administrator').slice(0, 120);
  }
  function audit(tx, uid, name, action, vendorId, caseId, reason) {
    tx.create(db.collection('adminActivity').doc(), {action: `moderation.${action}`,
      entityType: 'vendor', entityId: vendorId, entityName: vendorId,
      actorId: uid, actorName: name, actorEmail: '', summary: reason,
      caseId: caseId || null, createdAt: stamp()});
  }
  function notify(tx, vendorId, caseId, event, message) {
    tx.create(db.doc(`users/${vendorId}/notifications/moderation_${caseId}_${event}`), {
      type: 'moderation', recipientId: vendorId, vendorId, caseId,
      title: 'Stall information update', body: message, message,
      isRead: false, createdAt: stamp(), pushStatus: 'pending',
    });
  }
  async function submit(uid, input) {
    const time = now();
    const data = reportInput(input, time);
    if (data.vendorId === uid) fail('permission-denied', 'You cannot report your own stall.');
    const reportId = createHash('sha256').update(`${uid}:${data.requestKey}`).digest('hex');
    const ref = db.doc(`vendorReports/${reportId}`);
    const rate = db.doc(`moderationRateLimits/${createHash('sha256').update(`${uid}:${data.vendorId}`).digest('hex')}`);
    await db.runTransaction(async (tx) => {
      await actor(tx, uid, 'customer');
      const [existing, last, vendor, state, vendorDeletion, menu] = await Promise.all([
        tx.get(ref), tx.get(rate), tx.get(db.doc(`vendors/${data.vendorId}`)),
        tx.get(stateRef(data.vendorId)), tx.get(db.doc(`_accountDeletions/${data.vendorId}`)),
        tx.get(db.collection(`vendors/${data.vendorId}/menu`).limit(100)),
      ]);
      if (existing.exists) {
        if (existing.data().vendorId !== data.vendorId) fail('invalid-argument', 'Use a new request key.');
        return;
      }
      if (!vendor.exists || vendorDeletion.exists) fail('not-found', 'This stall is unavailable.');
      if ((last.data()?.submittedAt?.toMillis?.() ?? 0) > time - WINDOW_MS) {
        fail('resource-exhausted', 'You have already reported this stall within the last 30 days.');
      }
      const stall = vendor.data();
      tx.create(ref, {vendorId: data.vendorId, customerId: uid, stallName: String(stall.stallName || 'Stall').slice(0, 200),
        reason: data.reason, details: data.details, observedAt: stamp(data.observedAt),
        status: 'pending', caseId: state.data()?.currentCaseId || null,
        createdAt: stamp(time), updatedAt: stamp(time),
        snapshot: {stallName: String(stall.stallName || '').slice(0, 200), openingHours: String(stall.openingHours || '').slice(0, 500),
          isOpen: stall.isOpen === true, latitude: Number(stall.latitude || 0),
          longitude: Number(stall.longitude || 0), description: String(stall.description || '').slice(0, 2000),
          menu: menu.docs.map((item) => ({name: String(item.data().name || '').slice(0, 200),
            price: Number(item.data().price || 0), status: String(item.data().status || '')})),
          menuMayBeTruncated: menu.size === 100}});
      tx.set(rate, {customerId: uid, vendorId: data.vendorId, submittedAt: stamp(time)});
    });
    return {reportId};
  }
  async function review(uid, input) {
    const reportId = identifier(input?.reportId);
    const decision = input.decision;
    if (!['verify', 'reject'].includes(decision)) fail('invalid-argument', 'Choose verify or reject.');
    const reason = text(input.reason, 1000, 'Admin reason');
    return db.runTransaction(async (tx) => {
      const name = await actor(tx, uid, 'admin');
      const ref = db.doc(`vendorReports/${reportId}`);
      const report = (await tx.get(ref)).data();
      if (!report) fail('not-found', 'Report not found.');
      if (report.status !== 'pending') {
        if (report.status === (decision === 'verify' ? 'verified' : 'rejected')) return {caseId: report.caseId};
        fail('failed-precondition', 'This report has already been reviewed.');
      }
      const vendorId = report.vendorId;
      const [state, vendor, deleting] = await Promise.all([tx.get(stateRef(vendorId)),
        tx.get(db.doc(`vendors/${vendorId}`)), tx.get(db.doc(`_accountDeletions/${vendorId}`))]);
      if (!vendor.exists || deleting.exists) fail('not-found', 'Vendor account no longer exists.');
      const time = now();
      let caseId = report.caseId || state.data()?.currentCaseId || null;
      let linkedCase = caseId ? (await tx.get(db.doc(`moderationCases/${caseId}`))).data() : null;
      let candidates = [];
      if (decision === 'verify' && !caseId) {
        const result = await tx.get(db.collection('vendorReports').where('vendorId', '==', vendorId)
          .where('status', '==', 'verified').where('caseId', '==', null)
          .where('createdAt', '>=', stamp(time - WINDOW_MS)).orderBy('createdAt').limit(3));
        candidates = eligibleReports([...result.docs.map((doc) => ({...doc.data(), id: doc.id})),
          {...report, id: reportId, status: 'verified'}], time);
      }
      const createWarning = candidates.length >= 3;
      if (createWarning) {
        caseId = reportId;
        const summaries = candidates.slice(0, 3).map(({reason: category, details, observedAt}) => ({reason: category, details, observedAt}));
        tx.create(db.doc(`moderationCases/${caseId}`), {vendorId, stallName: report.stallName,
          status: 'warning', summaries, createdAt: stamp(time), dueAt: stamp(time + FIX_MS),
          updatedAt: stamp(time), issuedBy: uid, adminReason: reason, responseStatus: 'none'});
        for (const candidate of candidates.slice(0, 3)) {
          if (candidate.id !== reportId) tx.update(db.doc(`vendorReports/${candidate.id}`), {caseId, updatedAt: stamp(time)});
        }
        tx.set(stateRef(vendorId), {vendorId, currentCaseId: caseId, updatedAt: stamp(time)});
        notify(tx, vendorId, caseId, 'warning', 'An administrator verified reports about your stall. Correct the information within 48 hours and submit it for review.');
      } else if (caseId && linkedCase?.status === 'resolved') {
        // A report made during an older case cannot start a new warning cycle.
        linkedCase = {...linkedCase, closed: true};
      }
      tx.update(ref, {status: decision === 'reject' ? 'rejected' : linkedCase?.closed ? 'resolved' : 'verified',
        caseId, adminReason: reason, reviewedBy: uid, reviewedAt: stamp(time), updatedAt: stamp(time)});
      // Write the lock for every verification, serializing threshold queries.
      if (decision === 'verify' && !createWarning) tx.set(stateRef(vendorId), {vendorId,
        currentCaseId: state.data()?.currentCaseId || null, updatedAt: stamp(time)});
      audit(tx, uid, name, decision, vendorId, caseId, reason);
      return {caseId, warningCreated: createWarning};
    });
  }
  async function correction(uid, input) {
    const caseId = identifier(input?.caseId);
    const note = text(input.note, 1000, 'Correction or dispute');
    const requestKey = identifier(input.requestKey);
    await db.runTransaction(async (tx) => {
      await actor(tx, uid, 'vendor');
      const ref = db.doc(`moderationCases/${caseId}`);
      const response = ref.collection('responses').doc(requestKey);
      const [doc, existing] = await Promise.all([tx.get(ref), tx.get(response)]);
      const data = doc.data();
      if (data?.vendorId !== uid) fail('permission-denied', 'This is not your warning.');
      if (existing.exists) return;
      if (!['warning', 'suspended'].includes(data.status)) fail('failed-precondition', 'This case is closed.');
      tx.create(response, {vendorId: uid, note, createdAt: stamp()});
      tx.update(ref, {vendorResponse: note, responseStatus: 'pending', responseAt: stamp(), updatedAt: stamp()});
    });
    return {submitted: true};
  }
  async function decide(uid, input) {
    const vendorId = identifier(input?.vendorId);
    const reason = text(input.reason, 1000, 'Admin reason');
    return db.runTransaction(async (tx) => {
      const name = await actor(tx, uid, 'admin');
      const state = await tx.get(stateRef(vendorId));
      const caseId = state.data()?.currentCaseId;
      if (!caseId || caseId !== input.caseId) fail('failed-precondition', 'Refresh this vendor’s current warning.');
      const ref = db.doc(`moderationCases/${caseId}`);
      const [doc, vendor, deleting] = await Promise.all([tx.get(ref), tx.get(db.doc(`vendors/${vendorId}`)),
        tx.get(db.doc(`_accountDeletions/${vendorId}`))]);
      if (!vendor.exists || deleting.exists) fail('not-found', 'Vendor account no longer exists.');
      const data = doc.data();
      assertCaseAction(data, input.action, now());
      const reports = input.action === 'resolve'
        ? await tx.get(db.collection('vendorReports').where('caseId', '==', caseId).limit(400)) : null;
      // Cases with more linked reports are resolved through the case status;
      // clients display that status without an unbounded transaction fan-out.
      const status = input.action === 'resolve' ? 'resolved' : input.action === 'suspend' ? 'suspended' : data.status;
      tx.update(ref, {status, adminReason: reason, decidedBy: uid, updatedAt: stamp(),
        ...(input.action === 'rejectCorrection' ? {responseStatus: 'rejected'} : {}),
        ...(input.action === 'resolve' ? {responseStatus: 'approved', resolvedAt: stamp()} : {})});
      if (input.action !== 'rejectCorrection') {
        tx.update(db.doc(`vendors/${vendorId}`), {listingStatus: status === 'suspended' ? 'suspended' : 'active',
          isOpen: false, locationSharingActive: false});
      }
      if (input.action === 'resolve') {
        tx.set(stateRef(vendorId), {vendorId, currentCaseId: null, updatedAt: stamp()});
        for (const report of reports.docs) {
          if (report.data().status === 'verified') tx.update(report.ref, {status: 'resolved', updatedAt: stamp()});
        }
      }
      const event = createHash('sha256').update(`${input.action}:${doc.updateTime.seconds}:${doc.updateTime.nanoseconds}`).digest('hex').slice(0, 20);
      notify(tx, vendorId, caseId, event, input.action === 'suspend'
        ? 'Your listing is suspended until an administrator approves your correction.'
        : input.action === 'resolve' ? 'Your correction was approved. Your listing is restored; open your stall when ready.'
          : `Your correction needs more work: ${reason}`);
      audit(tx, uid, name, input.action, vendorId, caseId, reason);
      return {status};
    });
  }
  return {submit, review, correction, decide};
}
module.exports = {moderationService};
