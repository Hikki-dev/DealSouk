#!/bin/bash
set -e

# APP_MODE picks which app this Vercel project builds from the same codebase:
#   admin    (default) the moderator console, ADMIN_MODE=true
#   shopper  the shopper app on the web, ADMIN_MODE=false
APP_MODE="${APP_MODE:-admin}"
case "$APP_MODE" in
  admin) ADMIN_FLAG=true ;;
  shopper) ADMIN_FLAG=false ;;
  *) echo "APP_MODE must be 'admin' or 'shopper' (got '$APP_MODE')."; exit 1 ;;
esac
echo "==> Building the $APP_MODE app"

if [ -z "$FIREBASE_OPTIONS_DART_B64" ]; then
  echo "Missing FIREBASE_OPTIONS_DART_B64. Add it as a Vercel Environment Variable."
  exit 1
fi

if [ -z "$API_BASE_URL" ]; then
  echo "Missing API_BASE_URL. Add it as a Vercel Environment Variable."
  exit 1
fi

if [ -z "$MAPBOX_ACCESS_TOKEN" ]; then
  echo "NOTE: MAPBOX_ACCESS_TOKEN is not set. The maps will use OpenStreetMap tiles."
  echo "      Add it as a Vercel Environment Variable (a restricted public pk. token) for the Mapbox style."
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

echo "==> Building Flutter web $APP_MODE (release)..."
flutter build web --release \
  --dart-define=API_BASE_URL="$API_BASE_URL" \
  --dart-define=ADMIN_MODE="$ADMIN_FLAG" \
  --dart-define=MAPBOX_ACCESS_TOKEN="$MAPBOX_ACCESS_TOKEN"

echo "==> Build complete! Output in build/web"
