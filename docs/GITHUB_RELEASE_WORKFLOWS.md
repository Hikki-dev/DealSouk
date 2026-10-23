# DealSouk GitHub Workflows

Date: 2026-06-13
Branch: `stabilize/mvp-audit`

## Required GitHub Secrets

Add these in:

```text
GitHub repo -> Settings -> Secrets and variables -> Actions -> Repository secrets
```

| Secret | Purpose |
|---|---|
| `FIREBASE_OPTIONS_DART_B64` | Base64 of `lib/firebase_options.dart` |
| `GOOGLE_SERVICES_JSON_B64` | Base64 of `android/app/google-services.json` |
| `GOOGLE_SERVICE_INFO_PLIST_B64` | Base64 of `ios/Runner/GoogleService-Info.plist` |

Create the values locally without printing the decoded contents:

```bash
base64 -i lib/firebase_options.dart | pbcopy
base64 -i android/app/google-services.json | pbcopy
base64 -i ios/Runner/GoogleService-Info.plist | pbcopy
```

Paste each copied value into its matching GitHub secret.

## APK Builds

Workflow:

```text
.github/workflows/android-internal.yml
```

It runs automatically on pushes to:

```text
stabilize/mvp-audit
```

It also runs manually through:

```text
GitHub -> Actions -> Android Internal APK -> Run workflow
```

Artifacts produced:

- `DealSouk-Shopper.apk`
- `DealSouk-Shopper-arm64-v8a.apk`
- `DealSouk-Shopper-armeabi-v7a.apk`
- `DealSouk-Shopper-x86_64.apk`
- `DealSouk-Admin.apk`

For sharing with colleagues, use `DealSouk-Shopper.apk` unless you specifically know their Android CPU architecture.

## Release Assets

If a GitHub Release is published, the workflow uploads the APK files as release assets.

## Admin Web

Admin should be web-first:

```text
https://deal-souk.vercel.app
```

The admin APK is built only as an internal fallback. Production admin operations should use the web admin portal.

## Current API URL

The workflows default to:

```text
https://dealsouk.onrender.com
```

Override it only for staging/test builds.
