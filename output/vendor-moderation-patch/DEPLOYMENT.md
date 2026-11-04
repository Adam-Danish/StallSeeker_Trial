# Reporting release — 4 November 2026

## Published

- Customer/vendor website: https://stallseeker.my/
- Admin website: https://admin.stallseeker.my/
- Default Hosting URLs: https://stallseeker-c2ffe.web.app/ and https://stallseeker-admin.web.app/
- Android test APK: `C:\Others\SE\Flutter Projects\StallSeeker_Trial\build\app\outputs\flutter-apk\app-debug.apk` (approximately 196 MiB).

The patches are applied to both original projects. The backend, Firestore rules/indexes, and both website releases are published. The Android APK is built and ready to install; installed phone apps do not update through a website deployment.

## Customer report entry point

Refresh the website, tap a stall marker/card, and choose **Report this stall** beside Directions, Follow, and View menu. The full stall details page also has a flag button in its top bar. Customers must sign in with a verified account to submit a report. Submitted reports appear under Profile → My reports.

The entry button was corrected after the initial release: it had been inserted into a sign-in popup rather than the details toolbar. The correction adds a direct labelled action in the map stall preview and the flag in the proper toolbar. Two real customer-home navigation tests passed at 360px and 960px, and 16 stall-preview/reporting regression tests passed. The updated website and APK include this correction.

For this button correction, nine live file checks passed their complete build hashes. The custom-domain main-script download timed out on the verification connection after returning a matching prefix; the same complete script on the default Firebase Hosting domain passed its full hash check. Both domains' updated entry pages matched the release.

## Live verification

- All nine selected Cloud Functions are ACTIVE: six new moderation functions plus booking creation, dish-restock notifications, and account cleanup updates.
- Seven reporting indexes are READY. All 45 pre-existing index IDs are preserved, including explicit document-ID ordering used by the admin directory. Total live composite indexes: 52.
- Published Firestore rules match the local tested rules.
- All four callable moderation endpoints reject unauthenticated requests with HTTP 401 and return the expected CORS origin.
- The customer/vendor and admin custom domains, plus their default Firebase domains, return HTTP 200 and serve files whose SHA-256 hashes match the released builds. Ten entry-script/content checks passed.
- Current admin accounts use their existing trusted admin role for moderation. A final compatibility check found they are not email-verified, so the reporting endpoints/rules were adjusted and retested to retain the dashboard's existing role policy. Customer and vendor reporting/correction operations still require verified accounts; non-admin users cannot approve reports or change penalties.

See `live-deployment-verification.json`, `live-website-verification.json`, and `admin-access-check.json` for recorded checks. No real customer reports, vendor warnings, or penalties were created for production testing.

## Tests and builds

- Flutter analysis: no issues.
- Focused reporting/dashboard/profile tests: 22 passed.
- Complete Flutter suite: 196 passed; six previously identified discovery/map tests failed. These same failures were reproduced in the unchanged baseline before patch application.
- Firebase rules and moderation integration tests: 47 passed, including the existing-admin compatibility checks and verification requirements for customers/vendors.
- Backend/account tests: 50 passed; one existing optional account-deletion auth-emulator test skipped.
- Browser startup tests: seven passed.
- Flutter web release build, admin production build, and Android debug APK build: passed.

The original emulator/browser checks exercised customer report submission, third-report warning creation, vendor response, and admin approval. Live checks used metadata and unauthenticated requests rather than real penalties. Physical Android use and live push delivery remain device checks. The browser automation runtime was unavailable during the final live-page check; exact released file contents and HTTP responses were verified directly instead.

## Deployment notes

The ordinary functions deploy encountered unrelated, unset transaction-email secrets. The reporting release used a focused source bundle with identical selected modules, dependency manifest/lockfile, and function definitions. This left unrelated email functions and settings untouched. `focused-bundle-verification.json` records that comparison; `DEPLOY.md` contains the reproducible command.

The deployed rule and website release details from before this release are saved under the locally ignored `deployment-backup/cloud` folder. Original affected source files are backed up under `deployment-backup`; Dart backups use a `.backup` suffix to keep the analyzer from treating partial backups as application source. `deployment-backup/manifest.json` records their paths.

Google Play publication is not included. The current Android release Gradle configuration uses the debug signing key; configure production signing before a store release.
