# StallSeeker Cloud Functions

The default Functions codebase handles stall notifications and image cleanup.

Email verification and verified email changes use Firebase Authentication's
built-in action emails directly from the Flutter app. They do not require SMTP,
custom email functions, or verification-code secrets.

Configure the sender name and message in Firebase Console under
Authentication > Templates. The app requires the signed `email_verified` claim
before protected vendor, menu, review, follow, and image writes.
