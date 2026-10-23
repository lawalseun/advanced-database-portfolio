-- =====================================================================
-- ArenaPulse — sample data for Portfolio 1
-- Small, human-readable seed so the schema can be demonstrated.
-- (Portfolio 2 loads a larger dataset to show indexing/performance.)
-- =====================================================================

INSERT INTO players (username, email, country) VALUES
    ('shadowfox',   'shadowfox@example.com',   'NG'),
    ('queen_bee',   'queenbee@example.com',    'GH'),
    ('mr_rapid',    'rapid@example.com',       'NG'),
    ('luna_star',   'luna@example.com',        'KE'),
    ('byte_knight', 'byte@example.com',        'ZA');

INSERT INTO games (title, genre, released_at) VALUES
    ('Trivia Blitz',  'trivia',  DATE '2025-01-15'),
    ('Nitro Rush',    'racing',  DATE '2025-03-02'),
    ('Puzzle Peak',   'puzzle',  DATE '2025-06-20');

-- Sessions: (player_id, game_id) — ids follow insertion order above.
INSERT INTO game_sessions (player_id, game_id, device, started_at, ended_at) VALUES
    (1, 1, 'android', now() - interval '2 hours', now() - interval '1 hour 50 min'),
    (2, 1, 'ios',     now() - interval '90 min',  now() - interval '82 min'),
    (3, 2, 'android', now() - interval '60 min',  now() - interval '52 min'),
    (1, 2, 'android', now() - interval '40 min',  now() - interval '33 min'),
    (4, 3, 'ios',     now() - interval '30 min',  now() - interval '20 min'),
    (5, 1, 'android', now() - interval '15 min',  now() - interval '9 min');

-- Scores: linked to the session they happened in.
INSERT INTO scores (session_id, points) VALUES
    (1, 820),
    (2, 910),
    (3, 1340),
    (4, 770),
    (5, 1580),
    (6, 1120);

-- Achievement catalogue (per game).
INSERT INTO achievements (game_id, name, description, points_reward) VALUES
    (1, 'First Win',      'Win your first Trivia Blitz match.',        50),
    (1, 'Hot Streak',     'Answer 10 questions correctly in a row.',  120),
    (2, 'Clean Lap',      'Finish a lap without crashing.',            80),
    (3, 'Peak Climber',   'Clear 20 puzzles in one session.',         200);

-- Which player unlocked which achievement.
INSERT INTO player_achievements (player_id, achievement_id) VALUES
    (1, 1),
    (2, 1),
    (2, 2),
    (3, 3),
    (4, 4);
