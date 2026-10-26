# AI Use Log & Declaration (MIT 8103)

This file records how AI tools were used while building this portfolio, as
required by the assessment brief (Section 11). It is updated after each working
session.

**AI tool used:** Claude (Anthropic).

**How it was used overall:** as a learning aid and build assistant — to explain
advanced database concepts in plain language, to draft and run SQL and Redis
code, to generate diagrams and documentation, and to quiz me on each topic so I
could understand and explain the work myself.

**How outputs were reviewed/verified:** every script was executed on PostgreSQL 16
or Redis 7, and the real output was captured as evidence. I reviewed each
explanation, answered comprehension questions on each part, and wrote the final
reflection in my own words.

---

## Session log

### Session 1 — 2026-10-22 (Portfolio 1: Database Design & Modelling)
- **What AI helped with:** confirming the case study choice; designing the six-table
  3NF schema; writing `schema.sql`, `seed.sql` and the normalisation explanation;
  generating the ER diagram; running the schema + seed and capturing evidence.
- **How I checked it:** the schema and seed ran on PostgreSQL 16 with no errors
  (`evidence/01-schema-build.txt`); constraint tests confirmed invalid data is
  rejected (`evidence/02-constraints-in-action.txt`); I reviewed the normalisation
  write-up and answered comprehension questions on 1NF–3NF.

### Session 2 — 2026-10-23 (Portfolio 2: Query Processing & Optimisation)
- **What AI helped with:** generating a larger test dataset; writing the five
  leaderboard queries; capturing execution plans; choosing and writing the
  indexes; and drafting the performance analysis.
- **How I checked it:** I ran every query on PostgreSQL 16 and confirmed the
  results made sense; I compared the real `EXPLAIN ANALYZE` plans before and after
  indexing (evidence files `01`, `02`, `03`); I verified the ~43× speed-up on the
  player-history query by timing 5 runs with and without the index; and I made
  sure I could explain *why* the all-time top-10 query did not speed up.

### Session 3 — 2026-10-26 (Portfolio 3: Transactions & Concurrency)
- **What AI helped with:** designing the `leaderboard_totals` running-total table;
  writing the COMMIT/ROLLBACK demo; writing a Python script that runs two
  simultaneous sessions to reproduce a lost update and three fixes; and drafting
  the transactions/isolation explanation.
- **How I checked it:** I ran the COMMIT/ROLLBACK script and confirmed ROLLBACK
  undoes a change while COMMIT keeps it, and that a failed transaction discards
  all its work (evidence 01); I ran the concurrency program and saw the lost
  update land at 1500 instead of 2000, and all three fixes produce the correct
  2000 (evidence 02); I made sure I can explain in my own words why the bug
  happens under READ COMMITTED and why an atomic UPDATE avoids it.

<!-- Add a new dated entry here after each session. -->
