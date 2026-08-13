const {onDocumentUpdated} = require("firebase-functions/v2/firestore");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
const {getMessaging} = require("firebase-admin/messaging");

initializeApp();

// Fires whenever any vendor document is updated. We only act when the
// vendor transitions from closed to open -- editing other fields (name,
// description, menu, etc.) does not trigger a notification.
exports.notifyFollowersOnStallOpen = onDocumentUpdated(
  "vendors/{vendorId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();
    const vendorId = event.params.vendorId;

    const wasClosed = before.isOpen === false;
    const isNowOpen = after.isOpen === true;

    // Guard against duplicate notifications: only fire on the exact
    // false -> true transition, not on every write while already open.
    if (!wasClosed || !isNowOpen) {
      return;
    }

    const db = getFirestore();

    // Find every customer following this vendor.
    const followsSnapshot = await db
        .collection("follows")
        .where("vendorId", "==", vendorId)
        .get();

    if (followsSnapshot.empty) {
      return; // Nobody follows this vendor -- nothing to send.
    }

    const customerIds = followsSnapshot.docs.map(
        (doc) => doc.data().customerId,
    );

    // Look up each follower's saved FCM device token from their user doc.
    const tokens = [];
    for (const customerId of customerIds) {
      const userDoc = await db.collection("users").doc(customerId).get();
      const token = userDoc.data() && userDoc.data().fcmToken;
      if (token) tokens.push(token);
    }

    if (tokens.length === 0) {
      return; // No follower has a registered device to notify.
    }

    const stallName = after.stallName || "A stall you follow";

    await getMessaging().sendEachForMulticast({
      tokens: tokens,
      notification: {
        title: "StallSeeker",
        body: `${stallName} is now open!`,
      },
      data: {
        vendorId: vendorId,
      },
    });
  },
);