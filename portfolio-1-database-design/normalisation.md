# Normalisation Explanation (ArenaPulse)

**Normalisation** means organising tables so that each fact is stored in exactly
one place. This removes *anomalies* — problems that happen when the same fact is
duplicated across many rows. We take the design to **Third Normal Form (3NF)**.

## The problem we are avoiding: one big flat table
Imagine we stored everything in a single table, `big_scores`:

| player_name | player_email | country | game_title | genre | points | achieved_at |
|-------------|--------------|---------|------------|-------|--------|-------------|
| shadowfox   | shadow@..    | NG      | Trivia Blitz | trivia | 820 | ... |
| shadowfox   | shadow@..    | NG      | Nitro Rush   | racing | 770 | ... |

This "works", but it causes three classic anomalies:
- **Update anomaly** — if shadowfox changes email, we must find and edit *every*
  row for that player, or the data becomes inconsistent.
- **Insert anomaly** — we cannot add a brand-new game until someone has scored in
  it, because a row needs player + score data too.
- **Delete anomaly** — deleting a player's only score row also erases the only
  record that the game ever existed.

Normalisation fixes this by splitting the data into focused tables.

## First Normal Form (1NF) — atomic values, no repeating groups
A table is in 1NF when every column holds a single value (no lists in a cell) and
each row is unique. Our design is in 1NF: e.g. a player has one `username`, one
`email`; a player's many achievements are **not** crammed into one column — they
live as separate rows in `player_achievements`.

## Second Normal Form (2NF) — no partial dependencies
2NF applies where a table has a **composite** (multi-column) key. It says every
non-key column must depend on the *whole* key, not just part of it.
- Our `player_achievements` table has the composite key `(player_id,
  achievement_id)`. Its only extra column, `unlocked_at`, depends on the **whole**
  pair (that specific player unlocking that specific achievement). ✔ 2NF.
- The achievement's `name` and `points_reward` are **not** stored here — they
  belong to the achievement itself, so they live in `achievements`. Storing them
  here would be a partial dependency (depending only on `achievement_id`).

## Third Normal Form (3NF) — no transitive dependencies
3NF says a non-key column must depend **only** on the key, and never on another
non-key column. The clearest example is our `scores` table.

- A score happens inside a **session**, so `scores` references `session_id`.
- The **player** and **game** are already determined by the session.
- Therefore we do **not** copy `player_id` or `game_id` into `scores`. If we did,
  they would depend on `session_id` (a non-key column) rather than directly on
  `score_id` — a **transitive dependency** that breaks 3NF. To find a score's
  player, we join `scores → game_sessions → players`.

Similarly, a player's `country` lives only in `players`, and a game's `genre`
lives only in `games` — never duplicated onto session or score rows.

## Resulting tables (all in 3NF)
| Table | Stores one fact about… | Key |
|-------|------------------------|-----|
| `players` | a player account | `player_id` |
| `games` | a game in the catalogue | `game_id` |
| `game_sessions` | one play session | `session_id` |
| `scores` | points earned in a session | `score_id` |
| `achievements` | an unlockable achievement | `achievement_id` |
| `player_achievements` | a player⇄achievement unlock | `(player_id, achievement_id)` |

## A deliberate design decision: rankings are NOT stored
A player's **rank** is not a column anywhere. Rank is *derived* by ordering scores
at query time (Portfolio 2) or kept in Redis (Portfolio 4). Storing a rank column
would create a huge update anomaly — every new score would force us to rewrite
many players' ranks. Computing it on demand keeps the data correct by design.
