# StallSeeker

StallSeeker is a Flutter app that helps customers find nearby food stalls and see their current location, opening status, menu, and stock availability. Vendors can manage their stall and share their location while open.

## Features

### Customers

- Discover stalls on a map and filter by location, category, distance, price, and opening status.
- Browse menus, reviews, and directions.
- Follow stalls and dishes for updates.
- Request and track self-collect bookings.
- Browse as a guest or sign in for account features.

### Vendors

- Manage stall details, business hours, and temporary closures.
- Add and update menu items, prices, images, and stock status.
- Open or close the stall and share its location while open.
- Manage booking requests.

## Tech stack

- Flutter and Dart
- Firebase Authentication, Firestore, Storage, Cloud Functions, and Cloud Messaging
- Google Maps and device location services

## Getting started

### Prerequisites

- Flutter with Dart SDK `>=3.5.0 <4.0.0`
- Android Studio and an Android emulator or device
- Access to a configured Firebase project
- Node.js 22 for Cloud Functions development

### Run the app

```bash
git clone https://github.com/Adam-Danish/StallSeeker_Trial.git
cd StallSeeker_Trial
flutter pub get
flutter run
```

Before running, place the project's `google-services.json` file in `android/app/`. This file is excluded from Git. The Firebase project must have the services used by the app configured, and Google Maps needs a working Android Maps API key.

The repository contains generated Firebase settings in `lib/firebase_options.dart`. If you use another Firebase project, regenerate those settings and provide the matching platform configuration.

## Project structure

```text
lib/core/              Models, services, theme, and constants
lib/features/auth/     Sign-in, registration, and account routing
lib/features/customer/ Customer discovery, stall details, and bookings
lib/features/vendor/   Vendor dashboard, menu, and stall management
lib/features/shared/   Screens shared across user roles
functions/             Booking and notification Cloud Functions
functions-account/     Account deletion Cloud Functions
functions-schedule/    Scheduled stall closure Cloud Functions
firebase-tests/        Firebase rules and booking tests
appium-tests/          Android end-to-end tests
test/                  Flutter tests
docs/                  Test plans and demo documentation
```

## Testing

Run Flutter tests:

```bash
flutter test
```

Run Cloud Functions tests:

```bash
node --test functions/*test.cjs
npm test --prefix functions-schedule
```

Run Firebase tests with the Firestore and Storage emulators:

```bash
firebase emulators:exec --only firestore,storage --project demo-stallseeker-rules "npm test --prefix firebase-tests"
```

For Android Appium setup, see `appium-tests/README.md`.
