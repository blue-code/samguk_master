CREATE TABLE IF NOT EXISTS scores (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  player_id TEXT NOT NULL UNIQUE,
  nickname TEXT NOT NULL,
  score INTEGER NOT NULL,
  locale TEXT NOT NULL DEFAULT 'ko',
  platform TEXT NOT NULL DEFAULT 'unknown',
  created_at INTEGER NOT NULL DEFAULT (unixepoch()),
  updated_at INTEGER NOT NULL DEFAULT (unixepoch())
);

CREATE INDEX IF NOT EXISTS idx_scores_score_updated
ON scores(score DESC, updated_at ASC);
