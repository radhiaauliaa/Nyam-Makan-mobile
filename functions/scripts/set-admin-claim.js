const { applicationDefault, initializeApp } = require("firebase-admin/app");
const { getAuth } = require("firebase-admin/auth");

const uid = process.argv[2];
if (!uid) {
  console.error("Usage: npm run set-admin-claim -- <firebase-auth-uid>");
  process.exitCode = 1;
} else {
  initializeApp({ credential: applicationDefault() });
  getAuth()
    .getUser(uid)
    .then((user) =>
      getAuth().setCustomUserClaims(uid, {
        ...user.customClaims,
        admin: true,
      }),
    )
    .then(() => console.log(`Admin claim enabled for UID ${uid}.`))
    .catch((error) => {
      console.error("Failed to set admin claim:", error);
      process.exitCode = 1;
    });
}
