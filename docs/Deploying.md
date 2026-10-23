# Deployment and setup checklist

Two web apps are built from this one repository. Both use `vercel_build.sh`; `APP_MODE` picks which one.

| Vercel project | `APP_MODE` | Who uses it |
|---|---|---|
| `deal-souk` | `admin` (default) | Moderators: the console |
| `deal-souk-shopper` | `shopper` | Customers: the shopper app (phone and desktop layouts) |

Android APKs for both apps come from the **Android APK** GitHub workflow (artifacts `Dealsouk-Shopper-APK` and `Dealsouk-Admin-APK`).

## Environment variables (per Vercel project)
| Name | Required | Notes |
|---|---|---|
| `FIREBASE_OPTIONS_DART_B64` | yes | Base64 of the generated `lib/firebase_options.dart`. Same value in both projects. `base64 -w0 lib/firebase_options.dart` |
| `APP_MODE` | shopper project only | `shopper`. Already set on `deal-souk-shopper`. |
| `API_BASE_URL` | yes | The backend address. Same value in both projects. The build stops without it. |
| `MAPBOX_ACCESS_TOKEN` | recommended | A restricted public `pk.` token. Without it, maps show blank tiles. |

## Firebase authorized domains
Web sign-in is refused until every site address is listed in Firebase.

Firebase console, Authentication, Settings, Authorized domains, Add domain:
- the production addresses: `deal-souk.vercel.app`, `deal-souk-hikki-devs-projects.vercel.app`, `deal-souk-shopper.vercel.app` and `deal-souk-shopper-hikki-devs-projects.vercel.app`
- the `git-main` aliases: `deal-souk-git-main-hikki-devs-projects.vercel.app` and `deal-souk-shopper-git-main-hikki-devs-projects.vercel.app`
- any custom domain you attach
- preview addresses only if you want to sign in on previews

Also in Firebase: enable the **Google**, **Phone** and **Apple** providers you want to offer. Apple needs an Apple developer setup; hide that button if you do not use it.

## Making someone a moderator
New accounts are shoppers. Grant the admin role as described in [Moderator access](Moderator%20access.md), then sign out and in again.

## First deploy of the shopper project
1. Vercel project `deal-souk-shopper` already exists, linked to this repository, with `APP_MODE=shopper`.
2. Add `FIREBASE_OPTIONS_DART_B64` (and `MAPBOX_ACCESS_TOKEN`).
3. Redeploy the latest `main` deployment, or push a commit.
4. Add the new address to Firebase authorized domains.
