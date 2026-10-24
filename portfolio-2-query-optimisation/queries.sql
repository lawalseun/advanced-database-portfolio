-- =====================================================================
-- Portfolio 2 — Business queries for ArenaPulse
-- These are the real questions the leaderboard must answer.
-- Each is written in plain SQL and explained in a comment.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Q1. LEADERBOARD: Top 10 players for a given game, by their best score.
-- This is the headline leaderboard query.
-- ---------------------------------------------------------------------
SELECT p.username,
       MAX(sc.points) AS best_score
FROM scores sc
JOIN game_sessions gs ON gs.session_id = sc.session_id
JOIN players p        ON p.player_id   = gs.player_id
WHERE gs.game_id = 2
GROUP BY p.username
ORDER BY best_score DESC
LIMIT 10;

-- ---------------------------------------------------------------------
-- Q2. A SINGLE PLAYER'S HISTORY: every session + score for one player.
-- Powers a player's profile page. Filters by player_id.
-- ---------------------------------------------------------------------
SELECT g.title,
       gs.started_at,
       sc.points
FROM game_sessions gs
JOIN games  g  ON g.game_id    = gs.game_id
LEFT JOIN scores sc ON sc.session_id = gs.session_id
WHERE gs.player_id = 42
ORDER BY gs.started_at DESC;

-- ---------------------------------------------------------------------
-- Q3. THIS WEEK'S LEADERS: top scores for a game in the last 7 days.
-- Filters on both game_id and a date range.
-- ---------------------------------------------------------------------
SELECT p.username,
       sc.points,
       sc.achieved_at
FROM scores sc
JOIN game_sessions gs ON gs.session_id = sc.session_id
JOIN players p        ON p.player_id   = gs.player_id
WHERE gs.game_id = 2
  AND sc.achieved_at >= now() - interval '7 days'
ORDER BY sc.points DESC
LIMIT 10;

-- ---------------------------------------------------------------------
-- Q4. A PLAYER'S ACHIEVEMENTS: list what a player has unlocked.
-- Demonstrates the many-to-many join via player_achievements.
-- ---------------------------------------------------------------------
SELECT p.username,
       a.name        AS achievement,
       a.points_reward,
       pa.unlocked_at
FROM player_achievements pa
JOIN achievements a ON a.achievement_id = pa.achievement_id
JOIN players p      ON p.player_id      = pa.player_id
WHERE p.username = 'queen_bee'
ORDER BY pa.unlocked_at;

-- ---------------------------------------------------------------------
-- Q5. GLOBAL ACTIVITY: number of sessions and average score per game.
-- A reporting/analytics query across the whole dataset.
-- ---------------------------------------------------------------------
SELECT g.title,
       count(DISTINCT gs.session_id) AS sessions,
       round(avg(sc.points), 1)      AS avg_points,
       max(sc.points)                AS top_score
FROM games g
JOIN game_sessions gs ON gs.game_id    = g.game_id
JOIN scores sc        ON sc.session_id = gs.session_id
GROUP BY g.title
ORDER BY sessions DESC;
