# API overview

Every route is served by the Express app in `backend/src/index.ts`. Write routes are rate limited. Routes marked **auth** need a Firebase sign-in token. Everything under `/admin` also needs the moderator role.

| Area | Base path | What it does |
|---|---|---|
| Sign-in | `/auth` | `POST /verify` swaps a Firebase token for a DealSouk user |
| Products | `/products` | `GET /search`, `/:id`, `/:id/prices`, `/:id/history` |
| Stores | `/stores` | `GET /nearby`, `/:id`, `/:id/prices` |
| Shared prices | `/submissions` | `GET /feed`, `GET /estimate`, `POST /` (auth), `POST /:id/flag` (auth) |
| Requests | `/requests` | `GET /board`, `GET /mine`, `POST /`, `POST /:id/fulfill`, `DELETE /:id` |
| Profile | `/profile` | `/me`, `/me/transactions`, `/me/vouchers`, `/me/submissions`, `/me/cart`, `/me/requests`, `/me/fcm-token`, `DELETE /me` |
| Leaderboard | `/leaderboard` | `GET /monthly` |
| Challenges | `/challenges` | `GET /today` |
| Uploads | `/uploads` | `POST /signed-url` |
| Helpers | `/translate`, `/logos/:slug`, `/config` | Translation, store logos, app settings |
| Moderators | `/admin` | `/queue`, `/submissions/:id/{approve,reject}`, `/users/:id/{warn,suspend,ban}`, `/products`, `/users`, `/vouchers`, `/analytics`, `/settings`, `/exports/*` |

`GET /health` answers when the server is up. The keep-warm workflow calls it so the free Render server does not go to sleep.

## Safety on every route

* Helmet, a CORS allow-list and a limit on request size.
* Rate limits per route, kept in Redis in production.
* Phone numbers are encrypted in the database.
* Every moderator action is written to an audit log.

See [How a price travels](How%20a%20price%20travels.md) for how the routes work together.
