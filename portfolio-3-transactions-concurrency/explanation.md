# Transactions & Concurrency — ArenaPulse Leaderboard

**Database:** PostgreSQL 16. All results in `evidence/` are real program output.

## 1. What a transaction is
A **transaction** is a group of database changes treated as a single unit. It
follows the **ACID** guarantees:
- **Atomicity** — all the changes happen, or none do.
- **Consistency** — the database moves from one valid state to another (our CHECK
  constraints are never left violated).
- **Isolation** — concurrent transactions don't corrupt each other.
- **Durability** — once committed, the change survives a crash.

The two commands that end a transaction:
- **COMMIT** — make every change permanent.
- **ROLLBACK** — undo every change since `BEGIN`.

`evidence/01-commit-rollback.txt` shows this: a `+500` that we ROLLBACK leaves the
total unchanged; a `+500` that we COMMIT sticks; and a transaction whose second
statement fails a CHECK has its **whole** effect discarded (atomicity).

## 2. The concurrency problem: a lost update
ArenaPulse keeps a running `total_points` per player. When a player finishes a
session we add that session's points to the total — the case study's "update
score". Now suppose two score updates for the same player arrive at almost the
same instant (two servers, or two quick sessions). A naive app does:

1. **read** the current total,
2. **add** the points in application code,
3. **write** the new value back.

If two sessions interleave, both read the same old value and the second write
overwrites the first. One player's points simply vanish. This is a **lost
update**, and `evidence/02-concurrency-demo.txt` Section A shows it for real:
start 1000, two sessions each add 500, but the final total is **1500 instead of
2000**.

## 3. Three ways to fix it (all verified)

| Fix | How it works | Result in evidence |
|-----|--------------|--------------------|
| **Atomic UPDATE** | `UPDATE ... SET total = total + 500`. The database reads and adds in one indivisible step, so there is no gap to interleave. | Section B → 2000 ✔ |
| **Row lock** | `SELECT ... FOR UPDATE` locks the row; the second session **waits** until the first commits, then reads the fresh value. | Section C → 2000 ✔ (B waited 0.40s) |
| **SERIALIZABLE isolation** | The strictest isolation level makes the database detect the conflict and abort one transaction with a serialization error; the app **retries** it. | Section D → 2000 ✔ (one session retried) |

## 4. Isolation levels (from loosest to strictest)
Isolation level controls how much one transaction can see of another's
in-progress work. PostgreSQL supports:

| Level | Prevents | Notes |
|-------|----------|-------|
| READ UNCOMMITTED | (in PostgreSQL behaves like READ COMMITTED) | no "dirty reads" ever in PG |
| **READ COMMITTED** (default) | dirty reads | but lost updates like Section A are still possible with read-modify-write |
| REPEATABLE READ | dirty + non-repeatable reads | a row you read won't change under you; write conflicts abort |
| **SERIALIZABLE** | all of the above + serialization anomalies | transactions behave as if run one-at-a-time; may need retries |

The lost update in Section A happens under the **default** READ COMMITTED level,
which is exactly why developers must choose one of the fixes above.

## 5. What ArenaPulse should use, and why
For simply adding points, the **atomic UPDATE** (Fix 1) is best: it is the
simplest, has no application-side locking or retry logic, and is the fastest
because the database does the add in a single statement. We reserve
`SELECT ... FOR UPDATE` for cases where the app must read a value, make a
decision, *then* write (e.g. "only award a bonus if the total is below a cap"),
and SERIALIZABLE for multi-row rules that must appear to run one at a time.

## 6. Link to the rest of the portfolio
This is also why a live leaderboard is hard in pure SQL under heavy load: every
score update contends on the same hot rows. Portfolio 4 shows how Redis handles
the same "add points and re-rank" operation atomically and extremely fast with a
sorted set, sidestepping this contention for the live ranking.
