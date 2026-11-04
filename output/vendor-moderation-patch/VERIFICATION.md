# Verification — 4 November 2026

All implementation and build checks used isolated working copies. The original app/admin source files were not patched and no production deployment was made.

## Passed

- Both unified diffs pass `git apply --check` against their respective original working files and clean throwaway copies.
- Flutter analysis: no issues.
- Flutter production web build: passed.
- Flutter Android debug APK build: passed.
- Focused Flutter warning, responsive dashboard, and profile tests: 22 passed. Warning cards/correction dialogs were checked at 360px and 1200px with larger text.
- Node functions/account-cleanup tests: 42 passed, one existing account-deletion emulator test skipped without its optional auth-emulator setup.
- Firebase rules and integration tests: 47 passed using local Firestore/Storage emulators, including six moderation workflow integration scenarios and three moderation rules scenarios.
- Admin production build: passed.
- Admin TypeScript check: passed with overrides for the existing compiler configuration.
- Browser demo: customer report submission and Pending history; the new report appearing live in admin; admin sign-in; verification of the third report; warning creation with a 48-hour deadline; vendor correction submission; correction appearing live in admin; admin approval; vendor case changing to Resolved. Real callable-function and Firestore emulators were used, with disposable demo accounts.

## Existing failures

The complete Flutter suite produced **195 passing tests and six failing discovery/map tests**. Running the same discovery test file against the unchanged baseline reproduced all six failures:

- Keeping the real stall profile stationary while scrolling, at 390px and 1280px: a delayed marker-focus camera command was not cancelled.
- Keeping the GPS layer enabled during manual search: a map styling expectation did not match.
- Viewport cards/marker focus.
- Clearing discovery filters at 320px and 960px: the expected stall card was absent.

These tests and their map behavior are outside the moderation patch. The unchanged baseline reproduced the failures, and the patch introduces no additional failures in the full run.

## Limits

- No physical Android device test was performed; the APK compiled successfully and shared Flutter layouts were tested.
- Live FCM delivery, closed-app Android notification taps, and production browser push were not exercised. Their routing code is included; the persistent warning/history remains available without push delivery.
- No production rules, indexes, functions, hosting, account, listing, or report data were changed.
- The local browser preview used emulator wiring excluded from the patches. Existing admin dashboard services unrelated to moderation were not emulated; their demo-only status errors are not moderation failures.
- The admin compiler's existing `ignoreDeprecations` and TSX-import settings require the documented type-check overrides. The production admin build passes without configuration changes.
