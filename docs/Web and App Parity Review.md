# Web and app parity review

Reviewed 3 November 2026 (Asia/Kuala_Lumpur), source revision `67a630c`.

## Verdict

The web and Android app share the same Flutter screens, account routing, services and Firebase data. The main product features are present in both. The custom-domain photo defect found in this review was fixed on 3 November 2026. Full operational parity is not yet verified: several browser behaviors intentionally differ, and authenticated workflows still need end-to-end testing.

This review combines current source inspection, live guest checks on `https://stallseeker.my/` and `https://stallseeker-c2ffe.web.app/`, public image-response checks, static analysis and backend tests. It does not certify a separately installed APK, Safari or actual phone hardware. Following the user's request to fix the issue, the production bucket's existing GET/HEAD CORS rule was updated to include `https://stallseeker.my`. No application code was changed.

## Resolved issue: photos failed on the custom domain

**Original priority: high; now resolved.** On `stallseeker.my`, the Takoyaki4Lyfe cover and three menu photos rendered as placeholder stall icons. The same stall and menu showed their photos on `stallseeker-c2ffe.web.app`.

A read-only request for the same public cover photo returned:

| Request origin | HTTP status | Content type | Access-Control-Allow-Origin |
|---|---|---|---|
| `https://stallseeker.my` | 200 | `image/jpeg` | Missing |
| `https://stallseeker-c2ffe.web.app` | 200 | `image/jpeg` | `https://stallseeker-c2ffe.web.app` |

The photo existed and was publicly readable, but its response did not permit the custom website's browser origin. This confirmed an image CORS configuration gap. Flutter catches image errors and displays placeholders, so the page can otherwise look healthy. The custom-domain console did not expose a useful image error during the original checks.

**Correction applied:** added the exact production origin `https://stallseeker.my` to the image bucket's existing GET/HEAD CORS policy, preserving existing origins, methods, headers and access rules. The update used the bucket's metageneration as a concurrency guard. Before/after policy snapshots are saved in `tmp/custom-domain-photo-cors-before.json` and `tmp/custom-domain-photo-cors-after.json`.

**Verification:** the same public image now returns HTTP 200 and `Access-Control-Allow-Origin: https://stallseeker.my` for the custom origin; the Firebase domain still receives its matching permission header. Live browser checks confirm the custom-domain cover and menu photos display. Review photo reads use the same bucket policy, but their UI and authenticated uploads were not separately exercised.

## Feature comparison

“Shared implementation” means reachable code exists for both platforms; it does not mean a successful signed-in transaction was observed.

| Feature | Comparison | Evidence and verification level |
|---|---|---|
| Startup and guest access | Matches in live web checks | Both web domains start and enter customer discovery. Firebase data and roles are shared with the app. |
| Map and stall markers | Present in both | Custom-domain map and clustering loaded. No device GPS permission was granted during this review. |
| Manual location search | Works on web | Searched Kajang, received Places suggestions, selected an address and applied the resolved location. Browser and native geocoding use separate implementations. |
| Discovery list and search | Works on web | List view showed real stalls; an unmatched search returned zero results. |
| Filters and reset | Works in checked web flow | Updated-in-24-hours toggled; Reset filters cleared the active search/filter and restored results. Price, hours, radius, status and sorting controls are also wired in shared source. |
| Stall details and menus | Matches in checked web flow | Opening status, phone action, hours, stale-location warning, prices, available/low-stock/sold-out labels and reviews displayed. Photo exception described above. |
| Following and review actions | Shared implementation; guest restriction verified | Follow prompted the guest to log in. Signed-in follows and review creation were not exercised. |
| Directions | Intentional difference | Web offers Google Maps in browser. Native can also offer Google Maps/Waze apps when detected. The web chooser was inspected; an external navigation session was not started. |
| Login and registration | Shared implementation with browser Google popup | Login dialog and empty-form email/password validation checked. Actual password/Google sign-in and registration were not performed. |
| Saved places and account settings | Shared implementation | Guest Settings exposes current location, Home, custom pins, bookings, FAQ and About. Saving signed-in account data was not tested. |
| Bookings and special instructions | Shared implementation | Same booking service/backend and 500-character special-instruction rules. Actual customer/vendor booking lifecycle not exercised. |
| Stripe checkout and payment return | Intentional interaction difference | Native starts checkout after booking; web requires Pay on booking details and reserves a browser tab during that click. Resume refreshes verified payment state. Test mode applies to both. Source/backend-test coverage only in this review. |
| Vendor dashboard, menu and stall editing | Shared implementation | No web-only feature gate removes these screens. Signed-in vendor editing, stock changes, hours, closures and photo uploads need runtime testing. |
| Vendor live location | Intentional difference | Native supports background sharing; web explicitly pauses when hidden/paused and requires Resume sharing or a manually fixed location. |
| Notification history and push | Shared history; platform-specific alerts | Both use shared backend notifications and multiple device registrations. Web asks for permission in Settings, uses a service worker for background alerts and an in-app message while foregrounded. Actual delivery/tap routing not tested. |
| Back navigation and responsive layout | Passed checked web flows | App Back returned to discovery on the custom domain; browser Back returned from stall details on Firebase hosting. The hosting-domain detail screen was visually inspected at 390 × 844 and desktop width. This is not a Safari/device test. |

## Automated checks and limits

- Backend and scheduled-function tests: **38 passed, 0 failed** using `node --test functions/*test.cjs functions-schedule/*test.cjs`. Includes browser/phone token coexistence, delivery retries, booking validation, checkout and refund handling.
- `flutter analyze --no-pub`: completed with **two informational findings**, both in the existing ignored scratch file `tmp/repro_booking.dart` (relative library import and `print`). No findings were reported in application source. Command exit status was nonzero because of those infos.
- Flutter test run: **incomplete**. Output reached 19 passing tests and one infrastructure loading error after Windows reported insufficient disk space while copying a compiled test file. The process then stopped progressing and was interrupted. Do not interpret this as a full test pass or an application regression.
- A fresh release build was not attempted after the disk-space failure. About 170 MiB remained free during the checks.
- The first authenticated inspection failed under restricted network access and reported a credential error. Retrying with network access succeeded with the existing Firebase credentials; no reauthentication was needed. Bucket configuration confirmed the missing custom origin, and the authorized fix was applied and checked.

## Remaining verification

After freeing enough disk space, rerun Flutter tests and a web release build for the broader parity review. A build is not required for the applied bucket-only photo fix. Use designated customer/vendor accounts to check Google and password sign-in, account persistence, saved places, follows/reviews, vendor uploads and edits, booking/payment/refund updates across phone and browser, notification delivery/taps, and vendor sharing after hiding/resuming the browser tab. Test actual Safari/iPhone separately if supported.

Relevant implementation: [account routing](../lib/features/auth/auth_wrapper.dart), [Google sign-in](../lib/core/services/auth_service.dart), [discovery](../lib/features/customer/home/customer_home_screen.dart), [photo storage](../lib/core/services/storage_service.dart), [vendor location](../lib/core/services/vendor_location_service.dart), [checkout](../lib/features/shared/booking_detail_screen.dart), [notifications](../lib/core/services/notification_service.dart), and [web setup](Web%20Browser%20Setup.md).
