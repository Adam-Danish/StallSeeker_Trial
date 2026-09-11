const {
  onDocumentDeleted,
  onDocumentUpdated,
} = require("firebase-functions/v2/firestore");
const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {defineInt, defineSecret, defineString} = require("firebase-functions/params");
const {initializeApp} = require("firebase-admin/app");
const {
  FieldValue,
  Timestamp,
  getFirestore,
} = require("firebase-admin/firestore");
const {getAuth} = require("firebase-admin/auth");
const {getMessaging} = require("firebase-admin/messaging");
const {getStorage} = require("firebase-admin/storage");
const crypto = require("crypto");
const nodemailer = require("nodemailer");

const smtpHost = defineString("SMTP_HOST", {default: "smtp.gmail.com"});
const smtpPort = defineInt("SMTP_PORT", {default: 465});
const smtpFrom = defineString("SMTP_FROM", {default: ""});
const smtpUser = defineSecret("SMTP_USER");
const smtpPassword = defineSecret("SMTP_PASSWORD");
const emailCodeSecret = defineSecret("EMAIL_CODE_SECRET");

const verificationSecrets = [smtpUser, smtpPassword, emailCodeSecret];
const codeLifetimeMs = 10 * 60 * 1000;
const resendCooldownMs = 60 * 1000;
const maxAttempts = 5;

initializeApp();

function requireSignedIn(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in before requesting a code.");
  }
  return request.auth;
}

function normalizeEmail(value) {
  const email = typeof value === "string" ? value.trim().toLowerCase() : "";
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) {
    throw new HttpsError("invalid-argument", "Enter a valid email address.");
  }
  return email;
}

function requireRecentSignIn(auth) {
  const signedInAtSeconds = Number(auth.token.auth_time || 0);
  if (Date.now() - signedInAtSeconds * 1000 > 10 * 60 * 1000) {
    throw new HttpsError(
        "failed-precondition",
        "For security, sign out and sign in again before changing your email.",
    );
  }
}

function codeDocument(uid, purpose) {
  return getFirestore()
      .collection("_emailVerificationCodes")
      .doc(`${uid}_${purpose}`);
}

function hashCode(uid, purpose, email, code) {
  return crypto
      .createHmac("sha256", emailCodeSecret.value())
      .update(`${uid}|${purpose}|${email}|${code}`)
      .digest("hex");
}

function assertPurpose(value) {
  if (value !== "registration" && value !== "email_change") {
    throw new HttpsError("invalid-argument", "Unknown verification purpose.");
  }
  return value;
}

exports.requestEmailVerificationCode = onCall(
    {secrets: verificationSecrets},
    async (request) => {
      const auth = requireSignedIn(request);
      const purpose = assertPurpose(request.data && request.data.purpose);
      let targetEmail;

      if (purpose === "registration") {
        if (auth.token.email_verified === true) {
          throw new HttpsError("failed-precondition", "This email is already verified.");
        }
        targetEmail = normalizeEmail(auth.token.email);
      } else {
        requireRecentSignIn(auth);
        targetEmail = normalizeEmail(request.data && request.data.newEmail);
        if (targetEmail === String(auth.token.email || "").toLowerCase()) {
          throw new HttpsError(
              "invalid-argument",
              "The new email must be different from your current email.",
          );
        }
        try {
          await getAuth().getUserByEmail(targetEmail);
          throw new HttpsError(
              "already-exists",
              "That email is already connected to another account.",
          );
        } catch (error) {
          if (error instanceof HttpsError) throw error;
          if (error.code !== "auth/user-not-found") throw error;
        }
      }

      const reference = codeDocument(auth.uid, purpose);
      const existing = await reference.get();
      const cooldownUntil = existing.data() && existing.data().cooldownUntil;
      if (cooldownUntil instanceof Timestamp && cooldownUntil.toMillis() > Date.now()) {
        const waitSeconds = Math.ceil((cooldownUntil.toMillis() - Date.now()) / 1000);
        throw new HttpsError(
            "resource-exhausted",
            `Please wait ${waitSeconds} seconds before requesting another code.`,
        );
      }

      const code = crypto.randomInt(100000, 1000000).toString();
      await reference.set({
        uid: auth.uid,
        purpose,
        email: targetEmail,
        codeHash: hashCode(auth.uid, purpose, targetEmail, code),
        attempts: 0,
        expiresAt: Timestamp.fromMillis(Date.now() + codeLifetimeMs),
        cooldownUntil: Timestamp.fromMillis(Date.now() + resendCooldownMs),
        createdAt: FieldValue.serverTimestamp(),
      });

      const transporter = nodemailer.createTransport({
        host: smtpHost.value(),
        port: smtpPort.value(),
        secure: smtpPort.value() === 465,
        auth: {
          user: smtpUser.value(),
          pass: smtpPassword.value(),
        },
      });

      try {
        await transporter.sendMail({
          from: smtpFrom.value() || smtpUser.value(),
          to: targetEmail,
          subject: "Your StallSeeker verification code",
          text: `Your StallSeeker verification code is ${code}. ` +
            "It expires in 10 minutes. If you did not request this, ignore this email.",
          html: `<p>Your StallSeeker verification code is:</p>` +
            `<p style="font-size:28px;font-weight:700;letter-spacing:6px">${code}</p>` +
            `<p>It expires in 10 minutes. If you did not request this, ignore this email.</p>`,
        });
      } catch (error) {
        await reference.delete();
        console.error("Verification email could not be sent", error);
        throw new HttpsError(
            "internal",
            "The verification email could not be sent. Please try again later.",
        );
      }

      return {sent: true, expiresInSeconds: codeLifetimeMs / 1000};
    },
);

exports.confirmEmailVerificationCode = onCall(
    {secrets: verificationSecrets},
    async (request) => {
      const auth = requireSignedIn(request);
      const purpose = assertPurpose(request.data && request.data.purpose);
      const code = String(request.data && request.data.code || "").trim();
      if (!/^\d{6}$/.test(code)) {
        throw new HttpsError("invalid-argument", "Enter the six-digit code.");
      }
      if (purpose === "email_change") requireRecentSignIn(auth);

      const reference = codeDocument(auth.uid, purpose);
      const snapshot = await reference.get();
      const data = snapshot.data();
      if (!data) {
        throw new HttpsError(
            "not-found",
            "No active code was found. Request a new code.",
        );
      }
      if (!(data.expiresAt instanceof Timestamp) || data.expiresAt.toMillis() < Date.now()) {
        await reference.delete();
        throw new HttpsError("deadline-exceeded", "That code has expired. Request a new one.");
      }
      if (Number(data.attempts || 0) >= maxAttempts) {
        await reference.delete();
        throw new HttpsError(
            "resource-exhausted",
            "Too many incorrect attempts. Request a new code.",
        );
      }

      const targetEmail = normalizeEmail(data.email);
      if (purpose === "email_change") {
        const submittedEmail = normalizeEmail(request.data && request.data.newEmail);
        if (submittedEmail !== targetEmail) {
          throw new HttpsError(
              "invalid-argument",
              "This code was sent to a different email address.",
          );
        }
      }

      const submittedHash = hashCode(auth.uid, purpose, targetEmail, code);
      const expectedHash = String(data.codeHash || "");
      const matches = expectedHash.length === submittedHash.length &&
        crypto.timingSafeEqual(Buffer.from(expectedHash), Buffer.from(submittedHash));
      if (!matches) {
        await reference.update({attempts: FieldValue.increment(1)});
        const attemptsLeft = maxAttempts - Number(data.attempts || 0) - 1;
        throw new HttpsError(
            "permission-denied",
            attemptsLeft > 0 ?
              `Incorrect code. ${attemptsLeft} attempt${attemptsLeft === 1 ? "" : "s"} left.` :
              "Incorrect code. Request a new code.",
        );
      }

      if (purpose === "registration") {
        await getAuth().updateUser(auth.uid, {emailVerified: true});
        await getFirestore().collection("users").doc(auth.uid).set({
          emailVerified: true,
          updatedAt: FieldValue.serverTimestamp(),
        }, {merge: true});
      } else {
        await getAuth().updateUser(auth.uid, {
          email: targetEmail,
          emailVerified: true,
        });
        await getFirestore().collection("users").doc(auth.uid).set({
          email: targetEmail,
          emailVerified: true,
          updatedAt: FieldValue.serverTimestamp(),
        }, {merge: true});
      }

      await reference.delete();
      return {verified: true, email: targetEmail};
    },
);
// Fires whenever any vendor document is updated. We only act when the
// vendor transitions from closed to open -- editing other fields (name,
// description, menu, etc.) does not trigger a notification.
exports.recordVendorOpeningHistory =
  require('./notification-history.cjs').recordVendorOpeningHistory;

exports.cleanupDeletedMenuItemImage = onDocumentDeleted(
    {
      document: "vendors/{vendorId}/menu/{itemId}",
      retry: true,
    },
    async (event) => {
      const {vendorId, itemId} = event.params;

      await getStorage()
          .bucket()
          .file(`menu_images/${vendorId}/${itemId}.jpg`)
          .delete({ignoreNotFound: true});
    },
);

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
