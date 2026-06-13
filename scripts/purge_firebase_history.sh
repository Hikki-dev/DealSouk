#!/usr/bin/env bash
set -euo pipefail

if ! git diff --quiet || ! git diff --cached --quiet; then
  echo "Refusing to rewrite history with uncommitted changes."
  echo "Commit, stash, or move local changes first."
  exit 1
fi

if ! command -v git-filter-repo >/dev/null 2>&1; then
  echo "git-filter-repo is required."
  echo "Install it first, for example: brew install git-filter-repo"
  exit 1
fi

backup="../DealSouk-before-history-purge-$(date +%Y%m%d-%H%M%S).bundle"
git bundle create "$backup" --all
echo "Backup bundle created at $backup"

git filter-repo \
  --path android/app/google-services.json \
  --path ios/Runner/GoogleService-Info.plist \
  --path lib/firebase_options.dart \
  --invert-paths

echo "History purge complete locally."
echo "Verify with:"
echo "  git log --all --name-only --pretty=format: | sort -u | rg 'google-services.json|GoogleService-Info.plist|firebase_options.dart'"
echo
echo "When verified and coordinated, force-push:"
echo "  git push origin --force --all"
echo "  git push origin --force --tags"
