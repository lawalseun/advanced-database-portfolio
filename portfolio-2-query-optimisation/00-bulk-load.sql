-- =====================================================================
-- Portfolio 2 — bulk data load
-- Purpose: grow the dataset so indexing and performance differences are
-- real and measurable (the small Portfolio 1 seed is too tiny to show them).
-- Adds ~5,000 players and ~60,000 sessions+scores.
-- Safe to run on top of the Portfolio 1 seed data.
-- =====================================================================

-- 5,000 extra players (usernames/emails made unique with the row number).
INSERT INTO players (username, email, country)
SELECT
    'player_' || g,
    'player_' || g || '@example.com',
    (ARRAY['NG','GH','KE','ZA','UG'])[1 + (g % 5)]
FROM generate_series(1, 5000) AS g;

-- ~60,000 sessions. We build them FROM real player rows (12 sessions each),
-- so every player_id is guaranteed to exist — no reliance on ID numbering.
INSERT INTO game_sessions (player_id, game_id, device, started_at, ended_at)
SELECT
    p.player_id,
    1 + (random() * 2)::int,                              -- game 1, 2 or 3
    (ARRAY['android','ios'])[1 + (random())::int],
    ts,
    ts + (interval '1 minute' * (3 + random() * 12))      -- 3–15 min session
FROM players p
CROSS JOIN generate_series(1, 12) AS n
CROSS JOIN LATERAL (SELECT now() - (interval '30 days' * random()) AS ts) t;

-- One score per session that doesn't already have one (points 0–2000).
INSERT INTO scores (session_id, points, achieved_at)
SELECT
    gs.session_id,
    (random() * 2000)::int,
    gs.ended_at
FROM game_sessions gs
LEFT JOIN scores sc ON sc.session_id = gs.session_id
WHERE sc.session_id IS NULL;

-- Refresh planner statistics so EXPLAIN uses accurate row estimates.
ANALYZE;
