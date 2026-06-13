# DealSouk Secret Safety Checklist

Date: 2026-06-13
Branch: `stabilize/mvp-audit`

## Current Status

Current tracked files are clean for high-risk secrets.

The repository does not currently track:

- `backend/.env`
- `backend/render.env`
- `backend/firebase-service-account.json`
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`
- `.vercel/project.json`

Vercel stores these as encrypted environment variables:

- `FIREBASE_OPTIONS_DART_B64`
- `API_BASE_URL`

Render must store backend secrets as environment variables only.

Local Render helper:

- `backend/render.env` is ignored and may contain real Render env values for copy/paste.
- `backend/render.env.example` is the committed safe template.

## Still Required Before Public Launch

### 1. Rotate Firebase Client API Keys

Git history contains old Firebase client config values in:

- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `lib/firebase_options.dart`

Firebase client API keys are not the same as a Firebase Admin private key, but exposed historical client keys should still be rotated or replaced before public launch.

### 2. Restrict Firebase / Google API Keys

In Google Cloud Console:

1. Open **APIs & Services**.
2. Open **Credentials**.
3. Find the DealSouk Firebase client API keys.
4. Apply application restrictions:

| Key Type | Required Restriction |
|---|---|
| Android | Android package name + SHA-1/SHA-256 signing certificate fingerprints |
| iOS | iOS bundle ID |
| Web admin | HTTP referrer `https://deal-souk.vercel.app/*` and Vercel preview domains used for testing |

5. Apply API restrictions so each key can call only the required Firebase/Google APIs.

### 3. Rotate Firebase Admin Service Account Key

If `backend/firebase-service-account.json` was ever shared, uploaded, or copied outside this machine:

1. Open Google Cloud Console.
2. Go to **IAM & Admin** -> **Service Accounts**.
3. Open the Firebase Admin SDK service account.
4. Delete the old key.
5. Create a new JSON key.
6. Store only the new key values in Render secrets:
   - `FIREBASE_PROJECT_ID`
   - `FIREBASE_CLIENT_EMAIL`
   - `FIREBASE_PRIVATE_KEY`
7. Replace local `backend/firebase-service-account.json` if the admin script still needs it.

Never commit the JSON file.

### 4. Keep Local Secret Files Private

Local secret files should stay ignored and readable only by the local user:

```bash
chmod 600 backend/.env backend/firebase-service-account.json 2>/dev/null || true
chmod 600 android/app/google-services.json ios/Runner/GoogleService-Info.plist lib/firebase_options.dart 2>/dev/null || true
```

### 5. Purge Git History Before Public Repository

If the repository may become public, purge historical Firebase client config files from all branches and tags before publishing.

Recommended command after making a fresh backup clone:

```bash
brew install git-filter-repo
bash scripts/purge_firebase_history.sh
```

Then force-push the cleaned branches and tags:

```bash
git push origin --force --all
git push origin --force --tags
```

This rewrites commit history. Coordinate before doing it if anyone else has cloned the repo.

### 6. Enable Firebase Storage

Firebase Storage is enabled for `dealsouk-6e140`, and Storage rules were deployed on 2026-06-13.

To redeploy rules after future edits:

```bash
firebase deploy --only storage --project dealsouk-6e140
```

### 7. Keep Deployment Environments Locked

Vercel:

- Keep preview deployment protection enabled.
- Keep `FIREBASE_OPTIONS_DART_B64` encrypted.
- Keep `API_BASE_URL` pointing to the deployed backend.

Render:

- Store backend secrets only in Render environment variables.
- Never paste backend secrets into logs, build commands, or `render.yaml`.
- Keep `ALLOWED_ORIGINS` strict.

GitHub:

- Use GitHub Secrets for mobile build config.
- Never store Firebase files or signing material in git.

### 8. Configure Upload Scanner Secret

The Firebase upload-processing function reads `MALWARE_SCAN_URL`.

Before public launch, deploy a private scanner service and configure the function env var without committing it:

```bash
firebase functions:secrets:set MALWARE_SCAN_URL --project dealsouk-6e140
firebase deploy --only functions --project dealsouk-6e140
```

The scanner must return:

```json
{ "status": "clean" }
```

Any other response quarantines the uploaded file.

## Added Guardrails

The repository includes `scripts/secret_scan.py`.

CI runs this scanner before restoring Firebase config from secrets. It fails if a tracked file contains likely secrets or if known secret files become tracked.

Local usage:

```bash
python3 scripts/secret_scan.py
```
