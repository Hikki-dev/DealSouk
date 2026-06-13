#!/bin/bash
set -e

if [ -z "$FIREBASE_OPTIONS_DART_B64" ]; then
  echo "Missing FIREBASE_OPTIONS_DART_B64. Add it as a Vercel Environment Variable."
  exit 1
fi

if [ -z "$API_BASE_URL" ]; then
  echo "Missing API_BASE_URL. Add it as a Vercel Environment Variable."
  exit 1
fi

echo "==> Restoring generated Firebase options from Vercel env..."
echo "$FIREBASE_OPTIONS_DART_B64" | base64 --decode > lib/firebase_options.dart

echo "==> Installing Flutter SDK..."
git clone --depth 1 --branch stable https://github.com/flutter/flutter.git /tmp/flutter
export PATH="/tmp/flutter/bin:$PATH"

echo "==> Flutter version:"
flutter --version

echo "==> Enabling web support..."
flutter config --enable-web

echo "==> Getting dependencies..."
flutter pub get

echo "==> Building Flutter web admin (release)..."
flutter build web --release \
  --dart-define=API_BASE_URL="$API_BASE_URL" \
  --dart-define=ADMIN_MODE=true

echo "==> Build complete! Output in build/web"
