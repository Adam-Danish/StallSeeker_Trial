# StallSeeker Demo Runbook

| Field | Recommendation |
| --- | --- |
| Ideal length | 8-10 minutes plus questions |
| Main story | A customer finds and follows a stall; the vendor opens it; the customer receives the update |
| Devices | Two physical phones shown side by side: customer and vendor |
| Backup | Screen recording and screenshots of the same journey |

## 1. Demo principle

Present one connected story, not a tour of every screen. Start with the customer's problem, show the vendor action that solves it, and return to the customer for the result.

The strongest order is:

1. Customer discovers a stall.
2. Customer views its menu and follows it.
3. Vendor updates stock and opens the stall.
4. Customer receives an opening notification.
5. Customer taps the alert and gets directions.
6. Briefly show trust, safety, and testing evidence.

Do not begin with login, registration, settings, architecture, or a long problem statement. Those are supporting details; the useful experience should be visible in the first minute.

## 2. Recommended 9-minute flow

### 0:00-0:40 - Frame the problem

Show the app logo or customer Discover screen while speaking.

Suggested message:

> Food stalls can move, open at different times, and change what is available. StallSeeker helps customers find an open stall using its current location, while vendors can update their menu and availability directly.

Keep this section to two or three sentences. State the two roles - customer and vendor - and move immediately into the app.

### 0:40-2:40 - Customer discovers a stall

Use the customer device.

1. Start on Discover with a prepared location and at least three visible stalls.
2. Point out that open stalls are shown on the map and ordered by distance.
3. Search by stall name or food category.
4. Tap a marker and show the synchronized stall card.
5. Open the stall details.
6. Show current/open status, location freshness, menu prices, and stock labels.

What to say:

> The customer can use GPS or choose a location manually. Results combine the map, search, category, distance, opening status, and the vendor's latest shared location.

Avoid spending time moving and zooming the map repeatedly. One search, one marker, and one details page are enough.

### 2:40-3:30 - Customer follows the stall

1. Tap Follow on the customer device.
2. Open Following and show that the stall is saved.
3. Mention that guests may browse, but following and notifications require an account.

What to say:

> Following turns discovery into an ongoing connection. The customer does not need to keep checking the map to know when this stall starts selling.

### 3:30-5:40 - Vendor manages and opens the stall

Switch to the vendor device. Leave the customer device visible.

1. Open Manage menu & stock.
2. Change one dish from Available to Low stock or Out of stock.
3. Optionally edit the price of one prepared item; do not add a photo live unless image upload is a key assessment requirement.
4. Return to Dashboard.
5. Turn the stall from Closed to Open.
6. Accept the location-sharing explanation and show the active sharing state.

What to say:

> The vendor controls the information customers rely on. Menu stock can be changed quickly, and location sharing is tied to the selling session. Opening the stall starts sharing; closing or signing out stops it.

This is the technical center of the demo. Pause long enough for the audience to see the state change.

### 5:40-7:00 - Complete the notification loop

Return attention to the customer device.

1. Wait briefly for the opening notification.
2. Show the notification text with the prepared stall name.
3. Tap it and show the correct stall details.
4. Confirm that the changed menu stock is visible.
5. Open Notifications and show the saved history/unread behavior.

What to say:

> The opening transition creates a targeted update for followers. The same event is saved in notification history, and tapping the alert returns the customer to the current stall details.

If push delivery takes more than about 8 seconds, continue immediately with notification history or the backup recording. Do not let the presentation stall while waiting on an external service.

### 7:00-7:40 - Directions and real-world handoff

1. Tap Get directions.
2. Show Google Maps, Waze, or the browser choice.
3. Stop before spending time inside the navigation app.

What to say:

> Once the customer decides to visit, StallSeeker hands the vendor's current coordinates to their preferred navigation app.

### 7:40-8:30 - Reliability, privacy, and safety

Return to one concise slide or the relevant settings screen.

Cover only these points:

- Guests can browse without creating an account.
- Customers control notification permission and can delete their account.
- Vendor background location is used only while the stall is intentionally open.
- Server logic prevents duplicate opening-history records and cleans up account data on deletion.
- The current automated cloud suite passes 5 of 5 tests; the full test plan defines the remaining release coverage.

Do not show source code unless the assessor asks. A simple architecture diagram or test summary is easier to understand.

### 8:30-9:00 - Close

End on the customer map or the two devices showing the open stall.

Suggested closing:

> StallSeeker gives customers timely, location-aware stall information and gives vendors a simple way to keep it accurate. The full journey we demonstrated - discover, follow, open, notify, and navigate - is the core value of the app.

Then invite questions.

## 3. What to show only if asked

Keep these ready for questions or a longer demo:

- Registration, Google sign-in, password reset, verification code, and role routing.
- Manual location search and permission-denied recovery.
- Adding/deleting menu items and uploading images.
- Profile editing, notification settings, FAQ, privacy, and terms.
- Logout and permanent account deletion.
- Empty, offline, missing-vendor, stale-location, and retry states.
- Firebase collections, Cloud Functions, and detailed source code.
- The full test case document and automation roadmap.

These are valuable, but showing all of them in the main run makes the product feel like a collection of screens instead of one coherent experience.

## 4. Demo data setup

Prepare data that is easy to read from the audience's distance.

| Item | Demo state |
| --- | --- |
| Customer | Signed-in customer named `Aina`; notification permission allowed |
| Vendor | Signed-in vendor named `Nasi Lemak Adam`; complete stall profile |
| Stall start state | Closed, location available, followed only after the demo follow action |
| Menu | Nasi Lemak RM 6.50 Available; Fried Chicken RM 5.00 Available; Teh Ais RM 2.50 Low stock |
| Nearby data | Two or three other open stalls in different categories |
| Location | Fixed, safe test location with a recognizable map area; never a presenter's home address |
| Network | Stable Wi-Fi plus mobile-data fallback |
| Notification history | A few prior read items so the new unread item is obvious |

Use names and images with strong visual differences. Avoid very long stall or dish names in the primary demo.

## 5. Pre-demo checklist

### Day before

- Install the exact release-candidate build on both phones.
- Confirm both phones point to the staging Firebase project.
- Verify Google Maps key restrictions, OAuth fingerprints, Cloud Functions, SMTP, Firestore indexes/rules, Storage, FCM, and APNs if using iOS.
- Run the 12-case release smoke suite in the test plan.
- Confirm account credentials and disable password-manager popups that could cover the screen.
- Record a clean backup video of the complete 3-minute core journey.
- Capture backup screenshots of Discover, details/menu, vendor open state, received push, history, and directions choice.
- Charge devices and bring cables/power bank.

### 15 minutes before

- Restart both apps and phones if practical.
- Turn off Do Not Disturb, battery saver, VPN, and notification summaries that delay alerts.
- Set comfortable screen brightness and text size.
- Confirm location and notification permissions.
- Confirm the customer FCM token is current by receiving one disposable test notification, then reset the demo stall/history state.
- Set the vendor closed and location sharing inactive.
- Remove the customer follow record for the demo vendor.
- Restore the prepared menu and stock states.
- Keep both devices unlocked and prevent screen timeout for the presentation period.
- Open the customer on Discover and the vendor on Dashboard.
- Close unrelated apps and hide personal notifications.
- Test screen mirroring/projector framing and verify both devices are legible.

### Immediately before speaking

- Confirm Wi-Fi; keep mobile data enabled as fallback.
- Confirm the staging stall is visible at the prepared location.
- Confirm the backup video is open and ready, but not visible to the audience.
- Start a timer where only the presenter can see it.

## 6. Failure fallback order

Use a planned fallback quickly and calmly. The goal is to preserve the story.

| Failure | Immediate response |
| --- | --- |
| GPS cannot locate | Choose the prepared manual location and continue |
| Map tiles do not load | Use the stall list/card or prepared screenshot, then open details |
| Google sign-in fails | Use the already signed-in email customer; never troubleshoot OAuth live |
| Image fails | Continue with the placeholder; menu/status is the important behavior |
| Vendor open write is delayed | Show the vendor active state, then use the prepared customer history/recording |
| Push is delayed | Wait no more than 8 seconds, open notification history, then show the backup push clip |
| Directions app fails | Show the choices and browser fallback, then explain the handoff |
| Internet fails completely | Switch to mobile data once; if still unavailable, play the backup journey and narrate it |
| App crashes | State that the live environment failed, relaunch once, then use the backup instead of debugging |

Never repeat a failing action more than once in front of the audience. Continue the narrative and return to technical diagnosis after the session.

## 7. Suggested presentation materials

Use no more than four supporting slides:

1. **Problem and users:** mobile food stalls, customers, and vendors.
2. **Core journey:** Discover -> Follow -> Vendor opens -> Notify -> Navigate.
3. **System overview:** Flutter app -> Firebase Auth/Firestore/Storage -> Cloud Functions/FCM -> Maps.
4. **Validation and next steps:** smoke result, automated test baseline, high-priority test expansion.

The live app should occupy most of the presentation. Slides support the story; they should not duplicate every screen.

## 8. Likely questions and concise answers

| Question | Answer direction |
| --- | --- |
| Why not just use Google Maps? | StallSeeker focuses on mobile/local stalls, current selling status, vendor-updated menu stock, following, and opening alerts |
| How accurate is the location? | It uses the device's reported high-accuracy position; the app labels stale data and only treats active updates under two minutes as fresh |
| What happens when a vendor closes? | The stall closes, background sharing stops, and customers no longer see it in the normal open-stall discovery view |
| Does location run all the time? | Customer location supports search; vendor background sharing is tied to an intentionally open stall and stops on close/logout |
| Can guests use it? | Guests can discover and inspect stalls; an account is required to follow and receive personalized updates |
| How are duplicate alerts avoided? | Only a closed-to-open transition qualifies, and history uses a stable event-derived ID so retries do not duplicate or reset it |
| What happens when an account is deleted? | The callable backend reauthenticates and removes Auth, profile, owned relationships/history, vendor data, and images as applicable |
| How was it tested? | Start with the 5 passing server tests, then describe the smoke suite, emulator/security plan, and real-device permission/push/location matrix |
| What remains before production? | Complete Flutter automation, committed security-rule tests, production signing/identity, and full Android/iOS release regression |

## 9. Final rehearsal scorecard

The demo is ready when all answers are Yes:

- Does useful customer behavior appear within the first minute?
- Can the core journey finish in under 7 minutes without narration rushing?
- Can the audience read both device screens?
- Does the vendor begin closed and the customer begin not following?
- Does one menu stock change become visible to the customer?
- Does opening produce one notification and one history item?
- Can every external-service failure be bypassed in under 10 seconds?
- Are all accounts, images, notifications, and locations synthetic and presentation-safe?
- Is the backup recording from the same build and dataset as the live demo?
- Can the presenter explain the core value in one sentence at the end?
