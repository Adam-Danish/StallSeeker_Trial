# StallSeeker release APK — 4 October 2026

File: `StallSeeker-release.apk` (universal APK, version 1.0.0 / build 1).
Size: 63,431,000 bytes. SHA-256:
`445C2AF1084C6EB4C64B206332C75B304C595166B426898E7A2558B24F04EA62`.

The APK adds individual dish following with restock alerts, an inclusive RM
minimum/maximum price filter, ranked search suggestions, and Home/custom saved
map pins. The Settings screens use the supplied reference's pale background,
rounded grouped cards, line icons and spacing, with StallSeeker account actions.

Follow a dish from its stall menu; manage subscriptions in Following → Dishes.
Alerts are created when a sold-out dish becomes available or low stock again.
Saved Home/custom places are managed in Settings or Home → Set location. Guest
pins stay on-device; verified customer pins are private in the account.

Validation: 29 Flutter tests, 16 backend tests, and 15 Firestore/Storage rules
emulator tests passed. Static analysis of lib and test passed. APK signature
verification passed. This is a release-mode build signed with the project's
existing Android Debug certificate, suitable for sideload testing.

The user chose APK delivery only for now; Firebase deployment is postponed.
The live project needs
the new functions, indexes and permissions for dish subscriptions, alerts,
saved account pins, and global menu search used by price filters/suggestions.
Automatic approval review rejected the initial live deployment attempt because
production security rules/functions changes had not been explicitly approved.
No live Firebase changes were made.

Prepared deployment (only after approval):

```
firebase deploy --project stallseeker-c2ffe --only firestore:rules,firestore:indexes,functions:default:notifyFollowersOnDishAvailable,functions:default:cleanupDeletedDishFollows,functions:account-deletion:deleteAccount --non-interactive
```
