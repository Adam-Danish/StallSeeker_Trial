# StallSeeker Test Plan

| Field | Value |
| --- | --- |
| Product | StallSeeker |
| App version | 1.0.0+1 |
| Plan version | 1.0 |
| Prepared | 11 September 2026 |
| Status | Ready for review and execution |
| Primary stack | Flutter, Firebase Authentication, Firestore, Storage, Cloud Functions, FCM, Google Maps |
| Primary roles | Guest, customer, vendor |

## 1. Purpose

This plan verifies that StallSeeker reliably connects customers with nearby food stalls while protecting account data and handling location, notification, and network failures safely.

The release quality goals are:

1. A guest or customer can find a relevant stall and view accurate details without a crash or dead end.
2. A vendor can maintain a stall and menu, open or close the stall, and share location only when intended.
3. A customer can follow a stall and receive one useful opening update through push and notification history.
4. Authentication, profile changes, sign-out, and account deletion preserve role and ownership boundaries.
5. Failure states are recoverable and never silently corrupt stall, menu, follow, notification, or account data.

## 2. Scope

### In scope

- App startup, Firebase initialization, splash screen, session restoration, and account recovery.
- Anonymous guest access, email/password registration and login, Google sign-in, password reset, email verification, and email change code flows.
- Customer and vendor role routing.
- Customer GPS and manual location selection, saved location, map browsing, search, category filters, radius changes, and distance ordering.
- Stall markers, stall cards, stall details, live vendor changes, menu availability, following, and directions handoff.
- Vendor stall profile, image upload, menu create/edit/delete, stock state, open/close state, and foreground/background location sharing.
- Customer notification preferences, FCM token lifecycle, push handling, notification history, unread state, badge count, and notification deep links.
- Profile editing, password change, logout, privacy/terms/FAQ screens, and permanent account deletion.
- Firestore, Storage, Authentication, Cloud Function, and security-rule behavior used by the app.
- Accessibility, responsive layout, performance, battery use, connectivity, privacy, and basic compatibility.

### Out of scope

- Payments, ordering, chat, ratings, and administration features, because they are not present in this version.
- Correctness of routing inside Google Maps or Waze after StallSeeker hands off the coordinates.
- Internal availability guarantees of Google, Firebase, SMTP, or mobile operating-system services. StallSeeker's handling of their success and failure responses remains in scope.
- Desktop platforms unless they are added to the release target. Web receives a compatibility smoke pass only until its native location, map, image, and notification expectations are formally defined.

## 3. Test priorities and severity

| Priority | Meaning | Execution rule |
| --- | --- | --- |
| P0 | Startup, data security, destructive actions, and release-critical end-to-end paths | Run on every release candidate; all must pass |
| P1 | Core customer/vendor behavior and important recovery paths | Run on each release candidate and relevant pull request |
| P2 | Secondary behavior, compatibility, and uncommon errors | Run in full regression |
| P3 | Cosmetic or low-impact behavior | Run when the affected area changes |

| Severity | Definition |
| --- | --- |
| Critical | Data exposure/loss, unauthorized access, wrong-account action, or app unusable for all users |
| High | A core journey cannot be completed and no acceptable workaround exists |
| Medium | A feature is degraded but a reasonable workaround exists |
| Low | Minor visual, copy, or convenience issue with no incorrect data or blocked journey |

## 4. Test approach

### Automated layers

1. **Dart unit tests:** model parsing, validation, location freshness, search/filter/radius logic, formatting, and service error mapping.
2. **Flutter widget tests:** forms, role/guest gates, loading/empty/error states, navigation, menu actions, notification filters, and responsive layouts with Firebase/plugin boundaries mocked.
3. **Firebase emulator integration tests:** Authentication, Firestore ownership, rules, follow consistency, menu writes, account recovery, notification history, and account deletion.
4. **Cloud Function tests:** verification-code rules, opening transition behavior, idempotency, follower eligibility, push targeting, and recursive deletion.
5. **Mobile integration tests:** critical customer and vendor journeys using Flutter `integration_test` against a dedicated staging project.

### Manual layers

- Real-device permission behavior for location, background location, notifications, photos, and external navigation apps.
- Push delivery while the app is foregrounded, backgrounded, and terminated.
- Background location accuracy, battery behavior, and operating-system indicators.
- Screen reader, large text, rotation, keyboard, poor-network, and visual checks.

Manual exploratory testing should vary action order, rapidly repeat taps, switch accounts, background or kill the app during writes, and change the same record from a second device.

## 5. Environments and device matrix

| Environment | Purpose | Data policy |
| --- | --- | --- |
| Local unit runner | Fast Dart and Node tests | Fakes only; no production services |
| Firebase Emulator Suite | Auth, Firestore, rules, Functions, and deletion integration | Resettable synthetic data |
| Dedicated staging Firebase project | Maps, Google sign-in, SMTP verification, Storage, FCM, and full flows | Test accounts and non-sensitive images only |
| Production-like release build | Final Android/iOS smoke and upgrade checks | Controlled test accounts; no destructive tests on real users |

Minimum device coverage:

- Android: one device at the configured minimum SDK, one mid-range physical device, and one device on the highest supported target SDK.
- iOS: one iPhone on the oldest supported iOS version and one on the newest supported version; include a physical device for push and background location.
- Form factors: compact phone, large phone, and one tablet-size viewport.
- Network states: stable Wi-Fi, cellular, high latency, packet loss, offline, and offline-to-online recovery.
- Location states: services on/off, precise/approximate where supported, allow once/while using/always, denied, and denied permanently.
- Notification states: allowed, denied, quiet/provisional where supported, and disabled inside StallSeeker.

Run the release smoke suite on physical Android and iOS devices. Emulators alone are insufficient for FCM, background location, Google account selection, image picking, and app-to-app directions.

## 6. Test accounts and seeded data

| ID | Setup |
| --- | --- |
| G1 | Anonymous guest session |
| C1 | Email/password customer, notifications enabled, no follows |
| C2 | Email/password customer, notifications disabled, follows V1 and V2 |
| C3 | Google customer with a registered physical-device FCM token |
| V1 | Complete vendor profile, closed stall, 3 menu items in all stock states |
| V2 | Complete vendor profile, open stall, fresh shared location |
| V3 | Complete vendor profile, open stall, stale or inactive location |
| V4 | Vendor account with no stall profile |
| R1 | Auth account whose `users` profile is missing, with a surviving vendor document |
| R2 | Auth account whose `users` profile is missing, with no vendor document |

Seed stalls at approximately 1 km, 7 km, 20 km, and 40 km from the customer location. Include multiple categories, duplicate-looking names, a closed stall, a deleted vendor ID still referenced by a test fixture, invalid coordinates `(0, 0)`, out-of-range coordinates, a missing image, and an unreachable image URL.

Seed at least 60 notification-history records for pagination, including unread/read records, identical timestamps, a missing vendor, and a record arriving while "mark displayed read" is running.

Use small valid JPG/PNG images, an oversized image, a corrupt file renamed as an image, and a cancelled picker operation. Never use personal photos or real customer locations.

## 7. Release smoke suite

Run these cases first on every release candidate. Stop and reject the build when a P0 smoke case fails.

| ID | Pri | Scenario | Expected result |
| --- | --- | --- | --- |
| SMK-01 | P0 | Launch with valid Firebase configuration | Splash completes and the correct welcome or role screen appears without an exception |
| SMK-02 | P0 | Continue as guest | Discover opens; stall browsing works; account-only actions ask the guest to sign in |
| SMK-03 | P0 | Sign in as C1 | Customer tabs appear and no vendor control is accessible |
| SMK-04 | P0 | Sign in as V1 | Vendor dashboard/menu/profile appear and no customer account data is exposed |
| SMK-05 | P0 | Set customer location and open a nearby stall | Correct distance, details, menu, stock state, and directions control are shown |
| SMK-06 | P0 | Follow then unfollow V1 as C1 | Button and Following tab update once and stay consistent after restart |
| SMK-07 | P0 | Add/edit/status-change/delete a menu item as V1 | Each write is reflected in vendor and customer views without duplication |
| SMK-08 | P0 | Open V1 and grant required location access | Stall becomes discoverable and fresh location updates are stored while sharing is active |
| SMK-09 | P0 | Close V1 | Sharing stops, the sharing flag clears, and queued updates do not reopen the stall |
| SMK-10 | P0 | Open a stall followed by C3 | One push and one history record arrive; tapping opens the correct stall |
| SMK-11 | P0 | Sign out a customer and a vendor | Token/location cleanup runs and the welcome screen returns without leaking prior account state |
| SMK-12 | P0 | Delete a disposable customer and vendor account | Auth, profile, follows, vendor/menu/history, verification records, and owned images are removed as applicable |

## 8. Detailed functional cases

### 8.1 Startup, session, and routing

| ID | Pri | Scenario | Expected result |
| --- | --- | --- | --- |
| SES-01 | P1 | Launch while signed out | Splash is visible briefly, then Welcome appears exactly once |
| SES-02 | P1 | Firebase initialization fails, then succeeds on Retry | A useful startup error appears; Retry starts the app without stacked duplicate routes |
| SES-03 | P0 | Restore customer, vendor, and anonymous sessions | Each session reaches only its intended experience; anonymous access still requires explicit guest entry for the current launch |
| SES-04 | P1 | `users/{uid}` is missing, unreadable, or has an invalid role | Account recovery explains the problem and Retry/Sign out remain usable |
| SES-05 | P1 | Profile role changes remotely while the app is open | Role gate updates safely, customer notification navigation is disabled when no longer valid, and stale pages cannot access the prior role |
| SES-06 | P2 | Background/foreground and cold restart from every main tab | Selected data remains coherent and no disposed map, stream, or timer throws |

### 8.2 Authentication and verification

| ID | Pri | Scenario | Expected result |
| --- | --- | --- | --- |
| AUTH-01 | P1 | Register with blank name, malformed email, password under 6 characters, or mismatched confirmation | Inline validation blocks submission and identifies the field |
| AUTH-02 | P0 | Register valid customer and vendor accounts | One Auth user and one matching `users` document are created with trimmed fields and the selected role |
| AUTH-03 | P1 | Registration encounters duplicate email, offline state, or server failure | Error is understandable, input remains, controls re-enable, and no orphan/duplicate profile is created |
| AUTH-04 | P0 | Email/password login with valid and invalid credentials | Valid account routes by role; invalid login shows an error without changing account state |
| AUTH-05 | P1 | Tap login/register actions repeatedly during a slow request | Only one logical request and one navigation occur; busy controls prevent duplicate submission |
| AUTH-06 | P0 | Google sign-in succeeds for a new and returning customer | New user defaults to customer; returning user keeps the stored role and profile |
| AUTH-07 | P1 | Google picker is cancelled, times out, loses network, or hits provider collision | Cancellation is quiet; other cases show the mapped recovery message and leave no partial session |
| AUTH-08 | P1 | Login R1 and R2 with missing/invalid profile data | R1 is repaired as vendor from its vendor record; R2 is repaired as customer; valid existing roles are never overwritten |
| AUTH-09 | P1 | Request password reset for known and unknown emails | Both show the same success outcome; malformed, rate-limited, and offline cases show safe messages |
| AUTH-10 | P1 | Request and confirm registration verification code | Code is six digits, expires after 10 minutes, marks Auth and Firestore verified, is removed after success, and cannot be reused |
| AUTH-11 | P1 | Verification resend, wrong code, expired code, and sixth attempt | 60-second cooldown is enforced; attempts increment; after five failures the code is rejected/deleted; errors do not reveal secrets |
| AUTH-12 | P1 | Change email with valid code | Recent sign-in is required; Auth and Firestore emails change together and the new address is verified |
| AUTH-13 | P1 | Change email to current/invalid/in-use address or confirm a code for another address | Operation is rejected with no partial email change |
| AUTH-14 | P1 | Navigate through registration verification and change-email entry points | Required screens are reachable from the intended journey; if these features are not intended for this release, their unused endpoints/screens are explicitly removed from release scope |

### 8.3 Customer location and discovery

| ID | Pri | Scenario | Expected result |
| --- | --- | --- | --- |
| CUS-01 | P1 | C1 launches with a valid saved location | Saved coordinates/label load before a new GPS request and the map centers correctly |
| CUS-02 | P0 | Use current location with services and permission enabled | Position and readable label appear, map centers, and a signed-in customer's location is saved |
| CUS-03 | P1 | GPS is off, denied once, denied permanently, times out, or returns an error | Clear recovery text appears; retry and manual browsing remain available; no permission loop occurs |
| CUS-04 | P1 | Search for a manual area/city/state/postcode | Suggestions appear nearest-first, a selected result updates the map/label, and signed-in data persists |
| CUS-05 | P2 | Manual search is blank, returns no results, returns duplicates, or loses network | Invalid selection is blocked and a specific, recoverable state is shown |
| CUS-06 | P1 | Use manual/current location as G1 | Discovery updates for the session but no customer profile write is attempted |
| CUS-07 | P0 | Browse with no search text | Only open stalls with valid coordinates and within the active radius are listed/marked |
| CUS-08 | P1 | Search by stall name and category, including closed stalls | Open stalls match name/category; current closed-stall name behavior is verified and documented; clearing search restores open-only results |
| CUS-09 | P1 | Apply/clear each category filter | Map markers, cards, empty state, and filter label remain synchronized |
| CUS-10 | P1 | Expand radius through 5, 10, 25, and 50 km | Correct stalls enter the result set, camera zoom adjusts, and expansion stops at 50 km |
| CUS-11 | P1 | Pan/zoom the map across normal and longitude-wrapping bounds | The lower list represents visible results without dropping valid edge markers or retaining off-screen cards |
| CUS-12 | P1 | Select marker then card, and rapidly select several markers | Marker highlight, camera, and card scroll identify only the latest selection without layout jumps |
| CUS-13 | P1 | Compare distances and ordering against known coordinates | Distances are accurate, meters/km format is correct, and results sort nearest-first |
| CUS-14 | P1 | Vendor location is active/fresh, inactive, older than 2 minutes, exactly at threshold, or future-dated | Freshness label and styling match the defined less-than-2-minute rule; invalid/future timestamps are not treated as fresh |
| CUS-15 | P1 | Vendor stream is loading, empty, malformed, or fails | Loading/empty/error UI is usable, invalid vendor coordinates do not crash the map, and retry recovers |

### 8.4 Stall details, following, and directions

| ID | Pri | Scenario | Expected result |
| --- | --- | --- | --- |
| DET-01 | P0 | Open stall details from marker, card, Following, history, and push | The same vendor, current open state, image, category, hours, description, location freshness, and menu are shown |
| DET-02 | P1 | Vendor changes status/profile/menu while details are open | Live UI refreshes without navigating away; menu retry can replace a failed stream |
| DET-03 | P1 | Vendor is deleted while details are open | A stable deleted/unavailable state replaces stale data; actions cannot target the removed vendor |
| DET-04 | P1 | Menu is empty or contains available/low/out-of-stock items and broken images | Correct empty text, prices, badges, and image fallbacks render |
| DET-05 | P0 | C1 follows/unfollows from details | Predictable follow record is created/deleted once and state synchronizes across screens/devices |
| DET-06 | P1 | G1 taps Follow | Account-required dialog appears; Not Now dismisses and Log In opens authentication without changing follows |
| DET-07 | P1 | Following list has open/closed/missing vendors | All/Open Now filters and counts are accurate; stale references do not crash the list |
| DET-08 | P1 | Google Maps and Waze are installed, absent, or fail to launch | Available choices are offered, browser fallback remains, correct coordinates are passed, and failures show feedback |

### 8.5 Vendor stall, menu, and live location

| ID | Pri | Scenario | Expected result |
| --- | --- | --- | --- |
| VEN-01 | P1 | V4 opens dashboard without a stall profile | Setup guidance and Edit Stall path appear; no null-field crash occurs |
| VEN-02 | P0 | Create/edit stall name, category, description, hours, and image | Required validation runs, trimmed profile fields persist, and operational state/location fields are not reset by profile edits |
| VEN-03 | P1 | Pick, cancel, replace, fail, or retry a stall image upload | Cancel preserves the prior image; replacement overwrites the vendor path; write failure does not save a broken URL |
| VEN-04 | P0 | Add a dish with valid name, price, and optional image | Exactly one item is created as available; its image path and Firestore item ID agree |
| VEN-05 | P1 | Add/edit with blank name, zero/negative/NaN price, over two decimals, or long name | Validation blocks invalid data; values such as `10`, `10.5`, and `10.50` save correctly |
| VEN-06 | P0 | Retry a dish save after an uncertain timeout | The preallocated item ID prevents a duplicate dish and entered changes remain available for retry |
| VEN-07 | P1 | Edit dish with/without a new image | Name/price update; omitted image retains the old URL; current stock state is preserved |
| VEN-08 | P0 | Set available, low stock, and out of stock | Valid state is saved once and customer view updates; invalid state is rejected; failed optimistic UI rolls back or reports the error |
| VEN-09 | P0 | Cancel/confirm dish deletion and simulate failure | Cancel changes nothing; confirm removes only the selected item; failure keeps/restores the item with feedback |
| VEN-10 | P0 | Open stall, accept location notice, and grant permissions | Current position is written, stall opens, sharing becomes active, and the background stream starts once |
| VEN-11 | P1 | Opening is cancelled, GPS is off, permission is denied/denied forever, or position times out | Stall remains closed and inactive; recovery text explains the next action |
| VEN-12 | P0 | Close an open stall during active or queued location writes | Position stream stops, sharing flag becomes false, and no late write reopens or reactivates the stall |
| VEN-13 | P0 | Keep an open stall foregrounded/backgrounded for 10 minutes | Location updates at the intended cadence, foreground-service/iOS indicator is correct, and customers see fresh data |
| VEN-14 | P1 | App restarts, process is killed, connection drops, or another device closes the stall | UI offers safe resume behavior where appropriate; old timestamps become stale; transactions never reopen a remotely closed stall |
| VEN-15 | P2 | Rapidly toggle open/closed/open or switch vendor accounts | Serialized operations leave the latest intentional state and never write one vendor's location to another vendor |

### 8.6 Notifications and history

| ID | Pri | Scenario | Expected result |
| --- | --- | --- | --- |
| NOT-01 | P0 | Configure notifications for customer, vendor, and guest roles | Only an eligible signed-in customer can save an FCM token; vendor/guest tokens are removed or absent |
| NOT-02 | P1 | Customer grants, denies, or later revokes OS permission | Token and in-app preference remain consistent; blocked state points to phone settings without a prompt loop |
| NOT-03 | P0 | Turn Stall notifications off then on | Off deletes this device token and cancels local alerts but keeps history; On requests permission and registers a fresh token |
| NOT-04 | P0 | FCM token rotates or account changes during a token write | Only the current eligible customer's document receives the latest token; prior account token is cleared |
| NOT-05 | P0 | V1 transitions false to true | Each eligible follower receives one targeted push and one idempotent history item |
| NOT-06 | P0 | Edit vendor fields, update location/menu, write true-to-true, or close stall | No opening push/history item is created |
| NOT-07 | P1 | Trigger retries and follower list spans multiple 200-record pages | Stable event ID prevents duplicate/reset; all pre-existing eligible customers are processed once |
| NOT-08 | P1 | Follower was added after opening, account is missing/vendor, ID is invalid, or token is absent | No inappropriate inbox or push is created; valid recipients still succeed |
| NOT-09 | P0 | Receive push in foreground, background, and terminated states | Foreground local alert and OS alerts use correct text/channel; each tap opens the intended vendor once |
| NOT-10 | P1 | Tap notification before customer navigation is ready, after logout, or for a deleted vendor | Deep link waits only for a valid customer session; stale/other-account navigation is discarded safely |
| NOT-11 | P1 | View All/Unread, open an item, and mark displayed items read | Newest-first order, unread filter, item state, and badge update correctly; concurrently arriving items stay unread |
| NOT-12 | P1 | Load more than 50 records and reach 100 unread | Pagination adds older records without duplicates; badge displays `99+` at the cap |
| NOT-13 | P2 | History stream/write is offline, permission-denied, or times out | Useful error/retry UI appears and no local state falsely claims a successful write |

### 8.7 Profile, password, logout, and deletion

| ID | Pri | Scenario | Expected result |
| --- | --- | --- | --- |
| ACC-01 | P1 | Edit full name with whitespace, 1/80/81 characters, or offline | Valid trimmed name updates Firestore and best-effort Auth display name; invalid/failure cases preserve the old name |
| ACC-02 | P2 | Open personal information for email, Google, customer, and vendor accounts | Name, email, account type, and sign-in method are accurate and sensitive credentials are never displayed |
| ACC-03 | P1 | Change password with wrong current password, short/same/mismatched new password, rate limit, or offline | Validation/error is specific, fields remain protected, and password changes only after successful reauthentication |
| ACC-04 | P1 | Google-only account views profile | Password change control is hidden and provider-managed credentials are not treated as password credentials |
| ACC-05 | P1 | Cancel and confirm logout for guest/customer/vendor | Cancel preserves session; confirm pauses vendor location, clears the customer device token/local alerts, and signs out all providers |
| ACC-06 | P0 | Delete password account with missing/wrong/correct `DELETE` and password | Only exact confirmation plus successful recent reauthentication can start deletion |
| ACC-07 | P0 | Delete Google account and cancel/fail/succeed reauthentication | Cancellation/failure preserves the account; success proceeds once and returns to signed-out state |
| ACC-08 | P0 | Backend deletes customer account | User profile, nested notification history, owned follow records, verification records, and Auth user are gone |
| ACC-09 | P0 | Backend deletes vendor account | Vendor/stall/menu data, follows to/from vendor, stall/menu images, verification records, user profile, and Auth user are gone |
| ACC-10 | P0 | Delete call is unauthenticated, auth is older than 10 minutes, or a recursive/storage/Auth step fails | Request is rejected or reports incomplete deletion; failure is logged server-side and never reports false success |
| ACC-11 | P2 | Search FAQ and open About, Privacy, and Terms | Correct role-specific FAQ results appear; links/screens scroll and render at all supported text sizes |

## 9. Data, API, and security cases

These tests run against committed Firestore and Storage rules in the Emulator Suite. A rules snippet alone is not considered deployable test evidence.

| ID | Pri | Scenario | Expected result |
| --- | --- | --- | --- |
| SEC-01 | P0 | Unauthenticated or different user reads `users/{uid}/notifications` | Read is denied |
| SEC-02 | P0 | Owner reads notification history | Read succeeds only for the matching authenticated UID |
| SEC-03 | P0 | Owner changes notification content, changes `isRead` back to false, creates, or deletes a history item | Operation is denied; only the intended mark-read transition is allowed |
| SEC-04 | P0 | Customer/vendor writes another account's profile, stall, menu, follow, token, or location | Operation is denied according to the confirmed ownership policy |
| SEC-05 | P0 | Client attempts to set role, verified state, server timestamp, or notification content beyond allowed fields | Privilege-changing or server-owned writes are denied |
| SEC-06 | P1 | Malformed Firestore documents contain wrong types, nulls, invalid coordinates, unknown stock state, or missing timestamps | UI fails closed or uses defined defaults without crashing or granting access |
| SEC-07 | P0 | Call verification/deletion functions without auth or for another UID | Function rejects the request; request data cannot select a victim UID |
| SEC-08 | P0 | Inspect verification records/logs/network responses | Plaintext code, SMTP password, hashing secret, password, and ID token are never stored or logged |
| SEC-09 | P1 | Upload unsupported, oversized, or cross-vendor files | Storage rules/type/size limits reject unsafe writes; vendors can write only their paths; customer reads follow product policy |
| SEC-10 | P1 | Inspect Google Maps key and Firebase configuration | Public client keys are restricted by package/bundle/domain and API; no server secret is packaged in the app |
| SEC-11 | P1 | Duplicate/replayed function events and concurrent writes | Idempotency prevents duplicate alerts/deletes; a late location write cannot override a newer close |
| SEC-12 | P0 | Account switches during streams, pending push navigation, upload, or location update | Prior account data/actions are detached and never appear under or write to the new account |

## 10. Non-functional cases

| ID | Pri | Area | Check and target |
| --- | --- | --- | --- |
| NF-01 | P1 | Accessibility | All actions have meaningful labels/tooltips, logical screen-reader order, visible focus, and non-color-only stock/status meaning |
| NF-02 | P1 | Text/layout | No clipped or overlapping content at 200% text scale, compact/large phones, tablet width, keyboard open, or supported rotation |
| NF-03 | P2 | Contrast/motion | Text/control contrast is readable; loading and camera/scroll motion do not create unusable flashing or loss of context |
| NF-04 | P1 | Startup | Warm launch reaches usable UI within 2 seconds and cold launch within 4 seconds on the selected mid-range reference device under normal network conditions |
| NF-05 | P1 | Interaction | Search/filter/tabs respond within 100 ms locally; normal Firestore updates visibly settle within 2 seconds on stable network |
| NF-06 | P1 | Scale | Map/list remains usable with 200 stalls, vendor menu with 100 items, 200 follows, and 500 notification records |
| NF-07 | P1 | Stability | A 30-minute mixed customer session and 60-minute vendor sharing session produce no uncaught exception, runaway memory, duplicate stream, or stuck busy state |
| NF-08 | P1 | Battery/privacy | Background location runs only for an intentionally open vendor, stops promptly on close/logout, and has acceptable battery use over a 60-minute reference run |
| NF-09 | P1 | Resilience | Airplane mode and network switching during every write yields a recoverable state and no duplicate/cross-account data |
| NF-10 | P2 | Web | Welcome, email auth, profile, responsive layout, and supported discovery paths smoke successfully; unsupported native features are hidden or explain limitations |
| NF-11 | P1 | Installation | Fresh install, upgrade over the prior release, uninstall/reinstall, notification channel, icons, app name, and saved server data behave as intended |
| NF-12 | P0 | Release config | Production package/bundle ID, signing, Firebase project, OAuth fingerprints, Maps restrictions, privacy strings, and entitlements are production-ready |

Performance targets are initial acceptance targets and should be adjusted after measuring a representative device and real staging data. Record the device, OS, build mode, dataset size, and network condition with each result.

## 11. Traceability summary

| Product capability | Main cases |
| --- | --- |
| Startup and role routing | SMK-01, SMK-03, SMK-04, SES-01 to SES-06 |
| Guest and authentication | SMK-02, AUTH-01 to AUTH-14 |
| Discover nearby stalls | SMK-05, CUS-01 to CUS-15 |
| Details, following, directions | SMK-06, DET-01 to DET-08 |
| Vendor profile and menu | SMK-07, VEN-01 to VEN-09 |
| Open stall and live location | SMK-08, SMK-09, VEN-10 to VEN-15 |
| Push and history | SMK-10, NOT-01 to NOT-13 |
| Profile and account lifecycle | SMK-11, SMK-12, ACC-01 to ACC-11 |
| Security and privacy | SEC-01 to SEC-12, NF-08, NF-12 |

## 12. Automation implementation order

### Phase 1: fast release gates

- Create `test/` and cover `VendorModel`, `UserModel`, `MenuItemModel`, and `NotificationModel` parsing/defaults.
- Extract/test pure discovery filtering, radius, map-boundary, distance-formatting, and validation helpers.
- Add widget tests for registration, password, stall, dish, guest gate, empty/error/loading, and unread-filter states.
- Expand Node tests around verification-code policy and push transition/recipient construction.
- Make `flutter analyze`, `flutter test --coverage`, and Node tests required checks.

### Phase 2: emulator contracts

- Commit the complete Firestore and Storage rules and add allow/deny tests for every ownership boundary.
- Inject Firebase/plugin dependencies into services so Auth, Firestore, Storage, messaging, location, and navigation races can be tested deterministically.
- Add emulator tests for signup/profile repair, follow idempotency, menu writes, history pagination/read state, and recursive account deletion.

### Phase 3: critical mobile journeys

- Add Flutter `integration_test` flows for guest discovery, customer follow, vendor menu, open/close, logout, and delete with disposable accounts.
- Keep OS permission matrices, background location, FCM states, Google picker, images, and external directions in a real-device release checklist.
- Run load, battery, accessibility, and upgrade suites before production release.

Suggested automated coverage targets:

- 90% branch coverage for extracted Cloud Function business logic.
- 80% line coverage for pure Dart models, validation, filtering, and business logic.
- At least one automated happy path and one failure path for every P0/P1 capability.
- Coverage percentage never overrides the requirement that all P0 and P1 cases pass.

## 13. Entry and exit criteria

### Entry criteria

- Candidate build installs and points to the intended environment.
- Test Firebase project, Maps key restrictions, OAuth configuration, SMTP secrets, FCM/APNs, and indexes are ready.
- Complete Firestore/Storage rules are committed and deployed to the test environment.
- Seed script/data creates the accounts and boundary records in Section 6.
- Known changes and affected cases are identified; production data is excluded.

### Exit criteria

- 100% of P0 and P1 cases pass on the required platforms.
- At least 95% of executed P2 cases pass, with accepted defects documented.
- No open Critical or High defect; no unresolved security-rule failure or data-loss/cross-account defect.
- Android and iOS physical-device smoke passes, including push and background location.
- Analyzer, unit, widget, Cloud Function, and emulator checks pass in a clean run.
- Product owner accepts any Medium residual risk and the test summary links evidence for failures, devices, and deferred cases.

## 14. Execution cadence

| When | Suite |
| --- | --- |
| Every pull request | Analyzer, Dart/Node unit tests, affected widget tests |
| Nightly | Full unit/widget suite, Firebase emulator contracts, critical integration tests |
| Release candidate | Full P0/P1 regression, affected P2, real Android/iOS smoke, push, background location, security, accessibility |
| Post-release | Production synthetic smoke that never deletes real data; crash/error monitoring review |

## 15. Defect and test evidence

Each result should record build/version, environment, case ID, tester, device/OS, account/data IDs, timestamp/time zone, pass/fail/blocked status, and evidence. A defect should include concise steps, expected versus actual behavior, reproducibility, severity, logs/screenshots with secrets removed, and whether server data cleanup is needed.

The release summary should report P0/P1/P2 pass rates, open defects by severity, skipped/blocked cases with owners, automated coverage, performance/battery observations, and a clear ship/no-ship recommendation.

## 16. Current baseline and testability risks

Baseline observed while preparing this plan on 11 September 2026:

- The repository has no Flutter `test/` directory, so Flutter unit/widget regression coverage is currently absent.
- The existing Node suite contains 5 notification-history tests; all 5 passed.
- Flutter analysis could not be confirmed because the local Flutter command stalled before producing version or analyzer output. The release gate must be rerun after the toolchain is repaired.
- Only a notification-history rules snippet is present under `functions/`; a complete committed Firestore/Storage ruleset and emulator test configuration were not found.
- Email verification and change-email screens/functions exist, but their intended entry points should be confirmed by AUTH-14.
- Firebase/plugin singletons are constructed directly in many screens/services, increasing the effort and flakiness risk of isolated tests until dependencies are injectable.
- Android still uses an example application ID and debug signing for release builds; production identity/signing is covered by NF-12.
- Web, iOS local-notification initialization, background location, and external-map behavior require explicit physical/platform validation rather than being assumed from Android behavior.

These items do not replace functional testing. They define the first work needed to make the plan repeatable and suitable as a release gate.
