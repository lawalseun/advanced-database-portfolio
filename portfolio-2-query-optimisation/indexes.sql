-- =====================================================================
-- Portfolio 2 — Indexes
-- An index is a lookup structure (like a book's index) that lets the
-- database jump straight to matching rows instead of scanning every row.
-- Each index below targets a specific slow spot seen in the "before" plans.
-- =====================================================================

-- For Q2 (a player's history): find a player's sessions without scanning all.
-- PostgreSQL does NOT auto-index foreign keys, so we add this ourselves.
CREATE INDEX idx_sessions_player ON game_sessions (player_id);

-- For Q1 & Q3 (per-game leaderboards): jump to one game's sessions.
CREATE INDEX idx_sessions_game ON game_sessions (game_id);

-- For every scores→sessions join: look up a session's score directly.
CREATE INDEX idx_scores_session ON scores (session_id);

-- For Q3 (recent high scores): a composite index on the filter+sort columns,
-- so "recent scores, highest first" can be read in order from the index.
CREATE INDEX idx_scores_achieved_points ON scores (achieved_at, points DESC);

-- Update planner statistics so the optimiser notices the new indexes.
ANALYZE;
