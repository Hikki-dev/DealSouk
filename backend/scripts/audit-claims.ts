import "dotenv/config";
import * as admin from "firebase-admin";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

async function main() {
  console.log("--------------------------------------------------");
  console.log("DealSouk Firebase custom claims & IAM privilege auditor");
  console.log("--------------------------------------------------");

  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: requireEnv("FIREBASE_PROJECT_ID"),
        clientEmail: requireEnv("FIREBASE_CLIENT_EMAIL"),
        privateKey: requireEnv("FIREBASE_PRIVATE_KEY").replace(/\\n/g, "\n"),
      }),
    });
  }

  console.log("Fetching all users from Firebase Auth...");
  let nextPageToken: string | undefined = undefined;
  const firebaseUsers: admin.auth.UserRecord[] = [];
  do {
    const listUsersResult = await admin.auth().listUsers(1000, nextPageToken);
    firebaseUsers.push(...listUsersResult.users);
    nextPageToken = listUsersResult.pageToken;
  } while (nextPageToken);

  console.log(`Found ${firebaseUsers.length} users in Firebase Auth.`);

  console.log("Fetching all users from Neon Postgres...");
  const dbUsers = await prisma.user.findMany();
  console.log(`Found ${dbUsers.length} users in Postgres.`);

  const dbUserMap = new Map(dbUsers.map((u) => [u.firebaseUid, u]));

  const inconsistencies: Array<{
    uid: string;
    email?: string;
    displayName?: string;
    issue: string;
    actionRequired: string;
  }> = [];

  for (const firebaseUser of firebaseUsers) {
    const customClaims = firebaseUser.customClaims || {};
    const hasAdminClaim = customClaims.admin === true;
    const hasAdminRole = Array.isArray(customClaims.roles) && customClaims.roles.includes("admin");

    const dbUser = dbUserMap.get(firebaseUser.uid);

    if (!dbUser) {
      if (hasAdminClaim || hasAdminRole) {
        inconsistencies.push({
          uid: firebaseUser.uid,
          email: firebaseUser.email,
          displayName: firebaseUser.displayName,
          issue: `User exists in Firebase Auth with Admin claims/roles, but does NOT exist in the Postgres database.`,
          actionRequired: `Create user in database or remove claims by running: npx ts-node scripts/set-admin.ts --uid ${firebaseUser.uid} --no-admin`,
        });
      }
      continue;
    }

    const isDbAdmin = dbUser.isAdmin === true;

    // Check for mismatch between Firebase custom claims and database isAdmin flag
    if (hasAdminClaim !== isDbAdmin || hasAdminRole !== isDbAdmin) {
      inconsistencies.push({
        uid: firebaseUser.uid,
        email: firebaseUser.email,
        displayName: dbUser.displayName,
        issue: `Admin privilege mismatch! Firebase claims (admin: ${hasAdminClaim}, roles: ${JSON.stringify(
          customClaims.roles || []
        )}) do not match Postgres Database (isAdmin: ${isDbAdmin}).`,
        actionRequired: `Sync privileges by running: npx ts-node scripts/set-admin.ts --uid ${
          firebaseUser.uid
        } ${isDbAdmin ? "--admin" : "--no-admin"}`,
      });
    }
  }

  // Check for DB users marked as Admin but who don't exist in Firebase Auth or have no claims
  for (const dbUser of dbUsers) {
    if (dbUser.isAdmin) {
      const firebaseUser = firebaseUsers.find((fu) => fu.uid === dbUser.firebaseUid);
      if (!firebaseUser) {
        inconsistencies.push({
          uid: dbUser.firebaseUid,
          displayName: dbUser.displayName,
          issue: `User is marked as Admin in Postgres, but does NOT exist in Firebase Auth.`,
          actionRequired: `Verify if this user account was deleted in Firebase. Admin credentials must exist in Auth.`,
        });
      }
    }
  }

  console.log("\n--------------------------------------------------");
  console.log("AUDIT RESULTS SUMMARY");
  console.log("--------------------------------------------------");
  if (inconsistencies.length === 0) {
    console.log("✅ All clear! No inconsistencies found between Firebase Auth custom claims and the database.");
  } else {
    console.log(`⚠️  Found ${inconsistencies.length} inconsistency issues:\n`);
    for (const [idx, item] of inconsistencies.entries()) {
      console.log(`${idx + 1}. User: ${item.displayName || "Unknown"} (${item.email || "No Email"})`);
      console.log(`   UID: ${item.uid}`);
      console.log(`   Issue: ${item.issue}`);
      console.log(`   Action Required: ${item.actionRequired}\n`);
    }
  }
  console.log("--------------------------------------------------");
}

main()
  .catch((err) => {
    console.error("Audit failed with error:", err);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
