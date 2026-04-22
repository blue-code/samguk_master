const MAX_LIMIT = 100;

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

      if (url.pathname === '/api/scores' && request.method === 'POST') {
        return withCors(await submitScore(request, env));
      }

      if (url.pathname === '/' && request.method === 'GET') {
        return html(await renderLeaderboard(env));
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

async function submitScore(request, env) {
  const payload = await request.json();
  const playerId = normalizeText(payload.playerId, 64);
  const nickname = normalizeText(payload.nickname, 24) || 'Unknown Hero';
  const locale = normalizeText(payload.locale, 8) || 'ko';
  const platform = normalizeText(payload.platform, 24) || 'unknown';
  const score = Number(payload.score);

  if (!playerId || !Number.isInteger(score) || score < 0 || score > 1000000) {
    return json({ error: 'invalid_score' }, 400);
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

async function renderLeaderboard(env) {
  const { results } = await env.DB.prepare(
    `SELECT nickname, score, locale, updated_at
     FROM scores
     ORDER BY score DESC, updated_at ASC
     LIMIT 100`
  ).all();

  const rows = (results ?? [])
    .map(
      (score, index) => `
        <tr>
          <td class="rank">${index + 1}</td>
          <td>${escapeHtml(score.nickname)}</td>
          <td class="score">${score.score.toLocaleString('en-US')}</td>
          <td>${escapeHtml(score.locale.toUpperCase())}</td>
        </tr>`
    )
    .join('');

  return `<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>삼국지 덕력고사 랭킹</title>
  <style>
    :root { color-scheme: dark; }
    body {
      margin: 0;
      min-height: 100vh;
      font-family: ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Noto Sans KR", sans-serif;
      background: radial-gradient(circle at top, #583112 0, #17100c 42%, #080706 100%);
      color: #fff7df;
    }
    main { width: min(920px, calc(100% - 32px)); margin: 0 auto; padding: 48px 0; }
    h1 { margin: 0 0 10px; font-size: clamp(42px, 8vw, 88px); color: #f7c256; line-height: .95; }
    p { margin: 0 0 28px; color: #d8c7a0; }
    table { width: 100%; border-collapse: collapse; overflow: hidden; border-radius: 12px; background: rgba(0,0,0,.42); }
    th, td { padding: 16px 18px; border-bottom: 1px solid rgba(255,255,255,.08); text-align: left; }
    th { color: #f7c256; font-size: 13px; letter-spacing: .12em; text-transform: uppercase; }
    .rank { width: 56px; color: #f7c256; font-weight: 800; }
    .score { font-variant-numeric: tabular-nums; font-weight: 800; }
    .empty { padding: 36px; text-align: center; color: #d8c7a0; }
  </style>
</head>
<body>
  <main>
    <h1>삼국지 덕력고사</h1>
    <p>천하의 고수들이 겨루는 글로벌 랭킹</p>
    ${
      rows
        ? `<table><thead><tr><th>#</th><th>영웅</th><th>점수</th><th>언어</th></tr></thead><tbody>${rows}</tbody></table>`
        : `<div class="empty">아직 등록된 점수가 없습니다.</div>`
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

function escapeHtml(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#039;');
}
