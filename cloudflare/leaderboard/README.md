# Samguk Master Leaderboard

Cloudflare Worker + D1 leaderboard for the Flutter app.

## Current Production Settings

- Public leaderboard URL: <https://samguk-master-leaderboard.samguk-master.workers.dev>
- Worker name: `samguk-master-leaderboard`
- workers.dev subdomain: `samguk-master`
- D1 database name: `samguk-master-leaderboard`
- D1 database id: `e216d215-0e84-4ddd-a1db-ef432cdc85aa`
- D1 binding name in Worker code: `DB`
- Wrangler config: `cloudflare/leaderboard/wrangler.toml`
- Migration directory: `cloudflare/leaderboard/migrations`

The Flutter app default leaderboard URL is configured in:

```text
lib/services/external_leaderboard_service.dart
```

Current default:

```text
https://samguk-master-leaderboard.samguk-master.workers.dev
```

## First-Time Setup

```bash
cd cloudflare/leaderboard
npm install
npx wrangler login
npm run d1:create
```

Copy the created D1 `database_id` into `wrangler.toml`.

The D1 binding must stay named `DB`, because `src/index.js` reads `env.DB`:

```toml
[[d1_databases]]
binding = "DB"
database_name = "samguk-master-leaderboard"
database_id = "..."
migrations_dir = "migrations"
```

Then run:

```bash
npm run d1:migrate:remote
npm run deploy
```

## Routine Deployment

Use this when only `src/index.js`, `wrangler.toml`, or migrations changed:

```bash
cd cloudflare/leaderboard
npm run d1:migrate:remote
npm run deploy
```

Check the deployed API:

```bash
curl 'https://samguk-master-leaderboard.samguk-master.workers.dev/api/scores?limit=5'
```

## Changing Settings

### Change Worker code

Edit:

```text
cloudflare/leaderboard/src/index.js
```

Then deploy:

```bash
cd cloudflare/leaderboard
npm run deploy
```

### Change database schema

Add a new SQL file under `migrations/`, for example:

```text
cloudflare/leaderboard/migrations/0002_add_column.sql
```

Then apply it remotely and redeploy:

```bash
cd cloudflare/leaderboard
npm run d1:migrate:remote
npm run deploy
```

Do not edit an already-applied migration unless you are only resetting a local development database.

### Change the public leaderboard URL used by the app

For a one-off build, override it with `--dart-define`:

```bash
flutter build ipa --release \
  --dart-define=LEADERBOARD_BASE_URL=https://samguk-master-leaderboard.samguk-master.workers.dev
```

To permanently change the default URL, edit:

```text
lib/services/external_leaderboard_service.dart
```

and update the `defaultValue` for `LEADERBOARD_BASE_URL`.

### Change Worker name or D1 database

Edit:

```text
cloudflare/leaderboard/wrangler.toml
```

If you create a new D1 database:

```bash
cd cloudflare/leaderboard
npm run d1:create
```

Copy the new `database_id` into `wrangler.toml`, then run:

```bash
npm run d1:migrate:remote
npm run deploy
```

If the Worker URL changes, update the Flutter app URL as described above and rebuild the app.

## Local Development

```bash
cd cloudflare/leaderboard
npm install
npm run d1:migrate:local
npm run dev
```

Local URL:

```text
http://localhost:8787
```

Test locally:

```bash
curl -X POST 'http://localhost:8787/api/scores' \
  -H 'content-type: application/json' \
  --data '{"playerId":"local-test","nickname":"Local Hero","score":1234,"locale":"ko","platform":"ios"}'

curl 'http://localhost:8787/api/scores?limit=5'
```

## API

- `GET /` renders the public leaderboard page.
- `GET /api/scores?limit=50` returns JSON scores.
- `POST /api/scores` accepts:

```json
{
  "playerId": "stable-device-player-id",
  "nickname": "Hero ABC123",
  "score": 1234,
  "locale": "ko",
  "platform": "iOS"
}
```

## Notes

- The API keeps the best score per `playerId`; lower later scores do not overwrite a higher existing score.
- `node_modules/` and `.wrangler/` are intentionally ignored by Git.
- `wrangler.toml` contains infrastructure identifiers, not secrets.
