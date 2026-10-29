#!/usr/bin/env bash
# =====================================================================
# Portfolio 4 — Redis leaderboard: the core operations, explained.
# A readable walkthrough using a few named players so the data model
# and every command are easy to follow. Run against Redis on port 6380.
#
# DATA MODEL
#   * A SORTED SET per game holds the live leaderboard:
#       key    = leaderboard:game:2
#       member = the player (we use the username here for readability)
#       score  = the player's points   <-- Redis keeps members ordered by this
#   * A HASH per player holds profile details (the "document" style):
#       key = player:shadowfox  ->  { country: NG, games_played: 12 }
#
# WHY A SORTED SET: Redis keeps the set permanently ordered by score, so
# "top 10" and "what rank is this player" are near-instant (O(log N)) with
# no scanning — exactly what a real-time leaderboard needs.
# =====================================================================
R="redis-cli -p 6380"

echo "########## 0. Start clean ##########"
$R DEL leaderboard:game:2 player:shadowfox player:queen_bee player:mr_rapid player:luna_star player:byte_knight
echo

echo "########## 1. ADD / SET scores  (ZADD) ##########"
echo "# 'Update score, retrieve ranking, manage leaderboard' from the case study."
$R ZADD leaderboard:game:2 820  shadowfox
$R ZADD leaderboard:game:2 1340 mr_rapid
$R ZADD leaderboard:game:2 910  queen_bee
$R ZADD leaderboard:game:2 1580 luna_star
$R ZADD leaderboard:game:2 1120 byte_knight
echo "# (each '1' above = one new member added)"
echo

echo "########## 2. UPDATE a score when a player earns more  (ZINCRBY) ##########"
echo "# shadowfox finishes another session worth +500 points:"
$R ZINCRBY leaderboard:game:2 500 shadowfox
echo "# ZINCRBY adds atomically and re-ranks the player in one step."
echo

echo "########## 3. TOP 10 leaderboard  (ZREVRANGE ... WITHSCORES) ##########"
echo "# highest score first:"
$R ZREVRANGE leaderboard:game:2 0 9 WITHSCORES
echo

echo "########## 4. A PLAYER'S RANK  (ZREVRANK) ##########"
echo "# ZREVRANK is 0-based (0 = top). We add 1 for human ranking."
echo -n "# luna_star rank (0-based): "; $R ZREVRANK leaderboard:game:2 luna_star
echo -n "# shadowfox rank (0-based): "; $R ZREVRANK leaderboard:game:2 shadowfox
echo

echo "########## 5. A PLAYER'S SCORE  (ZSCORE)  and TOTAL PLAYERS (ZCARD) ##########"
echo -n "# shadowfox score: "; $R ZSCORE leaderboard:game:2 shadowfox
echo -n "# players on this leaderboard: "; $R ZCARD leaderboard:game:2
echo

echo "########## 6. PLAYER PROFILE as a HASH (document style)  (HSET / HGETALL) ##########"
$R HSET player:shadowfox country NG games_played 12 > /dev/null
$R HSET player:luna_star country KE games_played 8  > /dev/null
echo -n "# profile for shadowfox: "; $R HGETALL player:shadowfox
echo

echo "########## 7. A WINDOW of the board — ranks 2 to 4  (ZREVRANGE 1 3) ##########"
$R ZREVRANGE leaderboard:game:2 1 3 WITHSCORES
echo
echo "Done."
