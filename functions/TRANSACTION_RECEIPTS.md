# PDF receipts and transaction emails

`getBookingReceipt` generates an authenticated PDF from the server's booking
snapshot. Only the verified customer who owns the booking and administrators
can download it. Unpaid bookings have no receipt. Customer Android/web and the
admin Booking history page use this same callable.

`queueTransactionEmail` records a private durable outbox job for each change to
payment status or refunded cents, including the initial awaiting-payment state.
Preparing/ready/collected updates do not create financial emails. The recipient
comes from Firebase Auth's verified customer email. Once payment is recorded,
updates include a PDF attachment. Sandbox emails and PDFs clearly say test payment.
Existing bookings are not emailed retrospectively on deployment.

`sendTransactionEmail` attempts delivery, and `retryTransactionEmails` retries due
jobs every five minutes. Status is shown in admin Booking history after Refresh:
queued, sent, failed, or recipient unavailable. Sent means the SMTP server accepted
the message; inbox placement and bounces depend on the email provider.
Repeated delivery of the same Firebase event reuses its outbox ID. SMTP cannot
guarantee exactly once delivery if a server accepts a message and the function
crashes before storing success; stable Message-ID values help investigation.

## Configure email

The selected sender is `StallSeeker <receipts@stallseeker.my>`.
Use Brevo SMTP and authenticate the `stallseeker.my` domain in Brevo before sending.
This sender selection does not create an inbox or complete domain verification.
Create two
Firebase secrets interactively; do not put passwords into source files:

```powershell
npx -y firebase-tools@latest functions:secrets:set TRANSACTION_SMTP_URL --project stallseeker-c2ffe
npx -y firebase-tools@latest functions:secrets:set TRANSACTION_EMAIL_FROM --project stallseeker-c2ffe
```

SMTP URL format: `smtps://USERNAME:PASSWORD@smtp.example.com:465`, or
`smtp://USERNAME:PASSWORD@smtp.example.com:587` with mandatory STARTTLS. URL-encode
special characters in username/password. Set FROM to `StallSeeker <receipts@stallseeker.my>`.
Use the provider's SMTP credentials (or an app password if required).

Configure SPF/DKIM for your sender following that provider's instructions. Firebase
Authentication's verification-email templates do not send transaction emails.

## Publish

From the Flutter project directory, after configuring the secrets:

```powershell
npx -y firebase-tools@latest deploy --only functions:getBookingReceipt,functions:queueTransactionEmail,functions:sendTransactionEmail,functions:retryTransactionEmails --project stallseeker-c2ffe
flutter build web --release
npx -y firebase-tools@latest deploy --only hosting --project stallseeker-c2ffe
flutter build apk --release
```

Deploy the account-deletion codebase too to include cleanup of customer email jobs:
`npx -y firebase-tools@latest deploy --only functions:account-deletion --project stallseeker-c2ffe`.

From the separate admin project directory:

```powershell
npm run build
npx -y firebase-tools@latest deploy --only functions:getBookingHistory --project stallseeker-c2ffe
npx -y firebase-tools@latest deploy --only hosting --project stallseeker-c2ffe
```

The PDF endpoint can be deployed on its own before SMTP is configured. Receipt
emails require the queue and both sending workers plus valid credentials.

## Check after release

Make a new Stripe test payment. Download the PDF from Android/web and from admin
Booking history. Check items, amounts, reference and Malaysia payment time. Verify
emails arrive at the customer's verified account address and paid messages attach
a readable PDF. Exercise payment failure, cancellation, partial/full refund, and
temporary SMTP failure/recovery. Check queued/failed/sent status after admin Refresh.
Unauthenticated users, vendors, and other customers must not download the receipt.
