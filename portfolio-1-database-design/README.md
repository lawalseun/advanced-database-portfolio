# Portfolio 1 — Database Design & Modelling

**Case study:** ArenaPulse — Real-time Game Leaderboard
**Database:** PostgreSQL 16

## What this folder contains
| File | What it is |
|------|------------|
| `00-case-study.md` | The chosen organisation: who uses it, what data it stores, what it must do. |
| `er-diagram.png` | Entity-Relationship diagram of all six tables and their relationships. |
| `er-diagram.dot` | The source used to generate the diagram (re-render with Graphviz). |
| `schema.sql` | Creates every table with primary keys, foreign keys and constraints. |
| `seed.sql` | Loads small, readable sample data. |
| `normalisation.md` | Explains how the design reaches Third Normal Form (3NF). |
| `evidence/01-schema-build.txt` | Output proving the schema and seed run with no errors. |
| `evidence/02-constraints-in-action.txt` | Output proving the constraints reject invalid data. |

## The design in one picture
Six tables, all in 3NF:
`players`, `games`, `game_sessions`, `scores`, `achievements`, and the
many-to-many link `player_achievements`.

Key design decisions:
- **Scores link to a session, not directly to a player/game** — the player and
  game are reached *through* the session. This avoids a transitive dependency and
  keeps the design in 3NF.
- **Rank is never stored** — it is derived at query time (Portfolio 2) or kept in
  Redis (Portfolio 4), which avoids a massive update anomaly on every new score.

## How to run it yourself
```bash
# with a PostgreSQL server running and a database named 'arenapulse':
psql -d arenapulse -f schema.sql
psql -d arenapulse -f seed.sql
```

## How this was built and verified
The schema and seed were executed on PostgreSQL 16; the two files in `evidence/`
are the captured output. See the repository-level `AI_USE_LOG.md` for the
AI-use declaration.
