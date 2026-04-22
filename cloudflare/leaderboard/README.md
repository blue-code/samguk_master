# Samguk Master Leaderboard

Cloudflare Worker + D1 leaderboard for the Flutter app.

## Setup

```bash
cd cloudflare/leaderboard
npm install
npx wrangler login
npm run d1:create
```

Copy the created D1 `database_id` into `wrangler.toml`, then run:

```bash
npm run d1:migrate:remote
npm run deploy
```

Build the Flutter app with the deployed Worker URL:

```bash
flutter build ipa --release \
  --dart-define=LEADERBOARD_BASE_URL=https://samguk-master-leaderboard.samguk-master.workers.dev
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
