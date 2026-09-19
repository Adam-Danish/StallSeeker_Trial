# Recent changes test results

Date: 18 September 2026 (MYT). Source: current uncommitted working tree on base commit `f2dde9b`. The debug APK is `build/app/outputs/flutter-apk/app-debug.apk` (SHA-256 `14BBDAC304B2E3E49C6F38CE6C04F9CD5402C38997C1FC845FAD354C19C5D404`). Firebase project: `stallseeker-c2ffe` for deployment verification; `demo-stallseeker-rules` for isolated rule tests.

This is a partial execution of the [50-case recent changes test plan](Recent%20Changes%20Test%20Plan.md). Automated checks passed, but no Android device or AVD was connected, so the customer and vendor journeys have not received a device pass. The APK has not been distributed.

## Fixes made after testing

| Finding | Fix | Verification |
| --- | --- | --- |
| Guest and cross-account writes to vendor and menu records were allowed by public Firestore rules. | Vendor and menu writes now require the owning, signed-in vendor; reads remain public. Vendor signup's atomic user and stall creation is supported. | Firestore Emulator allow/deny tests pass; rules deployed to `stallseeker-c2ffe`. SEC-06 passes in the isolated emulator. |
| Review photo URL arrays accepted malformed entries, and callers could forge `updatedAt`. | Limit photo URLs to five strings and require the server request time for `updatedAt`. | Firestore Emulator valid/invalid review tests pass; rules deployed. |
| Scheduled closure logic had no direct regression tests, including large result sets. | Extracted closure selection and Firestore batching into a testable module. | Three Node tests pass, including 401 stalls split into two batches; updated scheduled function deployed. |

## Checks run

| Check | Result | Evidence and scope |
| --- | --- | --- |
| `dart analyze lib test` | Pass | No analyzer issues in app and new tests. |
| `flutter test --no-pub` | Pass: 7/7 | Phone validation, weekly hours and closure boundaries, effective closed state, legacy menu section and stock time, schedule editor controls. |
| `firebase emulators:exec --only firestore,storage --project demo-stallseeker-rules "npm test --prefix firebase-tests"` | Pass: 5/5 | Vendor/menu ownership and signup, immutable user role, review data validation, and review photo Storage permissions. Expected denied requests appear in emulator logs. |
| `npm test` in `functions-schedule` | Pass: 3/3 | Closure start/end behavior, only active closures, write batching. |
| `node --test functions/history-core.test.cjs` | Pass: 5/5 | Existing notification history regression checks. |
| Android debug APK build | Pass | `flutter build apk --debug --no-pub`; APK hash above. |
| Firebase deployment | Pass | Firestore rules and `schedule:closeStallsForScheduledBreaks(us-central1)` deployed. `firebase functions:list` readback showed `closeStallsForScheduledBreaks`. |
| Malaysia location service spot check | Pass, limited | Live Photon queries returned multiple results for Kota Kinabalu, Kuching, Ipoh, and Johor Bahru as well as earlier Bangi and Jalan Ilmiah checks. This confirms the search is not restricted to the two examples; it does not prove every Malaysian address is indexed. |

## Still to execute before release

- All device-driven plan cases, especially SMK-01 through SMK-09: map/list filtering, selecting suggested locations, vendor schedule persistence, stock updates, review creation/editing and photos, guest prompts, and dialer links.
- Timed closure on a real backend with a backgrounded vendor app (SMK-05, SEC-03 and SEC-04). Unit tests verify selection and write logic, not scheduler timing or notifications end to end.
- Account deletion cleanup of reviews and photos, plus the collection-group index query (REV-09 and SEC-02), using disposable accounts.
- Offline, weak-network, accessibility, and compact-screen cases. Load and reliability checks for the public Photon demo service.
- A physical Android smoke pass. `adb devices` listed no connected device and `emulator -list-avds` found no AVD during this run.

## Open release risks

- Firestore collections `reports`, `stalls`, and `_connection_test_` still have public write rules. Their consumers and migration needs should be checked before tightening them and before wider release.
- Photon is a public demo service with no availability guarantee. A managed or self-hosted location search service is needed for dependable production traffic.

The automated checks alone do not satisfy the plan's release criteria. Complete the P0/P1 device and backend journey checks before distributing this build.
