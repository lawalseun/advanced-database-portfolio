-- =====================================================================
-- ArenaPulse — Real-time Game Leaderboard
-- Portfolio 1: Relational schema (PostgreSQL)
-- Design level: Third Normal Form (3NF)
-- =====================================================================
-- This script creates every table, with primary keys, foreign keys and
-- constraints. Run it on an empty database to build the structure.
-- =====================================================================

-- Start clean (safe to re-run). CASCADE also drops dependent objects.
DROP TABLE IF EXISTS player_achievements CASCADE;
DROP TABLE IF EXISTS achievements       CASCADE;
DROP TABLE IF EXISTS scores             CASCADE;
DROP TABLE IF EXISTS game_sessions      CASCADE;
DROP TABLE IF EXISTS games              CASCADE;
DROP TABLE IF EXISTS players            CASCADE;

-- ---------------------------------------------------------------------
-- players: one row per player account
-- ---------------------------------------------------------------------
CREATE TABLE players (
    player_id    BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    username     VARCHAR(30)  NOT NULL UNIQUE,      -- no two players share a name
    email        VARCHAR(255) NOT NULL UNIQUE,      -- no two players share an email
    country      CHAR(2)      NOT NULL,             -- ISO country code, e.g. 'NG'
    created_at   TIMESTAMPTZ  NOT NULL DEFAULT now(),
    CONSTRAINT chk_username_len CHECK (char_length(username) >= 3)
);

-- ---------------------------------------------------------------------
-- games: the catalogue of games on the platform
-- ---------------------------------------------------------------------
CREATE TABLE games (
    game_id      BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title        VARCHAR(80) NOT NULL UNIQUE,
    genre        VARCHAR(40) NOT NULL,
    released_at  DATE        NOT NULL
);

-- ---------------------------------------------------------------------
-- game_sessions: one row per play session (who played what, and when)
-- ---------------------------------------------------------------------
CREATE TABLE game_sessions (
    session_id   BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    player_id    BIGINT      NOT NULL REFERENCES players(player_id) ON DELETE CASCADE,
    game_id      BIGINT      NOT NULL REFERENCES games(game_id)     ON DELETE CASCADE,
    device       VARCHAR(20) NOT NULL,              -- e.g. 'android', 'ios'
    started_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
    ended_at     TIMESTAMPTZ,                       -- NULL while a session is live
    CONSTRAINT chk_session_time CHECK (ended_at IS NULL OR ended_at >= started_at)
);

-- ---------------------------------------------------------------------
-- scores: the points earned IN a session.
-- Note: player_id and game_id are deliberately NOT repeated here — they
-- are reached through the session. Repeating them would be a transitive
-- dependency and would break 3NF (see normalisation.md).
-- ---------------------------------------------------------------------
CREATE TABLE scores (
    score_id     BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    session_id   BIGINT      NOT NULL REFERENCES game_sessions(session_id) ON DELETE CASCADE,
    points       INTEGER     NOT NULL,
    achieved_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT chk_points_nonneg CHECK (points >= 0)
);

-- ---------------------------------------------------------------------
-- achievements: the catalogue of unlockable achievements, per game
-- ---------------------------------------------------------------------
CREATE TABLE achievements (
    achievement_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    game_id        BIGINT      NOT NULL REFERENCES games(game_id) ON DELETE CASCADE,
    name           VARCHAR(60) NOT NULL,
    description    VARCHAR(255) NOT NULL,
    points_reward  INTEGER     NOT NULL DEFAULT 0,
    CONSTRAINT chk_reward_nonneg CHECK (points_reward >= 0),
    CONSTRAINT uq_achievement_per_game UNIQUE (game_id, name)  -- a name is unique within a game
);

-- ---------------------------------------------------------------------
-- player_achievements: which player unlocked which achievement (many-to-many)
-- The primary key is the PAIR, so a player cannot unlock the same one twice.
-- ---------------------------------------------------------------------
CREATE TABLE player_achievements (
    player_id      BIGINT      NOT NULL REFERENCES players(player_id)           ON DELETE CASCADE,
    achievement_id BIGINT      NOT NULL REFERENCES achievements(achievement_id) ON DELETE CASCADE,
    unlocked_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (player_id, achievement_id)
);
