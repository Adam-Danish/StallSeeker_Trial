# Deploy the vendor reporting patch

**This release is already applied and deployed.** See `DEPLOYMENT.md`. The commands below are a reference for future releases; do not reapply the patches to the current working copies.

## 1. Apply the patches

Back up or commit your existing work first. In the Flutter project:

```powershell
Set-Location 'C:\Others\SE\Flutter Projects\StallSeeker_Trial'
git apply --check output/vendor-moderation-patch/app-backend.patch
git apply output/vendor-moderation-patch/app-backend.patch
```

In the admin project:

```powershell
Set-Location 'C:\Others\SE\Flutter Projects\StallSeeker-Admin'
git -c core.bare=false --work-tree=. apply --check 'C:\Others\SE\Flutter Projects\StallSeeker_Trial\output\vendor-moderation-patch\admin.patch'
git -c core.bare=false --work-tree=. apply 'C:\Others\SE\Flutter Projects\StallSeeker_Trial\output\vendor-moderation-patch\admin.patch'
```

Stop if either check fails. Do not apply either patch twice.

## 2. Check and prepare the app

```powershell
Set-Location 'C:\Others\SE\Flutter Projects\StallSeeker_Trial'
flutter pub get
flutter analyze
flutter test test/moderation_test.dart
npm ci --prefix functions
npm ci --prefix functions-account
```

Review `VERIFICATION.md` for full-suite results and remaining Android-device/push testing. The rules should be reviewed before broad rollout.

## 3. Deploy indexes

```powershell
firebase deploy --only firestore:indexes --project stallseeker-c2ffe
```

In the Firebase console, open Firestore → Indexes and wait until the new indexes finish building before continuing. If asked to delete unrelated indexes, decline and reconcile the local index file first.

## 4. Deploy only the affected backend functions and rules

Still in the Flutter project:

```powershell
$moderationTargets = @(
  'functions:default:submitVendorReport'
  'functions:default:reviewVendorReport'
  'functions:default:submitVendorCorrection'
  'functions:default:decideVendorModeration'
  'functions:default:finishResolvedVendorReports'
  'functions:default:notifyVendorModeration'
  'functions:default:createBooking'
  'functions:default:notifyFollowersOnDishAvailable'
  'functions:account-deletion:cleanupDeletedAccount'
) -join ','

node output/vendor-moderation-patch/prepare-function-bundle.cjs
node output/vendor-moderation-patch/verify-function-bundle.cjs
firebase deploy --config output/vendor-moderation-patch/functions-deploy.json --only $moderationTargets --project stallseeker-c2ffe
firebase deploy --only firestore:rules --project stallseeker-c2ffe
```

Wait for both commands to succeed before publishing the interfaces. These selectors preserve the other function codebases; do not substitute a bare `firebase deploy`. The focused bundle avoids unrelated transaction-email secrets that are currently unset. Every included module, dependency lockfile, and selected function definition is checked against the source. The first creation of `finishResolvedVendorReports` required Firebase's `--force` acknowledgment for its tested idempotent retry policy; that acknowledgment was completed during this release.

## 5. Publish the web app

```powershell
flutter build web --release
firebase deploy --only hosting --project stallseeker-c2ffe
```

This updates the existing customer/vendor site at https://stallseeker.my/ and its default Firebase Hosting domain. Preserve any custom web-push build definition you use for normal releases.

## 6. Publish the admin page

```powershell
Set-Location 'C:\Others\SE\Flutter Projects\StallSeeker-Admin'
npm run build
firebase deploy --only hosting --project stallseeker-c2ffe
```

The admin project's `firebase.json` targets `stallseeker-admin`, so this updates the admin site, not the customer/vendor site. Use these commands rather than `npm run deploy`, which also invokes unrelated admin backend deployments.

## 7. Update Android

For a test APK:

```powershell
Set-Location 'C:\Others\SE\Flutter Projects\StallSeeker_Trial'
flutter build apk --debug
```

Install `build\app\outputs\flutter-apk\app-debug.apk` on your test phone. Web deployment does not update installed Android applications.

For Google Play, first configure a proper release signing key and increase the app version/build number, then build and upload an app bundle with `flutter build appbundle --release`. The current Gradle release configuration still uses the debug signing key, so it needs release-signing setup before a store release.

## 8. Check the live feature

Use dedicated test accounts and a test stall. Check customer reporting, admin verification, the vendor warning/deadline, correction submission, and admin approval. Test overdue suspension without backdating live vendor cases. Confirm existing bookings remain accessible and newly suspended stalls cannot receive new bookings.

References: https://firebase.google.com/docs/functions/manage-functions, https://firebase.google.com/docs/functions/organize-functions, https://firebase.google.com/docs/hosting/quickstart, https://firebase.google.com/docs/firestore/query-data/indexing, https://docs.flutter.dev/deployment/android.
