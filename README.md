# Advanced Database Systems Portfolio (MIT 8103)

**Student:** Lawal Oluwaseun
**Case study:** ArenaPulse — Real-time Game Leaderboard
**Core databases:** PostgreSQL 16 (relational) and Redis 7 (NoSQL)

ArenaPulse is a mobile competitive-gaming platform whose signature feature is a
real-time leaderboard. This portfolio designs, builds, queries, optimises and
scales the database behind it.

## Repository structure
| Folder | Portfolio activity | Status |
|--------|--------------------|--------|
| `portfolio-1-database-design/` | Database design & modelling | ✅ Done |
| `portfolio-2-query-optimisation/` | Query processing & optimisation | ⬜ |
| `portfolio-3-transactions-concurrency/` | Transactions & concurrency | ⬜ |
| `portfolio-4-nosql/` | NoSQL & advanced data models (Redis) | ⬜ |
| `portfolio-5-distributed-cloud/` | Distributed & cloud database | ⬜ |
| `AI_USE_LOG.md` | AI-use declaration (required by the brief) | 🔄 ongoing |

Each folder has its own `README.md` explaining what it contains and how to run it.

## The data model
Six tables in Third Normal Form: `players`, `games`, `game_sessions`, `scores`,
`achievements`, and the link table `player_achievements`. See
`portfolio-1-database-design/` for the ER diagram and full schema.
