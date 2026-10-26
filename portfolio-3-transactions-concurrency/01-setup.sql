-- =====================================================================
-- Portfolio 3 — setup
-- A "leaderboard_totals" table holds each player's RUNNING TOTAL points per
-- game. This is the live figure the leaderboard ranks on, and it is what the
-- case study calls "update score": when a player finishes a session, we ADD
-- that session's points to their total.
--
-- Because this row is updated (not just inserted), it is the perfect place to
-- study transactions and concurrency — two updates at once can collide.
-- =====================================================================

DROP TABLE IF EXISTS leaderboard_totals CASCADE;

CREATE TABLE leaderboard_totals (
    player_id    BIGINT      NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
    game_id      BIGINT      NOT NULL REFERENCES games(game_id)     ON DELETE CASCADE,
    total_points BIGINT      NOT NULL DEFAULT 0,
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (player_id, game_id),
    CONSTRAINT chk_total_nonneg CHECK (total_points >= 0)
);

-- Seed one known row we will experiment on: player 42 in game 2, starting at 1000.
INSERT INTO leaderboard_totals (player_id, game_id, total_points)
VALUES (42, 2, 1000);

SELECT player_id, game_id, total_points FROM leaderboard_totals WHERE player_id = 42 AND game_id = 2;
