# StallSeeker Feature Checklist

Reviewed: 28 October 2026 (Asia/Kuala_Lumpur). Current HEAD: `848f359`. Includes the current working tree.

## How to use

- Change `- [ ]` to `- [x]` when you finish an item; reverse it if more work remains. You can ask Codex to update specific IDs.
- Initially checked means an active implementation was found in source. It does not mean deployed, device-tested or production-ready.
- **Partial** stays unchecked: read the remaining-work note before ticking. **Not found** means no implementation was identified in this review, not proof that none exists anywhere.
- Section 17 is your manual verification checklist; every item starts unchecked. Existing test files are evidence of coverage, not a claim that tests passed today.
- The original 15 groups preserve every task in the pasted backlog. Section 16 expands your later requests and overlaps some earlier tasks; totals count rows, not unique features or release readiness.
- This file is a permanent editable project record. Inline chat checkbox changes do not automatically edit this file.

## Snapshot

Partial: 59 · Implemented: 16 · Not found: 108 · Verify manually: 12 · Total rows: 195

Recent confirmed additions include search aliases/sorting, list view, marker clustering, saved searches, availability filters, vendor replies and stall previews. Your map-first / second-tap dish-card behaviour remains outstanding.

## Evidence and limits

Compared the pasted backlog with the 24 October inventory, commits since `2721f1c`, and current source/rules/tests. No app code, user changes, remote services or deployment were modified. No Flutter, emulator or device tests were run for this checklist. Recent uncommitted menu-screen changes were included in the reading and preserved.

## 1. Customer discovery and search

- [ ] **01-01 · Result sorting** — Partial. nearest, lowest price, highest rating, and shortest preparation time.
  - Distance, price, rating, newest and recently updated sorting exist. Preparation-time sorting is still missing.
  - Evidence: [customer_home_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/home/customer_home_screen.dart>), [discovery_options.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/home/discovery_options.dart>), [discovery_options_test.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/test/discovery_options_test.dart>).
- [x] **01-02 · Search tolerance** — Implemented. handle misspellings, abbreviations, and alternative dish names.
  - Search normalises Malaysian aliases and abbreviations and tolerates limited spelling errors and transpositions.
  - Evidence: [discovery_options.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/home/discovery_options.dart>), [discovery_options_test.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/test/discovery_options_test.dart>).
- [x] **01-03 · Dish navigation** — Implemented. open the exact dish selected from Home search.
  - Home passes the selected dish ID into stall details, where that dish is focused and revealed. Your later map-first interaction is tracked separately below.
  - Evidence: [customer_home_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/home/customer_home_screen.dart>), [vendor_details_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/vendor_details/vendor_details_screen.dart>).
- [ ] **01-04 · Map consistency** — Partial. apply the same geographic boundaries to stall and dish results.
  - Radius filtering exists, but viewport bounds still narrow stall cards without equally narrowing dish cards.
  - Evidence: [customer_home_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/home/customer_home_screen.dart>).
- [ ] **01-05 · Empty results** — Partial. provide working actions to expand the radius, clear filters, or search another area.
  - Empty-result guidance exists. A dedicated Expand area action and a complete clear-filters recovery flow are still missing.
  - Evidence: [customer_home_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/home/customer_home_screen.dart>).
- [x] **01-06 · List-only discovery** — Implemented. let customers browse without interacting with the map.
  - Map/List view toggle and list-only results are connected to the same discovery controls.
  - Evidence: [customer_home_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/home/customer_home_screen.dart>).
- [ ] **01-07 · Dietary filters** — Not found. vegetarian, vegan, allergens, and other vendor-declared attributes.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **01-08 · Halal information** — Not found. clearly distinguish vendor declarations from independently verified certification.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [x] **01-09 · Availability filters** — Implemented. available dishes only, self-collect enabled, and recently updated stalls.
  - Available only, self-collect only and recently updated filters are wired into discovery.
  - Evidence: [customer_home_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/home/customer_home_screen.dart>), [discovery_options.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/home/discovery_options.dart>).
- [x] **01-10 · Saved searches** — Implemented. store combinations such as “burgers under RM10 within 5 km.”
  - Verified customers can save, load, apply and remove named filter combinations, including location and view mode. Ownership rules and regression tests exist.
  - Evidence: [customer_home_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/home/customer_home_screen.dart>), [saved_search_service.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/saved_search_service.dart>), [saved-searches.test.cjs](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/firebase-tests/saved-searches.test.cjs>), [saved_search_access_test.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/test/saved_search_access_test.dart>).
- [ ] **01-11 · Recommendations** — Not found. suggest stalls based on follows, previous orders, and explicit preferences.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **01-12 · Discovery collections** — Not found. breakfast, late-night food, budget meals, and newly added stalls.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.

## 2. Maps, locations, and travelling stalls

- [x] **02-01 · Marker clustering** — Implemented. group nearby markers in crowded areas.
  - Stall markers use a cluster manager. Cluster taps zoom in; the selected stall stays individually visible.
  - Evidence: [customer_home_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/home/customer_home_screen.dart>).
- [ ] **02-02 · Status clarity** — Partial. clearly separate “open now,” “scheduled to open,” and “last known location.”
  - Open/closed, scheduled search and last-known location labels exist. Review the combined wording so planned opening and confirmed live status remain unambiguous.
  - Evidence: [customer_home_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/home/customer_home_screen.dart>), [vendor_details_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/vendor_details/vendor_details_screen.dart>), [vendor_model.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/models/vendor_model.dart>).
- [ ] **02-03 · Stale-location handling** — Partial. warn customers and request vendor confirmation when coordinates become old.
  - Customers see stale/last-known location labels. Vendor reconfirmation prompts and a stronger stale-session policy are missing.
  - Evidence: [customer_home_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/home/customer_home_screen.dart>), [vendor_details_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/vendor_details/vendor_details_screen.dart>), [vendor_location_service.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/vendor_location_service.dart>).
- [ ] **02-04 · Battery use** — Partial. adapt vendor location-update frequency to movement and operating state.
  - Location sharing stops when paused/closed. Active Android sharing still requests high accuracy every 15 seconds rather than adapting to movement.
  - Evidence: [vendor_location_service.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/vendor_location_service.dart>).
- [ ] **02-05 · Guest saved places** — Not found. offer to merge guest pins into the account after sign-in.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **02-06 · Travel-time estimates** — Not found. show estimated journey time alongside straight-line distance.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **02-07 · Pickup landmarks** — Not found. entrance notes, parking information, and a stall-location photo.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **02-08 · Recurring selling locations** — Not found. support vendors who trade at different markets on different days.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **02-09 · Location-change alerts** — Not found. notify interested customers when a followed stall moves.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **02-10 · Location correction reports** — Not found. let customers report an inaccurate pin.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.

## 3. Stall pages and customer decision-making

- [ ] **03-01 · Photo viewing** — Partial. support full-screen images, zoom, and a stall gallery.
  - Review photos have a full-screen viewer and zoom. A stall-photo gallery and equivalent dish-photo browsing are still missing.
  - Evidence: [stall_review_card.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/stall_review_card.dart>), [vendor_details_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/vendor_details/vendor_details_screen.dart>).
- [ ] **03-02 · Menu presentation** — Partial. show descriptions, portion sizes, ingredients, and clearly grouped sections.
  - Menu sections exist. Dish descriptions, portion sizes and ingredients are not implemented.
  - Evidence: [vendor_details_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/vendor_details/vendor_details_screen.dart>), [vendor_menu_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/menu/vendor_menu_screen.dart>), [menu_item_model.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/models/menu_item_model.dart>).
- [ ] **03-03 · Availability explanations** — Partial. distinguish sold out, temporarily unavailable, and outside serving hours.
  - Available/low-stock/sold-out labels and stall closures exist. Per-dish temporary unavailability and serving-hour explanations are missing.
  - Evidence: [vendor_details_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/vendor_details/vendor_details_screen.dart>), [menu_item_model.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/models/menu_item_model.dart>).
- [ ] **03-04 · Popular dishes** — Not found. highlight frequently ordered items.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **03-05 · Stall announcements** — Not found. display notices such as “closing early today.”
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **03-06 · Stall and dish sharing** — Not found. share links that open the relevant content.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **03-07 · Comparison** — Not found. compare a few stalls by distance, price range, rating, and availability.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **03-08 · Accessibility and facilities** — Not found. seating, wheelchair access, parking, and accepted payment methods.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.

## 4. Menu and stock management

- [ ] **04-01 · Numeric inventory** — Not found. track actual remaining quantities.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **04-02 · Stock reservations** — Not found. temporarily reserve quantities during checkout.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **04-03 · Automatic deductions** — Not found. deduct inventory at a clearly defined point in the booking lifecycle.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **04-04 · Overselling protection** — Not found. make simultaneous purchases compete safely for the same stock.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **04-05 · Stock restoration** — Not found. release reservations after failed payment, expiry, or eligible cancellation.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **04-06 · Dish variants** — Not found. size, flavour, spice level, and other options.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **04-07 · Paid add-ons** — Not found. extra cheese, toppings, or additional portions.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **04-08 · Serving schedules** — Not found. breakfast-only dishes, weekend specials, and seasonal items.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **04-09 · Bulk updates** — Not found. mark several dishes available or sold out together.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **04-10 · Menu organisation** — Partial. reorder dishes and manage sections separately.
  - Items have a section field, but there is no standalone section management or manual dish reordering.
  - Evidence: [vendor_menu_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/menu/vendor_menu_screen.dart>).
- [ ] **04-11 · Photo controls** — Partial. remove, crop, replace, and capture photos with the camera.
  - Gallery selection and image replacement exist. Removing a menu photo, cropping and camera capture are missing.
  - Evidence: [vendor_menu_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/menu/vendor_menu_screen.dart>), [storage_service.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/storage_service.dart>).
- [ ] **04-12 · Stock tools** — Partial. low-stock alerts, restock history, daily resets, and temporary item hiding.
  - Manual low-stock labels and restock subscriptions exist. Numeric low-stock thresholds, restock logs, daily resets and item hiding are missing.
  - Evidence: [vendor_menu_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/menu/vendor_menu_screen.dart>), [dish-notifications.cjs](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/dish-notifications.cjs>).

## 5. Cart and checkout

- [ ] **05-01 · Persistent cart** — Not found. retain selections after leaving the screen or restarting the app.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **05-02 · Changed-item handling** — Partial. explain price or stock changes before asking customers to confirm again.
  - Live stock affects the cart and the server re-reads trusted prices. A clear before/after change summary with explicit reconfirmation is missing.
  - Evidence: [demo_order_cart_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/orders/demo_order_cart_screen.dart>), [bookings.cjs](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/bookings.cjs>).
- [ ] **05-03 · Duplicate prevention** — Partial. recover an interrupted submission without accidentally creating another booking.
  - Server request keys and checkout attempts are idempotent. Separate fresh UI submissions can still create separate bookings; interruption recovery needs strengthening.
  - Evidence: [demo_order_service.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/demo_order_service.dart>), [bookings.cjs](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/bookings.cjs>), [stripe-payment-service.cjs](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/stripe-payment-service.cjs>).
- [ ] **05-04 · Special instructions** — Not found. support requests such as “less spicy,” subject to vendor acceptance.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **05-05 · Pickup-time selection** — Not found. offer immediate collection or an available future slot.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **05-06 · Preparation estimate** — Not found. show the likely waiting time before payment.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **05-07 · Order review** — Partial. clearly summarise items, options, pickup location, and cancellation conditions.
  - Cart and booking details show items and totals. A complete pre-payment review covering options, pickup and cancellation conditions remains to be added.
  - Evidence: [demo_order_cart_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/orders/demo_order_cart_screen.dart>), [booking_detail_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/booking_detail_screen.dart>).
- [ ] **05-08 · Reorder** — Not found. recreate a previous order using current prices and availability.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **05-09 · Multiple saved carts** — Not found. retain separate carts for different stalls.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **05-10 · Fee breakdown** — Not found. display discounts, service fees, and other applicable charges if introduced.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.

## 6. Bookings and pickup coordination

- [ ] **06-01 · Status timeline** — Partial. show timestamps and the next expected action.
  - Booking progress and status are visible. A fully timestamped event history and clear next-action guidance are incomplete.
  - Evidence: [booking_detail_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/booking_detail_screen.dart>), [demo_order.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/models/demo_order.dart>).
- [x] **06-02 · Booking badges** — Implemented. use consistent attention counts in the vendor dashboard, preview, and navigation.
  - Current vendor dashboard actions/previews and vendor navigation use the broader vendor-attention predicate. The old shared preview vendor branch remains in source but is not used by the vendor dashboard.
  - Evidence: [vendor_dashboard_view.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/dashboard/vendor_dashboard_view.dart>), [vendor_main_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/vendor_main_screen.dart>), [demo_order.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/models/demo_order.dart>).
- [ ] **06-03 · Dedicated booking access** — Partial. make active orders easier to reach from customer navigation.
  - Customer Settings includes live bookings and My Bookings. A prominent shortcut from Home/customer navigation is still missing.
  - Evidence: [customer_profile_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/profile/customer_profile_screen.dart>), [customer_home_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/home/customer_home_screen.dart>).
- [ ] **06-04 · Pickup code or QR** — Not found. verify that the correct customer collects the order.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **06-05 · Customer arrival** — Not found. provide “I’m here” or “On my way” actions.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **06-06 · Queue position** — Not found. show an approximate position or expected ready time.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **06-07 · Delay updates** — Not found. let vendors revise preparation estimates and notify customers.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **06-08 · Cancellation reasons** — Not found. collect structured reasons from both parties.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **06-09 · Cancellation rules** — Partial. define behaviour before preparation, during preparation, and after readiness.
  - Server actor/status checks, cancellation and sandbox refunds exist. Stage-specific customer policy and explicit terms still need product decisions.
  - Evidence: [booking-core.cjs](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/booking-core.cjs>), [bookings.cjs](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/bookings.cjs>), [booking_detail_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/booking_detail_screen.dart>).
- [ ] **06-10 · Uncollected-order handling** — Not found. reminders, collection deadlines, and a defined resolution.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **06-11 · Order issue reporting** — Not found. missing items, incorrect items, or pickup disputes.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **06-12 · Booking history** — Partial. search and filter by date, stall, status, and payment state.
  - Active/History lists exist. Search and date/stall/status/payment filters are missing.
  - Evidence: [demo_orders_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/demo_orders_screen.dart>).

## 7. Vendor operations and scheduling

- [ ] **07-01 · Setup checklist** — Partial. guide vendors through stall details, location, hours, menu, and self-collect.
  - Dashboard setup prompts and validation exist. A complete persisted onboarding checklist is missing.
  - Evidence: [vendor_dashboard_view.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/dashboard/vendor_dashboard_view.dart>).
- [x] **07-02 · Customer preview** — Implemented. show vendors how their stall appears publicly.
  - Vendors can preview the public stall page from Dashboard and preview unsaved profile/photo changes from Edit stall.
  - Evidence: [edit_stall_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/profile/edit_stall_screen.dart>), [vendor_dashboard_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/dashboard/vendor_dashboard_screen.dart>), [vendor_details_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/vendor_details/vendor_details_screen.dart>), [edit_stall_view_test.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/test/edit_stall_view_test.dart>).
- [ ] **07-03 · Busy mode** — Partial. pause new bookings while completing existing orders.
  - Vendors can disable self-collect without closing the stall. A clearly named busy mode with preparation/capacity behaviour is missing.
  - Evidence: [vendor_dashboard_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/dashboard/vendor_dashboard_screen.dart>).
- [ ] **07-04 · Capacity limits** — Not found. restrict bookings per time slot or active preparation queue.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **07-05 · Preparation settings** — Not found. configure normal preparation time and extra delay during busy periods.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **07-06 · Weekly hours** — Partial. detect overlapping intervals and offer “copy to other days.”
  - Weekly intervals and overnight hours exist. Overlap detection and Copy to other days are missing.
  - Evidence: [stall_schedule_editor.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/profile/stall_schedule_editor.dart>).
- [ ] **07-07 · Temporary closures** — Partial. edit existing closures directly and use reusable holiday schedules.
  - Closures can be added and removed. Direct editing and reusable holiday schedules are missing.
  - Evidence: [stall_schedule_editor.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/profile/stall_schedule_editor.dart>).
- [ ] **07-08 · Closing reminders** — Not found. prompt vendors when their planned closing time arrives.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **07-09 · Session confirmation** — Not found. periodically ask vendors to confirm that the stall is still operating.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **07-10 · Staff access** — Not found. separate owner and staff permissions.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **07-11 · Multiple stalls** — Not found. support owners managing several locations.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **07-12 · Optional automatic opening/closing** — Partial. require explicit vendor configuration and handle location validity.
  - Scheduled temporary breaks can close stalls. Configurable automatic opening and reopening with location checks are missing.
  - Evidence: [index.js](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions-schedule/index.js>).

## 8. Payments, refunds, and financial records

- [ ] **08-01 · Checkout return** — Partial. reopen the relevant booking automatically after external checkout.
  - Returning to the app triggers reconciliation, but the hosted return page does not automatically deep-link back to the booking.
  - Evidence: [booking_detail_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/booking_detail_screen.dart>), [stripe-payments.cjs](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/stripe-payments.cjs>).
- [ ] **08-02 · Refund communication** — Partial. explain refund progress and provide a support path when it fails.
  - Pending/failed/full/partial refund states are displayed. Dedicated support and customer resolution flows are missing.
  - Evidence: [booking_payment_card.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/booking_payment_card.dart>).
- [ ] **08-03 · Refund management** — Not found. give authorised administrators tools to inspect and retry failed refunds.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **08-04 · Partial-refund requests** — Partial. support individual unavailable or incorrect items.
  - Backend recognises externally issued partial refunds. Customer/vendor requests for item-level refunds are missing.
  - Evidence: [stripe-payment-service.cjs](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/stripe-payment-service.cjs>).
- [ ] **08-05 · Receipts** — Not found. provide downloadable and shareable payment receipts.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **08-06 · Reconciliation** — Partial. identify mismatches between booking, payment, refund, and settlement records.
  - Stripe payment/refund reconciliation exists for sandbox bookings. Cross-record settlement reporting and an operational mismatch queue are missing.
  - Evidence: [stripe-payment-service.cjs](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/stripe-payment-service.cjs>).
- [ ] **08-07 · Account deletion lifecycle** — Partial. resolve active payments and preserve or remove financial records according to a defined retention policy.
  - Account deletion cleans much app data but does not comprehensively resolve active payments or reconcile private payment/notification-marker records.
  - Evidence: [index.js](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions-account/index.js>).
- [ ] **08-08 · Real-money payments** — Not found. develop a separate production payment flow.
  - Backend still creates test-mode bookings and enforces sandbox keys/events. Recent wording changes do not establish real-money payment support.
  - Evidence: [bookings.cjs](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/bookings.cjs>), [stripe-payments.cjs](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/stripe-payments.cjs>), [stripe-payment-core.cjs](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/stripe-payment-core.cjs>).
- [ ] **08-09 · Vendor onboarding and payouts** — Not found. establish how vendors receive their earnings.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **08-10 · Financial reporting** — Partial. show gross sales, refunds, fees, net earnings, and payout status.
  - Vendor sales totals and payment history are calculated from sandbox records. Fees, actual payouts, settlement and complete financial reports are missing.
  - Evidence: [vendor_demo_sales.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/dashboard/vendor_demo_sales.dart>).
- [ ] **08-11 · Additional payment methods** — Not found. evaluate locally relevant options against provider and marketplace support.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.

## 9. Notifications and following

- [ ] **09-01 · Multiple devices** — Not found. register separate notification tokens for each signed-in device.
  - The account still stores one fcmToken, so a later device can replace the earlier device registration.
  - Evidence: [notification_service.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/notification_service.dart>).
- [ ] **09-02 · Delivery reliability** — Partial. extend durable retry and deduplication behaviour to stall-opening and booking notifications.
  - Dish notifications have durable delivery state. Stall-opening and booking pushes still have weaker retry/delivery handling.
  - Evidence: [dish-notifications.cjs](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/dish-notifications.cjs>), [index.js](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/index.js>), [bookings.cjs](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/bookings.cjs>).
- [ ] **09-03 · Preference enforcement** — Partial. apply notification preferences consistently across all senders.
  - Dish/booking senders respect the account switch. The older stall-opening sender needs equivalent preference handling.
  - Evidence: [index.js](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/index.js>), [dish-notifications.cjs](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/dish-notifications.cjs>), [bookings.cjs](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/bookings.cjs>).
- [ ] **09-04 · Unified inbox** — Partial. include booking, payment, and refund events alongside stall and dish alerts.
  - Stall and dish history is durable. Booking, payment, refund and review events are not unified into that inbox.
  - Evidence: [customer_notifications_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/notifications/customer_notifications_screen.dart>), [index.js](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/index.js>).
- [ ] **09-05 · Notification categories** — Not found. independently control stall openings, restocks, orders, and promotions.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **09-06 · Quiet hours** — Not found. let customers mute discovery alerts during chosen times.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **09-07 · Sound and vibration controls** — Not found. provide the controls implied by the current settings label.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **09-08 · System-settings shortcut** — Not found. open phone notification settings when permission is blocked.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **09-09 · Following controls** — Partial. unfollow directly from stall rows and sort dishes by availability or distance.
  - Dish rows allow unfollowing. Direct stall-row unfollow and availability/distance sorting for follows are missing.
  - Evidence: [customer_following_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/following/customer_following_screen.dart>), [followed_dishes_list.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/following/followed_dishes_list.dart>).
- [ ] **09-10 · Per-stall preferences** — Not found. follow a stall while choosing which updates to receive.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **09-11 · Alert management** — Partial. clear selected notifications, undo deletion, and optionally group repeated events.
  - Individual deletion and marking loaded alerts read exist. Multi-select deletion, undo and grouping remain missing.
  - Evidence: [customer_notifications_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/notifications/customer_notifications_screen.dart>).

## 10. Reviews, trust, and community

- [x] **10-01 · Delete own review** — Implemented. let customers remove their review and associated photos.
  - Customers can confirm deletion of their own review. Associated photo deletion is best effort; the embedded owner reply disappears with the review.
  - Evidence: [vendor_details_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/vendor_details/vendor_details_screen.dart>), [stall_review_service.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/stall_review_service.dart>), [firestore.rules](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/firestore.rules>).
- [x] **10-02 · Vendor replies** — Implemented. allow one clearly identified vendor response.
  - Official owner reply can be posted, edited and deleted; it appears publicly with a Stall owner label. Ownership and field restrictions exist.
  - Evidence: [stall_review_service.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/stall_review_service.dart>), [vendor_reviews_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/reviews/vendor_reviews_screen.dart>), [stall_review_card.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/stall_review_card.dart>), [firestore.rules](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/firestore.rules>), [review-replies.test.cjs](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/firebase-tests/review-replies.test.cjs>).
- [ ] **10-03 · Verified-purchase indicator** — Not found. distinguish reviews associated with completed bookings.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **10-04 · Review browsing** — Partial. filter by rating, photos, and verified purchases.
  - Vendor review list filters unanswered/replied/updated and star rating, with date/rating sorting. Customer photo/verified-purchase filters are missing.
  - Evidence: [vendor_reviews_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/reviews/vendor_reviews_screen.dart>), [vendor_review_filters.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/reviews/vendor_review_filters.dart>), [vendor_details_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/vendor_details/vendor_details_screen.dart>).
- [ ] **10-05 · Helpful votes** — Not found. let customers identify useful reviews.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **10-06 · Review reports** — Not found. report abusive, misleading, or irrelevant content.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **10-07 · Stall reports** — Not found. report duplicate listings, incorrect details, or suspected impersonation.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **10-08 · Vendor verification** — Not found. provide a documented verification process and meaningful badge.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **10-09 · Review reminders** — Not found. invite feedback after collection without repeatedly prompting.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **10-10 · Community suggestions** — Not found. suggest missing stalls or corrections for review.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.

## 11. Accounts and onboarding

- [ ] **11-01 · Change email** — Partial. connect the existing screen to Settings and complete its recovery flow.
  - Change-email screen/service exist, but Edit Profile still keeps email read-only and provides no entry point.
  - Evidence: [change_email_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/auth/screens/change_email_screen.dart>), [edit_profile_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/edit_profile_screen.dart>).
- [ ] **11-02 · Password consistency** — Not found. handle whitespace consistently across registration, login, and password changes.
  - Login/signup still trim submitted passwords while change-password preserves deliberate spaces.
  - Evidence: [auth_service.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/auth_service.dart>).
- [ ] **11-03 · Registration recovery** — Partial. recover cleanly when authentication succeeds but profile creation fails.
  - Profile repair attempts exist, but auth identity creation and Firestore profile creation are separate and lack complete failure recovery.
  - Evidence: [auth_service.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/auth_service.dart>).
- [ ] **11-04 · Guest navigation** — Partial. make the registration-to-guest route behave consistently.
  - Guest entry exists. The registration close path still needs confirmation against the Welcome callback/routing behaviour.
  - Evidence: [register_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/auth/screens/register_screen.dart>), [auth_wrapper.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/auth/auth_wrapper.dart>).
- [ ] **11-05 · Profile recovery** — Partial. resolve malformed roles through an authorised recovery mechanism.
  - Profile repair infers roles, but immutable-role rules can prevent recovery of an already stored malformed role.
  - Evidence: [auth_service.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/auth_service.dart>), [firestore.rules](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/firestore.rules>).
- [ ] **11-06 · Avatar management** — Not found. upload, replace, and remove a profile picture.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **11-07 · Account linking** — Not found. connect supported sign-in methods to one account.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **11-08 · Vendor role application** — Not found. let an existing customer apply to operate a stall.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **11-09 · Device/session management** — Not found. view active devices and revoke access.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **11-10 · Stronger account protection** — Not found. consider additional verification for owners and administrators.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **11-11 · Personalisation settings** — Not found. preferred language, food interests, budget, and accessibility preferences.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **11-12 · Short onboarding** — Not found. explain location, following, and self-collect at the point of use.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.

## 12. Administration and customer support

- [ ] **12-01 · Admin dashboard** — Not found. manage users, vendors, bookings, and reports.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **12-02 · Vendor approval** — Not found. review applications, verification evidence, and duplicate stalls.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **12-03 · Moderation queue** — Not found. review reported photos, reviews, descriptions, and listings.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **12-04 · Account restrictions** — Not found. suspend abusive accounts with recorded reasons and an appeal process.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **12-05 · Support tickets** — Not found. submit issues linked to the relevant booking or stall.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **12-06 · Dispute handling** — Not found. track evidence, decisions, refunds, and communication.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **12-07 · Audit history** — Not found. record sensitive administrative and financial actions.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **12-08 · Content management** — Not found. update FAQs, announcements, categories, and support information.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **12-09 · Contact support** — Partial. make the support address actionable and prefill useful issue details.
  - Support contact is bundled text. An actionable contact flow with booking context is missing.
  - Evidence: [legal_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/legal_screen.dart>), [faq_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/faq_screen.dart>).
- [ ] **12-10 · Operational alerts** — Not found. surface repeated payment failures, notification failures, and stalled bookings.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.

## 13. Accessibility, appearance, and platform support

- [ ] **13-01 · Bahasa Melayu and English** — Not found. localise screens, dates, messages, and notifications.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **13-02 · Dark mode** — Not found. support light, dark, and system appearance.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **13-03 · Accessibility** — Partial. screen-reader labels, large text, contrast, touch targets, and keyboard focus.
  - Some semantics, account live regions and adaptive layouts exist. A full screen-reader, large-text, keyboard and contrast verification pass is outstanding.
  - Evidence: [account_ui.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/account_ui.dart>), [stall_review_card.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/stall_review_card.dart>), [booking_detail_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/booking_detail_screen.dart>).
- [ ] **13-04 · Status indicators** — Partial. combine colour with readable text and icons.
  - Many status chips combine labels and icons. A complete app-wide check of colour-independent status communication is outstanding.
  - Evidence: [customer_home_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/home/customer_home_screen.dart>), [stall_review_card.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/stall_review_card.dart>), [booking_detail_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/booking_detail_screen.dart>).
- [ ] **13-05 · Loading and recovery** — Partial. use consistent loading, empty, offline, and retry states.
  - Many screens have error/retry/loading states, but offline behaviour and recovery are inconsistent across the app.
  - Evidence: [customer_home_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/home/customer_home_screen.dart>), [vendor_details_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/vendor_details/vendor_details_screen.dart>), [edit_stall_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/profile/edit_stall_screen.dart>).
- [ ] **13-06 · Editing protection** — Partial. prevent accidental loss of unsaved changes and handle photo-selection failures consistently.
  - Edit stall now warns about unsaved changes and handles gallery errors; reply editor preserves drafts. Consistent app-wide exit protection and photo handling still need checking.
  - Evidence: [edit_stall_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/profile/edit_stall_screen.dart>), [unsaved_stall_changes_guard.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/profile/unsaved_stall_changes_guard.dart>), [vendor_reply_editor.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/reviews/vendor_reply_editor.dart>).
- [ ] **13-07 · About information** — Not found. read the actual installed app version.
  - About still displays a hardcoded Version 1.0.3 string.
  - Evidence: [about_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/about_screen.dart>).
- [ ] **13-08 · Permissions** — Partial. explain location, notification, and photo access when needed.
  - Location-sharing and notification explanations exist. Complete contextual permission education and recovery across supported platforms remain to be checked.
  - Evidence: [notification_service.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/notification_service.dart>), [vendor_dashboard_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/dashboard/vendor_dashboard_screen.dart>).
- [ ] **13-09 · iOS integration** — Partial. complete Maps, photo permissions, notifications, and device validation.
  - iOS scaffold/background-location setup exists. Maps, photo permissions and local notification setup remain incomplete according to the baseline inventory.
  - Evidence: [Info.plist](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/ios/Runner/Info.plist>), [AppDelegate.swift](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/ios/Runner/AppDelegate.swift>), [notification_service.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/notification_service.dart>).
- [ ] **13-10 · Web support** — Partial. address platform-specific images, authentication, maps, and notifications.
  - Web scaffold/Firebase options exist. Maps, messaging, authentication and image handling still need a unified supported web flow.
  - Evidence: [index.html](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/web/index.html>), [firebase_options.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/firebase_options.dart>), [storage_service.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/storage_service.dart>).
- [ ] **13-11 · Tablet layouts** — Partial. verify cart, bookings, menu editing, and settings alongside discovery.
  - Home, dashboard, reviews and Edit stall now have adaptive layouts/test coverage. Full booking/cart/menu/settings device validation is outstanding.
  - Evidence: [customer_home_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/home/customer_home_screen.dart>), [vendor_dashboard_view.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/dashboard/vendor_dashboard_view.dart>), [edit_stall_view.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/profile/edit_stall_view.dart>), [edit_stall_view_test.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/test/edit_stall_view_test.dart>).

## 14. Reliability, security, and performance

- [ ] **14-01 · Legacy access rules** — Not found. remove or restrict broadly accessible legacy data paths.
  - Legacy reports, stalls and _connection_test_ rules still allow public reads/writes.
  - Evidence: [firestore.rules](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/firestore.rules>).
- [ ] **14-02 · Upload validation** — Partial. enforce appropriate image type and size limits across uploads.
  - Review images enforce image content type and size. Stall/menu uploads still need equivalent type/size controls.
  - Evidence: [storage.rules](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/storage.rules>).
- [ ] **14-03 · Profile privacy** — Partial. expose only the public information needed for discovery and ordering.
  - Private subcollections/payment paths have controls, but account-profile/public-data separation still needs tightening.
  - Evidence: [firestore.rules](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/firestore.rules>).
- [ ] **14-04 · Abuse protection** — Not found. apply app verification, rate limits, and limits on costly actions.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **14-05 · Nearby data loading** — Not found. query a relevant geographic area instead of streaming every vendor and menu.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **14-06 · Pagination** — Partial. load bookings, reviews, notifications, and payment history in bounded pages.
  - Notification limits and bounded backend batches exist. Bookings/reviews/payment lists and several discovery queries still load whole matching collections.
  - Evidence: [notification_history_service.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/notification_history_service.dart>), [stall_review_service.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/stall_review_service.dart>), [demo_order_service.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/demo_order_service.dart>).
- [ ] **14-07 · Summary calculations** — Partial. maintain scalable rating and sales summaries as data grows.
  - Rating/sales summaries are calculated, largely from client-loaded records. Scalable maintained aggregate records are missing.
  - Evidence: [dish_search_service.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/dish_search_service.dart>), [customer_home_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/home/customer_home_screen.dart>), [vendor_demo_sales.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/dashboard/vendor_demo_sales.dart>).
- [ ] **14-08 · Offline browsing** — Partial. cache previously loaded menus, follows, and booking details with freshness labels.
  - Local guest preferences and stale-detail fallback exist. No complete offline browsing experience is established.
  - Evidence: [vendor_details_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/vendor_details/vendor_details_screen.dart>), [saved_location_service.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/saved_location_service.dart>).
- [ ] **14-09 · Connection recovery** — Partial. clearly distinguish queued, saved, stale, and failed changes.
  - Retries, stale warnings and guarded writes exist, but queued/saved/offline feedback is not consistent across flows.
  - Evidence: [vendor_details_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/vendor_details/vendor_details_screen.dart>), [edit_stall_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/profile/edit_stall_screen.dart>), [vendor_reply_editor.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/reviews/vendor_reply_editor.dart>).
- [ ] **14-10 · Crash and error monitoring** — Not found. detect failures beyond console logs.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **14-11 · Performance and cost monitoring** — Not found. track slow screens, database usage, and background work.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **14-12 · Data cleanup** — Partial. remove orphaned images, expired operational records, and unnecessary history.
  - Account/menu deletion and several media/follow cleanup paths exist. Orphan cleanup and complete record retention/expiry management remain incomplete.
  - Evidence: [index.js](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/index.js>), [index.js](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions-account/index.js>).
- [ ] **14-13 · Backup and recovery** — Not found. define and test restoration procedures.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **14-14 · Release verification** — Partial. automate critical booking, payment, permissions, and security checks.
  - Flutter, backend, rules-emulator and Android automation tests exist. No current complete device/deployment/release pass is established.
  - Evidence: [vendor_reviews_test.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/test/vendor_reviews_test.dart>), [review-replies.test.cjs](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/firebase-tests/review-replies.test.cjs>), [stripe-payments.test.cjs](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/stripe-payments.test.cjs>), [test_login_validation.py](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/appium-tests/test_login_validation.py>).
- [ ] **14-15 · Maintenance** — Partial. retire unused booking implementations and clarify misleading demo names.
  - Several user-facing payment labels were polished, but DemoOrder names and the old device-only booking service remain.
  - Evidence: [local_demo_booking_service.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/local_demo_booking_service.dart>), [demo_order.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/models/demo_order.dart>).

## 15. Analytics, retention, and future expansion

- [ ] **15-01 · Vendor analytics** — Partial. sales trends, popular dishes, peak periods, average order value, and cancellations.
  - Basic sandbox sales totals and paid count exist. Popular-dish, peak-period, average-order-value and cancellation dashboards are missing.
  - Evidence: [vendor_demo_sales.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/dashboard/vendor_demo_sales.dart>).
- [ ] **15-02 · Inventory insights** — Not found. identify frequent sellouts and estimate waste.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **15-03 · Discovery analytics** — Not found. understand searches, empty results, and stall-page visits.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **15-04 · Checkout funnel** — Not found. measure where customers abandon cart creation, payment, or collection.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **15-05 · Promotions** — Not found. discount codes, bundles, happy-hour pricing, and limited offers.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **15-06 · Loyalty** — Not found. repeat-customer rewards or a digital stamp card.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **15-07 · Referral programme** — Not found. reward useful customer or vendor referrals.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **15-08 · Vendor announcements** — Not found. reach followers with frequency controls and opt-outs.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **15-09 · Order-linked messaging** — Not found. support customer/vendor clarification with reporting and moderation.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **15-10 · Market or event pages** — Not found. group stalls at pasar malam, food courts, and temporary events.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **15-11 · Group ordering** — Not found. coordinate several people’s items and collection.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **15-12 · Delivery** — Not found. introduce delivery zones, fees, dispatch, tracking, and delivery support as a substantial separate project.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.
- [ ] **15-13 · Business models** — Not found. evaluate vendor subscriptions or clearly labelled promoted listings.
  - No active implementation identified in the reviewed source. Leave unticked until implemented or manually confirmed.

## 16. Your requested map behaviour and vendor reviews

- [ ] **16-01 · First dish-card tap previews the map** — Not found. Search crispy chicken, tap its card once, centre the map on that stall and highlight the card and marker.
  - Current dish-card onTap opens stall details immediately. This requested change is still outstanding.
  - Evidence: [customer_home_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/home/customer_home_screen.dart>).
- [ ] **16-02 · Second tap opens the selected dish** — Not found. A later tap on the same selected dish card opens that dish in the stall menu; a fast double-tap may do the same once.
  - No selected-dish-card state or second-tap handler is wired into Home. Exact-dish page navigation already exists separately.
  - Evidence: [customer_home_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/home/customer_home_screen.dart>).
- [ ] **16-03 · Different dish means a new preview** — Not found. Selecting a different dish, including another dish from the same stall, requires its own first preview tap.
  - Track selected dish identity, not only selected vendor identity.
  - Evidence: [customer_home_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/home/customer_home_screen.dart>).
- [ ] **16-04 · Clear selection after map or search changes** — Not found. Clear the preview selection after manual map movement, new search, filter changes or a new search area.
  - Add this with the two-step dish-card interaction.
  - Evidence: [customer_home_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/home/customer_home_screen.dart>).
- [ ] **16-05 · Explain the second tap** — Not found. Highlight the selected card and show Tap again to view menu or an explicit View menu action.
  - Dish cards currently have no map-preview selected state.
  - Evidence: [customer_home_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/home/customer_home_screen.dart>).
- [x] **16-06 · Vendor review dashboard summary** — Implemented. Show average rating, total reviews, awaiting-reply count and View reviews.
  - Reviews dashboard card is connected to the current vendor dashboard.
  - Evidence: [vendor_reviews_dashboard_card.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/reviews/vendor_reviews_dashboard_card.dart>), [vendor_dashboard_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/dashboard/vendor_dashboard_screen.dart>).
- [x] **16-07 · Vendor review filters and sorting** — Implemented. Support All, Unanswered, Replied, Updated after reply, star filter, newest and rating sort.
  - Filters/sorts are implemented and covered by regression tests.
  - Evidence: [vendor_reviews_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/reviews/vendor_reviews_screen.dart>), [vendor_review_filters.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/reviews/vendor_review_filters.dart>), [vendor_reviews_test.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/test/vendor_reviews_test.dart>).
- [x] **16-08 · Reply validation and draft recovery** — Implemented. One official reply, 1,000-character limit, retry with draft preserved and discard warning.
  - Reply editor and transaction-backed save implement these behaviours.
  - Evidence: [vendor_reply_editor.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/reviews/vendor_reply_editor.dart>), [stall_review_service.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/stall_review_service.dart>), [vendor_reviews_test.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/test/vendor_reviews_test.dart>).
- [x] **16-09 · Edit and delete owner reply** — Implemented. Allow only the owner to edit/delete their reply and show edited labels.
  - Reply screen/service/rules implement owner-only management.
  - Evidence: [vendor_reviews_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/reviews/vendor_reviews_screen.dart>), [stall_review_service.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/stall_review_service.dart>), [firestore.rules](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/firestore.rules>).
- [x] **16-10 · Public reply display** — Implemented. Customers see Reply from [stall] and Stall owner beneath the original review.
  - Shared review card is used on stall details and vendor review screens.
  - Evidence: [stall_review_card.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/stall_review_card.dart>), [vendor_details_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/customer/vendor_details/vendor_details_screen.dart>).
- [x] **16-11 · Handle customer review edits** — Implemented. Retain the owner reply and show when the review changed after the answered version.
  - Saved reply records the answered version and updated-after-reply is filterable.
  - Evidence: [stall_review_service.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/stall_review_service.dart>), [stall_review.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/models/stall_review.dart>), [vendor_reviews_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/reviews/vendor_reviews_screen.dart>).
- [ ] **16-12 · Notify vendor of a new review** — Not found. Create an in-app event and optional push that opens the relevant review.
  - No new-review notification backend is exported.
  - Evidence: [index.js](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/index.js>), [notification_service.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/notification_service.dart>).
- [ ] **16-13 · Notify customer of first owner reply** — Not found. Create an in-app event/push once for the first reply, respect settings and deep-link to the review.
  - Reply writes have no corresponding notification trigger.
  - Evidence: [index.js](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/functions/index.js>), [stall_review_service.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/stall_review_service.dart>), [notification_service.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/core/services/notification_service.dart>).
- [ ] **16-14 · Review and reply reporting** — Not found. Allow vendors to report reviews and customers to report owner replies.
  - Reporting UI/moderation flow is not implemented.
  - Evidence: [vendor_reviews_screen.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/vendor/reviews/vendor_reviews_screen.dart>), [stall_review_card.dart](<C:/Others/SE/Flutter Projects/StallSeeker_Trial/lib/features/shared/stall_review_card.dart>).

## 17. Your hands-on verification

- [ ] **17-01 · Map clusters** — Verify manually. Zoom out in a dense area, tap a cluster, and confirm it zooms to its stalls.
  - Not executed during this checklist review. Tick only after you perform this check and record the result.
- [ ] **17-02 · Map and list view** — Verify manually. Switch views with filters active; confirm the same intended results and usable scrolling.
  - Not executed during this checklist review. Tick only after you perform this check and record the result.
- [ ] **17-03 · Search tolerance and sorting** — Verify manually. Try an alias/misspelling and switch price/rating/distance sorting.
  - Not executed during this checklist review. Tick only after you perform this check and record the result.
- [ ] **17-04 · Availability filters** — Verify manually. Check available-only, self-collect-only and recent-update filters against known test stalls.
  - Not executed during this checklist review. Tick only after you perform this check and record the result.
- [ ] **17-05 · Saved searches** — Verify manually. Save a combination, restart, load it, delete it, and confirm another account cannot access it.
  - Not executed during this checklist review. Tick only after you perform this check and record the result.
- [ ] **17-06 · Exact-dish navigation** — Verify manually. Open a dish result; confirm the correct stall/dish and Show all dishes behaviour.
  - Not executed during this checklist review. Tick only after you perform this check and record the result.
- [ ] **17-07 · Vendor review journey** — Verify manually. Post a customer review, open vendor Reviews, reply, edit and delete the reply, and check customer display.
  - Not executed during this checklist review. Tick only after you perform this check and record the result.
- [ ] **17-08 · Review ownership** — Verify manually. Confirm customers cannot modify owner replies and unrelated vendors cannot reply to this stall.
  - Not executed during this checklist review. Tick only after you perform this check and record the result.
- [ ] **17-09 · Review changes and deletion** — Verify manually. Edit a review after a reply; check the updated indicator. Delete the review and confirm the reply disappears.
  - Not executed during this checklist review. Tick only after you perform this check and record the result.
- [ ] **17-10 · Unsaved stall preview** — Verify manually. Change name/photo without saving, preview it, then test Keep editing, Discard and Save.
  - Not executed during this checklist review. Tick only after you perform this check and record the result.
- [ ] **17-11 · Booking badges** — Verify manually. Pay for a sandbox booking and verify the current vendor dashboard and navigation show consistent attention.
  - Not executed during this checklist review. Tick only after you perform this check and record the result.
- [ ] **17-12 · Release device checks** — Verify manually. Check phone/tablet layouts, large text, permission denial, offline recovery and background/resume flows.
  - Not executed during this checklist review. Tick only after you perform this check and record the result.

