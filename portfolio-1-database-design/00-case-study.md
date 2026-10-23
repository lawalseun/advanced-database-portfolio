# Case Study: ArenaPulse — Real-time Game Leaderboard

> This statement is the agreed starting point for the whole portfolio. Every
> portfolio activity (1 to 5) uses this same organisation and data model.

## Organisation / scenario
**ArenaPulse** is a mobile competitive-gaming platform (a realistic simulated
organisation). It hosts several short-session games — for example a trivia game,
a racing game and a puzzle game — and its signature feature is a **real-time
leaderboard** that ranks players by the scores they earn while playing.

## Nature of the business / system
ArenaPulse is an online entertainment service. Players install the app, play
timed sessions of a game, earn points, unlock achievements, and compete to climb
the leaderboard. The business depends on the leaderboard feeling **fast and
fair**: when a player finishes a match, their new rank should appear almost
instantly, and the numbers must always be correct.

## Users of the database
- **Players** — the people playing games and competing for rank.
- **The game client (app)** — software that records sessions and submits scores
  on each player's behalf.
- **ArenaPulse operations/admin staff** — who add new games, define achievements,
  investigate disputes and monitor activity.
- **The analytics/reporting layer** — which reads the data to produce rankings,
  statistics and reports.

## Major data to be stored
- **Players** — account details (username, email, country, join date).
- **Games** — the catalogue of games on the platform.
- **Game sessions** — each individual play session (who, which game, when it
  started and ended, on what device).
- **Scores** — the points earned, linked to the session in which they happened.
- **Achievements** — the catalogue of unlockable achievements per game.
- **Player achievements** — which player unlocked which achievement, and when.

## Key operations the database must support
1. **Register / manage players** and their accounts.
2. **Record a game session** and the **score** a player earns in it.
3. **Retrieve rankings** — "top N players for a game", "a player's current rank",
   "this week's leaders".
4. **Update a player's score** safely, even when many players finish at the same
   instant (a concurrency concern — covered in Portfolio 3).
5. **Award and list achievements** per player.
6. **Manage the leaderboard** at speed and scale (covered with Redis in
   Portfolio 4 and distribution/cloud in Portfolio 5).

## Why this case study fits the assessment
A leaderboard naturally exercises **every** required concept: clean related
entities for design and normalisation (P1); ranking queries that beg for indexes
and performance tuning (P2); simultaneous score updates that create a textbook
concurrency problem (P3); and a ranking workload that real games solve with a
**NoSQL** store — Redis sorted sets — which also leads naturally into
**distributed and cloud** scaling (P4 and P5).
