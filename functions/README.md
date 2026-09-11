# Email verification function setup

The two callable functions in `index.js` send and confirm six-digit email
verification codes. Before deploying them, configure an SMTP account and a
random hashing secret:

```text
firebase functions:secrets:set SMTP_USER
firebase functions:secrets:set SMTP_PASSWORD
firebase functions:secrets:set EMAIL_CODE_SECRET
```

`EMAIL_CODE_SECRET` should be a long, random value and must not be committed.
The default SMTP server is Gmail (`smtp.gmail.com:465`). For Gmail, use an app
password rather than the account password. Other providers can be selected at
deploy time with the `SMTP_HOST`, `SMTP_PORT`, and `SMTP_FROM` function
parameters.

Deploy the functions after the secrets are configured:

```text
firebase deploy --only functions:requestEmailVerificationCode,functions:confirmEmailVerificationCode
```

The `_emailVerificationCodes` collection is backend-only. Production Firestore
rules should deny all client reads and writes to this collection.
