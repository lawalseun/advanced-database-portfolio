#!/usr/bin/env python3
"""
Portfolio 5 — SHARDING demo (Redis)

Sharding = splitting ONE big dataset across SEVERAL servers ("shards") so no
single server has to hold or handle all of it. It lets the leaderboard grow
beyond the memory and write capacity of one machine.

We spread ~5,000 players across TWO shards by hashing each player's id. Then we
show the catch: because the players are split up, answering a GLOBAL question
("overall top 10", "a player's overall rank") means asking EVERY shard and
combining the answers — a "scatter/gather". This is the real trade-off of
sharding a leaderboard, and why you shard by game or region when you can.
"""
import redis

# Two shards. In the cloud these would be separate servers; here, two ports.
SHARDS = [
    redis.Redis(host="localhost", port=6390, decode_responses=True),
    redis.Redis(host="localhost", port=6391, decode_responses=True),
]
KEY = "leaderboard:global"


def shard_for(player_id: int) -> redis.Redis:
    """Pick a shard by hashing the player id (simple modulo hashing)."""
    return SHARDS[player_id % len(SHARDS)]


def load():
    for s in SHARDS:
        s.delete(KEY)
    # Deterministic sample data: 5,000 players with spread-out scores.
    pipes = [s.pipeline() for s in SHARDS]
    for pid in range(1, 5001):
        score = (pid * 7919) % 2000  # pseudo-spread 0..1999
        idx = pid % len(SHARDS)
        pipes[idx].zadd(KEY, {f"player_{pid}": score})
    for p in pipes:
        p.execute()


def global_top_n(n=10):
    """Scatter: ask each shard for its top n. Gather: merge and take the overall top n."""
    collected = []
    for s in SHARDS:
        collected.extend(s.zrevrange(KEY, 0, n - 1, withscores=True))
    collected.sort(key=lambda kv: kv[1], reverse=True)
    return collected[:n]


def global_rank(player_id: int):
    """A player's OVERALL rank = 1 + how many players across ALL shards score higher."""
    member = f"player_{player_id}"
    my_shard = shard_for(player_id)
    my_score = my_shard.zscore(KEY, member)
    if my_score is None:
        return None, None
    higher = 0
    for s in SHARDS:
        # count members with a strictly higher score on this shard
        higher += s.zcount(KEY, f"({my_score}", "+inf")
    return int(my_score), higher + 1


def main():
    load()
    counts = [s.zcard(KEY) for s in SHARDS]
    print("=" * 60)
    print("SHARDING: ~5,000 players split across 2 shards by hash(id)")
    print("=" * 60)
    print(f"Shard A (port 6390) holds: {counts[0]:,} players")
    print(f"Shard B (port 6391) holds: {counts[1]:,} players")
    print(f"Total across shards:       {sum(counts):,} players")
    print("-> No single shard holds everything; the load is split.\n")

    print("GLOBAL TOP 5  (scatter: ask both shards; gather: merge + re-sort)")
    for i, (member, score) in enumerate(global_top_n(5), 1):
        print(f"  {i}. {member}  ({int(score)})")
    print("   Note: needed a query to EVERY shard, then a merge. With more")
    print("   shards this gets more expensive — the cost of a global view.\n")

    print("A PLAYER'S GLOBAL RANK  (must count higher scorers on ALL shards)")
    for pid in (2631, 4999):
        score, rank = global_rank(pid)
        print(f"  player_{pid}: score {score}, overall rank {rank}")
    print("   A single shard's ZREVRANK would give only the rank WITHIN that")
    print("   shard — wrong globally — so we count across every shard instead.\n")

    print("TAKEAWAY: sharding scales capacity, but global ranking needs")
    print("scatter/gather. For a leaderboard, prefer sharding by GAME or")
    print("REGION so each shard is a self-contained board (most views are")
    print("per-game/per-region anyway), and keep a global board only if needed.")


if __name__ == "__main__":
    main()
