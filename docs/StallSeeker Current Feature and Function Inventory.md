# StallSeeker — Current Feature and Function Inventory

**Analysis date:** 24 October 2026 (Asia/Kuala_Lumpur)  
**Code version:** `1.0.3+4`; Git HEAD `2721f1c`  
**Scope:** Current application source, all 82 Dart files under `lib`, the three configured Cloud Functions codebases, Firestore/Storage rules and indexes, platform configuration, and supporting tests/scripts. Generated builds, conversation exports, and Repomix exports are not treated as the application source of truth.

This is a source-based product and technical inventory. “Fully Implemented” means that the described capability has a concrete implementation and is connected to its stated flow; it does **not** certify production deployment, credentials, device permissions, or successful operation on every platform. Payment functionality is explicitly a Stripe sandbox implementation. Reachable features, retained legacy implementations, and unreachable screens are identified separately.

## Key findings

- There are three access paths: anonymous guest, registered customer, and registered vendor. There is no administrative application screen.
- Customers have Home, Following, Notifications, and Settings tabs. Vendors have Dashboard and Settings tabs.
- Discovery uses live vendor and menu snapshots, Google Maps, dish/stall/category search, price and schedule filters, saved places, and location selection.
- Stall details include live status, menu sections, stock, stall/dish following, reviews with photos, phone calls, directions, and eligible self-collect booking entry.
- **New bookings are shared Firebase bookings, despite the `DemoOrder` naming.** New bookings start at checkout, then become visible in the vendor booking list after verified test payment. The code also supports earlier request/accept/reject bookings.
- Payment, refund, vendor sales, and payment history are **test-mode capabilities**. Real-money checkout, vendor bank deposits, and payouts are not implemented.
- A change-email screen and service methods exist, but there is no current navigation link to that screen.
- An older device-only booking service remains in source and tests; current booking screens do not display it.

## Status definitions

| Status | Meaning in this report |
|---|---|
| Fully Implemented | A working implementation exists for the stated scope, with its required caller or backend export present. Runtime service configuration still applies. |
| Partially Implemented | Significant code exists, but a missing entry point, incomplete platform setup, incomplete lifecycle behavior, or material implementation limitation prevents calling the broader capability complete. |
| Hardcoded/Mock | Static bundled content, fixed configuration/defaults, an intentionally simulated financial capability, or the retained device-only demo. This does not mean all code behind a simulated capability is fake. |

---

## 1. Exhaustive feature list grouped by screen / module

### 1.1 Startup, splash, and startup failure

**Primary sources:** [main.dart][main], [splash_screen.dart][splash].

- Initialize Flutter bindings and Firebase using platform-specific generated options.
- Display startup logo, StallSeeker name, “Find nearby food stalls, live.” tagline, and loading indicator.
- Automatically replace splash with account routing after approximately 850 ms.
- Apply the app's light theme and readable dark system-status icons; suppress the debug banner.
- Initialize notifications asynchronously after the application starts.
- If Firebase initialization throws, display a startup failure message.
- **Retry:** invoke application initialization again from the failure view.

### 1.2 Session routing, verification gate, and account recovery

**Primary source:** [auth_wrapper.dart][authWrapper].

- Observe Firebase user changes rather than requiring manual screen refresh after sign-in/sign-out.
- Show loading state while checking the session.
- Route signed-out users to Welcome.
- Require an explicit guest-entry action for an anonymous session in the current wrapper instance; an existing anonymous Firebase session alone does not bypass Welcome.
- Route permitted guests to customer Home.
- Route unverified non-anonymous users to email verification.
- Listen to the signed-in user's Firestore profile and route `customer` or `vendor` roles appropriately.
- Attempt profile repair for missing/invalid role data; infer vendor role from an existing vendor document, otherwise customer.
- Show account/session failure or incomplete-setup recovery messages.
- **Retry:** recreate the profile listener and reattempt profile repair.
- **Sign out:** clean up the current session; show an error snackbar if it fails.
- Hold notification navigation until account verification and role routing are ready.
- **Limitation:** role repair is an attempted recovery mechanism; the rules preserve an existing role and can reject replacement of an already stored invalid role.

### 1.3 Welcome screen

**Primary source:** [welcome_screen.dart][welcome].

- Display app identity, logo, and tagline.
- **Continue with Google:** open Google authentication, then exchange credentials with Firebase.
- **Log in or sign up:** open the adaptive login interface.
- **Top-right close icon / Continue as guest:** reuse an existing anonymous session or create one, then grant guest browsing access.
- Hide the guest-close icon while the login interface is open.
- Disable primary actions while authentication is running and show progress.
- Show authentication errors in a snackbar; Google-picker cancellation is handled silently.

### 1.4 Login screen, phone sheet, and larger-screen dialog

**Primary source:** [login_screen.dart][login].

- Provide standalone login plus a draggable phone bottom sheet and a centered dialog on displays with shortest side at least 600 logical pixels.
- Phone sheet supports drag, dismissal, snap sizes, scrolling, safe layout, and keyboard-inset adjustment.
- Email field supports email keyboard, autofill, and next-field input action.
- Password field supports secure text, password autofill, and submit from the keyboard.
- Validate email using the screen's simple `@` check and require a nonempty password.
- **Eye icon:** toggle password visibility.
- **Continue:** validate, submit email/password login, display progress, and show service errors.
- **Forgot password?:** open reset-password screen with the typed email prefilled.
- **Continue with Google:** invoke Google/Firebase sign-in.
- **Sign up:** replace the current login route with registration.
- **Close:** dismiss the login interface when not busy.
- Automatically close a login route when a non-anonymous Firebase sign-in occurs.
- Dragging scroll content dismisses the keyboard.
- Google authentication and Firebase credential exchange each have a 25-second timeout in the service.

### 1.5 Registration screen

**Primary sources:** [register_screen.dart][register], [auth_service.dart][auth], [vendor_phone.dart][phone].

- Collect full name, email, password, and confirmation.
- Validate required name, basic email format, password length of at least six characters, and matching confirmation.
- **Password eye:** toggle masking for both password and confirmation together.
- **Customer / Vendor segmented selector:** choose the account role before registration.
- Selecting Vendor reveals a business-phone field and explains that customers can call the number.
- Validate and normalize Malaysian mobile/landline numbers to `+60…` format.
- **Create account:** create Firebase Authentication identity and batch-write the user profile; vendor signup also creates an initial closed vendor record with its business phone.
- Show busy state and authentication/backend errors.
- Successful registration returns to the root account-routing flow, where email verification is required.
- **Sign in:** replace registration with login.
- **Close / Continue as guest:** reuse/start an anonymous session and attempt to return to the previous route.
- **Limitation:** guest access is ultimately granted by the Welcome callback; registration's close action does not itself call that callback. Firebase identity creation and Firestore profile creation are separate operations, so failure after identity creation is not rolled back atomically.

### 1.6 Forgot-password screen and sent-email state

**Primary source:** [forgot_password_screen.dart][forgot].

- Accept an optional prefilled email from Login or Change password.
- Validate the email with a fuller email-pattern check.
- **Send reset link / keyboard submit:** call Firebase password reset.
- Display a generic success message whether or not an account uses the address, reducing account enumeration.
- Replace the form with “Check your email,” recipient information, and Spam/Junk guidance after success.
- Enforce a visible 60-second resend countdown.
- **Resend email:** request another reset when the cooldown ends.
- **Use another email:** return to the email-entry state; existing cooldown still applies.
- **Done:** close the screen.
- Explain that Google users should use Google sign-in.
- Show inline errors for invalid address, throttling, network problems, or other send failures.
- Block leaving the shared account layout while an operation is busy.

### 1.7 Email-verification screen

**Primary source:** [email_verification_screen.dart][verification].

- Automatically request a standard Firebase verification email after screen initialization.
- Show the current address and instructions to open the email link and return.
- **I Have Verified My Email:** reload the Firebase user, check verification, and refresh the ID token.
- Recheck verification quietly when the app resumes from the background.
- **Resend verification email:** send again after the 60-second countdown.
- **Use a different account:** sign out.
- Display sending/checking progress and success/error messages.
- On successful verification, the account gate can continue to the role-specific application.

### 1.8 Change-email screen — implemented but currently unreachable

**Primary sources:** [change_email_screen.dart][changeEmail], [auth_service.dart][auth].

- Collect and validate a different email address.
- **Send Verification Link:** call Firebase `verifyBeforeUpdateEmail`.
- Make the address read-only after a link has been sent.
- **I Have Verified My New Email:** reload the user, compare the actual email with the requested address, refresh the token, then sync email/verification fields to Firestore.
- Recheck quietly when the application resumes.
- **Resend verification email:** use a 60-second cooldown.
- Show progress and error/success snackbars; close with a success result after confirmation.
- Handle duplicate address, recent-login requirement, and throttling errors.
- **Status:** Partially Implemented as an app feature: no current screen imports or navigates to `ChangeEmailScreen`; Edit Profile explicitly displays a read-only email.

### 1.9 Customer application shell and tabs

**Primary sources:** [customer_home_screen.dart][home], [app_pill_navigation.dart][pill].

- Floating navigation bar with Home, Following, Notifications, and Settings.
- **Tab taps:** change the selected view; `IndexedStack` preserves mounted tab state.
- Selected tabs change icon and accent styling.
- Notifications tab and Home bell show unread-history counts, capped visually at `99+`.
- Settings tab shows the customer booking-attention badge.
- **Returning to Home:** reload the personalized greeting.
- Home and Settings use custom headers; Following and Notifications use app bars.
- Adapt content clearance to floating navigation and device safe areas.

### 1.10 Customer Home — location header and map

**Primary sources:** [customer_home_screen.dart][home], [map_marker_focus.dart][markerFocus], [vendor_model.dart][vendorModel].

- Personalized morning/afternoon/evening greeting using the first word of the account name; guests show Guest.
- Show the current search-location label or a prompt to set it.
- **Location header / Set location chip:** open the location-source sheet.
- **Bell icon:** switch to Notifications.
- Render a styled Google map with vendor markers and a blue search-location marker.
- Default initial camera targets Kuala Lumpur coordinates `(3.1390, 101.6869)` when no location has been applied.
- Show the device-location layer when GPS-derived permission state permits it.
- Support normal map panning, zooming, and rotation; custom controls replace the native compass/location buttons.
- **Vendor marker:** select the stall, change its marker color, focus the camera, and reveal its result card.
- **Marker info window:** open stall details; it contains stall name, category, and status.
- **Search-location marker:** identify the search origin and its label/map-area context.
- **Map tap:** dismiss the keyboard.
- **Compass:** animate the camera to north-up and zero tilt while keeping its target/zoom.
- **My location:** request GPS permission/location again, reverse-geocode it, recenter the map, and use it as the search origin.
- Show locating progress; handle GPS off, denied/permanently denied permission, timeouts, and unavailable coordinates.
- Location error banner offers **Enter manually**.
- Restore a registered customer's previously saved search origin before requesting fresh GPS.
- Persist chosen origin, coordinates, readable label, manual/GPS flag, and update time for non-anonymous accounts.
- Guard against stale GPS responses overwriting a newer manual/pin selection.
- Reevaluate freshness displays every 30 seconds.
- A recently shared location is marked fresh only while sharing is active and its timestamp is under two minutes old; stale locations remain available as “Last known location.”

### 1.11 Customer Home — discovery search and suggestions

**Primary sources:** [customer_home_screen.dart][home], [discovery_search_filters.dart][filters], [dish_search_service.dart][dishSearch], [search_history_service.dart][searchHistory].

- Search live menu dish names, stall names, and stall categories.
- Apply substring matching case-insensitively with normalized whitespace.
- Update filtered results while typing; keyboard submission commits the normalized query to recent history.
- **Clear search X:** clear the text and active query.
- **Tune icon when search is empty:** open the category dropdown.
- Show a scrollable suggestion panel while the field has focus.
- Suggest dishes, stalls, offered categories, and prior searches, each with its source icon/label.
- Limit suggestions to eight, deduplicate labels case-insensitively, and rank exact match, prefix, word-prefix, then substring matches.
- Use source priority dish → stall → category → recent when labels overlap; recent-search removability is preserved.
- Restrict suggestions to eligible nearby vendors and the active price range.
- **Suggestion tap:** submit its label as the search, dismiss focus, and save history.
- Focusing an empty field shows recent searches.
- **Recent-item X:** remove that history item optimistically; reload history if removal fails.
- **Recent searches → Clear:** clear saved history, with reload on failure.
- Keep the newest ten recent entries in the interface, deduplicated without case sensitivity.
- Store guest history locally and signed-in history in Firestore; merge guest history into a verified customer session on Home initialization.
- A history-write failure does not cancel the search; it shows a dedicated snackbar.
- For a matching dish query, include its sellers even if the stall is closed, bypassing the usual opening-status check for those dish matches.
- Search results distinguish unknown menu prices instead of treating invalid/missing prices as free items.

### 1.12 Customer Home — category, price, radius, and opening-time filters

**Primary sources:** [customer_home_screen.dart][home], [discovery_search_filters.dart][filters], [price_range_picker.dart][pricePicker], [open_at_picker.dart][openAt], [stall_categories.dart][categories].

- **Status dropdown:** Open now, Closed, or All stalls. Default is Open now.
- **Category dropdown:** All or one of nine fixed categories: Goreng Pisang, Burger, Beverages, Snacks & Desserts, Malay Food, Chinese Food, Indian Food, Western, Noodles.
- **Distance dropdown:** 5, 10, 25, or 50 km when an origin exists; default 5 km.
- Changing radius updates distance eligibility and map zoom; distances use geographic distance between coordinates.
- **Any price / price chip:** open a price-range sheet, prefilled from the current filter.
- Enter minimum, maximum, either bound, or neither; format RM labels and allow up to two decimal places.
- Validate finite nonnegative values and maximum ≥ minimum; price bounds are inclusive.
- **Apply price range / keyboard submit from maximum:** apply the selected range and clear stall selection.
- **Reset:** return to Any price.
- **Sheet close icon:** dismiss without applying edits.
- **Price-chip delete X:** clear the active range immediately.
- For dish-name searches, the matching dish itself must meet the price bound; a cheap unrelated item cannot qualify an expensive dish.
- For stall/category searches, the stall must offer a genuinely priced matching/eligible menu item.
- **Open at… chip:** open visit-time selection.
- **After 10 PM tonight:** search scheduled serving time from 10 PM (or now if later) through 6 AM tomorrow.
- **Tomorrow morning:** search scheduled serving time between 6 AM and noon tomorrow.
- **Choose date and time:** open date then time pickers, supporting dates up to 365 days ahead; reject past custom times.
- Use Malaysia time for schedule calculations and labels.
- Future-time filtering consults weekly hours and subtracts temporary closures; a window matches if any serving interval remains.
- Activating scheduled filtering sets status to All / displayed Scheduled; choosing a live status clears scheduled filtering.
- **Opening-time-chip X:** clear the future filter and restore Open now.

### 1.13 Customer Home — search area, result cards, and expanded lists

**Primary source:** [customer_home_screen.dart][home].

- Load all valid-location vendors and all menu entries as live streams; perform discovery filtering locally.
- Restrict stall-result cards to the visible map bounds, then sort nearest to the search origin.
- **Search this area:** after a user moves the map, apply pending map bounds and map center as the search origin, clear selection, and reset list scroll.
- When the map settles near a stall marker, automatically focus the nearest qualifying marker within a zoom-scaled threshold.
- Distinguish programmatic camera movement from a user gesture to avoid unwanted search-area prompts/selection changes.
- Display result count and labels for stalls, matching stalls, or dishes.
- **Stall card single tap:** select/recenter/reveal the stall on the map.
- **Stall card double tap / chevron:** open stall details.
- Stall cards show image/fallback, name, category, opening status, distance, and location freshness.
- Dish cards show image/fallback, dish name, known price/price unavailable, vendor, stock state, opening status, and distance.
- **Dish-card tap:** open its stall details. Home dish search does not currently pass a dish ID to focus that one menu item.
- Sort dish results by distance, then dish name.
- **View all stalls:** open a scrollable bottom sheet with names, images, category/status/distance; selecting a row focuses that stall on the map.
- **View all dishes:** open a larger result sheet with dish price/stock/stall/distance/status; selecting a row opens stall details.
- Both expanded sheets have close icons.
- Support horizontal cards on phones and a vertical floating side panel on sufficiently large displays (at least 900 × 600 logical pixels).
- Hide card rows on very short viewports while preserving result header/map access.
- Show loading, unavailable menu data, no matches, and no stalls in radius/bounds states.
- **Retry on stall-load error:** recreate the vendor stream.
- **Known minor gap:** one empty state suggests “Expand area,” but there is no separately wired button with that name; the actual available controls are radius selection and moving/zooming the map.

### 1.14 Location-source sheet

**Primary source:** [customer_home_screen.dart][home].

- **Use current location:** request/reuse device GPS and set it as the search origin.
- **Enter manually:** open Malaysian place/address search.
- **Pin on map:** open exact map-pin placement.
- **Home & saved places:** open Home/custom-place management.
- Selecting an option closes the sheet before opening its flow; ordinary dismissal makes no location change.

### 1.15 Manual location dialog

**Primary sources:** [manual_location_dialog.dart][manualLocation], [place_search_service.dart][places].

- Search Malaysian places, areas, cities, states, and postcodes via Google Places autocomplete.
- Begin requests after two characters with a 350 ms debounce; keyboard Search explicitly submits.
- Show at most five Google suggestions with primary/secondary addresses and Google attribution.
- **Suggestion tap:** fetch place coordinates, mark the result selected, and show its full label.
- Show search/detail progress and block conflicting result taps.
- If Google errors or returns no suggestions, fall back to device geocoding with Malaysia added to the query.
- Sort device results approximately by proximity to the existing origin, show up to three candidates, and deduplicate labels.
- Reverse-geocode readable addresses; fall back to named coordinates when necessary.
- Show limited-device-results notices and differentiated no-result/unavailable errors.
- **Retry Google search:** reattempt Google after a device-fallback result.
- **Use location:** enabled only after a valid selection and when not busy; return the selected coordinates and label.
- **Cancel:** close without applying the selection and invalidate pending results.
- Ignore stale asynchronous responses after query changes, a newer request, or dialog disposal.
- Google calls time out after 12 seconds; device forward/reverse geocoding after eight seconds.
- This dialog is reused for customer origins, saved places, pin search, and vendor manual-location fallback.

### 1.16 Pin-location screen

**Primary source:** [pin_location_screen.dart][pin].

- Show a map centered on the supplied location and a fixed center-pin indicator.
- Pan/zoom the map to choose the exact coordinates; rotation and tilt are disabled.
- **Search for a place:** open manual location search and animate to the chosen address.
- Clear a previously resolved address when the map moves to a materially different point.
- **Use this pin:** reverse-geocode the current center or fall back to coordinates, then return the location.
- Keep confirmation disabled until the map is ready; freeze gestures during confirmation.
- Show progress while resolving the label; Back closes without applying.

### 1.17 Saved places sheet and custom-place naming dialog

**Primary sources:** [saved_locations_sheet.dart][savedSheet], [saved_location_service.dart][savedService], [saved_location.dart][savedModel].

- Show HOME and CUSTOM PLACES groups, using a context-specific title for Home/Custom entry points.
- **Saved-place row:** return that precise pin as the discovery origin, with name and address in the label.
- **Save Home location:** create the single Home pin; Home always uses ID `home` and name `Home`.
- **Add custom location:** create another named pin.
- **More → Edit place:** choose a new location and, for custom places, edit its name.
- **More → Remove place:** delete the pin and reload the list; no additional confirmation dialog is implemented.
- Location-choice sub-sheet offers **Search address**, **Pin on map**, and **Use current search location**.
- The current-search option uses the passed search origin, not a new GPS reading.
- Custom-place dialog collects a required name, caps entry at 60 characters, and has **Cancel** / **Save place**.
- Show saved names, addresses, Home/custom icons, loading/saving indicators, inline failures, and **Retry**.
- Sort Home first and custom names alphabetically.
- Guests store pins in device preferences; registered customers store them in their private Firestore subcollection.
- Ignore invalid/corrupt legacy guest entries instead of hiding all other saved pins.
- Validate IDs, finite coordinate ranges, name/address bounds, boolean type, and Home consistency.
- **Limitation:** guest saved places are not merged into an account on sign-in; only search history has such a merge.

### 1.18 Stall details — identity, status, contact, and actions

**Primary source:** [vendor_details_screen.dart][details].

- Show stall photo/fallback, name, category, description, current opening badge, today's planned hours, active temporary-closure notice, business phone, and location freshness/explanation.
- Subscribe to the vendor document so edits/status/deletion update while the page is open.
- Keep the previous data and show a warning if vendor updates fail; show a distinct no-longer-available message when deleted.
- Reevaluate location freshness every 30 seconds.
- **Refresh icon:** fetch current vendor details independently of the passed-in snapshot.
- **Heart:** follow/unfollow the stall, update the heart optimistically, and roll back if the write fails; disable during save or after stall deletion.
- **Guest heart:** show an account-required dialog.
- Account-required dialog offers **Not Now** and **Log In**, which opens login.
- **Phone row/call icon:** launch the system dialer using `tel:`.
- **Get directions:** open navigation selection if the stall still exists and has a valid location.
- **Book for self-collect:** open this stall's cart only when self-collect is enabled, the stall is currently open, and its location is valid.
- **Sign in to book:** for eligible guests, show the account-required dialog.
- On phones, action buttons are in a bottom area; at width 700+ they appear in a left information column beside the menu/reviews.
- **Back:** return to the previous screen.

### 1.19 Navigation-app selection sheet

**Primary source:** [vendor_details_screen.dart][details].

- Detect Google Maps and Waze URL handlers on native platforms.
- **Google Maps:** open driving navigation using the platform-specific URL scheme, when detected.
- **Waze:** open navigation to the stall coordinates, when detected.
- **Google Maps in browser:** always offer browser directions as a fallback.
- Explain when installed navigation apps were not detected.
- Close the chooser before launching; show a snackbar when the selected navigation app cannot open.
- Directions use the stall coordinates; the application does not implement its own route calculation or turn-by-turn navigation.

### 1.20 Stall details — menu, menu search, and dish following

**Primary source:** [vendor_details_screen.dart][details].

- Subscribe to this vendor's menu and group items by menu section; legacy items default to Main menu.
- Display item photo/fallback, name, RM price, Available/Low Stock/Sold out badge, and stock-update timestamp formatted in Malaysia time.
- **Search dishes:** filter this stall's menu by case-insensitive dish-name substring.
- **Clear dish search X:** clear that filter.
- When opened from a dish follow/alert, restrict to the supplied dish ID and display a followed-dish context notice.
- **Show all dishes:** remove the focused-dish restriction.
- **Follow dish / Following dish:** create/remove a restock subscription for a verified customer, with per-item saving spinner and success/error snackbar.
- Guest attempt opens the login-required dialog; unverified/noncustomer attempts show explanatory messages.
- Load current dish subscriptions and disable follow controls during loading/failure.
- **Retry dish following:** recheck the account role and recreate the subscription.
- **Retry menu:** recreate the menu stream after an error.
- Show empty menu, no search results, and focused dish no longer on menu states.

### 1.21 Stall details — reviews and review editor sheet

**Primary sources:** [vendor_details_screen.dart][details], [stall_review_service.dart][reviews], [storage_service.dart][storage].

- Subscribe to public reviews and sort by most recently updated.
- Show review count and arithmetic mean rating to one decimal place.
- Display reviewer name, numeric star rating, optional text, and horizontally scrollable photo thumbnails with broken-image fallback.
- Recognize the current user's review using customer ID.
- **Write a review / Edit your review:** open the same editor with blank or existing values.
- Guests receive an account-required dialog.
- **Stars 1–5:** choose rating; saving without a rating shows a snackbar.
- Optional review text allows up to 1,000 characters and multiple lines.
- **Add photos:** open multi-image gallery selection; retain at most five total existing/new photos.
- Show existing/new-photo chips and count.
- **Photo-chip remove X:** omit that photo from the saved review.
- **Save review:** upload new photos, write/replace the customer's single review for this stall, then best-effort delete removed stored photos.
- Show saving state and failure snackbar; close after successful save.
- Firestore rules restrict writes to verified customers reviewing another vendor; the editor itself only performs a guest check before opening.
- **Not present:** a delete-review action, vendor replies, moderation, purchase-verification badge, or full-screen photo viewer.

### 1.22 Following tab — stalls

**Primary source:** [customer_following_screen.dart][following].

- **Stalls / Dishes selector:** switch between followed stalls and dish subscriptions.
- Stream followed vendor IDs and individually subscribe to their live profiles.
- Show open and closed groups with counts; a deleted stall drops out of displayed profiles.
- **All stalls / Open now:** show all followed stalls or just currently open ones.
- **Alphabetical-sort icon:** toggle A→Z and Z→A order inside the displayed groups.
- **Refresh icon / pull down:** cancel and recreate listeners.
- **Stall row:** open stall details; show category and Open/Closed state.
- Guest view offers **Sign in**.
- Show loading, empty list, no open followed stalls, total load failure with **Retry**, and partial-load warning.
- There is no unfollow button directly on a stall row; unfollow through stall details.

### 1.23 Following tab — dishes

**Primary source:** [followed_dishes_list.dart][followedDishes].

- Require a verified account to display dish subscriptions.
- Sort subscriptions by most recent follow time.
- Subscribe to both the current dish and its vendor for every row.
- Show dish name, vendor, price, and Available / Low stock / Sold out · waiting for restock status.
- Show Loading, Could not refresh, or No longer available when underlying data is unavailable.
- **Row tap:** open vendor details focused on that dish, if vendor/data are available.
- **Active-notification icon:** unfollow the dish directly, with a saving spinner and failure snackbar.
- **Retry:** recreate the dish-subscription stream after a list failure.
- Show count, explanation of restock alerts, and an empty-state guide.

### 1.24 Notifications tab

**Primary sources:** [customer_notifications_screen.dart][notificationScreen], [notification_history_service.dart][historyService].

- Show server-created stall-opening and dish-restock notification history newest first.
- **All / Unread:** filter the currently loaded list.
- Highlight unread cards with background, weight, dot, and event-specific icon.
- Show title, body, and local-formatted date/time.
- **Notification tap:** try to mark it read, fetch its current vendor, and open stall details; dish alerts focus the relevant dish.
- Do not discard navigation merely because mark-read failed; show that error separately.
- Show missing-link, unavailable vendor, timeout, and open-failure feedback.
- **Mark shown as read:** mark all loaded unread records read, in chunks of 400; newly arriving records outside that loaded set are not included.
- **Swipe end-to-start / Remove:** delete an alert optimistically; restore it on server failure.
- **Pull-to-refresh:** recreate the history stream.
- Initially load 50 records; **Load older updates** increases the query limit by 50.
- Guest empty state offers **Sign in**.
- Show no notifications/no unread results states.
- Distinguish permission-denied, unauthenticated, unavailable, deadline-exceeded, failed-precondition, and unknown errors; display a selectable error code and **Retry**.
- **Boundary:** this history screen stores stall/dish alerts. Booking pushes open bookings directly and do not create records in this inbox in the current backend.

### 1.25 Customer Settings / Profile

**Primary sources:** [customer_profile_screen.dart][customerProfile], [profile_page.dart][profilePage].

- Display full name, email, Google/Firebase profile photo if available, or fallback avatar.
- **Header Edit / Edit Profile:** open account-name editor; guests instead see Sign in actions.
- **My Profile:** open personal information for registered users.
- **Live bookings:** show up to two active bookings and a View all link for registered customers.
- **Current Location:** choose GPS or manual address; update the Home search location and show permission/GPS/error text.
- **Home location / Custom pins:** open the saved-place sheet in the corresponding context.
- **My Bookings:** open Active/History booking lists.
- **Notifications and Sounds:** open the notification preference screen for registered users.
- **Privacy Policy / Terms of Use:** open bundled legal pages for registered users.
- **Change password:** shown only for users whose Firebase providers include email/password.
- **Help & FAQ / About StallSeeker:** open informational screens, including for guests.
- **Delete account:** open the authenticated deletion flow.
- **Logout / Leave guest mode:** open the confirmation action sheet.
- **Pull-to-refresh:** reload account data.
- Refresh account data after returning from a successful edit/personal-information flow.
- **Boundary:** “Notifications and Sounds” is the menu label; the destination has one notification-enable switch, not sound selection or volume controls.

### 1.26 Vendor application shell

**Primary source:** [vendor_main_screen.dart][vendorMain].

- Dashboard and Settings tabs with retained mounted state.
- Show dashboard attention badge for new vendor booking activity, formatted as `99+` above 99.
- **Dashboard refresh icon:** ask the dashboard to reload its vendor listener/data.
- Apply selected-tab icons, safe-area navigation spacing, and Settings-specific background.

### 1.27 Vendor Dashboard — stall operation and location sharing

**Primary sources:** [vendor_dashboard_screen.dart][dashboard], [vendor_location_service.dart][vendorLocation], [vendor_service.dart][vendorService].

- Show stall name or setup prompt and subscribe to the vendor document.
- **Pull-to-refresh / retry:** recreate the listener.
- **Stall open/closed switch:** open or close the selling session.
- Before opening, require a nonempty stall name, valid Malaysian business phone, and no currently active temporary closure.
- Opening confirmation explains background location and Android's persistent sharing notification.
- **Cancel / Open stall:** dismiss or proceed.
- Attempt a high-accuracy GPS reading, requesting permission if needed, with a 12-second timeout.
- If GPS fails, offer the reusable manual-location dialog, preserving prior valid coordinates as context.
- Save location and timestamp, turn the stall open, and start location updates for GPS-based operation.
- Manual opening stores a valid fixed location without enabling live sharing and shows explanatory feedback.
- **Close switch:** pause sharing, write closed status, and show confirmation feedback.
- Show active/paused/off location-sharing state and location service error text.
- **Resume sharing:** obtain GPS/permission and restart the sharing stream while the stall remains open.
- If a live vendor update says the stall has closed, pause an active location stream.
- Show saving indicator; prevent concurrent operational changes; report failed operations.
- **Manage menu & stock:** open menu management.
- Stall information card shows category, today's hours, and description.
- **Edit stall:** open the stall-profile editor.
- **Boundary:** weekly hours describe the plan; they do not automatically open the stall. Scheduled temporary breaks can close it, and reopening afterward is manual.

### 1.28 Vendor Dashboard — self-collect and live booking preview

**Primary sources:** [vendor_dashboard_screen.dart][dashboard], [live_booking_section.dart][liveBookings].

- **Self-collect bookings switch:** persist whether new customers may start bookings at this stall.
- Show update progress and success/error feedback.
- **View current and past bookings:** open vendor Active/History lists.
- Live bookings preview shows up to two active bookings, customer names, totals, progress/status, payment labels, unread marker, and count of additional active bookings.
- **Preview card:** open booking details.
- **View all:** open full booking list.
- The preview's internal unseen count still checks legacy `requested` records; the shell badge uses a broader attention predicate that also includes paid checkout-first bookings.

### 1.29 Vendor Dashboard — Demo sales and payment history

**Primary source:** [vendor_demo_sales.dart][sales].

- Calculate today's and total simulated paid sales from vendor booking data.
- Use Malaysia calendar days and `paymentPaidAt` for today's grouping.
- Deduct recorded refunded cents from paid totals; exclude zero/net-refunded or unpaid transactions.
- Display paid order count, TEST MODE label, loading/error states, and explicit no-payout text.
- **View payment history:** open Demo payment history.
- Payment history lists this vendor's test bookings whose payment status is not `unpaid`, after the vendor-service visibility filter.
- Show customer, payment-state label, and original booking total.
- **Payment-history row:** open vendor booking details.
- Show empty/error/loading history states.
- **Status:** Hardcoded/Mock for earnings as a financial product: figures are derived from real sandbox records, but represent simulated revenue and do not produce deposits/payouts.

### 1.30 Vendor Settings / Profile

**Primary sources:** [vendor_profile_screen.dart][vendorProfile], [profile_page.dart][profilePage].

- Display account name, email, vendor business phone, and account-provided photo/fallback.
- Header Edit, Edit Profile, My Profile, Notifications and Sounds, Privacy Policy, Terms of Use, provider-eligible Change password, Help & FAQ, About, Delete account, and Logout behave as their shared customer equivalents.
- **Current Location:** fetch current GPS and reverse-geocode the vendor's present area for display; show service/permission/error states.
- This Settings lookup does not itself write operational stall coordinates; Dashboard controls sharing.
- **My Stall:** open stall-profile editing.
- **Pull-to-refresh:** reload user/vendor profile details.
- No Home/custom pins or customer My Bookings row are wired into vendor Settings.

### 1.31 Edit-stall screen

**Primary source:** [edit_stall_screen.dart][editStall].

- Load existing stall information, business phone, photo, weekly hours, and temporary closures.
- **Photo area / camera badge:** choose a gallery photo and preview it; retain existing image if no replacement is picked.
- Edit required stall name and description.
- **Food category dropdown:** choose a fixed supported category.
- Edit and normalize the required Malaysian business phone.
- Embed the weekly-hours and temporary-closures editor.
- If legacy free-text hours exist without structured weekly hours, display them as previous hours for migration context.
- **Done:** validate fields, upload a replacement photo if present, merge editable profile fields into Firestore, show success, and return.
- **Cancel:** leave without saving; save/cancel buttons disable while saving and progress is shown.
- Show load spinner and save-failure snackbar.
- Profile writes intentionally exclude current location, live-sharing state, open/closed state, and self-collect setting, so editing descriptive information does not overwrite the selling session.
- **Limitation:** image picking/loading has less explicit failure handling than the menu editor, and this screen does not implement the same busy back-navigation guard.

### 1.32 Weekly-hours section and temporary-closure pickers

**Primary sources:** [stall_schedule_editor.dart][scheduleEditor], [stall_schedule.dart][schedule].

- Display Monday through Sunday switches with Closed/Scheduled labels.
- **Day switch on:** add a default 9 AM–5 PM interval; **off:** remove that day's intervals.
- **Opening/closing time buttons:** open time picker for each interval.
- Reject identical opening and closing times.
- Support overnight intervals where closing is earlier than opening.
- **Add time:** add a default 6 PM–10 PM interval, up to three intervals per day.
- **Remove time X:** remove that interval.
- **Add closure:** choose start date/time, then end date/time; require end after start.
- Accept closure date selection from roughly yesterday through two years ahead; store instants using Malaysia time conversion.
- Sort closures by start time and display formatted Malaysia dates/times.
- **Remove closure trash:** remove it from the draft.
- Cap closures at 20; disable addition at the cap.
- Changes become persistent when the parent Edit stall screen is saved.
- **Boundary:** there is no overlap detection/merging for weekly intervals and no separate in-place edit action for an existing closure; remove/re-add is available.

### 1.33 Vendor Menu & stock screen

**Primary sources:** [vendor_menu_screen.dart][vendorMenu], [menu_service.dart][menuService].

- Subscribe to the vendor's menu and show item image/fallback, name, RM price, and section.
- **Available / Low stock / Sold out chips:** set qualitative stock status and server timestamp; ignore reselecting the current status.
- Disable only the busy item's controls and show its progress indicator.
- **More → Edit dish:** open prefilled menu editor.
- **More → Delete dish:** show “Delete dish?” with the item name and irreversible-action copy.
- **Delete confirmation → Cancel / Delete:** leave it or remove the Firestore menu item.
- A backend deletion trigger removes its stored image; another removes all matching dish subscriptions.
- **Add dish floating button:** open a new menu editor.
- Show empty-menu guidance, loading spinner, and load error with **Retry**.
- **Boundary:** stock is a three-state vendor-controlled label; there is no numeric inventory or automatic quantity deduction.

### 1.34 Add/Edit dish sheet

**Primary source:** [vendor_menu_screen.dart][vendorMenu].

- Present a modal sheet that cannot be dragged away or dismissed by tapping outside.
- Allocate a stable document ID when adding so retrying an uncertain save does not create another dish ID.
- Edit required dish name (80-character limit), required menu section (40-character limit), and price.
- Default new section to Main menu.
- Validate finite positive price with no more than two decimal places.
- **Choose photo:** open gallery, preview chosen image, or keep/display the current image.
- **Done:** upload replacement image if selected, then create/update menu fields.
- New dishes start Available and receive stock-update timestamp.
- **Cancel:** close without saving when idle.
- Disable form/actions and prevent Back while saving.
- Preserve edits and show inline save failure for retry; handle gallery-opening errors inline.
- **Boundary:** there is no remove-photo button, camera capture mode, custom crop editor, or standalone menu-section-management screen.

### 1.35 Customer self-collect cart

**Primary source:** [demo_order_cart_screen.dart][cart].

- Load the selected vendor's live menu.
- Show stall name, self-collect heading, payment-before-vendor explanation, menu count, and explicit Stripe test/no-real-charge text.
- **Plus:** increase an available item's quantity up to 20.
- **Minus:** decrease quantity to zero; disable at zero.
- Show quantity and price per item; display Out of stock and disable addition for sold-out items.
- Exclude sold-out selections from effective quantity and total when live stock changes.
- Recalculate total and item count in integer cents with RM formatting.
- Show RM2 minimum-order guidance if below the threshold.
- **Choose an item / Continue to payment:** disabled until the total is at least RM2 and no submission is running.
- Verify a signed-in, non-anonymous, email-verified account before submission; the server also validates customer role.
- Submit only item IDs and quantities to the backend, which obtains trusted names/prices from its own menu read.
- Successful submission replaces the cart with booking details and immediately starts opening checkout.
- Show progress and backend-specific/fallback errors; loading/error/empty menu states are provided.
- Cart quantities are screen-local memory; there is no persisted cart, delivery address, special instructions, multi-vendor basket, discount, or tax/service-fee calculation.

### 1.36 My bookings / Stall bookings — Active and History

**Primary sources:** [demo_orders_screen.dart][orders], [booking_detail_screen.dart][bookingDetails], [demo_order_service.dart][orderService].

- Query the current customer's or vendor's shared Firestore bookings newest first.
- **Active / History tabs:** switch by tapping or swiping.
- Active excludes collected, rejected, cancelled, and expired effective statuses.
- Show booking summary cards: counterparty name, total, status, optional payment label, item summary, created date, and unread dot.
- **Card tap:** open role-specific booking details.
- Show empty/loading/error list states.
- Vendor lists hide checkout-first bookings until `paymentPaidAt` exists; customer lists include their unpaid checkouts.
- Current UI contains no tab for older device-only demo bookings.

### 1.37 Booking details — progress, actions, pickup, and read state

**Primary sources:** [booking_detail_screen.dart][bookingDetails], [demo_order.dart][orderModel], [bookings.cjs][bookings], [booking-core.cjs][bookingCore].

- Subscribe to one booking and show counterparty, start/request timestamp, line-item quantities/subtotals, and total.
- Render progress for checkout-first flows and earlier request/accept flows.
- Show legacy vendor-response deadline when a requested booking has an expiry.
- **Opening an unseen booking:** request the server to clear that participant's unread flag.
- **Vendor Accept / Reject:** handle earlier `requested` bookings.
- **Vendor Start preparing:** move confirmed → preparing; for test-payment bookings it is unavailable until payment is paid.
- **Vendor Mark ready:** move preparing → ready and trigger customer-ready attention/push.
- **Vendor Mark collected:** move ready → collected.
- **Customer Cancel booking / Cancel and refund:** available for requested bookings and supported test bookings before collection.
- **Vendor Cancel booking / Cancel and refund:** available in confirmed/preparing/ready UI; legacy requested records can be rejected.
- Cancellation confirmation offers **Keep booking** and **Cancel booking / Cancel and refund** with appropriate payment explanation.
- **Self-collect location:** open Google Maps for the pickup coordinates snapshotted when the booking was created.
- Earlier non-test bookings show a message that payment is arranged directly with the stall.
- Disable booking action buttons during operations; show backend-specific/fallback error snackbars.
- Show not-found, loading, and read-error states.

### 1.38 Booking payment card, external checkout, and return page

**Primary sources:** [booking_payment_card.dart][paymentCard], [booking_detail_screen.dart][bookingDetails], [stripe-payments.cjs][stripeEndpoints], [stripe-payment-service.cjs][stripeService].

- Show TEST MODE, booking amount, payment state, payment reference, and refunded amount where recorded.
- Display paid, awaiting/pending, failed, expired, cancelled, refund pending, refund failed, refunded, and partially refunded labels.
- For legacy requested bookings, explain payment is available after acceptance.
- Display remaining time in the ten-minute payment window; vendor wording explains preparation is waiting for payment.
- **Pay RM…:** create/reuse Stripe test Checkout and open it in an external application/browser.
- The client rejects non-HTTPS/non-`checkout.stripe.com` checkout URLs.
- Display a blocking progress view while opening secure checkout or checking payment, with accessible live-region messaging.
- If checkout launch fails, show **Try again** to reopen the returned URL.
- Show test-card instructions and explicit no-real-money text.
- **Check payment:** ask the backend to retrieve and reconcile actual Stripe sandbox state.
- Automatically recheck on app resume and once on opening a relevant booking; queue a resume recheck if another operation is busy.
- Repaint countdown every second for payment bookings.
- Stripe success/cancel URLs go to a small hosted HTML return page telling the user to return to the app and check the booking.
- **Boundary:** the return page has no custom deep link to reopen the app; success/cancel query text is not treated as proof of payment. Verified Stripe state determines the result.

### 1.39 Personal-information screen

**Primary sources:** [personal_information_screen.dart][personalInfo], [profile_header.dart][profileHeader].

- Display account avatar, full name, Customer/Vendor account label, email, account type, and sign-in providers.
- Translate Firebase provider IDs into Google and Email and password labels.
- Show detail values as selectable text; missing values show Not available.
- **Edit:** open the shared name editor and reload name after a successful change.
- **Back:** close the screen.
- Profile photos are displayed from the authentication account; this screen does not upload or replace avatars.

### 1.40 Edit-profile screen

**Primary sources:** [edit_profile_screen.dart][editProfile], [auth_service.dart][auth].

- Prefill full name and display the account avatar.
- Edit required full name up to 80 characters, with name autofill and word capitalization.
- Display email read-only with an explanation that it cannot be changed here.
- **Done / keyboard submit:** verify owner session, save the trimmed name to Firestore, and best-effort sync Firebase Auth display name.
- **Cancel:** discard draft edits.
- Show inline errors and Saving state; disable fields/actions and prevent leaving during save.
- Return a success flag to the profile screen so it can refresh and show “Profile updated.”

### 1.41 Change-password screen

**Primary sources:** [change_password_screen.dart][changePassword], [auth_service.dart][auth].

- Collect current password, new password, and confirmation.
- Each field has its own **Show/Hide password** control.
- Disable suggestions/autocorrect; provide password/new-password autofill hints.
- Validate current password presence, new length ≥6, new differs from current, and matching confirmation.
- **Update password / keyboard submit:** reauthenticate with the current password and call Firebase password update.
- Preserve deliberate spaces in this flow's passwords; unlike this flow, login/signup service methods trim submitted passwords.
- Show invalid-current-password, network, throttling, recent-login, and provider errors.
- On success, clear password fields and display a success state.
- **Back to profile:** close after success.
- **Forgot your current password?:** open reset password with the account email prefilled.
- The profile entry is hidden for Google-only users.

### 1.42 Notification settings

**Primary sources:** [notification_settings_screen.dart][notificationSettings], [notification_service.dart][notifications].

- Load the account's notification preference and the device's authorization status together.
- **Stall & dish notifications switch:** persist enablement, request system permission when enabling, and register/remove the current FCM token.
- Disabling also cancels local displayed notifications.
- Show Allowed, Quiet notifications allowed, Blocked in phone settings, or Permission not requested.
- If blocked, explain how to allow notifications in phone settings.
- Refresh preference/permission state on app resume.
- Show busy and inline failure states; reject guest management.
- Explain that in-app history remains even if alerts are disabled.
- **Boundary:** no button opens system settings, and no sound/vibration/per-category preferences exist. The shared account preference is also respected by booking and dish push senders; the legacy stall-opening sender has weaker preference handling described below.

### 1.43 Delete-account screen

**Primary sources:** [delete_account_screen.dart][deleteAccountScreen], [auth_service.dart][auth], [functions-account/index.js][accountBackend].

- Explain permanent removal of profile, follows, history, and vendor data.
- Require confirmation text whose trimmed, uppercased form equals `DELETE`; the check is case-insensitive despite exact-word UI copy.
- Email/password users must provide current password and can toggle its visibility.
- Google users reauthenticate using the Google picker.
- **Delete Account / keyboard submit:** validate confirmation, reauthenticate, clear device notification registration, call server account deletion, remove matching old local demo data, and sign out.
- **Cancel / Back:** leave when idle.
- Disable controls and prevent leaving while busy; show inline errors for confirmation, credentials, expired session, and server failure.
- On success, return to root routing.
- Server cleanup covers recursive user/vendor data, incoming/outgoing stall follows, dish follows to the vendor, owned/received bookings, reviews, legacy stalls/verification-code records, and relevant storage images, before deleting Firebase Auth identity.
- **Status limitation:** this is a real deletion implementation, but it does not explicitly reconcile/refund active Stripe payments or delete `bookingPayments` / booking-notification marker records. Guest-local pins/history also have separate device-level retention behavior. Complete lifecycle erasure is therefore Partially Implemented.

### 1.44 Logout / Leave Guest Mode confirmation sheet

**Primary source:** [logout_helper.dart][logout].

- Present an explicit Cupertino action sheet for Logout or Leave Guest Mode.
- **Cancel:** close without ending the session.
- **Log Out / Leave Guest Mode:** pause vendor location sharing, remove current device notification registration, sign out Google if initialized, then Firebase sign-out.
- Show progress and retain the sheet with retryable error text if sign-out fails.
- Prevent outside-tap dismissal and prevent Back while busy.
- On success, return navigation to its root account flow.

### 1.45 Help & FAQ

**Primary source:** [faq_screen.dart][faq].

- Display role-specific questions plus shared account questions.
- Customer topics: discovery, price filtering, saved pins, history, missing stalls, menu/stock, stall following, dish alerts, notification history, and missing alerts.
- Vendor topics: opening, missing map listing, menu/stock, photos, and follower notification triggers.
- Shared topics: name editing, forgotten password, missing reset email, and logout/data retention.
- **Search questions:** filter both questions and answers case-insensitively.
- **Clear search X:** restore all questions.
- **Question/chevron tap:** expand/collapse the answer, retaining expansion with page-storage keys.
- Show grouped sections and no-matching-answer feedback.
- **Back:** leave the page; scroll on phones and in a constrained larger-screen panel.
- FAQ content is hardcoded. Its account-avatar wording is not authoritative for avatar behavior; the UI uses provider photos/fallback graphics.

### 1.46 About StallSeeker

**Primary source:** [about_screen.dart][about].

- Display logo, app name, hardcoded “Version 1.0.3 · Prototype,” and FYP prototype notice.
- Explain product purpose, discovery, vendor management, guest/account access, and checking latest details.
- Scroll content and return with Back.
- Version display is bundled text, not dynamically read from package metadata.

### 1.47 Privacy Policy and Terms of Use

**Primary source:** [legal_screen.dart][legal].

- Two routes share one legal-page renderer.
- Privacy content covers collected information, usage, location, storage/sharing, choices, deletion, and contact.
- Terms cover purpose, account responsibility, vendor information, prototype payments/refunds, acceptable use, availability, account action, and changes/contact.
- Display a hardcoded last-updated date of 20 October 2026 and support email as text.
- Scroll and return with Back.
- These are bundled informational documents. There is no consent checkbox/version acceptance record or contact-email launch button.

### 1.48 Shared visual and interaction components

**Primary sources:** [app_dropdown.dart][dropdown], [app_pill_navigation.dart][pill], [ios_grouped.dart][grouped], [account_ui.dart][accountUI], [info_page.dart][infoPage], [profile_header.dart][profileHeader], [app_theme.dart][theme].

- Reusable dropdowns support current selection/checkmark, label/hint, icon-only or compact mode, disabled state, open/closed arrow state, constrained scrolling menus, and callback on selection.
- Reusable navigation component supports selected icons, labels, badges supplied by callers, and tab actions.
- Grouped cards, icon tiles, profile avatar, and pill-shaped top actions provide consistent screen controls.
- Shared account layout constrains wide screens, scrolls around the keyboard, blocks navigation while busy, and provides common progress buttons/errors.
- Inline account error text and payment transitions expose live-region semantics for assistive technology.
- Information pages provide scrollable, width-constrained larger-screen layout and Back.
- Theme uses light Material 3 styling, platform typography, and shared colors/shapes.
- No dark-theme configuration, theme toggle, language selector, localization catalogue, or onboarding carousel is implemented.

---

## 2. Functionality and business-logic inventory

### 2.1 User account and security functions

| Function / entry point | Implemented behavior and conditions |
|---|---|
| `AuthService.authStateChanges`, `currentUser` | Expose Firebase auth state/current identity. Firebase SDK session state is reused; there is no custom remember-me checkbox or custom session-token store. |
| `repairCurrentUserProfile()` | Skip guests and valid roles; inspect vendor record and merge missing identity/profile fields and an inferred role. Subject to existing-role write restrictions. |
| `signUp()` | Normalize vendor phone; create email/password identity; create user role/profile and initial closed vendor document through a Firestore batch. |
| `login()` | Trim email/password, authenticate through Firebase, and return a user-facing error string or success. |
| `_ensureGoogleSignInReady()`, `signInWithGoogle()` | Initialize Google Sign-In once with configured client ID, authenticate, exchange ID token with Firebase, and create customer profile for a new Google user. Handle cancellation, timeout, and conflicting credential provider. |
| `signInAsGuest()` | Create a Firebase anonymous session used for public customer browsing. |
| `getUserData(uid)` | Fetch/deserialize user profile; log failures and return null if unavailable. |
| `saveCustomerLocation()` | Merge selected origin, label, manual flag, and server update timestamp into the registered user's profile; skip guests. |
| `signOut()` | Pause vendor location, clear notification registration, sign out initialized Google session, and always attempt Firebase sign-out. |
| `resetPassword()` | Send standard Firebase reset link; present the same result for an unknown account; translate invalid email/throttling/network failures. |
| `sendEmailVerificationLink()` | Reload current account, skip already verified users, and send standard Firebase verification link. |
| `refreshEmailVerification()` | Reload user, require verified email, and force-refresh the signed token. |
| `sendEmailChangeLink()`, `refreshEmailChange()` | Verify-before-update flow; sync verified replacement address to Firestore. Service code exists, but the screen is unreachable from current navigation. |
| `changePassword()` | Reauthenticate a password-provider account, then change password; handle wrong credentials/recent-login/network/throttling errors. |
| `updateFullName()` | Verify owner identity, trim and bound name to 1–80 characters, update Firestore, then best-effort sync Auth display name. |
| `deleteAccount()` | Reauthenticate by password or Google, call configured deletion callable, clear old local demo data, and sign out. |

**Role behavior:** customer/vendor role is chosen during email registration; new Google users are customers. No role-switching UI exists. Email verification is required before the registered application gates open. Anonymous users can read public stall/menu/review data and keep guest-local search/pins, but cannot create bookings, reviews, or dish subscriptions.

**Server/rule boundaries actually present:**

- Vendor document/menu writes require a verified non-anonymous owner whose user profile role is vendor, except the restricted initial vendor record created at registration.
- Booking documents are readable only by verified participants; clients cannot directly create/update/delete them. Callable functions perform authoritative writes and participant/role checks.
- Review writes require a verified customer, the review document ID matching the customer, and a different target vendor.
- Dish subscriptions and cloud saved locations require verified customer ownership; dish IDs and original follow timestamps are immutable.
- Notification content is server-created. A user can read/delete their own alerts and change only `isRead` to true.
- Search-history writes require verified ownership, bounded query strings, normalized lowercase field, and server timestamp.
- User role is preserved on updates. However, profile reads are allowed to **any authenticated identity**, not just the profile owner; this is broader than a private-profile model.
- Stall-follow creation checks verified customer ID ownership but does not enforce a customer role in the same way as dish following.
- Public read/write rules exist for legacy `reports`, `stalls`, and `_connection_test_` collections. No corresponding user-facing report/admin capability is found in the active application.
- Storage limits review-image writes to the matching verified customer, image content type, and less than 5 MB; stall/menu image paths enforce UID ownership but lack equivalent file size/content-type rules and explicit vendor-role validation.
- No app-layer MFA, biometric sign-in, SMS sign-in, App Check enforcement, account-management administrator UI, or server rate-limiting policy is implemented here.

**Primary sources:** [auth_service.dart][auth], [auth_wrapper.dart][authWrapper], [firestore.rules][firestoreRules], [storage.rules][storageRules]. These describe existing controls and limits, not a separate security audit or certification.

### 2.2 Core data CRUD and service entry points

| Service | Function inventory |
|---|---|
| `VendorService` | `getVendorProfile`: one-shot fetch with null/error fallback; `saveVendorProfile`: merge descriptive profile fields; `toggleStallStatus`: persist open state and clear sharing when closing; `updateVendorLocation`: save coordinates/freshness/sharing; `watchVendorProfile`: live single-vendor stream; `setSelfCollectEnabled`: persist opt-in; `getAllVendors`: live discovery source; `getOpenVendors`: implemented open-only query helper, currently not used by the Home flow. |
| `MenuService` | `getMenuItems`: live vendor menu; `newMenuItemId`: allocate ID; `addMenuItem`: validate name/positive price and create default-available item; `updateMenuItem`: update name/price/section and optional image without resetting stock; `updateItemStatus`: validate state and set stock timestamp; `deleteMenuItem`: delete the document. Writes have 15-second timeouts. |
| `FollowService` | `followVendor`, `unfollowVendor`, `isFollowing`, `getFollowedVendorIds`. Predictable customer/vendor document ID prevents duplicate follows. Live listeners synchronize heart state and the Following screen across devices. |
| `DishFollowService` | `follow`, `unfollow`, `watch`, `watchDish`. Validate IDs/owner/verified customer role; create via transaction only when absent, preserving original `followedAt`; store under the owner user; optional vendor-scoped subscription query. |
| `StallReviewService` | `watchReviews`: read and locally sort reviews newest-updated first; `saveReview`: validate 1–5 stars, max five photos, max 1,000 characters, and overwrite the single customer-keyed review. No review-delete service method. |
| `SavedLocationService` | `load`, `save`, `delete`; choose guest preferences or current-account cloud storage; use one stable Home ID, preserve precise coordinates, sort Home/name, validate data, and tolerate corrupt local records. Cloud operations time out after 12 seconds. |
| `SearchHistoryService` | `loadRecent`, `mergeGuestHistoryIntoCustomerAccount`, `save`, `remove`, `clear`; normalize/cap text to 100 characters, deterministic base64URL lowercase query IDs, newest-ten retrieval, retry-safe guest merge. Cloud history is not automatically pruned to ten stored documents; only retrieval/UI is limited. |
| `DishSearchService` | `watchAllDishes`: stream collection-group `menu`, derive parent vendor ID, preserve known-price metadata, deserialize, and sort by dish name. |
| `DemoOrderService` | `watchCustomerOrders`, `watchVendorOrders`, `watchBooking`, `watchUnseenCount`, `requestOrder`, `respond`, `advance`, `cancel`, `createTestCheckout`, `refreshPayment`, `markViewed`. Uses `bookings` and callable functions; filters unpaid checkout-first records from vendor lists. Generates a secure random request key per new client submission. Checkout/refresh callable requests allow 120 seconds. |
| `NotificationHistoryService` | `watch`: newest limited history; `watchUnreadCount`: at most 100 unread for `99+`; `markRead`, `remove`: owner-checked writes with ten-second timeout; `markDisplayedRead`: deduplicate IDs and batch 400 writes while rechecking ownership. |
| `StorageService` | `pickImage`: gallery with maximum width 1080 and quality 80; `uploadStallImage`: stable overwrite path; `uploadMenuItemImage`: stable per-dish overwrite path; `pickReviewImages`: gallery multi-select, width 1080/quality 75 and remaining-five cap; `uploadReviewImage`: unique review-image path; `deleteReviewImageUrl`: require expected vendor/customer prefix before deletion. |
| `PlaceSearchService` | `search`: Google Places autocomplete, Malaysia restriction and minimum two characters; `getCoordinates`: fetch location field by place ID; `dispose`: lifecycle hook currently does no work. |

**Primary sources:** the named [vendor][vendorService], [menu][menuService], [stall-follow][followService], [dish-follow][dishFollowService], [review][reviews], [saved-location][savedService], [search-history][searchHistory], [dish-search][dishSearch], [booking][orderService], [notification-history][historyService], [storage][storage], and [place-search][places] service implementations.

### 2.3 Search, sorting, filtering, and calculations

- `normalizeDiscoveryQuery`: trim, collapse whitespace, and lowercase search text.
- `MenuPriceRange.contains`: require a known finite nonnegative dish price and apply inclusive lower/upper bounds; `label` formats closed/open-ended RM ranges.
- `vendorMatchesQueryAndPrice`: combine stall/category/dish-name search with correct matching-dish price logic.
- `buildDiscoverySuggestions`: collect sources, filter radius-eligible vendor data and budget, deduplicate, rank, and limit suggestions.
- Discovery result sorting uses physical distance; dish-name breaks equal-distance ties. There is no Home price-sort or rating-sort control.
- Home stall cards are bounded by map viewport in addition to radius. The dish-result list uses nearby filtered vendors but does not apply the same viewport-card restriction.
- `stallNearMapCenter`: choose the nearest visible vendor within a normalized map-center region, default fraction 0.15 of viewport spans.
- Following stalls sort A→Z/Z→A and group by effective open state; followed dishes sort by follow timestamp.
- Reviews sort by latest update; average is calculated in the client from the streamed set.
- Bookings sort by server `createdAt` descending; Active/History is a client classification.
- Saved locations sort Home first, then case-insensitive name.
- Notification history sorts on server `createdAt`; Load older increases the query's limit, rather than using a cursor-based client page model.
- Server opening/restock fan-out does use bounded pages/cursors; history uses 200-follower pages and 20-profile lookups, dish pushes use up to 500 tokens, and cleanup/write batches use 400.
- Discovery, menu, following, reviews, booking lists, and sales do not have explicit user-facing pagination; many query the whole matching collection.

### 2.4 Schedule, location freshness, and model helpers

- `malaysiaTime` / `malaysiaInstant`: convert between absolute instants and Malaysia calendar fields.
- `isWithinStallSchedule`: evaluate a single visit instant, including previous-day overnight carryover and Sunday/Monday rollover; closures override availability.
- `hasScheduledOpening`: intersect a window with planned intervals and subtract closures; true if any serving portion remains.
- `StallHoursInterval.fromMap`: validate minute bounds and reject equal endpoints; `parseWeeklyHours` ignores malformed entries; `serializeWeeklyHours` writes all seven weekday keys.
- `TemporaryClosure.contains`: inclusive start, exclusive end; parser requires valid timestamp ordering.
- `formatStallTime`: format minutes as 12-hour display time.
- `VendorModel.isOpenNow`: persisted `isOpen` **and** no current temporary closure. It does not require a fresh location or that current time is within weekly hours.
- `VendorModel.hasValidLocation`: finite valid ranges and exclude `(0,0)`; `hasFreshLocation`: active sharing plus nonfuture timestamp less than two minutes old.
- `hoursToday`: structured Malaysia weekday intervals, Closed today, or legacy free-text fallback; mark overnight closing as next day.
- `toProfileMap` separates profile information from operational fields; `toMap`, parsers, and `copyWith` support persistence/state updates.
- `SavedLocation.fromMap` rejects invalid IDs, coordinates, strings, and inconsistent Home records; `selection` includes the saved name/address.
- `normalizeVendorPhone`: remove common separators, accept Malaysian national/60/+60 prefixes, validate mobile/landline shape, and produce `+60…`; it does not verify ownership by OTP.
- Menu/notification models supply legacy defaults and safe fallback labels; booking models support Firestore timestamps and local JSON serialization.
- `DemoOrderItem.subtotalCents`: quantity × unit price. `DemoOrder` derives effective expiry, active status, payment eligibility, preparation eligibility, customer cancellation eligibility, vendor attention, and net simulated sales.
- `withStatus`, `toMap`, and `fromMap` remain for old local bookings; `fromDocument` reads the live booking schema.
- `demoOrderStatusLabel`, `bookingStatusLabel`, and `bookingPaymentLabel` centralize user-facing lifecycle/payment wording.

### 2.5 Authoritative booking workflow and business constraints

**Primary sources:** [bookings.cjs][bookings], [booking-core.cjs][bookingCore], [stripe-payment-core.cjs][stripeCore].

1. Require a signed-in, non-anonymous, email-verified actor.
2. Validate customer/vendor identity, reject self-booking, validate vendor ID and request-key shape, and limit a request to 1–20 distinct dishes.
3. Re-read customer role, vendor role, stall, and selected menu items in a transaction.
4. Vendor must opt into self-collect, be explicitly open, have valid coordinates, and have no active temporary closure. Freshness and weekly planned hours are not part of this eligibility check.
5. Validate each integer quantity from 1–20; reject missing/sold-out dishes, invalid names, and invalid/out-of-range prices. Snapshot trusted menu names and prices; do not trust client totals.
6. Enforce a total of at least RM2.00. Prices are rounded to integer cents; each stored menu price must be between zero and RM10,000 for this server function.
7. Derive booking ID from actor UID and request key. Repeating the same key is idempotent. A fresh UI submission generates a fresh key, so this is not a universal duplicate-order detector across separate submission attempts.
8. Create the new booking as `confirmed`, `checkoutFirst: true`, payment mode test, provider Stripe, `awaiting_payment`, ten-minute deadline, no initial vendor attention, and a pickup-location snapshot.
9. Vendor-facing streams hide the new record until verified payment has a paid timestamp.
10. Payment success sets vendor attention; vendor can prepare, mark ready, and mark collected. The customer receives ready attention and push.
11. Supported earlier flows remain `requested → confirmed/rejected`, then preparing/ready/collected, with optional reply expiry.
12. Enforce actor and transition rules on every update; reject preparation before test payment is paid.
13. Allow supported customer/vendor cancellation before collection; paid test cancellation marks refund pending and invokes backend Stripe reconciliation.
14. `markBookingViewed` only clears the actor's own relevant unread flag; unrelated users are rejected.
15. Expiry scheduler processes due legacy requests each minute, up to five pages of 100 in one invocation, and sends expiry feedback to customers.

**Lifecycle labels implemented:** requested, confirmed, preparing, ready, collected, rejected, cancelled, expired. New checkout-first UI displays confirmed/unpaid as Awaiting payment and confirmed/paid as Paid · awaiting preparation.

### 2.6 Stripe test payment and refund functions

**Primary sources:** [stripe-payments.cjs][stripeEndpoints], [stripe-payment-service.cjs][stripeService], [stripe-payment-core.cjs][stripeCore].

- Enforce sandbox `sk_test_` / `rk_test_` keys; reject live keys. API/webhook keys are declared as backend secrets.
- Validate participant identity/role on refresh and customer-only ownership on checkout creation.
- `assertPayable`: check owner, test mode, confirmed status, supported unpaid status, safe integer total ≥200 cents, and unexpired deadline.
- Persist one checkout attempt/UUID and its exact Stripe parameters under `bookingPayments/{bookingId}` before making the external call.
- Use an idempotency key for Checkout session creation, reusing it after uncertain/time-out responses or cross-device retries.
- Support repair of an older uncreated attempt's retired parameter spelling; do not recover a missing session blindly after 23 hours.
- Create card-only MYR Checkout with booking/customer/vendor/attempt metadata, aggregate order total, and success/cancel return URLs.
- `assertSession`: verify test mode, payment mode, currency, amount, buyer/vendor/booking/attempt metadata, client reference, and known session identity before applying results.
- Webhook verifies raw-body Stripe signature, accepts only sandbox events, and recognizes completed, async success/failure, expired, payment-intent failure, charge-refunded, and refund-updated event types.
- Re-read Stripe's latest state rather than trusting webhook arrival order; paid/refunded states do not regress because of stale unpaid events.
- Update paid reference/timestamp and checkout-first vendor attention transactionally; avoid writing unchanged fields to prevent trigger loops.
- Expire open sessions on cancellation or unpaid deadline. If payment completes during expiry, re-read Stripe and preserve/reconcile the payment.
- A late success for an already cancelled/expired/rejected booking enters refund handling.
- Full test refund uses its own stable idempotency key and records refund identity/status; recognize Stripe-dashboard refunds and partial refunded cents.
- Full dashboard refund can also cancel an active booking. Vendor simulated sales subtract recorded refunds.
- Refund errors expose pending/failed statuses; no administrative refund-retry UI is present.
- Each minute, process up to 100 due confirmed/unpaid test bookings. Callables/triggers have 120-second timeout and at most five instances in their configured options.
- Return page sets no-store and restrictive content-security headers; it does not write payment success based on browser parameters.

**Not implemented as commercial payments:** live charges, connected vendor accounts, bank onboarding, transfers/payouts, settlement reports, payment-method saving, downloadable receipts/invoices, fees/commissions, and financial reconciliation across account deletion.

### 2.7 Background, notification, cleanup, and scheduled functions

There are **18 exported application backend entry points** across the three configured codebases:

| Export | Trigger / responsibility |
|---|---|
| `recordVendorOpeningHistory` | Vendor update; create durable per-customer opening history with stable event hash, follower-time eligibility, missing/deleted/vendor-account filtering, and retry-safe create-once writes. |
| `notifyFollowersOnStallOpen` | Vendor update exactly false→true; find stall followers and send multicast FCM with a vendor link. This is the older, simpler push sender, separate from history. |
| `notifyFollowersOnDishAvailable` | Menu update out_of_stock→available/low_stock; create restock inbox events and deliver pushes using a durable pending/delivered/skipped/discarded state. |
| `cleanupDeletedDishFollows` | Menu deletion; remove matching subscriptions across users in batches of 400. |
| `cleanupDeletedMenuItemImage` | Menu deletion; delete the stable menu image, ignoring missing files, with retries enabled. |
| `createBooking` | Callable; validate and create checkout-first self-collect booking transactionally. |
| `updateBooking` | Callable; validate participant/role and lifecycle transition, update unread/payment flags, and send applicable status push. |
| `markBookingViewed` | Callable; clear the participant's unread flag. |
| `expireBookings` | Every minute; expire legacy unanswered requests and notify customers. |
| `notifyPaidSelfCollect` | Booking update; when checkout-first payment becomes paid/confirmed, create a deduplication marker and alert vendor. Explicitly configured in `asia-southeast1`. |
| `createStripeCheckout` | Callable; customer-only sandbox checkout creation/reuse. |
| `refreshStripePayment` | Callable; participant-authorized payment reconciliation. |
| `stripeWebhook` | Public HTTPS POST; verify signature and sandbox event, then reconcile booking. |
| `stripePaymentReturn` | Public HTTPS HTML endpoint with instructions to return to the app. |
| `closeCancelledStripePayment` | Booking update; reconcile cancelled/expired/rejected test payments and refunds. |
| `expireStripePayments` | Every minute; reconcile expired unpaid payment windows. |
| `deleteAccount` | Account-deletion codebase callable; require sign-in within ten minutes and delete related account data/identity. |
| `closeStallsForScheduledBreaks` | Schedule codebase, every five minutes, Asia/Kuala_Lumpur; close persisted open state and sharing during active temporary closures; batch up to 400 writes. No automatic reopen. |

**Push client lifecycle:**

- Create high-importance Android notification channel and initialize local notifications.
- Receive foreground FCM messages and display local notifications because the app is active.
- Route taps from foreground/local, background, and terminated/cold-start messages.
- Decode booking vs vendor/dish payloads and retain compatibility with older plain-vendor-ID payloads.
- Queue deep-link destinations until verification/account routing permits navigation; check current account/booking recipient before opening.
- Ask for system permission after a recognized signed-in role is established.
- Save a single FCM token on the user document and follow token rotations through serialized writes.
- Remove matching device token transactionally when muted/signing out, delete the FCM token, cancel local alerts, and clear pending destinations.
- Expose load/update preference methods: `isEnabledForCurrentUser`, `setEnabledForCurrentUser`, `syncTokenForCurrentUser`, `clearCurrentDevice`, `configureForRole`, `setNavigationReady`, and `initialize`.
- Background-message handler is deliberately empty; Android/system notification payload display provides the background alert.
- A single `fcmToken` per user means the latest device registration can replace another device's token; there is no per-device token collection.

**Delivery boundaries:** stall-opening push lacks the newer dish sender's token deduplication/chunking, per-recipient stored preference check, invalid-token cleanup, and durable delivery state. Muting normally removes the current token, but it is not an equivalent server-side preference guard for the older sender. Paid-booking push marks a deduplication event before calling a push helper that catches delivery failure; no durable failed-push retry queue is implemented for that event. History and live data can therefore remain correct even if an individual phone push is missed.

### 2.8 Vendor background location functions

**Primary source:** [vendor_location_service.dart][vendorLocation].

- Singleton ChangeNotifier exposes `start`, `pause`, `isSharing`, and `error` to the Dashboard.
- Serialize start/pause operations and invalidate earlier requests with generation counters.
- Android uses high accuracy, zero distance filter, requested 15-second interval, persistent foreground-service notification, and wake lock.
- Apple settings request background location, disable automatic pauses, and show the location indicator.
- Queue coordinate writes; verify UID and generation, and transactionally confirm the stall is still open before updating coordinates, server timestamp, and sharing flag.
- This prevents a location update from reopening a stall closed on another screen/device.
- Pause cancels the position stream, finishes queued writes, and best-effort persists sharing inactive.
- Errors update the Dashboard; customers independently show old locations as stale.
- **Boundary:** no automatic restart of sharing after process death/cold start is implemented. The vendor can use Resume sharing. A stale timestamp does not automatically set `isOpen` false, despite one older source comment suggesting closure.

### 2.9 Local storage, caching, offline, errors, and validation

- SharedPreferences keys implement guest search history, guest saved pins, old same-device bookings, and old per-vendor same-device self-collect enablement.
- Registered profile/search/pins/follows/bookings/notifications live in Firebase, with snapshot streams for current data.
- No explicit Firestore offline-cache policy, custom persistent vendor/menu cache, connectivity monitor, offline indicator, guaranteed offline booking queue, or offline sync-conflict UI is implemented. Any default Firebase SDK cache behavior is not a custom app feature verified here.
- Existing vendor details can remain visible after stream failure, with a stale-data warning; many other screens show an error/retry or empty state.
- Guest pin storage and old local booking flows can operate from device preferences; map tiles/place lookup still depend on their providers.
- Error logging uses Dart `debugPrint` / stack traces and Node console logs. No Crashlytics, Sentry, Analytics, or remote application error dashboard SDK is integrated.
- Input-validation functions cover required names, password length/confirmation, email patterns, Malaysian phone normalization, menu-price format, price-range ordering, rating/text/photo bounds, valid coordinates/IDs, schedule endpoints, closure ordering, booking ownership/roles, quantity/item caps, trusted menu prices, and payment eligibility/signature/metadata.
- Feedback includes inline field validation, account-error text, snackbars, confirmation dialogs, spinners/linear progress, disabled busy controls, selected states, and retry actions as detailed per screen.
- Error handling is not uniform: some profile fetches return null on any error, review/photo picking has fewer dedicated exception states, and not every screen guards all exits while saving.

### 2.10 External integrations and platform configuration

| Integration | Existing use | Boundary |
|---|---|---|
| Firebase Core | Startup and generated Android/iOS/macOS/web/Windows options. | Linux options explicitly throw unsupported. Generated options do not prove every platform is fully configured. |
| Firebase Authentication | Email/password, Google credential exchange, anonymous sessions, verification/reset/change-email links, reauthentication, deletion. | No MFA/SMS/biometrics. |
| Cloud Firestore | Profiles, vendors, menus, follows, dish follows, search/pins, reviews, bookings, notification history, private server payment metadata. | Deployment/rules/index readiness not remotely checked in this analysis. |
| Firebase Storage | Stall/menu/review photos, download URLs, overwrite and deletion cleanup. | No user-facing file-download/save-to-device workflow. |
| Firebase Cloud Functions / Scheduler | The 18 exports above; payment/account deletion/booking authority and notifications/cleanup. | Source/export presence is distinct from deployed operation. |
| Firebase Cloud Messaging + local notifications | Token registration, permission, foreground alert display, background/cold tap routing, booking/stall/dish links. | Local notification initialization/channel details are Android-specific; multi-device token registry is absent. |
| Google Sign-In | Google account picker, Firebase sign-in, Google reauthentication for deletion. | Client ID is fixed; web-specific sign-in path is not separately implemented. |
| Google Maps Flutter | Discovery map, live markers, location layer, camera operations, exact-pin map. | In-app directions/navigation are delegated externally. |
| Google Places SDK | Malaysian autocomplete and coordinate lookup. | Fixed source-configured API key and native configuration; failures fall back to device geocoding. |
| Geolocator | Customer GPS and vendor foreground/background location. | OS permission/service restrictions still apply. |
| Geocoding | Address lookup, reverse-geocoding, and fallback search. | Used with bounded timeouts and fallback labels. |
| URL Launcher | Google Maps/Waze/browser directions, phone dialer, Stripe checkout, pickup map. | No in-app web checkout, custom payment return deep link, or general file downloader. |
| Image Picker | Gallery single image and review multi-selection. | The camera icon does not mean camera capture is enabled; source is gallery. |
| Stripe Node SDK | Sandbox card Checkout, signature verification, session/payment/refund reconciliation. | Live keys deliberately rejected; no payout/Connect. |
| SharedPreferences | Guest preferences and retained legacy booking state. | Not a cloud-sync system for guests. |

**Platform detail:** Android manifest includes network, foreground/background location, foreground-service location, wake lock, and notification permissions; Maps metadata and navigation-app queries are configured. iOS includes background-location descriptions/mode and navigation-app queries, but the inspected AppDelegate does not register a Maps API key, Info.plist does not declare a photo-library usage description, and local notification initialization supplies Android settings only. Web/desktop directories and Firebase options exist, but native plugin use, `dart:io` image handling, web Maps/FCM setup, and platform-specific initialization are not completed as a unified supported flow. Treat iOS/web/desktop readiness as partial, not proven feature parity.

### 2.11 Retained legacy, dormant code, and developer-only capabilities

- `LocalDemoBookingService` retains device-only `isSelfCollectEnabled`, `setSelfCollectEnabled`, customer/vendor streams, `requestOrder`, `respond`, `advance`, `cancel`, `removeAccountData`, JSON load/save, and a broadcast change stream. It validates basic local actor/transition conditions but is not used for current customer/vendor booking screens. It remains called for deletion cleanup and used in tests.
- `functions/delete-account.cjs` is an older, smaller deletion implementation. The default functions entrypoint does not export it. The configured account-deletion codebase exports the broader `functions-account/index.js` implementation instead.
- `functions/index-addition.txt` and `functions/firestore-rules-snippet.txt` are reference snippets, not configured runtime entrypoints.
- `VendorService.getOpenVendors` is an available unused query helper; Home uses `getAllVendors` to support closed/future discovery.
- Change-email UI/service is implemented but unwired, as noted above.
- Stripe setup script can create a sandbox webhook, store its signing secret in Google Secret Manager, and roll back only its newly created endpoint if secret storage fails. Verification script checks deployed index/webhook/auth behavior, creates and expires a test Checkout, and avoids logging secrets. These are developer utilities, not in-app screens; they were **not executed** for this analysis.
- Repository includes Flutter tests, backend unit tests, Firebase emulator rules/booking/pin tests, and Android Appium login/navigation checks, plus test plans/runbooks. Test scaffolding is not an additional customer-facing feature.
- Fixed categories, Kuala Lumpur default map target, colors/assets, provider identifiers, FAQ/legal/about text, and prototype version label are bundled configuration/content. Installed but unused dependency declarations are not counted as app functions merely because a package appears in `pubspec.yaml`.

### 2.12 Persistent-data map

| Data path / storage location | Purpose and lifecycle |
|---|---|
| `users/{uid}` | Account identity/profile, role, chosen search origin, notification preference, single FCM token. |
| `users/{uid}/savedLocations/{id}` | Registered customer's Home/custom pins. |
| `users/{uid}/searchHistory/{queryId}` | Bounded query records with last-searched timestamp. |
| `users/{uid}/dishFollows/{vendorId:itemId}` | Restock subscription, identity, original follow time. |
| `users/{uid}/notifications/{eventId}` | Server-authored stall/dish inbox; unread and optional push-delivery state. |
| `vendors/{uid}` | Stall descriptive profile, weekly schedule/closures, operational open/location/sharing state, self-collect setting. |
| `vendors/{uid}/menu/{itemId}` | Dish name, price, section, image, qualitative availability, stock-change timestamp. |
| `follows/{customerId_vendorId}` | Stall-follow relationship and timestamp. |
| `stallReviews/{vendorId}/entries/{customerId}` | One review/customer/stall, rating/text/photo URLs/update time. |
| `bookings/{customerId_requestKey}` | Trusted item/price/pickup snapshots, participants, workflow/payment/refund/unseen metadata. |
| `bookingPayments/{bookingId}` | Server-only Stripe attempt, exact Checkout parameters, session/payment-intent/refund IDs. No client allow-rule. |
| `bookingNotificationEvents/{eventHash}` | Server-only paid-booking push deduplication marker. |
| `stall_images/{vendorId}.jpg` | Stable stall-photo overwrite path. |
| `menu_images/{vendorId}/{itemId}.jpg` | Stable dish-photo path; cleaned by menu-deletion trigger. |
| `review_images/{vendorId}/{customerId}/{imageId}.jpg` | Review photo objects; selective removal after edit and broader deletion cleanup. |
| `guest_search_history_v1` | Device preference for guest recent queries, merged on verified customer Home entry. |
| `guest_saved_locations_v1` | Device preference for guest pins; no account merge. |
| `self_collect_bookings_v1`, `self_collect_enabled_v1_{vendorId}` | Retained old device-only demo data, separate from live booking screens. |
| Legacy `stalls`, `reports`, `_connection_test_`, `_emailVerificationCodes` | Legacy rules/cleanup references; no active user-facing screens inferred from their names. |

---

## 3. Feature status table

The table consolidates capabilities described above; the detailed controls and conditions remain in Sections 1–2. Source links resolve to the exact current files. Static information pages are classified as Hardcoded/Mock for their content, while their navigation/search/expansion controls are implemented.

### 3.1 Startup, authentication, and account management

| Feature / Function Name | Module / Screen Location | Status | Primary File Path(s) |
|---|---|---|---|
| Firebase initialization and startup Retry | Startup | Fully Implemented | [main.dart][main] |
| Branded splash and automatic transition | Splash | Fully Implemented | [splash_screen.dart][splash] |
| Persisted Firebase session observation and role routing | Auth gate | Fully Implemented | [auth_wrapper.dart][authWrapper], [auth_service.dart][auth] |
| Account/profile recovery and inferred-role repair | Auth gate | Partially Implemented | [auth_wrapper.dart][authWrapper], [auth_service.dart][auth], [firestore.rules][firestoreRules] |
| Anonymous guest browsing entry/re-entry | Welcome | Fully Implemented | [welcome_screen.dart][welcome], [auth_wrapper.dart][authWrapper] |
| Registration close-to-guest path | Registration | Partially Implemented | [register_screen.dart][register], [auth_wrapper.dart][authWrapper] |
| Adaptive login sheet/dialog and dismissal | Welcome / Login | Fully Implemented | [login_screen.dart][login] |
| Email/password login | Login | Fully Implemented | [login_screen.dart][login], [auth_service.dart][auth] |
| Login validation, autofill, keyboard submit, password eye | Login | Fully Implemented | [login_screen.dart][login] |
| Google login/new-customer profile/cancellation/timeout | Welcome / Login | Fully Implemented | [auth_service.dart][auth], [welcome_screen.dart][welcome], [login_screen.dart][login] |
| Customer/vendor registration, phone requirement, confirmation | Registration | Fully Implemented | [register_screen.dart][register], [auth_service.dart][auth], [vendor_phone.dart][phone] |
| Registration identity/profile atomicity | Registration | Partially Implemented | [auth_service.dart][auth] |
| Password-reset links, generic result, resend/change-email entry | Forgot password | Fully Implemented | [forgot_password_screen.dart][forgot], [auth_service.dart][auth] |
| Email verification, 60-second resend, resume/token refresh | Verification | Fully Implemented | [email_verification_screen.dart][verification], [auth_service.dart][auth] |
| Verified-account gate before customer/vendor app | Auth gate | Fully Implemented | [auth_wrapper.dart][authWrapper] |
| Change-email form/link/recheck implementation | Unwired email-change screen | Partially Implemented | [change_email_screen.dart][changeEmail], [auth_service.dart][auth] |
| Name editing and Firebase display-name synchronization | Edit Profile | Fully Implemented | [edit_profile_screen.dart][editProfile], [auth_service.dart][auth] |
| Personal information, selectable details, provider labels | My Profile | Fully Implemented | [personal_information_screen.dart][personalInfo] |
| Current-password reauthentication and password replacement | Change password | Fully Implemented | [change_password_screen.dart][changePassword], [auth_service.dart][auth] |
| Independent password eyes, validation, reset shortcut | Change password | Fully Implemented | [change_password_screen.dart][changePassword] |
| Account avatar display/fallback | Profiles | Fully Implemented | [profile_page.dart][profilePage], [profile_header.dart][profileHeader] |
| Delete confirmation, password/Google reauthentication, server call | Delete account | Fully Implemented | [delete_account_screen.dart][deleteAccountScreen], [auth_service.dart][auth], [functions-account/index.js][accountBackend] |
| Complete account/payment lifecycle erasure and reconciliation | Account deletion backend | Partially Implemented | [functions-account/index.js][accountBackend], [stripe-payment-service.cjs][stripeService] |
| Logout/leave-guest confirmation, token/location cleanup | Shared Logout | Fully Implemented | [logout_helper.dart][logout], [auth_service.dart][auth] |

### 3.2 Discovery, location, and saved places

| Feature / Function Name | Module / Screen Location | Status | Primary File Path(s) |
|---|---|---|---|
| Four-tab customer navigation and retained tab state | Customer shell | Fully Implemented | [customer_home_screen.dart][home], [app_pill_navigation.dart][pill] |
| Greeting, first-name display, location header, bell shortcut | Home | Fully Implemented | [customer_home_screen.dart][home] |
| Live Google map and public vendor markers | Home | Fully Implemented | [customer_home_screen.dart][home], [vendor_service.dart][vendorService] |
| Kuala Lumpur default map target and bundled map style | Home | Hardcoded/Mock | [customer_home_screen.dart][home] |
| Marker selection, info-window navigation, focused-card scroll | Home | Fully Implemented | [customer_home_screen.dart][home] |
| Compass reset and GPS recenter | Home | Fully Implemented | [customer_home_screen.dart][home] |
| GPS permission, timeout, error banner/manual fallback | Home / Settings | Fully Implemented | [customer_home_screen.dart][home], [customer_profile_screen.dart][customerProfile] |
| Restore/save registered customer's chosen origin | Home | Fully Implemented | [customer_home_screen.dart][home], [auth_service.dart][auth] |
| Prevent stale GPS selection overwrites | Home | Fully Implemented | [customer_home_screen.dart][home] |
| Location source chooser | Home | Fully Implemented | [customer_home_screen.dart][home] |
| Malaysian Places autocomplete and coordinates | Manual location dialog | Fully Implemented | [manual_location_dialog.dart][manualLocation], [place_search_service.dart][places] |
| Debounce, stale-result guards, selected-address confirmation | Manual location dialog | Fully Implemented | [manual_location_dialog.dart][manualLocation] |
| Device geocoding fallback, retry Google, coordinate label fallback | Manual location dialog | Fully Implemented | [manual_location_dialog.dart][manualLocation] |
| Exact pin placement and optional address search | Pin location | Fully Implemented | [pin_location_screen.dart][pin] |
| Single Home pin create/select/edit/remove | Saved places | Fully Implemented | [saved_locations_sheet.dart][savedSheet], [saved_location_service.dart][savedService] |
| Named custom pins create/select/edit/remove | Saved places | Fully Implemented | [saved_locations_sheet.dart][savedSheet], [saved_location_service.dart][savedService] |
| Guest-local vs registered-customer cloud saved pins | Saved places | Fully Implemented | [saved_location_service.dart][savedService] |
| Precise-coordinate and Home/schema validation | Saved places | Fully Implemented | [saved_location.dart][savedModel], [firestore.rules][firestoreRules] |
| Live dish/stall/category substring search | Home | Fully Implemented | [customer_home_screen.dart][home], [dish_search_service.dart][dishSearch] |
| Clear search and category tune shortcut | Home | Fully Implemented | [customer_home_screen.dart][home] |
| Ranked/deduplicated suggestions and select-to-search | Home | Fully Implemented | [discovery_search_filters.dart][filters], [customer_home_screen.dart][home] |
| Recent queries, single remove, clear all, local/cloud storage | Home search | Fully Implemented | [search_history_service.dart][searchHistory], [customer_home_screen.dart][home] |
| Retry-safe guest-history merge into verified account | Home search | Fully Implemented | [search_history_service.dart][searchHistory] |
| Open/Closed/All status selection | Home filters | Fully Implemented | [customer_home_screen.dart][home] |
| Category selection logic | Home filters | Fully Implemented | [customer_home_screen.dart][home] |
| Nine-category catalogue | Discovery / Edit stall | Hardcoded/Mock | [stall_categories.dart][categories] |
| 5/10/25/50 km radius and nearest sorting | Home filters/results | Fully Implemented | [customer_home_screen.dart][home] |
| Minimum/maximum RM filter, reset, clear, validation | Price sheet / chip | Fully Implemented | [price_range_picker.dart][pricePicker], [discovery_search_filters.dart][filters] |
| Matching-dish price qualification and unknown-price exclusion | Home search | Fully Implemented | [discovery_search_filters.dart][filters], [dish_search_service.dart][dishSearch] |
| Tonight/morning/custom visit-time filtering | Opening-time sheet | Fully Implemented | [open_at_picker.dart][openAt], [stall_schedule.dart][schedule] |
| Overnight hours and closure subtraction for future visits | Schedule logic | Fully Implemented | [stall_schedule.dart][schedule] |
| Map-bounds selection and Search this area | Home | Fully Implemented | [customer_home_screen.dart][home] |
| Auto-focus stall near map center | Home | Fully Implemented | [map_marker_focus.dart][markerFocus], [customer_home_screen.dart][home] |
| Stall cards: selection, double tap, details arrow | Home results | Fully Implemented | [customer_home_screen.dart][home] |
| Dish result cards, distance, price, availability | Home results | Fully Implemented | [customer_home_screen.dart][home] |
| Expanded stall list and select-to-focus | Home results sheet | Fully Implemented | [customer_home_screen.dart][home] |
| Expanded dish list and select-to-open | Home results sheet | Fully Implemented | [customer_home_screen.dart][home] |
| Responsive map side panel/phone carousel | Home | Fully Implemented | [customer_home_screen.dart][home] |
| Loading, empty, error, Retry, freshness indicators | Home | Fully Implemented | [customer_home_screen.dart][home], [vendor_model.dart][vendorModel] |
| “Expand area” empty-state action wording | Home | Partially Implemented | [customer_home_screen.dart][home] |

### 3.3 Stall details, following, reviews, and notifications

| Feature / Function Name | Module / Screen Location | Status | Primary File Path(s) |
|---|---|---|---|
| Live stall identity/status/hours/closure/freshness | Stall details | Fully Implemented | [vendor_details_screen.dart][details], [vendor_model.dart][vendorModel] |
| Manual refresh/deleted stall/stale-details warning | Stall details | Fully Implemented | [vendor_details_screen.dart][details] |
| Optimistic stall follow/unfollow and rollback | Stall details | Fully Implemented | [vendor_details_screen.dart][details], [follow_service.dart][followService] |
| Guest account-required dialogs | Stall details actions | Fully Implemented | [vendor_details_screen.dart][details] |
| Business-phone tap-to-call | Stall details | Fully Implemented | [vendor_details_screen.dart][details] |
| Google Maps/Waze/browser navigation chooser | Directions sheet | Fully Implemented | [vendor_details_screen.dart][details] |
| Eligible self-collect entry and guest sign-in prompt | Stall details | Fully Implemented | [vendor_details_screen.dart][details] |
| Phone/tablet detail layouts | Stall details | Fully Implemented | [vendor_details_screen.dart][details] |
| Live sectioned menu, stock labels/time, image fallback | Stall menu | Fully Implemented | [vendor_details_screen.dart][details], [menu_service.dart][menuService] |
| In-stall dish search, clear field, focused dish/show all | Stall menu | Fully Implemented | [vendor_details_screen.dart][details] |
| Verified-customer dish follow/unfollow | Stall menu | Fully Implemented | [dish_follow_service.dart][dishFollowService], [vendor_details_screen.dart][details] |
| Review list, count, mean stars, image thumbnails | Stall reviews | Fully Implemented | [vendor_details_screen.dart][details], [stall_review_service.dart][reviews] |
| One review/customer/stall create/edit | Review editor | Fully Implemented | [vendor_details_screen.dart][details], [stall_review_service.dart][reviews] |
| Star selection and 1,000-character optional text | Review editor | Fully Implemented | [vendor_details_screen.dart][details] |
| Up to five review photos, remove, upload, cleanup | Review editor / Storage | Fully Implemented | [storage_service.dart][storage], [vendor_details_screen.dart][details] |
| Followed stalls, live open/closed grouping | Following → Stalls | Fully Implemented | [customer_following_screen.dart][following] |
| All/Open now, A–Z/Z–A, refresh/pull-to-refresh | Following → Stalls | Fully Implemented | [customer_following_screen.dart][following] |
| Followed dishes, latest-follow sort, current availability | Following → Dishes | Fully Implemented | [followed_dishes_list.dart][followedDishes] |
| Direct dish unfollow and focused-stall link | Following → Dishes | Fully Implemented | [followed_dishes_list.dart][followedDishes] |
| Server-created stall-opening inbox history | Notifications backend | Fully Implemented | [notification-history.cjs][historyBackend], [history-core.cjs][historyCore] |
| Stall-opening phone push robust delivery/preferences | Notifications backend | Partially Implemented | [functions/index.js][functionsIndex] |
| Dish-restock trigger/history/push outbox | Notifications backend | Fully Implemented | [dish-notifications.cjs][dishBackend], [dish-notifications-core.cjs][dishCore] |
| Token deduplication/batching/invalid cleanup for dish pushes | Notifications backend | Fully Implemented | [dish-notifications-core.cjs][dishCore] |
| Notifications All/Unread, card navigation, read highlights | Notifications | Fully Implemented | [customer_notifications_screen.dart][notificationScreen] |
| Mark shown as read in safe-sized batches | Notifications | Fully Implemented | [notification_history_service.dart][historyService] |
| Swipe/remove with failure rollback | Notifications | Fully Implemented | [customer_notifications_screen.dart][notificationScreen] |
| Load 50 then increment by 50 | Notifications | Fully Implemented | [customer_notifications_screen.dart][notificationScreen], [notification_history_service.dart][historyService] |
| History unread badges and error-code-specific Retry | Customer shell / Notifications | Fully Implemented | [customer_home_screen.dart][home], [customer_notifications_screen.dart][notificationScreen] |
| Android foreground/local/background/cold tap routing | Notification system | Fully Implemented | [notification_service.dart][notifications] |
| Pending notification routing across account gate | Notification system | Fully Implemented | [notification_service.dart][notifications], [auth_wrapper.dart][authWrapper] |
| Notification preference/device permission/resume refresh | Notification settings | Fully Implemented | [notification_settings_screen.dart][notificationSettings], [notification_service.dart][notifications] |
| Per-user token rotation and current-token cleanup | Notification system | Fully Implemented | [notification_service.dart][notifications] |
| Multi-device push delivery | Notification system | Partially Implemented | [notification_service.dart][notifications] |

### 3.4 Vendor management

| Feature / Function Name | Module / Screen Location | Status | Primary File Path(s) |
|---|---|---|---|
| Dashboard/Settings navigation and booking attention badge | Vendor shell | Fully Implemented | [vendor_main_screen.dart][vendorMain] |
| Stall listener/loading/error/retry/pull refresh | Dashboard | Fully Implemented | [vendor_dashboard_screen.dart][dashboard] |
| Open/close switch, prerequisites, explicit location consent | Dashboard | Fully Implemented | [vendor_dashboard_screen.dart][dashboard] |
| GPS opening with manual fixed-location fallback | Dashboard | Fully Implemented | [vendor_dashboard_screen.dart][dashboard], [manual_location_dialog.dart][manualLocation] |
| Android continuous location foreground service | Dashboard / Background | Fully Implemented | [vendor_location_service.dart][vendorLocation] |
| Serialized location writes and do-not-reopen transaction | Background | Fully Implemented | [vendor_location_service.dart][vendorLocation] |
| Sharing status/error/resume/close cleanup | Dashboard | Fully Implemented | [vendor_dashboard_screen.dart][dashboard], [vendor_location_service.dart][vendorLocation] |
| Automatic sharing recovery after killed process | Vendor background lifecycle | Partially Implemented | [vendor_location_service.dart][vendorLocation], [vendor_dashboard_screen.dart][dashboard] |
| Self-collect enable/disable | Dashboard | Fully Implemented | [vendor_dashboard_screen.dart][dashboard], [vendor_service.dart][vendorService] |
| Live booking preview and current/past bookings links | Dashboard | Fully Implemented | [live_booking_section.dart][liveBookings], [vendor_dashboard_screen.dart][dashboard] |
| All new-booking attention counts consistent in preview/shell | Dashboard preview | Partially Implemented | [live_booking_section.dart][liveBookings], [demo_order_service.dart][orderService] |
| Stall profile name/description/category/business phone | Edit stall | Fully Implemented | [edit_stall_screen.dart][editStall], [vendor_service.dart][vendorService] |
| Stall cover pick/preview/overwrite upload | Edit stall | Fully Implemented | [edit_stall_screen.dart][editStall], [storage_service.dart][storage] |
| Profile save preserves operational stall fields | Edit stall | Fully Implemented | [vendor_model.dart][vendorModel], [vendor_service.dart][vendorService] |
| Seven-day switches and up to three serving intervals/day | Weekly schedule | Fully Implemented | [stall_schedule_editor.dart][scheduleEditor] |
| Time pickers, overnight intervals, remove interval | Weekly schedule | Fully Implemented | [stall_schedule_editor.dart][scheduleEditor], [stall_schedule.dart][schedule] |
| Temporary closures add/remove/order/max 20 | Stall schedule | Fully Implemented | [stall_schedule_editor.dart][scheduleEditor] |
| Scheduled persisted closure every five minutes | Schedule backend | Fully Implemented | [functions-schedule/index.js][scheduleBackend], [closure-core.cjs][closureCore] |
| Menu item live read/create/update/delete | Menu & stock | Fully Implemented | [vendor_menu_screen.dart][vendorMenu], [menu_service.dart][menuService] |
| Available/Low stock/Sold out and timestamp | Menu & stock | Fully Implemented | [vendor_menu_screen.dart][vendorMenu], [menu_service.dart][menuService] |
| Add/edit modal, stable ID, validation, retained edits/retry | Dish editor | Fully Implemented | [vendor_menu_screen.dart][vendorMenu] |
| Dish gallery selection/preview/stable image overwrite | Dish editor | Fully Implemented | [storage_service.dart][storage], [vendor_menu_screen.dart][vendorMenu] |
| Delete confirmation and automatic image/subscription cleanup | Menu / Backend | Fully Implemented | [vendor_menu_screen.dart][vendorMenu], [functions/index.js][functionsIndex], [dish-notifications.cjs][dishBackend] |
| Vendor Settings phone/profile/current-area lookup | Vendor Settings | Fully Implemented | [vendor_profile_screen.dart][vendorProfile], [profile_page.dart][profilePage] |

### 3.5 Bookings, payment, and sales

| Feature / Function Name | Module / Screen Location | Status | Primary File Path(s) |
|---|---|---|---|
| Live-menu single-vendor cart | Cart | Fully Implemented | [demo_order_cart_screen.dart][cart] |
| Quantity +/−, 0–20 bounds, sold-out exclusion | Cart | Fully Implemented | [demo_order_cart_screen.dart][cart] |
| Integer-cent total/item count and RM2 minimum | Cart / Backend | Fully Implemented | [demo_order_cart_screen.dart][cart], [bookings.cjs][bookings] |
| Verified-customer/eligible-vendor server validation | Booking creation | Fully Implemented | [bookings.cjs][bookings], [booking-core.cjs][bookingCore] |
| Trusted menu snapshots, distinct item caps, request-key idempotency | Booking creation | Fully Implemented | [bookings.cjs][bookings], [booking-core.cjs][bookingCore] |
| Shared cross-account Firestore bookings | Customer / Vendor | Fully Implemented | [demo_order_service.dart][orderService], [bookings.cjs][bookings] |
| Checkout-first creation and vendor visibility after payment | Cart / Vendor bookings | Fully Implemented | [bookings.cjs][bookings], [demo_order_service.dart][orderService], [stripe-payment-service.cjs][stripeService] |
| Active/History tabs and summary-card navigation | My/Stall bookings | Fully Implemented | [demo_orders_screen.dart][orders], [booking_detail_screen.dart][bookingDetails] |
| Progress timeline, items, totals, timestamp, pickup map | Booking details | Fully Implemented | [booking_detail_screen.dart][bookingDetails] |
| Earlier request accept/reject and response expiry | Legacy shared booking lifecycle | Fully Implemented | [booking_detail_screen.dart][bookingDetails], [booking-core.cjs][bookingCore], [bookings.cjs][bookings] |
| Paid preparation, ready, collected state transitions | Vendor booking details | Fully Implemented | [booking_detail_screen.dart][bookingDetails], [booking-core.cjs][bookingCore] |
| Participant cancellation confirmation | Booking details | Fully Implemented | [booking_detail_screen.dart][bookingDetails], [bookings.cjs][bookings] |
| Participant unread flags/mark viewed/badges | Bookings | Fully Implemented | [demo_order_service.dart][orderService], [bookings.cjs][bookings] |
| Paid-booking vendor push and ready/cancellation/status pushes | Booking notification backend | Partially Implemented | [bookings.cjs][bookings] |
| Legacy request expiry scheduler | Booking backend | Fully Implemented | [bookings.cjs][bookings] |
| Stripe card Checkout and MYR payment as a financial capability | Test checkout | Hardcoded/Mock | [stripe-payments.cjs][stripeEndpoints], [stripe-payment-service.cjs][stripeService] |
| Test-only key enforcement and participant payment authorization | Payment backend | Fully Implemented | [stripe-payment-core.cjs][stripeCore], [stripe-payments.cjs][stripeEndpoints] |
| Persisted checkout attempt and session idempotency/recovery | Payment backend | Fully Implemented | [stripe-payment-service.cjs][stripeService] |
| Webhook signature/mode/amount/currency/metadata verification | Payment backend | Fully Implemented | [stripe-payments.cjs][stripeEndpoints], [stripe-payment-core.cjs][stripeCore] |
| Payment reconciliation, stale-event protection, race handling | Payment backend | Fully Implemented | [stripe-payment-service.cjs][stripeService], [stripe-payment-core.cjs][stripeCore] |
| Ten-minute payment window/countdown and minute expiry job | Payment | Fully Implemented | [booking_payment_card.dart][paymentCard], [stripe-payments.cjs][stripeEndpoints] |
| Payment state/reference/refunded amount and test instructions | Booking payment card | Fully Implemented | [booking_payment_card.dart][paymentCard] |
| External checkout launch/retry/progress/resume recheck | Booking details | Fully Implemented | [booking_detail_screen.dart][bookingDetails], [demo_order_service.dart][orderService] |
| Static payment-return instructions | Stripe return HTML | Hardcoded/Mock | [stripe-payments.cjs][stripeEndpoints] |
| Full test refund on cancellation and dashboard refund reflection | Payment / Refunds | Hardcoded/Mock | [stripe-payment-service.cjs][stripeService] |
| Pending/failed/partial/full refund display | Booking payment card | Fully Implemented | [booking_payment_card.dart][paymentCard] |
| Today/total net simulated sales and paid count | Vendor Dashboard | Hardcoded/Mock | [vendor_demo_sales.dart][sales], [demo_order.dart][orderModel] |
| Test transaction history with booking links | Vendor payment history | Fully Implemented | [vendor_demo_sales.dart][sales] |
| Retained device-only booking CRUD/lifecycle | Legacy service, not current UI | Hardcoded/Mock | [local_demo_booking_service.dart][localBookings] |

### 3.6 Shared content, system infrastructure, and developer utilities

| Feature / Function Name | Module / Screen Location | Status | Primary File Path(s) |
|---|---|---|---|
| Customer/vendor Settings actions and guest visibility | Settings | Fully Implemented | [profile_page.dart][profilePage], [customer_profile_screen.dart][customerProfile], [vendor_profile_screen.dart][vendorProfile] |
| Role-specific FAQ content | Help & FAQ | Hardcoded/Mock | [faq_screen.dart][faq] |
| FAQ search/clear/expand/collapse | Help & FAQ | Fully Implemented | [faq_screen.dart][faq] |
| About/version/prototype description | About | Hardcoded/Mock | [about_screen.dart][about] |
| Privacy/Terms content and last-updated date | Legal pages | Hardcoded/Mock | [legal_screen.dart][legal] |
| Dropdown selection/disabled states, grouped cards, navigation | Shared widgets | Fully Implemented | [app_dropdown.dart][dropdown], [ios_grouped.dart][grouped], [app_pill_navigation.dart][pill] |
| Shared progress/error/back guards and basic accessibility | Shared account/payment UI | Fully Implemented | [account_ui.dart][accountUI], [booking_detail_screen.dart][bookingDetails] |
| Bundled light theme/assets/design defaults | App theme | Hardcoded/Mock | [app_theme.dart][theme] |
| Guest history/pins local persistence | Local storage | Fully Implemented | [search_history_service.dart][searchHistory], [saved_location_service.dart][savedService] |
| Custom application-wide offline handling | System resilience | Partially Implemented | [vendor_details_screen.dart][details], [saved_location_service.dart][savedService], [main.dart][main] |
| Console error logging and user feedback | Shared services / Backend | Fully Implemented | [auth_service.dart][auth], [notification_service.dart][notifications], [bookings.cjs][bookings] |
| Firestore participant/owner/role rules with broader legacy access | Data security | Partially Implemented | [firestore.rules][firestoreRules] |
| Storage owner paths/review limits with stall/menu validation gaps | Media security | Partially Implemented | [storage.rules][storageRules] |
| Three function codebases, rules/indexes and SPA hosting config | Deployment configuration | Fully Implemented | [firebase.json][firebaseConfig], [firestore.indexes.json][indexes] |
| Android location/notification/Maps/navigation declarations | Android configuration | Fully Implemented | [AndroidManifest.xml][androidManifest] |
| iOS location support and wider app integration | iOS configuration | Partially Implemented | [Info.plist][iosInfo], [AppDelegate.swift][iosDelegate], [notification_service.dart][notifications] |
| Web/macOS/Windows scaffolding and Firebase options | Platform support | Partially Implemented | [firebase_options.dart][firebaseOptions], [index.html][webIndex], [storage_service.dart][storage] |
| Old nonexported deletion implementation | Dormant backend source | Partially Implemented | [delete-account.cjs][oldDelete] |
| Sandbox webhook/secret setup utility | Developer tools | Fully Implemented | [configure-stripe-sandbox.cjs][stripeSetup] |
| Deployed sandbox/index/webhook smoke verification utility | Developer tools | Fully Implemented | [verify-stripe-sandbox.cjs][stripeVerify] |
| Flutter UI/model and backend unit tests | Verification code | Fully Implemented | [payment_ui_test.dart][paymentTests], [customer_discovery_search_test.dart][searchTests], [stripe-payments.test.cjs][stripeTests] |
| Emulator security/booking/pin tests and Android automation | Verification code | Fully Implemented | [rules.test.cjs][rulesTests], [bookings.test.cjs][bookingRulesTests], [login-validation.cjs][appiumLogin] |

## 4. Important boundaries when describing current progress

These are distinctions needed to avoid overstating features represented by partial or legacy code:

1. **Current bookings are live shared records; payment is sandbox.** Do not describe the current app as only a same-device booking demo, and do not describe it as charging real customers.
2. **Current new flow is pay-first.** Legacy accept/reject support remains, but new checkout-first orders reach vendor-facing lists after payment.
3. **Stock is qualitative.** Available/Low stock/Sold out does not imply counted stock, reservations, automatic deductions, or oversell protection.
4. **Planned hours, current open state, and location freshness differ.** Weekly hours power planned visits; the vendor switch controls current service, temporary closures override it, and stale coordinates are labelled rather than automatically closing a stall.
5. **Email change exists only in source.** Profile's email is currently read-only.
6. **Account deletion has meaningful cleanup but an incomplete financial-data lifecycle.** Stripe objects/private payment records are not comprehensively reconciled or purged by its implementation.
7. **No full offline mode is established.** Guest local preferences and a stale-detail fallback are narrower capabilities.
8. **No feature parity across all generated Flutter platforms is established.** Android has the strongest integration evidence; Linux is explicitly unsupported in generated Firebase options.
9. **Push and in-app data have different delivery guarantees.** Dish history is durable with retry state; the older stall sender and booking push paths are simpler. Booking updates are not entries in the stall/dish inbox.
10. **Content can describe intentions beyond enforcement.** Bundled FAQs/legal text/comments are not proof of active controls or backend behavior.

Features with no active implementation found include delivery dispatch/tracking, customer-vendor chat, numeric inventory, coupons/promotions, real-money payments/payouts, downloadable invoices, admin/moderation dashboards, review deletion/replies, avatar upload, camera capture, dark mode, language switching, social sharing, and an explicit report-stall UI. A legacy collection/rule/package name alone was not counted as one of these features.

## 5. Validation and confidence

- Read the current Dart application modules and the configured backend implementations, rules, indexes, and relevant platform files directly.
- Confirmed 82 Dart source files under `lib`; referenced the working tree at HEAD `2721f1c`.
- Ran backend unit tests for bookings, notification history, dish notifications, Stripe payments, and scheduled closures: **34 passed, 0 failed**.
- These tests cover transition/actor constraints, menu-price trust, payment gating, retry/idempotency, expiry/cancellation races, test refunds, notification eligibility/deduplication/delivery retries, and closure batching.
- Flutter analysis was attempted but did not complete. A direct Dart analyzer attempt also failed because its telemetry file outside the workspace could not be updated (`Access is denied`). No clean Flutter/Dart analysis result is claimed.
- Firebase emulator tests, Android Appium tests, real-device flows, deployment inspection, live Google/Firebase integrations, and remote Stripe smoke scripts were not run for this inventory.
- No application source or deployed service was changed. This report is an analysis artifact.

## Source references

All file links below point to the current local workspace. Backend codebase paths matter: the current account deletion is in `functions-account`, and scheduled stall closure is in `functions-schedule`.

[about]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/about_screen.dart>
[accountBackend]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions-account/index.js>
[accountUI]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/account_ui.dart>
[androidManifest]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/android/app/src/main/AndroidManifest.xml>
[appiumLogin]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/appium-tests/login-validation.cjs>
[auth]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/auth_service.dart>
[authWrapper]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/auth/auth_wrapper.dart>
[bookingCore]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/booking-core.cjs>
[bookingDetails]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/booking_detail_screen.dart>
[bookingRulesTests]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/firebase-tests/bookings.test.cjs>
[bookings]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/bookings.cjs>
[cart]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/orders/demo_order_cart_screen.dart>
[categories]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/constants/stall_categories.dart>
[changeEmail]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/auth/screens/change_email_screen.dart>
[changePassword]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/change_password_screen.dart>
[closureCore]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions-schedule/closure-core.cjs>
[customerProfile]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/profile/customer_profile_screen.dart>
[dashboard]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/dashboard/vendor_dashboard_screen.dart>
[deleteAccountScreen]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/delete_account_screen.dart>
[details]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/vendor_details/vendor_details_screen.dart>
[dishBackend]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/dish-notifications.cjs>
[dishCore]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/dish-notifications-core.cjs>
[dishFollowService]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/dish_follow_service.dart>
[dishSearch]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/dish_search_service.dart>
[dropdown]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/widgets/app_dropdown.dart>
[editProfile]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/edit_profile_screen.dart>
[editStall]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/profile/edit_stall_screen.dart>
[faq]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/faq_screen.dart>
[filters]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/home/discovery_search_filters.dart>
[firebaseConfig]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/firebase.json>
[firebaseOptions]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/firebase_options.dart>
[firestoreRules]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/firestore.rules>
[followedDishes]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/following/followed_dishes_list.dart>
[following]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/following/customer_following_screen.dart>
[followService]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/follow_service.dart>
[forgot]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/auth/screens/forgot_password_screen.dart>
[functionsIndex]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/index.js>
[grouped]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/widgets/ios_grouped.dart>
[historyBackend]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/notification-history.cjs>
[historyCore]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/history-core.cjs>
[historyService]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/notification_history_service.dart>
[home]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/home/customer_home_screen.dart>
[indexes]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/firestore.indexes.json>
[infoPage]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/info_page.dart>
[iosDelegate]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/ios/Runner/AppDelegate.swift>
[iosInfo]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/ios/Runner/Info.plist>
[legal]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/legal_screen.dart>
[liveBookings]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/live_booking_section.dart>
[localBookings]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/local_demo_booking_service.dart>
[login]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/auth/screens/login_screen.dart>
[logout]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/logout_helper.dart>
[main]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/main.dart>
[manualLocation]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/manual_location_dialog.dart>
[markerFocus]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/home/map_marker_focus.dart>
[menuService]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/menu_service.dart>
[notifications]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/notification_service.dart>
[notificationScreen]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/notifications/customer_notifications_screen.dart>
[notificationSettings]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/notification_settings_screen.dart>
[oldDelete]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/delete-account.cjs>
[openAt]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/home/open_at_picker.dart>
[orderModel]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/models/demo_order.dart>
[orders]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/demo_orders_screen.dart>
[orderService]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/demo_order_service.dart>
[paymentCard]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/booking_payment_card.dart>
[paymentTests]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/test/payment_ui_test.dart>
[personalInfo]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/personal_information_screen.dart>
[phone]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/utils/vendor_phone.dart>
[pill]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/widgets/app_pill_navigation.dart>
[pin]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/pin_location_screen.dart>
[places]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/place_search_service.dart>
[pricePicker]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/home/price_range_picker.dart>
[profileHeader]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/profile_header.dart>
[profilePage]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/profile_page.dart>
[register]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/auth/screens/register_screen.dart>
[reviews]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/stall_review_service.dart>
[rulesTests]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/firebase-tests/rules.test.cjs>
[sales]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/dashboard/vendor_demo_sales.dart>
[savedModel]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/models/saved_location.dart>
[savedService]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/saved_location_service.dart>
[savedSheet]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/saved_locations_sheet.dart>
[schedule]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/models/stall_schedule.dart>
[scheduleBackend]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions-schedule/index.js>
[scheduleEditor]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/profile/stall_schedule_editor.dart>
[searchHistory]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/search_history_service.dart>
[searchTests]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/test/customer_discovery_search_test.dart>
[splash]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/splash/splash_screen.dart>
[storage]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/storage_service.dart>
[storageRules]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/storage.rules>
[stripeCore]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/stripe-payment-core.cjs>
[stripeEndpoints]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/stripe-payments.cjs>
[stripeService]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/stripe-payment-service.cjs>
[stripeSetup]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/scripts/configure-stripe-sandbox.cjs>
[stripeTests]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/stripe-payments.test.cjs>
[stripeVerify]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/scripts/verify-stripe-sandbox.cjs>
[theme]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/theme/app_theme.dart>
[vendorLocation]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/vendor_location_service.dart>
[vendorMain]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/vendor_main_screen.dart>
[vendorMenu]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/menu/vendor_menu_screen.dart>
[vendorModel]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/models/vendor_model.dart>
[vendorProfile]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/profile/vendor_profile_screen.dart>
[vendorService]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/vendor_service.dart>
[verification]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/auth/screens/email_verification_screen.dart>
[webIndex]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/web/index.html>
[welcome]: <C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/auth/screens/welcome_screen.dart>

