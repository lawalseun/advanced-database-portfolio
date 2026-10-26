# Portfolio 3 — Transactions & Concurrency

**Case study:** ArenaPulse — Real-time Game Leaderboard · **Database:** PostgreSQL 16

## What this folder contains
| File | What it is |
|------|------------|
| `01-setup.sql` | Creates `leaderboard_totals` (a player's running total per game) and seeds one test row. |
| `02-commit-rollback.sql` | Demonstrates COMMIT, ROLLBACK and atomicity (all-or-nothing). |
| `concurrency_demo.py` | Runs two simultaneous database sessions to show the lost-update bug and three fixes. |
| `explanation.md` | Plain-language write-up: ACID, the lost update, the fixes, isolation levels. |
| `evidence/01-commit-rollback.txt` | Captured output of the COMMIT/ROLLBACK script. |
| `evidence/02-concurrency-demo.txt` | Captured output of the concurrency program. |

## The short version
ArenaPulse adds points to a player's running total when a session ends. If two
updates land at once, a naive "read, add in code, write back" **loses one
update** — the evidence shows a total landing at 1500 when it should be 2000.

Three fixes, all tested and all giving the correct 2000:
1. **Atomic `UPDATE ... SET total = total + x`** — the database does the add in one step.
2. **`SELECT ... FOR UPDATE`** — locks the row so the second session waits.
3. **SERIALIZABLE isolation** — detects the conflict and retries the loser.

ArenaPulse uses the atomic UPDATE for score adds: simplest, safest, fastest.

## How to reproduce
```bash
psql -d arenapulse -f 01-setup.sql
psql -d arenapulse -f 02-commit-rollback.sql
python3 concurrency_demo.py
```
(Requires the `psycopg2` Python package and the `arenapulse` database from Portfolios 1–2.)
