# Vendor reporting — unified diff patches

These patches have **not been applied** to the original projects. Nothing has been deployed.

## Files

- `app-backend.patch`: apply in `StallSeeker_Trial`. Includes shared Flutter web/Android screens, Firebase functions, rules, indexes, account-cleanup changes, and tests.
- `admin.patch`: apply in `StallSeeker-Admin`. Includes report review, warning/correction history, and working suspension/restoration controls.
- `VERIFICATION.md`: checks performed and remaining limitations.
- `admin-preview.png`, `vendor-preview.png`, and `customer-preview.png`: local demo browser evidence. No live customer or vendor accounts were used.

## Behavior

Three admin-verified reports from different customers, submitted within a rolling 30-day window, issue one warning. Pending, rejected, old, and previously counted reports do not increase the threshold. One customer can submit one report per stall every 30 days.

The vendor receives 48 hours to fix the information. The deadline does not extend when a correction is submitted. An admin may suspend an overdue listing; suspension hides it in the app and blocks new bookings until an admin approves the correction. Existing bookings remain manageable. Restoration leaves the stall closed until the vendor opens it.

Reports include an explanation, observation time, and a bounded snapshot of the listing and first 100 menu items. Vendors see complaint summaries without customer identities. Reporting is separate from public reviews. No fines, permanent bans, automatic suspension, or photo uploads are included.

## Apply later

The commands below describe application only; they have not been run against the original projects. Back up or commit your current work first. These patches were generated from the current working files, including existing local changes as their baseline; those unrelated changes are not included in the patches.

From the Flutter project directory:

```powershell
git apply --check output/vendor-moderation-patch/app-backend.patch
git apply output/vendor-moderation-patch/app-backend.patch
```

From the admin project directory, use the actual path to the delivered patch:

```powershell
git -c core.bare=false --work-tree=. apply --check 'C:\Others\SE\Flutter Projects\StallSeeker_Trial\output\vendor-moderation-patch\admin.patch'
git -c core.bare=false --work-tree=. apply 'C:\Others\SE\Flutter Projects\StallSeeker_Trial\output\vendor-moderation-patch\admin.patch'
```

The explicit admin work-tree option accommodates the current admin checkout's Git configuration. It changes no saved Git configuration.

## Verify after application

In the Flutter project, run `flutter analyze`, `flutter test`, `flutter build web --release`, and `flutter build apk --debug`. Run Node function tests and Firebase rule/integration tests with local emulators. The baseline currently has six failing map/discovery tests; see `VERIFICATION.md`.

In the admin project, run `npm run build`. Type checking currently needs these overrides for the pre-existing compiler configuration:

```powershell
node node_modules/typescript/bin/tsc --noEmit --ignoreDeprecations 5.0 --allowImportingTsExtensions
```

## Release order, when deployment is requested

1. Deploy the added indexes and wait for them to finish building.
2. Deploy the moderation functions and updated booking, dish-notification, and account-cleanup functions; deploy the combined Firestore rules before exposing the new interfaces.
3. Publish the Flutter web build, admin build, and updated Android application.

The new functions are `submitVendorReport`, `reviewVendorReport`, `submitVendorCorrection`, `decideVendorModeration`, `finishResolvedVendorReports`, and `notifyVendorModeration`, all in `asia-southeast1`. Existing functions requiring an update are `createBooking`, `notifyFollowersOnDishAvailable`, and `cleanupDeletedAccount` (account-deletion codebase). Use targeted deployment so other codebases' functions are preserved. Do not deploy the test preview tools.

The existing Firebase project and `(default)` Standard-edition database are retained. Existing vendors without `listingStatus` are treated as active; retired reports are not imported.

An older installed Android client may still display a suspended listing until it updates. The backend already blocks new bookings and the rules block reopening. Release the updated clients to complete the visibility behavior.

Security Rules remain a prototype requiring review before broad rollout. The included emulator checks cover report privacy, server-only decisions, and suspension bypass attempts.
