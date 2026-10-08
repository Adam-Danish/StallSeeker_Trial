# StallSeeker prototype APK — 7 October 2026

Version: 1.0.1 / build 2. This is a sideload prototype APK with simulated
payments only. No card or bank details are collected and no money moves.

File: `StallSeeker-prototype-v1.0.1-b2.apk` (63,496,876 bytes)

SHA-256: `03EF1739CD32A2BD0A7D026729C1B64F9F1E4ED73AC5304524E798E041E61F54`

## Prototype flow

Vendors can opt into demo self-collect from the dashboard and can always open
their order history. Customers see the order button only when the stall is open
and has enabled demo self-collect. A signed-in customer chooses dishes and sends
a request. The vendor accepts or rejects it. The customer then taps **Simulate
payment**, after which the vendor can mark it preparing, ready and collected.
Customer and vendor order history show the same order across devices. Requests
expire after five minutes; accepted orders expire if no demo payment is made
within ten minutes. Guest searches merge into a customer account after sign-in.

## Backend requirement

The APK is packaged with the app's existing Firebase configuration, which points
to `stallseeker-c2ffe`. Prototype order Cloud Functions and Firestore rules are
prepared in the repository but are not enabled in that live project by building
the APK. Until a test backend is connected or the prepared backend is deployed,
demo order requests cannot complete across devices. Do not use this APK as a
real ordering or payment system.

The unused prototype order backend was removed from the current source when
v1.0.2 replaced this flow with device-only self-collect bookings.

## Validation

Flutter source analysis passed. All 29 Flutter tests, 18 Firebase emulator
rules tests, and 2 backend order flow tests passed. The APK manifest reports
version 1.0.1 / build 2, and the APK v2 signature verifies with the project's
existing Android Debug certificate. It is suitable for sideload testing.
The signing certificate matches the 4 October APK, so it can install over that
build on the same device.
