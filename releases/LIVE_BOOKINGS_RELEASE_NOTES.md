# StallSeeker live self-collect bookings — 8 October 2026

APK: `StallSeeker-live-bookings-v1.0.3-b4.apk`  
Version: 1.0.3 (build 4)  
Size: 64,004,804 bytes  
SHA-256: `9306F9BFD144D887E3A5DE49CC5BDF2EBAD057F15547E501CF30F08B3A6EEC18`

## Changes

- Self-collect is optional for each vendor and starts off until enabled online.
- Customer requests now sync between customer and vendor accounts through
  `stallseeker-c2ffe`. The vendor can accept, reject, cancel, prepare, mark ready,
  and mark collected. Customers can cancel before acceptance. Unanswered
  requests expire after 10 minutes.
- Customer Settings shows up to two active bookings between the profile card
  and Location. My bookings has Active, History, and read-only Past demos.
- Each booking has its own item, total, pickup location, and progress details.
  Settings and Dashboard badges count unseen ready bookings and new requests;
  opening a booking clears only that booking's indicator.
- Vendor and customer booking phone alerts open the matching booking when
  notifications are enabled. In-app badges work independently of notification
  permission. There is no in-app payment.

## Online deployment

Booking-only Firestore rules and three composite indexes were deployed to
`stallseeker-c2ffe`. The `createBooking`, `updateBooking`, `markBookingViewed`,
and `expireBookings` Cloud Functions were deployed, and `deleteAccount` was
updated to remove a deleted account's bookings. Local unrelated Firestore
changes were not published with this deployment.

## Verification and limitation

All 31 Flutter tests, 11 backend logic tests, and 18 Firestore/Storage rules
tests passed. The exact booking-only rules deployed also passed their three
booking rules tests. `dart analyze lib test` found no issues. The APK reports
version 1.0.3/build 4, verifies with Android APK v2 signing, and uses the same
Android Debug certificate as the previous prototype APK. It is suitable for
sideload testing.

A complete customer/vendor walkthrough on two phones was not possible on this
computer. The second Android emulator could not become usable with the
available disk space. The first emulator booted, but its package service
returned a broken-pipe error during APK installation, so an on-device launch
was not verified. Live push delivery and badge clearing on two actual phones
still need a hands-on check before a public release.
