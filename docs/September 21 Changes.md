# Discovery and email verification changes

Date: 21 September 2026 (Malaysia time).

## What customers and vendors will see

| Feature | How it works |
| --- | --- |
| Email verification | Email/password accounts must verify their email before entering the app. Firebase sends its standard verification link, using the same built-in delivery system as Forgot Password. Open the link, return to StallSeeker, and tap **I Have Verified My Email**. Already verified accounts and guest browsing continue through their existing flows. |
| Double-tap stall card | One tap selects the stall on the map. Two taps open its details. The existing View stall action remains available. |
| Search this area | Move or zoom the map, then tap the white Search this area button. Results use that map area and the selected distance from its centre, with the current category and opening filters. |
| Location suggestions | Typing at least three characters starts a Malaysia-wide search. Up to 15 distinct matching places appear in a scrollable list. Tap a result, change your choice if needed, then tap Use Location. Nearby location is a ranking hint; it does not limit the search to your current area. |
| Goreng Pisang and Burger | Separate choices are available in customer category filters and the vendor's Edit Stall form. Existing vendors should choose the appropriate category; old categories are not guessed or rewritten. |
| Open at | Choose After 10 PM tonight, Tomorrow morning, or a custom date and time. Tonight covers 10 PM to 6 AM; morning covers 6 AM to noon. A stall matches a preset if it has some scheduled serving time within that window. A custom time requires it to be scheduled open at that exact time. |

Future opening filters use Malaysia time and saved weekly hours, including overnight intervals. Temporary closures take precedence. Stalls without saved schedules are excluded from future searches. These are scheduled openings, not a guarantee that a vendor will actually open. Open now continues to use the vendor's live switch and current temporary closures.

## Email verification delivery

Signup verification and email changes now use Firebase Authentication's built-in action emails. No StallSeeker SMTP account, custom email function, or email-code secret is required.

Before release:

1. In Firebase Console, review **Authentication > Templates > Email address verification** and set the sender name, subject, and message for StallSeeker.
2. Create an owner-controlled test account and confirm that Firebase delivers the link, the link opens successfully, and returning to the app unlocks the account.
3. Deploy the updated Firestore and Storage rules after the delivery test, then test customer and vendor signup with the updated app.

Existing email/password accounts that are still unverified will also see the verification screen. Older installed app versions cannot perform protected writes with an unverified token after these rules are deployed. Coordinate the rule rollout and updated app distribution accordingly.

The app refreshes the Firebase user and ID token after verification. Security rules use Firebase's signed `email_verified` claim rather than a client-editable profile field.

## Verification

- Flutter tests: 14 passed, including Malaysia schedule boundaries, closures, multiple location results, and changing the selected location in the dialog.
- Backend logic tests: eight existing notification and schedule tests passed. The removed custom code-delivery backend no longer needs verification-policy tests.
- Firestore and Storage emulator tests: six passed, including rejection of unverified vendor updates, menu writes, reviews, follows, and photo uploads, while allowing the initial closed vendor signup record.
- Node syntax checks for the remaining Functions entry point passed.
- Flutter analysis passed with no issues.
- Android debug APK build passed: `flutter build apk --debug --no-pub`. Artifact: `build/app/outputs/flutter-apk/app-debug.apk`. Existing plugin Kotlin/Java deprecation warnings were non-fatal. This is a local test build and has not been distributed.
- One live Photon request timed out; a subsequent Bangi request returned 15 suggestions. Location results depend on provider coverage and availability. A device-only fallback is explicitly labelled and offers retry instead of silently presenting one result as the full search.
- No Android device or emulator was connected. Map gestures, double-tap navigation, and Firebase verification-link delivery still need device testing.

## Device acceptance checklist

- Create customer and vendor accounts with a test email you control; open the Firebase verification link before entering the account. Verify vendor phone and role are retained.
- Tap the verification check before opening the link, then open the link, return to the app, and check again. Test resend cooldown and Firebase's expired-link behavior.
- Sign out during delivery; reopen an unverified account; verify an already verified Google account does not get stuck at the gate.
- Try several places in Peninsular Malaysia, Sabah, and Sarawak. Scroll beyond the first few suggestions, choose another result, and confirm the map moves there. Rapidly change the query and ensure old results do not replace the latest query.
- Pan to another town, tap Search this area, and confirm the map and stall list use that area. Change radius, return to current location, and select a stall marker.
- Single-tap and double-tap a stall card; verify map selection and detail navigation respectively.
- Set one vendor to Burger and one to Goreng Pisang, then check each category filter.
- Test a vendor open 8 PM–2 AM with the tonight filter, a morning vendor with the tomorrow filter, and a temporary closure that covers only part or all of the chosen window.
- Check the dialogs on a small phone with the keyboard open and on a tablet.
