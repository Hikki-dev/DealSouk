// Creates the two demo accounts in the LOCAL Firebase Auth emulator and prints a sign-in token.
// Used by demo/screenshots and handy for trying the API with curl. See docs/Demo mode.md.
//   FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099 npx ts-node scripts/demo-token.ts demo-shopper-1
//   (prints a custom token; exchange it for an ID token, or pass --id-token to get the ID token)
import * as admin from 'firebase-admin';

if (!process.env.FIREBASE_AUTH_EMULATOR_HOST) {
  console.error('Set FIREBASE_AUTH_EMULATOR_HOST (for example 127.0.0.1:9099). This only works on the emulator.');
  process.exit(1);
}

const people: Record<string, { email: string; name: string; admin?: boolean }> = {
  'demo-shopper-1': { email: 'priya@example.com', name: 'Priya Nair' },
  'demo-admin-1': { email: 'omar@example.com', name: 'Moderator Omar', admin: true },
};

async function main() {
  const uid = process.argv[2] ?? 'demo-shopper-1';
  const person = people[uid];
  if (!person) throw new Error(`Unknown demo user ${uid}. Use one of: ${Object.keys(people).join(', ')}`);
  admin.initializeApp({ projectId: process.env.FIREBASE_PROJECT_ID ?? 'demo-dealsouk' });
  const auth = admin.auth();
  // Import the account with a linked Google identity whose id is the same as the uid. Then the
  // emulator's fake Google sign-in page lists this person, and picking them signs in as this user.
  await auth.importUsers([
    {
      uid,
      email: person.email,
      emailVerified: true,
      displayName: person.name,
      providerData: [{ providerId: 'google.com', uid, email: person.email, displayName: person.name }],
      customClaims: person.admin ? { admin: true } : undefined,
    },
  ]);
  const custom = await auth.createCustomToken(uid, person.admin ? { admin: true } : {});
  if (process.argv.includes('--id-token')) {
    const res = await fetch(`http://${process.env.FIREBASE_AUTH_EMULATOR_HOST}/identitytoolkit.googleapis.com/v1/accounts:signInWithCustomToken?key=demo`, {
      method: 'POST', headers: { 'content-type': 'application/json' }, body: JSON.stringify({ token: custom, returnSecureToken: true }),
    });
    console.log(((await res.json()) as { idToken: string }).idToken);
  } else {
    console.log(custom);
  }
}
main().catch((e) => { console.error(e); process.exit(1); });
