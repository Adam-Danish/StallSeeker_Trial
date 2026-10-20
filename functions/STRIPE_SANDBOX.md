# StallSeeker Stripe prototype

This integration accepts **sandbox keys only**. Customers pay as soon as they
place a self-collect booking. Vendor acceptance is not required. The vendor
sees the new booking after server-verified payment and must wait for that
confirmation before preparing it. New bookings require at least RM2.00 and
give customers 10 minutes to pay. Older bookings keep their original flow.

## Try it

1. Install/restart the updated app. Sign in with verified customer and vendor accounts.
2. Customer: choose at least RM2.00 of dishes and tap Continue to payment.
3. Checkout opens automatically. Use Stripe test card
   `4242 4242 4242 4242`, any future expiry, and any three-digit CVC.
5. Close the checkout browser and return to the booking. Payment refreshes on
   return; Check payment can also refresh it. A browser redirect alone never
   marks a booking paid.
6. Vendor: see the paid booking, start preparing, mark ready, then collected.
   Demo sales and payment history show the simulated payment.
7. Either customer or vendor can cancel before collection, including after
   payment. The server requests a full test refund to the original payment
   method. Failed refunds show a status requiring administrator attention.

There are **no vendor bank deposits, transfers, Stripe Connect accounts, or real
payouts**. Vendors need only their normal StallSeeker account for this prototype.
The platform's Stripe sandbox contains the test transactions; the app attributes
each booking to its vendor. Do not treat demo sales as a withdrawable balance.

## Configuration

Firebase project: `stallseeker-c2ffe`. Callable/HTTP/scheduled functions use
`us-central1`; the Firestore cancellation trigger uses the database region,
`asia-southeast1`.
Store `STRIPE_SECRET_KEY` and `STRIPE_WEBHOOK_SECRET` in Google Secret Manager.
Never place either in Flutter, Git, screenshots, or logs. Hosted Checkout needs
no Stripe publishable key in this Flutter app.

Webhook URL:
`https://us-central1-stallseeker-c2ffe.cloudfunctions.net/stripeWebhook`

Subscribed events: `checkout.session.completed`,
`checkout.session.async_payment_succeeded`,
`checkout.session.async_payment_failed`, `checkout.session.expired`,
`payment_intent.payment_failed`, `charge.refunded`, `refund.updated`.

The local `scripts/configure-stripe-sandbox.cjs` helper uses the signed-in Firebase
CLI account, reads credentials only in memory, and disables credential logging.
On Windows it finds firebase-tools in `%APPDATA%/npm/node_modules`; set
`FIREBASE_TOOLS_ROOT` for a different installation. It creates a sandbox webhook
and stores its signing secret. If an endpoint already exists, the helper leaves
it unchanged; keep the matching signing secret. It never switches to live mode.

## Backend behavior

- `createStripeCheckout`: verifies the customer, eligible booking, deadline and
  server-calculated amount. One persisted idempotent session per booking.
- `refreshStripePayment` and `stripeWebhook`: reconcile with Stripe's current
  state; webhooks verify the raw request signature. Events cannot choose the
  amount, recipient, or paid state.
- `expireStripePayments`: closes unpaid checkout sessions after the app deadline.
  Stripe's own session expiry is longer, so a scheduled task enforces this window.
- `closeCancelledStripePayment`: closes cancelled sessions and refunds late or
  already-completed test payments. Full dashboard refunds cancel active bookings;
  partial refunds reduce demo sales. Collected bookings retain their history.
- Public booking documents contain payment status and reference. Checkout attempt
  data is in server-only `bookingPayments`; existing default-deny rules protect it.
- The booking/status/deadline composite index is in `firestore.indexes.json`.

## Validation

From the repository root:

```text
node --test functions/*.test.cjs
flutter analyze
flutter test --no-pub test/payment_ui_test.dart test/booking_card_test.dart test/demo_booking_service_test.dart
firebase emulators:exec --only firestore --project demo-stallseeker-bookings "node --test firebase-tests/bookings.test.cjs"
```

UI previews are optional: add `--dart-define=PAYMENT_PREVIEW=true` and
`--dart-define=PREVIEW_FONT_ROOT=<Flutter SDK>/bin/cache/artifacts/material_fonts`
to the Flutter test command. Previews go to ignored `tmp/payment-previews/`.

The backend tests cover duplicate requests, ownership/amount checks, expiry and
cancellation races, repeated notifications, and refunds. The emulator checks
that clients cannot forge payment fields or read/write private checkout records.
An actual checkout on the updated app is still the final device acceptance test.

Stripe SDK 23 uses API `2026-09-30.endive`. Checkout uses the
[`allowed_payment_method_types` filter](https://docs.stripe.com/api/checkout/sessions/create)
to offer enabled cards; the older `payment_method_types` request parameter is
rejected by this API version.
