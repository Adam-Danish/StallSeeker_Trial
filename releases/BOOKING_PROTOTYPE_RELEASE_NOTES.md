# StallSeeker self-collect booking prototype — 8 October 2026

APK: `StallSeeker-booking-prototype-v1.0.2-b3.apk`  
Version: 1.0.2 (build 3)  
Size: 63,578,796 bytes  
SHA-256: `4F298A329BD14A1E34AF93B1A51D628F9C5AD789B2B27DF280E88D83D1587D8E`

## What this build does

- A vendor can turn on the self-collect booking demo from the dashboard.
- A customer can select available menu items and save a booking request.
- The vendor account can accept or reject it, then mark it preparing, ready,
  and collected. Both accounts can review their booking history.
- The payment screen and simulated payment step have been removed. The app
  does not take an in-app payment.
- Guest search history still merges into a customer account after sign-in.

## Prototype limit

Bookings and the vendor's booking setting are stored **on this phone only**.
To demonstrate the vendor flow, switch between customer and vendor accounts
on the same phone. A vendor on another phone will not receive the request.
The screens show this limit. No Firebase order functions or rules were enabled
in the live project.

This is a booking interaction prototype, not a real reservation or payment
system. The menu and stall details still use the app's existing Firebase data.
Clearing the app's data removes local bookings.

## Verification

`dart analyze lib test` found no issues. All 30 Flutter tests passed, including
the local booking status and persistence test. The APK reports version 1.0.2
and build 3 and verifies with an Android APK v2 signature. Its signing
certificate matches the previous v1.0.1 prototype APK. No phone installation
or two-phone booking test was performed.
