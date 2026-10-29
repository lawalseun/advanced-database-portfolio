# Portfolio 4 — NoSQL & Advanced Data Models

**Case study:** ArenaPulse — Real-time Game Leaderboard
**NoSQL store:** Redis 7 (with PostgreSQL 16 as the source of truth for the benchmark)

## What this folder contains
| File | What it is |
|------|------------|
| `redis-commands.sh` | A readable walkthrough of every leaderboard operation in Redis, using named players. |
| `load_and_benchmark.py` | Loads ~5,000 players into a Redis sorted set and times Redis vs PostgreSQL on the same queries. |
| `explanation.md` | Plain-language write-up: the data model, operations, why Redis fits, and the trade-offs. |
| `evidence/01-redis-commands.txt` | Captured output of the Redis walkthrough. |
| `evidence/02-benchmark-redis-vs-sql.txt` | Captured benchmark results. |

## The short version
Real games don't rank players with SQL at read time — they use a **Redis sorted
set**, which keeps the leaderboard permanently ordered by score. That makes the
two constant leaderboard questions almost free:
- **Top 10:** `ZREVRANGE leaderboard:game:2 0 9 WITHSCORES`
- **A player's rank:** `ZREVRANK leaderboard:game:2 <player>`
- **Update a score:** `ZINCRBY` (adds and re-ranks atomically — also dodges the
  Portfolio 3 lost-update problem).

**Measured on the same 5,003-player dataset:** Redis was **~130× faster** for
top-10 and **~206× faster** for a player's rank than the equivalent SQL.

PostgreSQL stays the source of truth for everything (and for rich queries Redis
can't do); Redis is the fast serving layer for the live ranking.

## How to reproduce
```bash
redis-server --port 6380 --daemonize yes
bash redis-commands.sh
python3 load_and_benchmark.py     # needs the arenapulse Postgres DB from P1–P2
```
(Requires the `redis` and `psycopg2` Python packages.)
