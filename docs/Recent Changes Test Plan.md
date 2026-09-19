# StallSeeker recent changes test plan

| Field | Value |
| --- | --- |
| Scope | Discover filters, Malaysia place suggestions, vendor hours and closures, menu sections and stock time, vendor phone, stall reviews |
| Build | Android build from the current working tree (`1.0.0+1` until version is incremented) |
| Time zone | Asia/Kuala_Lumpur (MYT, UTC+8) |
| Status | Automated checks partially executed; see [Recent Changes Test Results.md](Recent%20Changes%20Test%20Results.md) |
| Parent plan | [StallSeeker Test Plan.md](StallSeeker%20Test%20Plan.md) |

## Goal and release rule

Verify the new customer and vendor journeys on a real Android device and a disposable Firebase test environment. A successful build or Firebase deploy is **not** a pass for the user journeys below. Record each case as Pass, Fail, or Blocked with a screenshot or log where useful.

Run all P0 and P1 cases before distributing the new app. Do not use real customer accounts, personal phone numbers, or production reviews for destructive and permission tests. SEC-06 was fixed and passed in the Firestore Emulator; other legacy public-write rules still need a separate security review before a wider release.

## Setup and test data

1. Install the latest Android build on two devices or emulators. Use a disposable Firebase test project with the same Firestore, Storage, index, and scheduled-function configuration as the deployed project. If testing against production, use only controlled test accounts and stalls, and do not run cross-account attack or deletion cases there.
2. Create customer accounts **C1** and **C2**, a guest session **G1**, a new vendor **V1**, and an existing vendor **V2** whose record has no phone or structured weekly hours. Give C1 and C2 different names.
3. Seed named stalls with valid coordinates at about 1, 7, 20, and 40 km from a fixed customer location. Use at least two categories; keep one open, one manually closed, and one open with an active temporary closure. Add one stall with `(0, 0)` coordinates to confirm it is excluded.
4. Give V1 dishes in two sections, all three stock states, and one older dish without `section` or `statusUpdatedAt` fields. Prepare five disposable JPG/PNG review photos plus a sixth photo, and one image over 5 MB.
5. Set test devices to automatic time in MYT. For the scheduled closure test, choose a start at least 7 minutes ahead and an end at least 15 minutes later. Record actual timestamps; do not change production clocks or data to force the scheduler.

## Fast acceptance run

| ID | Pri | Steps | Expected result |
| --- | --- | --- | --- |
| SMK-01 | P0 | As C1, select **Open now**, **Closed**, then **All stalls** on Discover. | Both map markers and the stall list switch together; each status has the correct stalls. |
| SMK-02 | P0 | Change category and distance, then search for a stall. | All active filters combine correctly; the label and empty state agree with visible results. |
| SMK-03 | P1 | Enter a common Malaysia place name and select one of several suggestions. | Several distinct results appear when data exists; the chosen coordinates and label center the map. |
| SMK-04 | P0 | As V1, save weekday hours and a future temporary closure. | Day switches, time pickers, and closure date/time persist after leaving and reopening Edit Stall. |
| SMK-05 | P0 | Open V1 before the closure starts; observe customer and vendor devices during the closure. | Customer view changes to Closed on its next refresh (within about 30 seconds); the persisted Open switch turns off at the next scheduled run (normally within about 5 minutes) and stays off until the vendor reopens. |
| SMK-06 | P0 | Register a vendor with a valid phone and a customer without a phone. | Vendor registration requires and saves the phone; customer registration has no phone requirement. |
| SMK-07 | P1 | Add dishes in two sections, search a dish, then change its stock state. | Customer details show sections, the matching dish, and the new stock update time in MYT. |
| SMK-08 | P0 | As C1, save a 5-star review with five photos; edit it; view as C2. | Exactly one C1 review exists for that stall, the edit replaces its content, and C2 sees the latest review. |
| SMK-09 | P0 | As G1, attempt to review. | Sign-in prompt appears and no review or photo is written. |

## Detailed cases

### Discover and manual location

| ID | Pri | Steps | Expected result |
| --- | --- | --- | --- |
| DIS-01 | P0 | Set the customer location, leave search empty, choose **Open now**, **Closed**, and **All stalls**. | Open excludes both manually closed and temporarily closed stalls; Closed includes both; All includes both groups. Valid nearby markers and cards agree. |
| DIS-02 | P1 | With **Closed** selected, search by stall name and category. Clear search and change to **All stalls**. | Search does not silently force Open; clearing it retains the chosen status. |
| DIS-03 | P1 | Try every category with each status choice, including a category with no matches. | Category, count, markers, cards, and empty message stay synchronized. |
| DIS-04 | P1 | Select 5, 10, 25, then 50 km with seeded distances. | Stalls enter at the expected threshold, the chip shows the selected distance, and the map camera adjusts. |
| DIS-05 | P1 | Pan and zoom so a matching stall leaves and re-enters the visible map. Tap its marker and card. | The current-map list follows visible bounds; selecting the stall highlights the correct marker/card. |
| DIS-06 | P1 | Search “Bangi” and “Jalan Ilmiah”; repeat with another state or town elsewhere in Malaysia. | Suggestions are not hardcoded to the examples; multiple distinct Malaysian places appear where the source has data. The chosen result has the right label and coordinates. |
| DIS-07 | P1 | Search a short query, a nonsense query, and a duplicate-looking place name; tap Use Location before selecting. | Short input does not search, no match is explained, duplicates are limited, and an unselected location cannot be submitted. |
| DIS-08 | P1 | Disable internet or make the place service unavailable, then search a known address. Restore network and retry. | Device geocoding can provide a fallback result if available; otherwise a recoverable error appears. No stale result from an earlier query is selectable. |
| DIS-09 | P2 | Type one place, immediately replace it with another, then close the dialog during loading. | Only the latest query may update suggestions; closing the dialog causes no crash or delayed selection. |
| DIS-10 | P1 | Set a manual location as C1, restart, then repeat as guest; also use the shared picker from vendor location setup. | C1's choice persists, guest choice stays in the session, and vendor manual location still works. |

### Vendor phone and schedule

| ID | Pri | Steps | Expected result |
| --- | --- | --- | --- |
| VEN-01 | P0 | Register vendor with blank, malformed, and valid Malaysian mobile/landline numbers; register a customer. | Invalid vendor numbers block signup; valid number is stored in normalized `+60` form; customer sees no phone field. |
| VEN-02 | P0 | Sign in as V2 without a phone and try Open; add a valid phone in Edit Stall and try again. | Open is blocked with a useful message until the phone is saved, then can proceed. |
| VEN-03 | P1 | Open V1's profile, Discover card, and stall details; tap the number. | The same vendor number appears on all three surfaces; tap opens the device dialer. Customer profiles do not acquire a vendor phone field. |
| VEN-04 | P0 | Toggle Monday and Friday on, choose different opening/closing times, add a second period, save, reload. | All selected days and intervals persist; other days remain Closed; today's hours render in MYT. |
| VEN-05 | P1 | Remove a time interval and toggle a day off; try choosing equal opening and closing times. | Saved values reflect removals; equal times are rejected with feedback. |
| VEN-06 | P1 | Load V2's legacy free-text hours, set new structured hours, and save. | Existing text is shown during migration; structured hours are used thereafter without resetting stall name, location, or Open state. |
| VEN-07 | P0 | Add a future closure using start and end date/time pickers; save, reopen, remove it, and save again. | Closure persists exactly once and is removable; end at or before start is rejected. |
| VEN-08 | P0 | Leave V1 open before a closure starts; watch customer status at start and stored `isOpen` through the next scheduler run. Try to open during the active closure and after it ends. | Customers see Closed on their next refresh; scheduled backend job sets `isOpen=false` and stops sharing at its next run. Reopening is blocked during closure and is a manual action afterward. Record any delay beyond about 5 minutes. |
| VEN-09 | P1 | Close V1 manually while hours say it is scheduled to be open; leave the app and return. | Manual Closed remains authoritative and schedule does not open it automatically. |
| VEN-10 | P2 | Schedule an overnight interval and a closure across midnight; inspect both sides of midnight MYT. | Displayed dates/times and effective closure use MYT with no one-day shift. |

### Menu and stock

| ID | Pri | Steps | Expected result |
| --- | --- | --- | --- |
| MENU-01 | P0 | Add dishes in “Drinks” and “Mains”; edit a dish's section and reopen customer details. | Dishes are grouped under saved sections; editing moves a dish without duplicating it. |
| MENU-02 | P1 | Open the seeded legacy dish with no section or stock timestamp. | It appears under “Main menu”; missing stock time is not shown as a made-up value. |
| MENU-03 | P1 | Search a dish by part of its name with mixed case; search a missing dish; clear the query. | Matching dishes appear across sections; no-match state is clear; clearing restores all dishes. |
| MENU-04 | P0 | Change a dish from Available to Low stock to Sold out while C1 views details. | Status and “Stock updated” time refresh after each successful write and show MYT date/time. |
| MENU-05 | P1 | Disconnect V1 during a stock change and retry after reconnecting. | Failure is reported; customer does not see a false update time or status; retry writes one final state. |

### Reviews and photos

| ID | Pri | Steps | Expected result |
| --- | --- | --- | --- |
| REV-01 | P0 | As C1, submit with no stars, then submit stars only. | No-star submission is blocked; text and photos are optional. |
| REV-02 | P0 | Add five photos, attempt a sixth, and save. | At most five photos are attached and displayed; star rating and text are retained. |
| REV-03 | P0 | Edit C1's review, change stars/text, remove a photo, and add another; reload. | One review remains for C1 on this stall; the removed photo URL disappears and its owned Storage file is deleted. |
| REV-04 | P1 | Review the same stall as C2 and inspect the review count and average. | Both reviews appear, count is 2, average stars are correct, and each customer edits only their own entry. |
| REV-05 | P0 | Attempt review as guest and as a vendor account. | Guest is prompted to sign in; vendor write is denied by Firestore rules. Neither creates a review. |
| REV-06 | P0 | In the Firebase Emulator, attempt to write C1's review as C2, set 0/6 stars, text over 1,000 characters, or six photo URLs. | Every invalid or cross-account write is denied; a valid customer-owned write succeeds. |
| REV-07 | P0 | In the Storage Emulator, upload to another customer's path, upload a non-image, upload over 5 MB, and delete another customer's photo. | All four writes are denied; C1 can upload/delete only within C1's review photo path. |
| REV-08 | P1 | Use an image with a broken URL, cancel the picker, go offline during upload, then retry. | Detail screen remains usable; no false success is shown; selected review input stays available for retry. |
| REV-09 | P0 | Delete disposable C1 and V1 accounts after they have reviews/photos. | C1's reviews and owned photos disappear across stalls; V1's review entries and stall review photos disappear with the vendor. Auth and account deletion behavior also passes the parent plan. |
| REV-10 | P1 | Inspect stall details and review editor at 200% text scale and on a compact phone. | Stars, photo count, Save, review images, and status remain reachable without clipping. No Report control appears. |

### Firebase and regression

| ID | Pri | Steps | Expected result |
| --- | --- | --- | --- |
| SEC-01 | P0 | In the Firestore Emulator, create and update a user profile as its owner, then attempt to change `role`. | Ordinary profile update works; role change is denied. |
| SEC-02 | P0 | Check the `entries.customerId` collection-group index and run disposable account deletion with reviews. | Index exists and cleanup query completes without a missing-index error. |
| SEC-03 | P1 | Let a scheduled closure start while vendor app is backgrounded or offline; inspect vendor record and notification history. | Backend closes the stall at its next scheduled run without relying on the vendor app. Closing does not generate an opening notification. Record scheduler delay. |
| SEC-04 | P1 | Reopen after closure and follow the stall from C1. | Only the intentional false-to-true opening creates the normal follower notification. |
| SEC-05 | P1 | Review deployed rules and function list against the build's Firebase project. | Review permissions, photo permissions, index, account deletion function, and closure function match the test configuration. |
| SEC-06 | P0 | On an isolated test project, attempt unauthenticated and cross-vendor writes to vendor and menu documents; test an authorized vendor write. | Guest and other-vendor writes are denied; the owning vendor can update its stall and menu. |

## Evidence and exit criteria

For every case, record ID, build hash/APK, Firebase project, device and Android version, account IDs, MYT timestamp, result, and a short note or screenshot. For scheduler cases, capture both customer display time and Firestore `isOpen` update time. For failed writes, keep only redacted error logs.

Release recommendation requires all P0 and P1 cases to pass or have an explicitly accepted exception, no unexplained data loss or cross-account access, and an Android physical-device smoke pass. Legacy `reports`, `stalls`, and `_connection_test_` collections still permit public writes and need review before a wider public release. Also check the location search under realistic load: [Photon's public demo](https://github.com/komoot/photon) may throttle requests and does not promise availability.

## Current verification versus work still to run

See [Recent Changes Test Results.md](Recent%20Changes%20Test%20Results.md) for executed checks, fixes, evidence, and remaining manual cases.
