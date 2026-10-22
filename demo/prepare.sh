#!/usr/bin/env bash
# Makes the two git-ignored files a local demo needs, filled with FAKE values and a throwaway key,
# so DealSouk can run on your computer with no Firebase project. It never overwrites a file you
# already have, so your real settings are safe.
#   lib/firebase_options.dart   fake Firebase app settings
#   backend/.env                settings for an API that talks to a local Postgres and the Auth emulator
set -euo pipefail
cd "$(dirname "$0")/.."

if [ ! -f lib/firebase_options.dart ]; then
  cp demo/firebase_options.demo.dart lib/firebase_options.dart
  echo "made lib/firebase_options.dart (fake values)"
else
  echo "lib/firebase_options.dart already exists, left alone"
fi

if [ ! -f backend/.env ]; then
  PRIVATE_KEY=$(openssl genrsa 2048 2>/dev/null | awk 'BEGIN { ORS = "\\n" } { print }')
  cat > backend/.env <<ENV
NODE_ENV=development
PORT=3000
# A Postgres on this computer. Change it if yours has another user, password or port.
DATABASE_URL=postgresql://postgres@127.0.0.1:5432/dealsouk?schema=public
DATABASE_ENCRYPTION_KEY=$(openssl rand -base64 32)
# Fake Firebase settings. The Auth emulator does not check them.
FIREBASE_PROJECT_ID=demo-dealsouk
FIREBASE_CLIENT_EMAIL=demo@demo-dealsouk.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="$PRIVATE_KEY"
FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099
ALLOWED_ORIGINS=http://127.0.0.1:8100,http://localhost:8100
ENV
  echo "made backend/.env (local Postgres and the Auth emulator)"
else
  echo "backend/.env already exists, left alone"
fi
