#!/usr/bin/env bash
# Builds the demo database and fills it: tables, 18 Dubai stores, 20 products, 175 prices,
# a leaderboard, price requests, a moderation queue and vouchers. Also creates the two demo
# accounts in the Firebase Auth emulator. Start Postgres and the emulator first (see docs/Demo mode.md).
# It refuses to touch any database that is not on this computer.
set -euo pipefail
cd "$(dirname "$0")/../backend"

set -a; . ./.env; set +a
case "$DATABASE_URL" in
  *@127.0.0.1:*|*@localhost:*) ;;
  *) echo "DATABASE_URL must point at this computer. Stopping."; exit 1 ;;
esac

npm install --no-audit --no-fund >/dev/null
npx prisma generate >/dev/null
npx prisma migrate deploy
npm run seed
npm run seed:demo
npx ts-node scripts/demo-token.ts demo-shopper-1 >/dev/null
npx ts-node scripts/demo-token.ts demo-admin-1 >/dev/null
echo "Done. Accounts in the Auth emulator: priya@example.com (a shopper) and omar@example.com (the moderator)."
