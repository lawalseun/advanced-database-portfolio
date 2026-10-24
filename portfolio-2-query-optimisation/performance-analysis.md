# Performance Analysis — Indexing the ArenaPulse Leaderboard

**Database:** PostgreSQL 16 · **Dataset:** 5,005 players · 60,066 sessions · 60,066 scores
All timings come from `EXPLAIN (ANALYZE, BUFFERS)` — real measured execution, not estimates.
Raw output is in `01-before-indexes.txt` and `02-after-indexes.txt`.

## What an index is (plain words)
An **index** is a separate, sorted lookup structure the database keeps for a
column — like the index at the back of a textbook. Instead of reading every row
("sequential scan") to find matches, the database jumps straight to them ("index
scan"). The trade-off: indexes take disk space and slightly slow down writes
(every INSERT must also update the index), so we add them only where they earn it.

## Headline result: Q2 (a single player's history)

This query finds all sessions for **one** player (`player_id = 42`) — just 12 rows
out of 60,066. This is where an index shines.

| | Plan used | Median of 5 runs |
|---|-----------|------------------|
| **Before index** | Sequential Scan — reads all 60,066 session rows | **~10.2 ms** |
| **After index** (`idx_sessions_player`) | Index Scan — jumps to the 12 matching rows | **~0.24 ms** |

**≈ 43× faster.** The "before" plan reads the whole table to find 12 rows; the
"after" plan uses `idx_sessions_player` to go straight to them. A second index,
`idx_scores_session`, then fetches each session's score by direct lookup instead
of scanning the scores table.

> Note: PostgreSQL does **not** automatically create indexes on foreign-key
> columns. `game_sessions.player_id` is a foreign key, but we still had to add the
> index ourselves — a common real-world gotcha.

## The honest result: Q1 (all-time top 10) did NOT speed up

| | Plan used | Execution time |
|---|-----------|----------------|
| Before | Seq Scan + hash aggregate | ~42 ms |
| After | Bitmap Index Scan on `idx_sessions_game` + Seq Scan on scores | ~55 ms (no better) |

**Why?** The all-time leaderboard for a game must look at **every** score for that
game — roughly half the entire table (29,877 of 60,066 sessions). When a query
needs a large fraction of the rows, reading them in bulk (a sequential scan) is
genuinely cheaper than bouncing through an index thousands of times. The planner
knows this, so forcing index use here would only add overhead.

**This is the key lesson:** indexes speed up **selective** queries (find a few
rows among many); they do little for **bulk aggregation** queries that touch most
of the table. A good design indexes the former and accepts a scan for the latter.

## Indexes created
| Index | Table (column) | Helps |
|-------|----------------|-------|
| `idx_sessions_player` | `game_sessions(player_id)` | Q2 — player history lookups |
| `idx_sessions_game` | `game_sessions(game_id)` | narrowing to one game's sessions |
| `idx_scores_session` | `scores(session_id)` | every scores→sessions join |
| `idx_scores_achieved_points` | `scores(achieved_at, points DESC)` | recent-high-score queries |

## How this points to Portfolio 4
Q1 shows the real limit of a relational database for *live* ranking: an all-time
"top N" needs a big scan every time it runs. This is exactly why real games keep
the leaderboard in a **Redis sorted set** (Portfolio 4), where "top 10" and "a
player's rank" are near-instant operations by design — no scan at all.
