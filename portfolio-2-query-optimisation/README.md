# Portfolio 2 — Query Processing & Optimisation

**Case study:** ArenaPulse — Real-time Game Leaderboard · **Database:** PostgreSQL 16

## What this folder contains
| File | What it is |
|------|------------|
| `00-bulk-load.sql` | Grows the dataset to ~60,000 scores so performance differences are real. |
| `queries.sql` | The five business queries the leaderboard must answer, each explained. |
| `indexes.sql` | The indexes added to speed up selective queries, with reasons. |
| `performance-analysis.md` | Before/after comparison and what the numbers mean. |
| `01-before-indexes.txt` | Real `EXPLAIN (ANALYZE, BUFFERS)` plans **before** indexing. |
| `02-after-indexes.txt` | Real execution plans **after** indexing. |
| `03-query-results.txt` | Actual output rows from the business queries. |

## The short version
- Built a realistic dataset (5,005 players, 60,066 sessions/scores).
- Wrote 5 real leaderboard queries and captured their execution plans.
- Added four targeted indexes.
- **Result:** a single player's history lookup went from ~10 ms to ~0.24 ms
  (≈ 43× faster) by replacing a full-table sequential scan with an index scan.
- **Honest finding:** the all-time "top 10" query did *not* speed up, because it
  must aggregate half the table — a case where a sequential scan is correctly the
  fastest option. This is the key insight and it sets up the Redis work in
  Portfolio 4.

## How to reproduce
```bash
psql -d arenapulse -f ../portfolio-1-database-design/schema.sql
psql -d arenapulse -f ../portfolio-1-database-design/seed.sql
psql -d arenapulse -f 00-bulk-load.sql
# capture plans, then:
psql -d arenapulse -f indexes.sql
# re-capture plans to compare
```
