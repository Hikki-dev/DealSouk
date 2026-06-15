# DealSouk Pre-Launch Security Checklist

Use this before every production deployment and as a periodic security hygiene check.

---

## 1. Secrets & Credentials

- [ ] No `.env`, `render.env`, `firebase-service-account.json`, `google-services.json`, `GoogleService-Info.plist`, or `firebase_options.dart` appear in `git status` or `git log`
- [ ] Run `python3 scripts/secret_scan.py` — must pass with no findings
- [ ] All production secrets are set in Render dashboard (not in any committed file)
- [ ] `DATABASE_ENCRYPTION_KEY` is set and matches the key used to encrypt existing phone numbers
- [ ] Firebase service account has only the minimum required IAM roles (Firebase Auth Admin, FCM)
- [ ] Firebase Android API key restricted to `com.dealsouk.dealsouk` + release certificate SHA-1
- [ ] Firebase iOS API key restricted to bundle ID `com.dealsouk.dealsouk`
- [ ] Firebase Web API key restricted to production domain

---

## 2. Backend Authentication

- [ ] Every route that returns user-specific data uses `requireAuth` middleware
- [ ] All `/admin/*` routes use both `requireAuth` and `requireAdmin`
- [ ] `isAdmin` is **never** set via API — only via `npm run admin:set` CLI
- [ ] `req.userId` (from token) is used for all user lookups — never `req.body.userId`
- [ ] Token verification uses `verifyIdToken(token, true)` (checkRevoked = true)

---

## 3. Manual API Tests

Run these against the production URL after each deploy:

```bash
BASE=https://dealsouk.onrender.com

# Unauthenticated access to protected route must return 401
curl -s $BASE/profile/me | jq .
# Expected: {"error":"Missing authorization token"}

# Admin endpoint must return 403 for normal user token
# Replace $TOKEN with a real non-admin Firebase ID token
curl -s -H "Authorization: Bearer $TOKEN" $BASE/admin/queue | jq .
# Expected: {"error":"Admin access required"}

# Price submission must reject negative price
curl -s -X POST $BASE/submissions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"productId":"test","storeId":"test","priceAed":-1}' | jq .
# Expected: 400 error

# Price submission must reject price above MAX (999)
curl -s -X POST $BASE/submissions \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"productId":"test","storeId":"test","priceAed":99999}' | jq .
# Expected: 400 error

# Request with oversized text must be rejected
python3 -c "print('A'*1001)" | xargs -I{} curl -s -X POST $BASE/requests \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"productName\":\"{}\",\"storeName\":\"test\"}" | jq .
# Expected: 400 error

# Health endpoint must not leak config
curl -s $BASE/health | jq .
# Expected: {"status":"ok","timestamp":"..."}  — nothing else

# System status must not leak env vars
curl -s $BASE/system/status | jq .
# Expected: {"maintenance":false,"message":"..."}  — nothing sensitive
```

---

## 4. Firebase Checks

- [ ] Firebase Auth → Users: no unexpected accounts with unusually large token balances
- [ ] Firebase Auth → Settings: email enumeration protection enabled
- [ ] Firebase Storage rules: deny public write; read allowed only via signed URL or authenticated user's own path
- [ ] Firestore rules (if used): default deny for all unauthenticated reads/writes
- [ ] Service account `dealsouk@dealsouk-6e140.iam.gserviceaccount.com` — verify active keys in Cloud Console → IAM → Service Accounts

---

## 5. Render (Backend) Checks

- [ ] All required env vars are set (see SECURITY_AUDIT.md table)
- [ ] `NODE_ENV=production`
- [ ] `ALLOWED_ORIGINS` = production domain(s) only (no localhost)
- [ ] `RATE_LIMIT_REDIS=true` and `REDIS_URL` set
- [ ] `ADMIN_MFA_REQUIRED=true` (recommended)
- [ ] Health check URL configured in Render: `GET /health`
- [ ] Auto-deploy from `main` branch only (not feature branches)
- [ ] Render deploy hook URL is not publicly known/guessable

---

## 6. GitHub Checks

- [ ] Branch protection on `main`: require PR, require CI pass, no force push
- [ ] GitHub Secrets set: `FIREBASE_OPTIONS_DART_B64`, `GOOGLE_SERVICES_JSON_B64`, `GOOGLE_SERVICE_INFO_PLIST_B64`, `ANDROID_UPLOAD_KEYSTORE_B64`, `ANDROID_UPLOAD_STORE_PASSWORD`, `ANDROID_UPLOAD_KEY_ALIAS`, `ANDROID_UPLOAD_KEY_PASSWORD`
- [ ] No workflow uses `pull_request_target` with `actions/checkout` of PR branch
- [ ] Workflows do not `echo` or `print` secret values
- [ ] Dependabot PRs are reviewed and merged regularly
- [ ] Repository access: only authorized team members have write access

---

## 7. Database Checks

Run against production Neon DB after each deployment:

```sql
-- Verify no unexpected admin accounts
SELECT "displayName", "firebaseUid", "createdAt"
FROM "User"
WHERE "isAdmin" = true
ORDER BY "createdAt";

-- Verify token ledger chain is intact (no gaps or duplicates)
SELECT COUNT(*) as total, COUNT(DISTINCT hash) as unique_hashes
FROM "TokenTransaction";
-- total should equal unique_hashes

-- Check for suspiciously high token balances
SELECT "displayName", "tokenBalance", "lifetimeTokensEarned"
FROM "User"
ORDER BY "tokenBalance" DESC
LIMIT 10;

-- Check for duplicate submissions (same user, product, store, price within 24h)
SELECT "sourcerId", "productId", "storeId", "priceAed", COUNT(*) as cnt
FROM "PriceSubmission"
WHERE "submittedAt" > NOW() - INTERVAL '24 hours'
GROUP BY "sourcerId", "productId", "storeId", "priceAed"
HAVING COUNT(*) > 1;
```

---

## 8. UptimeRobot / Monitoring

- [ ] Monitor URL is `GET /health` — not `/admin/*` or any authenticated endpoint
- [ ] Alert notification channel is set (email/Slack)
- [ ] No monitor credentials or API keys stored in plaintext in UptimeRobot notification webhooks

---

## 9. Periodic Security Tasks (Monthly)

- [ ] Review Dependabot PRs — merge patch/minor; review major versions manually
- [ ] Run `cd backend && npm audit` — resolve any high/critical findings
- [ ] Run `flutter pub outdated` — note major version gaps
- [ ] Review Render logs for anomalous patterns (repeated 401s, admin endpoint probing)
- [ ] Confirm Firebase service account keys have not been leaked (check `git log -S "BEGIN PRIVATE KEY"`)
