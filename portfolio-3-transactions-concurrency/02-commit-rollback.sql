-- =====================================================================
-- Portfolio 3 — COMMIT vs ROLLBACK
-- A TRANSACTION groups statements so they succeed or fail as ONE unit.
--   COMMIT   = make all the changes permanent.
--   ROLLBACK = undo everything since the transaction began.
-- This is the "all or nothing" guarantee (atomicity).
-- =====================================================================

-- Show the starting value.
SELECT 'START' AS stage, total_points FROM leaderboard_totals WHERE player_id=42 AND game_id=2;

-- ---------- ROLLBACK demo: change, then change our mind ----------
BEGIN;
    UPDATE leaderboard_totals SET total_points = total_points + 500
    WHERE player_id=42 AND game_id=2;
    -- Inside the transaction, THIS session sees 1500...
    SELECT 'inside txn (before rollback)' AS stage, total_points
    FROM leaderboard_totals WHERE player_id=42 AND game_id=2;
ROLLBACK;  -- ...but we undo it.

-- After ROLLBACK the value is back to 1000 — the change never happened.
SELECT 'after ROLLBACK' AS stage, total_points FROM leaderboard_totals WHERE player_id=42 AND game_id=2;

-- ---------- COMMIT demo: change and keep it ----------
BEGIN;
    UPDATE leaderboard_totals SET total_points = total_points + 500, updated_at = now()
    WHERE player_id=42 AND game_id=2;
COMMIT;  -- make it permanent.

-- After COMMIT the value is 1500 and stays that way.
SELECT 'after COMMIT' AS stage, total_points FROM leaderboard_totals WHERE player_id=42 AND game_id=2;

-- ---------- Atomicity demo: a failing statement rolls the whole txn back ----------
-- We try two updates; the second violates the CHECK (total can't go negative),
-- so the WHOLE transaction is aborted and the first update is undone too.
BEGIN;
    UPDATE leaderboard_totals SET total_points = total_points + 100 WHERE player_id=42 AND game_id=2;
    UPDATE leaderboard_totals SET total_points = -5 WHERE player_id=42 AND game_id=2; -- fails CHECK
COMMIT;  -- Postgres aborts the txn; nothing from this BEGIN is kept.

-- Still 1500 — the +100 was discarded because its transaction failed as a unit.
SELECT 'after failed txn' AS stage, total_points FROM leaderboard_totals WHERE player_id=42 AND game_id=2;

-- Reset to 1000 for the concurrency experiments that follow.
UPDATE leaderboard_totals SET total_points = 1000 WHERE player_id=42 AND game_id=2;
