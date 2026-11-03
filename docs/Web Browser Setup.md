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

The public site is `https://stallseeker.my`; Firebase Hosting also serves
`https://stallseeker-c2ffe.web.app`. A custom domain or
preview channel also needs to be added to Firebase Authentication's authorized
domains, the Maps key's allowed websites, and the Storage bucket's CORS origins.
The bucket currently allows browser image reads from `https://stallseeker.my`,
the default hosting domains, the existing preview domain and local port 7357;
existing Storage security rules still apply. The custom domain was added to
the existing GET/HEAD CORS policy on 3 November 2026 after stall and menu photos
were found to render as placeholders there. Public image responses now return
`Access-Control-Allow-Origin: https://stallseeker.my` for that origin, and live
browser checks confirm the cover and menu photos display. No app rebuild is
needed for this bucket configuration change.

## Browser behavior

- Google sign-in uses Firebase's popup flow. If blocked, allow pop-ups for
  StallSeeker. Password, guest and registration flows share Firebase Auth.
- Photo selection and upload use image bytes on all platforms. JPEG/PNG and
  other supported image types retain their upload content type.
- Native maps retain their GPS blue dot. Web draws a blue round GPS marker
  using actual device coordinates. Manual search never turns off GPS display
  and does not add a search-location pin.
- Stall cards scroll continuously and retain partial positions. The final
  card stops at the right edge. Scrolling never selects a stall or moves the
  map. Tapping a card focuses its stall and outlines the category marker;
  marker selection brings a card into view. Cards follow the visible viewport.
- Search here is centered above the cards. Results actions reserve enough
  height for full labels, and the top header/search/filter gaps are 6 pixels.
- Firebase initializes before querying apps, avoiding a browser-dependent
  pre-initialization error. Startup failures offer Retry and expandable error
  details. Hosting revalidates entry scripts, and the Maps/Flutter loaders and
  compiled app use build-specific URLs so existing tabs bypass older cached
  releases. The custom Flutter bootstrap does not register an offline worker;
  the separate Firebase messaging worker still handles notifications.
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

On 2 November 2026, the release web build and analyzer passed, all 153 Flutter
tests and 38 backend/schedule tests passed, and browser smoke checks verified
guest browsing, Maps/clusters, public photos, address suggestions and selection,
the left-aligned login Cancel button, and card scrolling at phone width. The
last-card edge behavior is also covered by phone and tablet widget tests.
Regression tests also cover passive card scrolling, explicit tap focus, viewport
membership, centered results actions at phone/desktop widths and enlarged text,
and initialization before inspecting Firebase apps. Real iPhone startup still
requires a device check; a phone-width Chromium check does not validate Safari.
