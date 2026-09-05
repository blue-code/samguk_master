-- 데일리 챌린지 순위표. day 는 'YYYY-MM-DD' (UTC) — 앱의 dayKey 와 동일 규칙.
CREATE TABLE IF NOT EXISTS daily_scores (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  day TEXT NOT NULL,
  player_id TEXT NOT NULL,
  nickname TEXT NOT NULL,
  score INTEGER NOT NULL,
  locale TEXT NOT NULL DEFAULT 'ko',
  platform TEXT NOT NULL DEFAULT 'unknown',
  created_at INTEGER NOT NULL DEFAULT (unixepoch()),
  updated_at INTEGER NOT NULL DEFAULT (unixepoch()),
  UNIQUE(day, player_id)
);

CREATE INDEX IF NOT EXISTS idx_daily_scores_day_score
ON daily_scores(day, score DESC, updated_at ASC);
