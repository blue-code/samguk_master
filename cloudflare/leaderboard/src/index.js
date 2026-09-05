const MAX_LIMIT = 100;

// 게임 로직상 도달 가능한 최대 점수.
// 앱 규칙(lib/viewmodels/quiz_viewmodel.dart:23-24, 257):
//   한 판 = SESSION_LENGTH 문항, 정답마다 콤보가 1씩 오르고
//   점수 += (BASE_POINTS + 남은시간) * 콤보
// 최선의 경우 = 전 문항을 남은시간 최대로 정답 →
//   (BASE_POINTS + QUESTION_SECONDS) * (1+2+...+SESSION_LENGTH)
// ⚠️ 앱에서 sessionLength / questionSeconds를 바꾸면 여기도 함께 고쳐야 한다.
//    안 그러면 상위권 정상 점수가 400으로 거부된다.
const SESSION_LENGTH = 15;
const QUESTION_SECONDS = 15;
const BASE_POINTS = 10;
const MAX_SCORE =
  ((BASE_POINTS + QUESTION_SECONDS) * SESSION_LENGTH * (SESSION_LENGTH + 1)) / 2; // 3000

// 제출 빈도 제한: 한 IP당 60초에 10회.
// 한 판이 약 4분이라 정상 플레이에는 여유가 크다.
const RATE_LIMIT_PER_WINDOW = 10;
const RATE_WINDOW_SECONDS = 60;
const RATE_LOG_RETENTION_SECONDS = 600;

export default {
  async fetch(request, env) {
    const url = new URL(request.url);

    if (request.method === 'OPTIONS') {
      return withCors(new Response(null, { status: 204 }));
    }

    try {
      if (url.pathname === '/api/scores' && request.method === 'GET') {
        return withCors(await listScores(request, env));
      }

      if (url.pathname === '/api/daily' && request.method === 'GET') {
        return withCors(await listDailyScores(request, env));
      }

      if (url.pathname === '/api/daily' && request.method === 'POST') {
        const allowed = await checkRateLimit(request, env);
        if (!allowed) {
          return withCors(json({ error: 'rate_limited' }, 429));
        }
        return withCors(await submitDailyScore(request, env));
      }

      if (url.pathname === '/api/scores' && request.method === 'POST') {
        const allowed = await checkRateLimit(request, env);
        if (!allowed) {
          return withCors(json({ error: 'rate_limited' }, 429));
        }
        return withCors(await submitScore(request, env));
      }

      if (url.pathname === '/' && request.method === 'GET') {
        return html(await renderLeaderboard(request, env));
      }

      if (
        url.pathname.startsWith('/assets/') &&
        (request.method === 'GET' || request.method === 'HEAD')
      ) {
        return env.ASSETS.fetch(request);
      }

      return withCors(json({ error: 'not_found' }, 404));
    } catch (error) {
      console.error(error);
      return withCors(json({ error: 'internal_error' }, 500));
    }
  },
};

async function listScores(request, env) {
  const url = new URL(request.url);
  const limit = clamp(Number(url.searchParams.get('limit') || 50), 1, MAX_LIMIT);

  const { results } = await env.DB.prepare(
    `SELECT nickname, score, locale, platform, updated_at
     FROM scores
     ORDER BY score DESC, updated_at ASC
     LIMIT ?`
  )
    .bind(limit)
    .all();

  return json({ scores: results ?? [] });
}

// IP 단위 제출 빈도 제한.
// Cloudflare Rate Limiting 바인딩([[ratelimits]])을 먼저 시도했으나 실측에서
// 동작하지 않았다: limit=1/period=10 설정으로도 같은 IP 연속 5회가 전부
// success:true를 반환. 원인 미확인(계정 게이팅인지, 문서에 적힌 per-location
// eventual consistency 때문인지 확인 못 함). 그래서 D1으로 직접 구현했다.
// 원본 IP는 저장하지 않고 SHA-256 해시만 남긴다.
async function checkRateLimit(request, env) {
  const ip = request.headers.get('cf-connecting-ip') || 'unknown';
  const ipHash = await sha256Hex(ip);

  const row = await env.DB.prepare(
    `SELECT COUNT(*) AS hits FROM submit_log
     WHERE ip_hash = ? AND created_at > unixepoch() - ?`
  )
    .bind(ipHash, RATE_WINDOW_SECONDS)
    .first();

  if ((row?.hits ?? 0) >= RATE_LIMIT_PER_WINDOW) return false;

  // 기록 + 오래된 행 청소를 한 번의 왕복으로 처리
  await env.DB.batch([
    env.DB.prepare(`INSERT INTO submit_log (ip_hash) VALUES (?)`).bind(ipHash),
    env.DB.prepare(
      `DELETE FROM submit_log WHERE created_at < unixepoch() - ?`
    ).bind(RATE_LOG_RETENTION_SECONDS),
  ]);

  return true;
}

async function sha256Hex(value) {
  const digest = await crypto.subtle.digest(
    'SHA-256',
    new TextEncoder().encode(value)
  );
  return [...new Uint8Array(digest)]
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('');
}

// 'YYYY-MM-DD' (UTC). 앱의 daily_challenge.dart dayKey 와 같은 규칙이어야
// 한다 — 다르면 플레이어의 '오늘' 점수가 어제 순위표로 들어간다.
function todayKey() {
  return new Date().toISOString().slice(0, 10);
}

function normalizeDay(value) {
  return /^\d{4}-\d{2}-\d{2}$/.test(value ?? '') ? value : null;
}

async function listDailyScores(request, env) {
  const url = new URL(request.url);
  const day = normalizeDay(url.searchParams.get('day')) ?? todayKey();
  const limit = clamp(Number(url.searchParams.get('limit') || 50), 1, MAX_LIMIT);

  const { results } = await env.DB.prepare(
    `SELECT nickname, score, locale, platform, updated_at
     FROM daily_scores
     WHERE day = ?
     ORDER BY score DESC, updated_at ASC
     LIMIT ?`
  )
    .bind(day, limit)
    .all();

  return json({ day, scores: results ?? [] });
}

async function submitDailyScore(request, env) {
  let payload;
  try {
    payload = await request.json();
  } catch {
    return json({ error: 'invalid_body' }, 400);
  }
  if (payload === null || typeof payload !== 'object') {
    return json({ error: 'invalid_body' }, 400);
  }

  const playerId = normalizeText(payload.playerId, 64);
  const nickname = normalizeText(payload.nickname, 24) || 'Unknown Hero';
  const locale = normalizeText(payload.locale, 8) || 'ko';
  const platform = normalizeText(payload.platform, 24) || 'unknown';
  const score = Number(payload.score);

  // 클라이언트가 보낸 day 는 신뢰하지 않는다 — 서버 시각으로 고정한다.
  // 그렇지 않으면 지난 날짜 순위표에 점수를 밀어 넣을 수 있다.
  const day = todayKey();

  // 같은 15문항·같은 점수식이므로 전체 순위표와 상한을 공유한다.
  if (!playerId || !Number.isInteger(score) || score < 0 || score > MAX_SCORE) {
    return json({ error: 'invalid_score', maxScore: MAX_SCORE }, 400);
  }

  await env.DB.prepare(
    `INSERT INTO daily_scores (day, player_id, nickname, score, locale, platform)
     VALUES (?, ?, ?, ?, ?, ?)
     ON CONFLICT(day, player_id) DO UPDATE SET
       nickname = excluded.nickname,
       score = MAX(daily_scores.score, excluded.score),
       locale = excluded.locale,
       platform = excluded.platform,
       updated_at = unixepoch()`
  )
    .bind(day, playerId, nickname, score, locale, platform)
    .run();

  const saved = await env.DB.prepare(
    `SELECT score FROM daily_scores WHERE day = ? AND player_id = ?`
  )
    .bind(day, playerId)
    .first();

  const rank = await env.DB.prepare(
    `SELECT COUNT(*) + 1 AS rank FROM daily_scores WHERE day = ? AND score > ?`
  )
    .bind(day, saved?.score ?? score)
    .first();

  return json({
    ok: true,
    day,
    rank: rank?.rank ?? null,
    score: saved?.score ?? score,
  });
}

async function submitScore(request, env) {
  let payload;
  try {
    payload = await request.json();
  } catch {
    return json({ error: 'invalid_body' }, 400);
  }
  if (payload === null || typeof payload !== 'object') {
    return json({ error: 'invalid_body' }, 400);
  }

  const playerId = normalizeText(payload.playerId, 64);
  const nickname = normalizeText(payload.nickname, 24) || 'Unknown Hero';
  const locale = normalizeText(payload.locale, 8) || 'ko';
  const platform = normalizeText(payload.platform, 24) || 'unknown';
  const score = Number(payload.score);

  if (!playerId || !Number.isInteger(score) || score < 0 || score > MAX_SCORE) {
    return json({ error: 'invalid_score', maxScore: MAX_SCORE }, 400);
  }

  await env.DB.prepare(
    `INSERT INTO scores (player_id, nickname, score, locale, platform)
     VALUES (?, ?, ?, ?, ?)
     ON CONFLICT(player_id) DO UPDATE SET
       nickname = excluded.nickname,
       score = MAX(scores.score, excluded.score),
       locale = excluded.locale,
       platform = excluded.platform,
       updated_at = unixepoch()`
  )
    .bind(playerId, nickname, score, locale, platform)
    .run();

  const saved = await env.DB.prepare(
    `SELECT score FROM scores WHERE player_id = ?`
  )
    .bind(playerId)
    .first();

  const rank = await env.DB.prepare(
    `SELECT COUNT(*) + 1 AS rank FROM scores WHERE score > ?`
  )
    .bind(saved?.score ?? score)
    .first();

  return json({ ok: true, rank: rank?.rank ?? null, score: saved?.score ?? score });
}

async function renderLeaderboard(request, env) {
  const url = new URL(request.url);
  const lang = languageFor(url.searchParams.get('lang'));
  const copy = COPY[lang];

  const { results } = await env.DB.prepare(
    `SELECT nickname, score, locale, updated_at
     FROM scores
     ORDER BY score DESC, updated_at ASC
     LIMIT 100`
  ).all();

  const rows = (results ?? [])
    .map(
      (score, index) => `
        <tr class="${index < 3 ? `podium podium-${index + 1}` : ''}">
          <td class="rank"><span>${index + 1}</span></td>
          <td>
            <div class="hero-cell">
              <span class="flag" title="${escapeHtml(regionLabel(score.locale))}">${flagForLocale(score.locale)}</span>
              <span class="hero-name">${escapeHtml(score.nickname)}</span>
            </div>
          </td>
          <td class="score">${Number(score.score).toLocaleString('en-US')}</td>
        </tr>`
    )
    .join('');

  const top = (results ?? [])[0];

  return `<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>${escapeHtml(copy.title)} ${escapeHtml(copy.ranking)}</title>
  <style>
    :root {
      color-scheme: dark;
      --paper: #fff1c5;
      --gold: #f2bd58;
      --red: #b33d28;
      --ink: #17100b;
      --muted: #d9bf89;
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      min-height: 100vh;
      font-family: ui-serif, Georgia, "Times New Roman", "Noto Serif KR", serif;
      background:
        linear-gradient(180deg, rgba(5, 4, 3, .18), rgba(5, 4, 3, .94)),
        radial-gradient(circle at 18% 18%, rgba(221, 70, 39, .3), transparent 28%),
        url("/assets/leaderboard-bg.jpg") center top / cover fixed no-repeat,
        linear-gradient(135deg, #3a1c10 0%, #120b08 48%, #050403 100%);
      color: var(--paper);
      overflow-x: hidden;
    }
    main {
      position: relative;
      width: min(1040px, calc(100% - 32px));
      margin: 0 auto;
      padding: clamp(28px, 6vw, 74px) 0 48px;
    }
    .hero {
      min-height: clamp(220px, 34vh, 340px);
      display: grid;
      align-content: end;
      padding-bottom: 24px;
    }
    .eyebrow {
      width: fit-content;
      margin: 0 0 18px;
      padding: 7px 12px;
      border: 1px solid rgba(242, 189, 88, .45);
      border-radius: 999px;
      color: var(--muted);
      font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Noto Sans KR", sans-serif;
      font-size: 10px;
      font-weight: 800;
      letter-spacing: .18em;
      text-transform: uppercase;
      background: rgba(0, 0, 0, .28);
      backdrop-filter: blur(8px);
    }
    .lang-switcher {
      position: absolute;
      top: clamp(18px, 4vw, 34px);
      right: 0;
      display: flex;
      gap: 8px;
      padding: 6px;
      border: 1px solid rgba(242, 189, 88, .22);
      border-radius: 999px;
      background: rgba(0, 0, 0, .34);
      backdrop-filter: blur(10px);
    }
    .lang-switcher a {
      display: inline-grid;
      place-items: center;
      width: 38px;
      height: 38px;
      border-radius: 50%;
      color: inherit;
      text-decoration: none;
      font-family: "Apple Color Emoji", "Segoe UI Emoji", sans-serif;
      font-size: 22px;
      opacity: .62;
    }
    .lang-switcher a.active {
      background: rgba(242, 189, 88, .18);
      box-shadow: inset 0 0 0 1px rgba(242, 189, 88, .38);
      opacity: 1;
    }
    h1 {
      max-width: 880px;
      margin: 0;
      color: var(--gold);
      font-size: clamp(42px, 8.5vw, 96px);
      line-height: .98;
      letter-spacing: 0;
      text-shadow: 0 8px 28px rgba(0,0,0,.72);
    }
    .subtitle {
      max-width: 680px;
      margin: 14px 0 0;
      color: rgba(255, 241, 197, .84);
      font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Noto Sans KR", sans-serif;
      font-size: clamp(14px, 1.7vw, 18px);
      font-weight: 650;
      line-height: 1.45;
    }
    .top-card {
      display: grid;
      grid-template-columns: minmax(0, 1fr) auto;
      gap: 18px;
      align-items: end;
      margin: 8px 0 16px;
      padding: 18px;
      border: 1px solid rgba(242, 189, 88, .32);
      border-radius: 14px;
      background: linear-gradient(135deg, rgba(0,0,0,.72), rgba(72, 31, 16, .54));
      box-shadow: 0 24px 80px rgba(0, 0, 0, .32);
      backdrop-filter: blur(12px);
    }
    .top-label {
      margin: 0 0 8px;
      color: var(--muted);
      font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Noto Sans KR", sans-serif;
      font-size: 10px;
      font-weight: 900;
      letter-spacing: .2em;
      text-transform: uppercase;
    }
    .top-name {
      display: flex;
      align-items: center;
      gap: 18px;
      margin: 0;
      font-size: clamp(23px, 3.8vw, 40px);
      line-height: .95;
      color: var(--paper);
    }
    .top-flag {
      width: 56px;
      height: 56px;
      font-size: 32px;
    }
    .top-score {
      color: var(--gold);
      font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, sans-serif;
      font-size: clamp(25px, 4.4vw, 46px);
      font-weight: 950;
      line-height: .9;
      font-variant-numeric: tabular-nums;
      white-space: nowrap;
    }
    .board {
      position: relative;
      overflow: hidden;
      border: 1px solid rgba(242, 189, 88, .26);
      border-radius: 14px;
      background: rgba(5, 4, 3, .68);
      box-shadow: 0 28px 90px rgba(0,0,0,.36);
      backdrop-filter: blur(16px);
    }
    table {
      width: 100%;
      border-collapse: collapse;
    }
    th, td {
      padding: 13px 16px;
      border-bottom: 1px solid rgba(255,255,255,.08);
      text-align: left;
    }
    th {
      color: var(--muted);
      font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Noto Sans KR", sans-serif;
      font-size: 10px;
      font-weight: 900;
      letter-spacing: .16em;
      text-transform: uppercase;
    }
    tbody tr:last-child td { border-bottom: 0; }
    tbody tr:hover { background: rgba(255,255,255,.045); }
    .rank {
      width: 74px;
      color: var(--gold);
      font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, sans-serif;
      font-weight: 950;
      font-size: 16px;
    }
    .rank span {
      display: inline-grid;
      place-items: center;
      width: 32px;
      height: 32px;
      border-radius: 50%;
      background: rgba(242, 189, 88, .1);
    }
    .podium-1 .rank span { background: rgba(242, 189, 88, .24); }
    .podium-2 .rank span,
    .podium-3 .rank span { background: rgba(255,255,255,.12); }
    .hero-cell {
      display: flex;
      align-items: center;
      min-width: 0;
      gap: 13px;
    }
    .flag {
      display: inline-grid;
      place-items: center;
      flex: 0 0 auto;
      width: 34px;
      height: 34px;
      border-radius: 50%;
      background: rgba(255,255,255,.1);
      box-shadow: inset 0 0 0 1px rgba(255,255,255,.14);
      font-family: "Apple Color Emoji", "Segoe UI Emoji", sans-serif;
      font-size: 20px;
    }
    .hero-name {
      overflow: hidden;
      text-overflow: ellipsis;
      white-space: nowrap;
      color: var(--paper);
      font-size: clamp(16px, 2.1vw, 23px);
      line-height: 1;
    }
    .score {
      width: 150px;
      color: var(--gold);
      font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, sans-serif;
      font-size: clamp(17px, 2.6vw, 26px);
      font-weight: 950;
      text-align: right;
      font-variant-numeric: tabular-nums;
      white-space: nowrap;
    }
    .empty {
      padding: 52px 28px;
      text-align: center;
      color: var(--muted);
      font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Noto Sans KR", sans-serif;
    }
    .appstore-cta {
      display: flex;
      justify-content: center;
      margin: 22px 0 4px;
    }
    .appstore-link {
      display: inline-flex;
      align-items: center;
      gap: 11px;
      padding: 11px 18px 11px 16px;
      border-radius: 12px;
      background: #000;
      color: #fff;
      text-decoration: none;
      border: 1px solid rgba(255,255,255,.22);
      font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Noto Sans KR", sans-serif;
      transition: transform .18s ease, box-shadow .18s ease, border-color .18s ease;
    }
    .appstore-link:hover {
      transform: translateY(-2px);
      box-shadow: 0 18px 40px rgba(0,0,0,.5);
      border-color: rgba(242, 189, 88, .55);
    }
    .appstore-link svg {
      width: 28px;
      height: 28px;
      fill: #fff;
      flex: 0 0 auto;
    }
    .appstore-text {
      display: flex;
      flex-direction: column;
      line-height: 1;
      text-align: left;
    }
    .appstore-text small {
      font-size: 10px;
      letter-spacing: .04em;
      opacity: .82;
    }
    .appstore-text strong {
      margin-top: 3px;
      font-size: 18px;
      font-weight: 600;
      letter-spacing: -.02em;
    }
    @media (max-width: 620px) {
      main { width: min(100% - 20px, 1040px); padding-top: 22px; }
      .lang-switcher { left: 0; right: auto; }
      .hero { min-height: 250px; }
      .top-card { grid-template-columns: 1fr; padding: 18px; }
      .top-score { justify-self: start; }
      .top-flag { width: 48px; height: 48px; font-size: 28px; }
      th, td { padding: 12px 10px; }
      th:nth-child(1), .rank { width: 52px; }
      .rank span { width: 28px; height: 28px; font-size: 14px; }
      .flag { width: 30px; height: 30px; font-size: 18px; }
      .score { width: 100px; }
    }
  </style>
</head>
<body>
  <main>
    <nav class="lang-switcher" aria-label="Language">
      ${languageLink('ko', lang)}
      ${languageLink('en', lang)}
      ${languageLink('zh', lang)}
      ${languageLink('ja', lang)}
    </nav>
    <section class="hero">
      <div class="eyebrow">${escapeHtml(copy.eyebrow)}</div>
      <h1>${copy.heading}</h1>
      <p class="subtitle">${escapeHtml(copy.subtitle)}</p>
    </section>
    <div class="appstore-cta">
      <a class="appstore-link" href="${APP_STORE_URL}" target="_blank" rel="noopener">
        <svg viewBox="0 0 24 24" aria-hidden="true">
          <path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z"/>
        </svg>
        <span class="appstore-text">
          <small>${escapeHtml(copy.downloadOn)}</small>
          <strong>App Store</strong>
        </span>
      </a>
    </div>
    ${
      top
        ? `<section class="top-card">
            <div>
              <p class="top-label">${escapeHtml(copy.champion)}</p>
              <h2 class="top-name"><span class="flag top-flag" title="${escapeHtml(regionLabel(top.locale))}">${flagForLocale(top.locale)}</span> <span>${escapeHtml(top.nickname)}</span></h2>
            </div>
            <div class="top-score">${Number(top.score).toLocaleString('en-US')}</div>
          </section>`
        : ''
    }
    ${
      rows
        ? `<section class="board"><table><thead><tr><th>#</th><th>${escapeHtml(copy.hero)}</th><th>${escapeHtml(copy.score)}</th></tr></thead><tbody>${rows}</tbody></table></section>`
        : `<div class="empty">${escapeHtml(copy.empty)}</div>`
    }
  </main>
</body>
</html>`;
}

function json(value, status = 200) {
  return new Response(JSON.stringify(value), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8' },
  });
}

function html(value) {
  return new Response(value, {
    headers: { 'content-type': 'text/html; charset=utf-8' },
  });
}

function withCors(response) {
  const headers = new Headers(response.headers);
  headers.set('access-control-allow-origin', '*');
  headers.set('access-control-allow-methods', 'GET,POST,OPTIONS');
  headers.set('access-control-allow-headers', 'content-type');
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}

function normalizeText(value, maxLength) {
  if (typeof value !== 'string') return '';
  return value.trim().replace(/\s+/g, ' ').slice(0, maxLength);
}

function clamp(value, min, max) {
  if (!Number.isFinite(value)) return min;
  return Math.max(min, Math.min(max, Math.floor(value)));
}

function flagForLocale(locale) {
  const normalized = normalizeLocale(locale);
  const flags = {
    ko: '🇰🇷',
    kr: '🇰🇷',
    zh: '🇨🇳',
    cn: '🇨🇳',
    'zh-cn': '🇨🇳',
    'zh-hans': '🇨🇳',
    'zh-tw': '🇹🇼',
    'zh-hant': '🇹🇼',
    ja: '🇯🇵',
    jp: '🇯🇵',
    en: '🇺🇸',
    'en-us': '🇺🇸',
    'en-gb': '🇬🇧',
    'en-au': '🇦🇺',
    'en-ca': '🇨🇦',
    'en-nz': '🇳🇿',
    'en-ie': '🇮🇪',
    'en-sg': '🇸🇬',
  };
  return flags[normalized] ?? '🌐';
}

const COPY = {
  ko: {
    title: '삼국지 덕력고사',
    ranking: '랭킹',
    eyebrow: 'GLOBAL WAR COUNCIL',
    heading: '삼국지<br>덕력고사',
    subtitle: '천하의 영웅들이 겨루는 지식의 전장. 오늘의 군략가는 누구인가.',
    champion: '현재 천하제일',
    hero: '영웅',
    score: '점수',
    empty: '아직 등록된 점수가 없습니다.',
    downloadOn: '다음에서 다운로드',
  },
  en: {
    title: 'Three Kingdoms Quiz',
    ranking: 'Ranking',
    eyebrow: 'GLOBAL WAR COUNCIL',
    heading: 'Three<br>Kingdoms',
    subtitle: 'A battlefield of wit where heroes across the realm compete for glory.',
    champion: 'Current Champion',
    hero: 'Hero',
    score: 'Score',
    empty: 'No scores have been recorded yet.',
    downloadOn: 'Download on the',
  },
  zh: {
    title: '三国英雄试炼',
    ranking: '排行榜',
    eyebrow: '天下军议',
    heading: '三国<br>英雄试炼',
    subtitle: '群雄逐鹿的知识战场，今日谁能问鼎天下。',
    champion: '当前霸主',
    hero: '英雄',
    score: '分数',
    empty: '尚无排行榜记录。',
    downloadOn: '下载',
  },
  ja: {
    title: '三国志英雄検定',
    ranking: 'ランキング',
    eyebrow: '天下軍議',
    heading: '三国志<br>英雄検定',
    subtitle: '天下の英雄たちが知略を競う戦場。今日の覇者は誰か。',
    champion: '現在の覇者',
    hero: '英雄',
    score: 'スコア',
    empty: 'まだスコアが登録されていません。',
    downloadOn: 'ダウンロード元',
  },
};

const APP_STORE_URL = 'https://apps.apple.com/app/id6762790807';

function languageFor(value) {
  const normalized = normalizeLocale(value).split('-')[0];
  return ['ko', 'en', 'zh', 'ja'].includes(normalized) ? normalized : 'ko';
}

function languageLink(lang, current) {
  const flags = { ko: '🇰🇷', en: '🇺🇸', zh: '🇨🇳', ja: '🇯🇵' };
  const labels = {
    ko: '한국어',
    en: 'English',
    zh: '中文',
    ja: '日本語',
  };
  return `<a class="${lang === current ? 'active' : ''}" href="/?lang=${lang}" title="${labels[lang]}" aria-label="${labels[lang]}">${flags[lang]}</a>`;
}

function regionLabel(locale) {
  const normalized = normalizeLocale(locale);
  const labels = {
    ko: 'Korea',
    kr: 'Korea',
    zh: 'China',
    cn: 'China',
    'zh-cn': 'China',
    'zh-hans': 'China',
    'zh-tw': 'Taiwan',
    'zh-hant': 'Taiwan',
    ja: 'Japan',
    jp: 'Japan',
    en: 'United States',
    'en-us': 'United States',
    'en-gb': 'United Kingdom',
    'en-au': 'Australia',
    'en-ca': 'Canada',
    'en-nz': 'New Zealand',
    'en-ie': 'Ireland',
    'en-sg': 'Singapore',
  };
  return labels[normalized] ?? 'Global';
}

function normalizeLocale(locale) {
  return String(locale || '')
    .trim()
    .toLowerCase()
    .replaceAll('_', '-');
}

function escapeHtml(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}
