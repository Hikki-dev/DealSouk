#!/bin/bash
set -e

echo "==> Installing Flutter SDK..."
git clone --depth 1 --branch stable https://github.com/flutter/flutter.git /tmp/flutter
export PATH="/tmp/flutter/bin:$PATH"

echo "==> Flutter version:"
flutter --version

echo "==> Enabling web support..."
flutter config --enable-web

echo "==> Getting dependencies..."
flutter pub get

echo "==> Building Flutter web (release)..."
flutter build web --release

echo "==> Build complete! Output in build/web"
