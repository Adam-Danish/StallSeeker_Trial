# Account deletion

## Production rollout — 3 November 2026

Published all four account-deletion services, Firestore/Storage rules and the
release web build to `https://stallseeker.my`. The Firestore rules retain the
production admin-directory permissions. Storage's dedicated Firestore lookup
permission was enabled for its service account.

Live checks verified customer and vendor self-deletion, profile-only admin
deletion and Auth-only deletion. Each check confirmed that the old login failed,
the email could be registered with a new UID, background cleanup finished and
the replacement account survived the old cleanup. All temporary test identities,
profiles, vendor records and admin-directory entries were removed.

All four functions reported ACTIVE. Both public Hosting domains served the exact
new release build; the admin domain remained reachable. The 20 combined-rule
tests passed, including preserved admin read access and denied client writes.
The release web build, source analyzer, deletion tests and browser-startup tests
also passed. This publishes the web app and shared backend; installed mobile apps
receive client changes through a separately distributed app build.

`deleteAccount` requires a signed-in user authenticated within ten minutes. It
creates a durable `_accountDeletions/{uid}` job, deletes the Firebase Auth identity
and removes the profile before returning `{deleted: true}`. The deleted email can
then be used for a new account with a new UID.

`cleanupDeletedAccount` retries related data and photo cleanup. Storage is cleaned
before review records are removed so retries retain the paths of customer photos.
Deletion jobs remain as UID tombstones; client rules prevent a stale token from
recreating the old account. Tombstones contain request/completion timestamps only.

`onAccountProfileDeleted` covers admin deletion of a `users/{uid}` profile.
`onAuthAccountDeleted` covers admin/Firebase Auth identity deletion, including
vendor deletion where the admin removed only the vendor document. Auth events use
the first-generation trigger supported by the installed Firebase Functions SDK.

## Verification

From the repository root:

```powershell
node --test functions-account/account-deletion.test.cjs
flutter test test/account_session_test.dart
firebase emulators:exec --config firebase.account-emulators.json --project demo-stallseeker-rules --only auth,firestore "node --test functions-account/deletion-emulator.test.cjs"
firebase emulators:exec --config firebase.review-emulators.json --project demo-stallseeker-rules --only firestore,storage "node --test firebase-tests/rules.test.cjs"
```

## Deployment

Deploy the account-deletion codebase and the updated Firestore/Storage rules to
the existing project. Preserve any production admin rules managed by the admin
project when applying the `_accountDeletions` check. Storage's Firestore lookup
may require the cross-service permission grant offered by the Firebase CLI.

```powershell
firebase login --reauth
firebase deploy --project stallseeker-c2ffe --only functions:account-deletion,firestore:rules,storage
```

Publish a new customer/vendor app build to deliver the login gate, session
validation and deletion-token changes. The admin frontend needs no change.

Accounts deleted before these triggers are deployed are not retroactively
processed. To release a previously deleted account's email, rerun the admin
deletion for its original UID or remove that specific identity in Firebase Auth;
the Auth deletion trigger then queues cleanup. Do not select accounts for deletion
solely because a profile is missing: a registration may still be in progress.
