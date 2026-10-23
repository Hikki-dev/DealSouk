# Secret Rotation Runbook

Date: 2026-06-12

## What Must Be Rotated Before Public Production

Rotate anything that may have appeared in git history or local shared builds:

- Firebase Admin service-account key.
- Firebase client config files if exposed in public repos.
- Google Maps API keys.
- OAuth client secrets.
- Database passwords.
- CI/deployment tokens.
- Android/iOS signing credentials later, when store signing is enabled.

## Git History Cleanup

Before making the repo public or granting broad access:

1. Audit tracked files:

```bash
git ls-files | rg '(^|/)(\\.env|google-services\\.json|GoogleService-Info\\.plist|firebase_options\\.dart|.*service-account.*|.*secret.*|.*key.*\\.json)'
```

2. Audit history:

```bash
git log --all --name-only --pretty=format: | sort -u | rg '(^|/)(\\.env|google-services\\.json|GoogleService-Info\\.plist|firebase_options\\.dart|.*service-account.*|.*secret.*|.*key.*\\.json)'
```

3. If secrets/configs appeared in history, purge with `git-filter-repo` in a coordinated maintenance window.
4. Force-push only after every collaborator is warned.
5. Rotate the affected credentials after purge.

## GitHub Secrets

Use GitHub Secrets for build-time config:

- `FIREBASE_OPTIONS_DART_B64`
- `GOOGLE_SERVICES_JSON_B64`
- `GOOGLE_SERVICE_INFO_PLIST_B64`

Never print decoded secrets in workflow logs.

## Local Developer Rules

- Use `.env` locally, never commit it.
- Use `.env.example` for placeholders only.
- Do not paste production secrets into issue trackers, PRs, screenshots, docs, or chat.
- Prefer short-lived deploy credentials where the platform supports them.
