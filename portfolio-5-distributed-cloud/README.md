# Portfolio 5 — Distributed & Cloud Database

**Case study:** ArenaPulse — Real-time Game Leaderboard
**Demonstrated with:** Redis 7 (replication + sharding), plus a cloud architecture design

## What this folder contains
| File | What it is |
|------|------------|
| `replication_demo.sh` | Starts a real Redis primary + replica and shows writes copying over + the replica being read-only. |
| `sharding_demo.py` | Splits ~5,000 players across two shards and shows the scatter/gather needed for a global view. |
| `architecture.dot` / `architecture.png` | The full distributed + cloud architecture diagram. |
| `explanation.md` | Plain-language write-up: replication, sharding, CAP (consistency vs availability), cloud deployment. |
| `evidence/01-replication.txt` | Captured output of the replication demo. |
| `evidence/02-sharding.txt` | Captured output of the sharding demo. |

## The short version
- **Replication** (shown live): a primary accepts writes; read-only replicas copy
  the data automatically. Gives high availability and lets reads scale. A write on
  the primary was seen propagating to the replica, and the replica refused writes.
- **Sharding** (shown live): splitting players across servers scales capacity, but
  a *global* top-N or rank then needs a scatter/gather across all shards — so for a
  leaderboard you shard by **game or region** where you can.
- **Consistency vs availability (CAP):** Redis replicas are eventually consistent
  (reads can be a beat stale); fine for a leaderboard, while PostgreSQL holds the
  strongly-consistent source of truth.
- **Cloud:** managed Redis (Redis Cloud / ElastiCache) + managed PostgreSQL
  (Supabase / RDS / Neon), app servers behind a load balancer, multi-AZ.

## How to reproduce
```bash
redis-server --port 6380 --daemonize yes          # primary (if not already up)
bash replication_demo.sh                           # starts a replica on 6381
redis-server --port 6390 --daemonize yes
redis-server --port 6391 --daemonize yes
python3 sharding_demo.py
dot -Tpng architecture.dot -o architecture.png     # (re)render the diagram
```
