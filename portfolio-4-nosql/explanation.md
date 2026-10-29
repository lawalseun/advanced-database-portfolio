# NoSQL & Advanced Data Models — Redis Leaderboard (ArenaPulse)

**NoSQL store:** Redis 7 (an in-memory key-value database).
All results in `evidence/` are real captured output.

## 1. What NoSQL is, and which type we chose
**NoSQL** ("Not Only SQL") covers databases that don't use the rows-and-tables
relational model. The main families are **key-value**, **document**, **column**
and **graph**. For a real-time leaderboard the natural fit is a **key-value
store with a sorted collection** — and **Redis** provides exactly that with its
**sorted set** type.

## 2. The data model
Instead of computing rankings from tables at query time (as SQL must), Redis
keeps the leaderboard **permanently ordered by score**:

| Purpose | Redis type | Key | Holds |
|---------|-----------|-----|-------|
| The live leaderboard | **Sorted set** | `leaderboard:game:2` | each player as a *member*, their points as the *score*; Redis keeps it ordered by score at all times |
| A player's profile | **Hash** (document style) | `player:shadowfox` | fields like `country`, `games_played` |

A sorted set is the key idea: every member has a numeric score, and Redis
maintains the ordering automatically, so ranking questions need no sorting or
scanning at read time.

## 3. The operations (and the case study's verbs)
From `evidence/01-redis-commands.txt`:

| Case-study need | Redis command | Cost |
|-----------------|---------------|------|
| **Update score** (new points) | `ZADD` / `ZINCRBY` (adds and re-ranks atomically) | O(log N) |
| **Retrieve ranking** — top N | `ZREVRANGE key 0 9 WITHSCORES` | O(log N + 10) |
| **A player's rank** | `ZREVRANK key player` | O(log N) |
| A player's score | `ZSCORE key player` | O(1) |
| How many players | `ZCARD key` | O(1) |
| A slice of the board (e.g. ranks 2–4) | `ZREVRANGE key 1 3` | O(log N + range) |
| Manage profile | `HSET` / `HGETALL` | O(1) per field |

`ZINCRBY` matters for concurrency too: it adds points **atomically** in one
operation, so the lost-update problem from Portfolio 3 simply cannot happen for
a score add — there is no separate read-then-write to interleave.

## 4. Why Redis suits this better than SQL — with numbers
From `evidence/02-benchmark-redis-vs-sql.txt`, same data (5,003 ranked players),
median of 7 runs:

| Operation | PostgreSQL | Redis | Speed-up |
|-----------|-----------|-------|----------|
| Top 10 players | ~66 ms | ~0.5 ms | **~130×** |
| A player's rank | ~84 ms | ~0.4 ms | **~206×** |

The reason is structural, not just "Redis is in memory":
- **SQL** has to aggregate each player's best score, **sort** everyone, and only
  then take the top 10 or find one player's position — work that grows with the
  whole table every time (this is the exact limit we measured in Portfolio 2).
- **Redis** already stores the data **in ranked order**, so "top 10" reads the
  first 10 entries and "a player's rank" is a direct O(log N) lookup — no sort,
  no scan.

For a leaderboard that updates and is read constantly, this is the difference
between a sluggish and an instant experience.

## 5. Trade-offs (why we still keep PostgreSQL too)
Redis is the right tool for the *live ranking*, but not for everything:
- **Limited querying.** Redis answers the ranking questions it is shaped for; it
  cannot do the rich ad-hoc joins and filters SQL does (e.g. "average score by
  country for sessions on Android last week"). Those stay in PostgreSQL.
- **Memory-bound.** Redis keeps data in RAM, so the dataset must fit in memory.
- **Durability.** Being in-memory, Redis needs a persistence option to survive a
  restart: **RDB** (periodic snapshots) or **AOF** (append-only log of every
  write). A leaderboard typically enables one of these, accepting that the
  authoritative scores also live safely in PostgreSQL.

**The real architecture** (and ArenaPulse's): PostgreSQL is the **source of
truth** for all data; Redis is a **fast serving layer** for the live leaderboard,
kept in step by `ZADD`/`ZINCRBY` whenever a score is recorded. This is the
standard way real games build leaderboards.

## 6. How this connects to the rest of the portfolio
- Portfolio 2 measured *why* SQL ranking is slow at scale (full scans).
- Portfolio 3 showed the concurrency hazard of score updates; `ZINCRBY` sidesteps
  it atomically.
- Portfolio 5 extends this: how the Redis + PostgreSQL setup is replicated and
  distributed across machines for availability and scale.
