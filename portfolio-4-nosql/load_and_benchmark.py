#!/usr/bin/env python3
"""
Portfolio 4 — Load the ArenaPulse leaderboard into Redis and benchmark it
against the equivalent PostgreSQL queries from Portfolio 2.

Same data, two engines, same two questions a leaderboard is asked constantly:
  1. "Give me the top 10 players for this game."
  2. "What rank is this specific player?"

We time each on PostgreSQL and on Redis and compare.
"""
import time
import statistics
import psycopg2
import redis

PG = "host=/var/run/postgresql port=5433 user=postgres dbname=arenapulse"
GAME = 2
KEY = f"leaderboard:game:{GAME}"


def median_ms(fn, runs=7):
    times = []
    for _ in range(runs):
        t0 = time.perf_counter()
        fn()
        times.append((time.perf_counter() - t0) * 1000)
    return statistics.median(times)


def main():
    pg = psycopg2.connect(PG)
    r = redis.Redis(host="localhost", port=6380, decode_responses=True)

    # ----- Build the Redis leaderboard from the SQL data (each player's best score in game 2) -----
    print("Loading Redis leaderboard from PostgreSQL data...")
    with pg.cursor() as cur:
        cur.execute("""
            SELECT gs.player_id, MAX(sc.points) AS best
            FROM scores sc
            JOIN game_sessions gs ON gs.session_id = sc.session_id
            WHERE gs.game_id = %s
            GROUP BY gs.player_id
        """, (GAME,))
        rows = cur.fetchall()

    r.delete(KEY)
    pipe = r.pipeline()
    for player_id, best in rows:
        pipe.zadd(KEY, {f"player_{player_id}": best})
    pipe.execute()
    print(f"Loaded {r.zcard(KEY):,} players into Redis sorted set '{KEY}'.\n")

    # Pick a mid-pack player to ask the "what rank am I" question about.
    sample_player_id = rows[len(rows) // 2][0]
    sample_member = f"player_{sample_player_id}"

    # ---------------- Query 1: TOP 10 ----------------
    def sql_top10():
        with pg.cursor() as cur:
            cur.execute("""
                SELECT gs.player_id, MAX(sc.points) AS best
                FROM scores sc
                JOIN game_sessions gs ON gs.session_id = sc.session_id
                WHERE gs.game_id = %s
                GROUP BY gs.player_id
                ORDER BY best DESC
                LIMIT 10
            """, (GAME,))
            cur.fetchall()

    def redis_top10():
        r.zrevrange(KEY, 0, 9, withscores=True)

    # ---------------- Query 2: A PLAYER'S RANK ----------------
    def sql_rank():
        with pg.cursor() as cur:
            cur.execute("""
                SELECT rnk FROM (
                    SELECT gs.player_id,
                           RANK() OVER (ORDER BY MAX(sc.points) DESC) AS rnk
                    FROM scores sc
                    JOIN game_sessions gs ON gs.session_id = sc.session_id
                    WHERE gs.game_id = %s
                    GROUP BY gs.player_id
                ) ranked
                WHERE player_id = %s
            """, (GAME, sample_player_id))
            cur.fetchone()

    def redis_rank():
        r.zrevrank(KEY, sample_member)

    sql_t10 = median_ms(sql_top10)
    rds_t10 = median_ms(redis_top10)
    sql_rk = median_ms(sql_rank)
    rds_rk = median_ms(redis_rank)

    # ---------------- Report ----------------
    print("=" * 66)
    print(f"BENCHMARK  (game {GAME}, {len(rows):,} ranked players, median of 7 runs)")
    print("=" * 66)
    print(f"{'Operation':<26}{'PostgreSQL':>14}{'Redis':>12}{'Speed-up':>12}")
    print("-" * 66)
    print(f"{'Top 10 players':<26}{sql_t10:>11.3f} ms{rds_t10:>9.3f} ms{sql_t10/rds_t10:>10.0f}x")
    print(f"{'A player''s rank':<26}{sql_rk:>11.3f} ms{rds_rk:>9.3f} ms{sql_rk/rds_rk:>10.0f}x")
    print("=" * 66)

    # Show the two engines agree on the answer (correctness check).
    top3_redis = r.zrevrange(KEY, 0, 2, withscores=True)
    print("\nTop 3 from Redis (sanity check):")
    for member, score in top3_redis:
        print(f"  {member}: {int(score)}")
    print(f"\nRank of {sample_member}:")
    print(f"  Redis ZREVRANK -> {r.zrevrank(KEY, sample_member) + 1} (1-based)")

    pg.close()


if __name__ == "__main__":
    main()
