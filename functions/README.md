# Chatbot database search function

The callable function discovers Firestore root collections and nested
subcollections dynamically. It skips every collection named `users`, scans the
remaining documents for matches to the question, and returns a bounded context
for Gemini. The full database is searched, but only relevant results that fit
the AI context limit are returned.

Only Firebase Auth users with the server-managed `admin: true` custom claim can
call this function. Do not grant the claim based on a client-editable profile
field.

## Deploy

From the repository root:

```powershell
cd functions
npm install
cd ..
firebase deploy --only functions:getChatbotDatabaseContext
```

The deployment account must be able to deploy Cloud Functions and create or
update the required Google Cloud resources.

## Grant admin access

Use a trusted environment with Google Application Default Credentials for the
`nyam-makaan` project (for example, Cloud Shell or a secured admin workstation):

```powershell
cd functions
npm install
npm run set-admin-claim -- <FIREBASE_AUTH_UID>
```

The claim is set server-side and existing custom claims are preserved. The admin
must sign out and back in (or refresh the ID token) before the claim is present
in callable requests.
