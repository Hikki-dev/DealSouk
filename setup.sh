#!/usr/bin/env bash
# DealSouk first-time setup script
# Run this once after cloning the repo on a new machine.
set -e

echo "==> Generating Firebase config files (requires Firebase login)..."
flutterfire configure \
  --project dealsouk-6e140 \
  --platforms android,ios \
  --android-package-name com.dealsouk.dealsouk \
  --ios-bundle-id com.dealsouk.dealsouk \
  --out lib/firebase_options.dart \
  --yes

echo "==> Installing Flutter packages..."
flutter pub get

echo "==> Installing backend npm packages..."
cd backend && npm install && cd ..

echo "==> Done! Next steps:"
echo "  1. Copy backend/.env.example → backend/.env and fill in your credentials"
echo "  2. Run: cd backend && npx prisma migrate dev"
echo "  3. Run: cd backend && npm run dev"
echo "  4. Run: flutter run"
