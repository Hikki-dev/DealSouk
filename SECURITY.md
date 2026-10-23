# Security

## Reporting a problem

Please do not open a public issue for a security problem. Use the **Report a vulnerability** button on the Security tab of this project on GitHub. Say what you found and how to repeat it. We will reply as soon as we can.

## What this project protects

1. Phone numbers are encrypted in the database.
2. Every photo has its location data removed and is scanned for viruses before anyone sees it.
3. Every moderator action is written to an audit log, and moderators can be made to use a second sign-in step.
4. Every token change is written in a chain, so a balance cannot be changed quietly.
5. Write requests are rate limited, and the API only answers the websites on its allow-list.

## What to keep in mind

1. Never commit `.env`, service-account files, `google-services.json`, `GoogleService-Info.plist` or `firebase_options.dart`. The secret scan checks for them.
2. A Mapbox token should be a restricted public token. Restrict it by website and app in the Mapbox dashboard.
3. Keep sign-in tokens and keys out of screenshots and bug reports.

More: [SECURITY_AUDIT.md](SECURITY_AUDIT.md) is the review, and [SECURITY_CHECKLIST.md](SECURITY_CHECKLIST.md) is the list to finish before launch.
