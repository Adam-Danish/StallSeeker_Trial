# StallSeeker Cloud Functions

The default Functions codebase handles stall notifications, followed-dish
restock alerts and image/subscription cleanup.

`notifyFollowersOnDishAvailable` runs only when a menu item's stock changes
from `out_of_stock` to `available` or `low_stock`. Customers subscribe under
`users/{uid}/dishFollows/{vendorId}:{itemId}`. The event ID gives each inbox alert
a stable ID; its server-owned `pushState` keeps pending pushes eligible for
retry while confirmed successes and permanently invalid tokens are skipped.
An FCM success followed by a failed state write can still cause a retry push,
since Firestore and FCM do not share a transaction.

Phone alerts respect `notificationsEnabled`. Inbox history remains available
with phone alerts disabled. FCM requests contain at most 500 unique tokens,
and invalid registration tokens are removed only if they are still the user's
current token. Deleting a dish removes its subscriptions; deleting a vendor
account also removes subscriptions from customer accounts.

Local delivery regression tests: `node --test functions/*test.cjs`.

Email verification and verified email changes use Firebase Authentication's
built-in action emails directly from the Flutter app. They do not require SMTP,
custom email functions, or verification-code secrets.

Configure the sender name and message in Firebase Console under
Authentication > Templates. The app requires the signed `email_verified` claim
before protected vendor, menu, review, follow, and image writes.
