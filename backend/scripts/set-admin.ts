import "dotenv/config";
import * as admin from "firebase-admin";
import { PrismaClient } from "@prisma/client";
import { encrypt } from "../src/services/encryption";

const prisma = new PrismaClient();

function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}

function parseArgs() {
  const args = process.argv.slice(2);
  const result: { email?: string; uid?: string; admin?: boolean } = {};

  for (let i = 0; i < args.length; i += 1) {
    const arg = args[i];
    if (arg === "--email") result.email = args[++i];
    if (arg === "--uid") result.uid = args[++i];
    if (arg === "--admin") result.admin = true;
    if (arg === "--no-admin") result.admin = false;
  }

  if (!result.email && !result.uid) {
    throw new Error("Provide --email user@example.com or --uid firebase_uid");
  }
  if (result.admin == null) {
    throw new Error("Provide --admin or --no-admin");
  }

  return result;
}

async function main() {
  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert({
        projectId: requireEnv("FIREBASE_PROJECT_ID"),
        clientEmail: requireEnv("FIREBASE_CLIENT_EMAIL"),
        privateKey: requireEnv("FIREBASE_PRIVATE_KEY").replace(/\\n/g, "\n"),
      }),
    });
  }

  const args = parseArgs();
  const firebaseUser = args.uid
    ? await admin.auth().getUser(args.uid)
    : await admin.auth().getUserByEmail(args.email!);

  const displayName =
    firebaseUser.displayName ??
    firebaseUser.email?.split("@")[0] ??
    firebaseUser.phoneNumber ??
    "DealSouk Admin";
  const encryptedPhone = firebaseUser.phoneNumber
    ? encrypt(firebaseUser.phoneNumber)
    : null;

  const user = await prisma.user.upsert({
    where: { firebaseUid: firebaseUser.uid },
    update: { isAdmin: args.admin },
    create: {
      firebaseUid: firebaseUser.uid,
      displayName,
      phoneNumber: encryptedPhone,
      preferredLocale: "en",
      isAdmin: args.admin,
    },
  });

  await admin.auth().setCustomUserClaims(firebaseUser.uid, {
    admin: args.admin,
    roles: args.admin ? ["user", "admin"] : ["user"],
  });

  console.log(
    `${user.displayName} (${firebaseUser.uid}) admin=${args.admin ? "true" : "false"}`,
  );
}

main()
  .catch((err) => {
    console.error(err);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
