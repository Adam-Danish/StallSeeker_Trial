# StallSeeker in a browser

The web and Android versions use the same Firebase project, accounts, menus,
bookings, reviews and notification history.

## Run locally

```powershell
flutter pub get
flutter run -d chrome --web-port 7357
```

Google Maps' browser key is restricted to port 7357 for local development and
the project's `web.app` / `firebaseapp.com` domains. Add another exact origin
to the key's website restrictions before using another port or domain.
`web/maps-config.js` and `lib/core/constants/web_maps_config.dart` contain the
same public browser Maps key. Keep both values in sync. The Android key is
separate and retains its application restrictions.

Maps JavaScript, Places and Geocoding APIs must be enabled. The web loader
loads Maps once, with Places and marker clustering, before starting Flutter.
Address selection uses Google's browser Place API directly to avoid the
installed Places plugin's missing location-field mapping on web.

## Publish

```powershell
flutter build web --release
firebase deploy --only hosting --project stallseeker-c2ffe
```

The stable site is `https://stallseeker-c2ffe.web.app`. A custom domain or
preview channel also needs to be added to Firebase Authentication's authorized
domains, the Maps key's allowed websites, and the Storage bucket's CORS origins.
The bucket currently allows browser image reads from the default hosting
domains and local port 7357; existing Storage security rules still apply.

## Browser behavior

- Google sign-in uses Firebase's popup flow. If blocked, allow pop-ups for
  StallSeeker. Password, guest and registration flows share Firebase Auth.
- Photo selection and upload use image bytes on all platforms. JPEG/PNG and
  other supported image types retain their upload content type.
- Native maps retain their GPS blue dot. Web draws a blue round GPS marker
  using actual device coordinates. Manual search never turns off GPS display
  and does not add a search-location pin.
- Stall cards scroll continuously and retain partial positions. The final
  card stops at the right edge. Marker selection brings a card into view.
- Location permission requires HTTPS, except on localhost. Browsers can
  provide less precise coordinates than phone GPS. A fresh browser asks for
  location when the customer clicks My location; existing grants are reused.
- A vendor's browser location sharing pauses when its tab is hidden. The
  vendor can resume sharing or choose a fixed stall location manually.
- Browser notifications require browser support and explicit permission in
  Settings. The Firebase messaging service worker handles background alerts.
  The optional `FCM_WEB_VAPID_KEY` build definition selects a custom public
  web-push key; otherwise Firebase's default key is used.
- Separate phone/browser push tokens are retained, with a maximum of 20
  current registrations per account. Backend senders support old phone-only
  registrations as well as the new token list. The five affected production
  notification/booking functions and the web Hosting build were published
  on 2 November 2026 following user approval.
- On web, a customer taps Pay on the booking screen. Checkout opens a reserved
  browser tab to avoid popup blocking after the network request. Returning to
  StallSeeker refreshes the verified payment state. Payments remain Stripe
  test mode.

## Verification

```powershell
flutter analyze --no-pub
flutter test --no-pub
node --test functions/*test.cjs
```

Live browser smoke checks should include guest maps, address suggestions and
selection, photos, card scrolling, filtering, pin selection and the login
dialog. Google-account login, vendor editing/uploads, checkout and actual
push delivery also need account/device testing with the appropriate accounts.

On 2 November 2026, the release web build and analyzer passed, all 145 Flutter
tests and 38 backend/schedule tests passed, and browser smoke checks verified
guest browsing, Maps/clusters, public photos, address suggestions and selection,
the left-aligned login Cancel button, and card scrolling at phone width. The
last-card edge behavior is also covered by phone and tablet widget tests.
