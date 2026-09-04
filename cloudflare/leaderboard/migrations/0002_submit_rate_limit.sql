-- 점수 제출 빈도 제한용 로그.
-- 원본 IP는 저장하지 않고 SHA-256 해시만 남긴다.
CREATE TABLE IF NOT EXISTS submit_log (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  ip_hash TEXT NOT NULL,
  created_at INTEGER NOT NULL DEFAULT (unixepoch())
);

CREATE INDEX IF NOT EXISTS idx_submit_log_ip_time
ON submit_log(ip_hash, created_at);
