# Distributed & Cloud Database — ArenaPulse Leaderboard

A **distributed database** spreads data across several servers instead of one.
For ArenaPulse this matters because a popular leaderboard must stay fast and
available even under heavy load or a server failure. All results in `evidence/`
are real captured output.

## 1. Replication (demonstrated)
**Replication** keeps live **copies** of the data on other servers. One node is
the **primary** (accepts writes); the others are **replicas** (read-only copies
that follow the primary).

`evidence/01-replication.txt` shows a real Redis primary + replica:
- The replica links to the primary (`master_link_status: up`).
- A score written on the primary **appears on the replica** automatically.
- A `ZINCRBY` update on the primary **propagates** and re-ranks on the replica.
- The replica **refuses writes** (`READONLY` error) — writes only go to the primary.

**Why ArenaPulse wants it:**
- **High availability** — if the primary fails, a replica can be promoted, so the
  leaderboard keeps working.
- **Read scaling** — leaderboard reads (top-N, a player's rank) are spread across
  replicas, while the primary handles the writes.

PostgreSQL does the same with **streaming replication** (a primary plus read
replicas), which we use for reporting/analytics reads.

## 2. Sharding (demonstrated)
**Sharding** splits one big dataset across several servers ("shards"), so no
single server must hold or handle all of it. It scales **capacity** (memory and
write throughput) beyond one machine.

`evidence/02-sharding.txt` shows ~5,000 players split across two shards by
hashing the player id — each shard holds ~2,500. But it also shows the **catch**:
- A **global top-N** needs a **scatter/gather** — ask *every* shard for its top-N,
  then merge and re-sort. More shards = more work for a global view.
- A **player's global rank** can't come from one shard's `ZREVRANK` (that's only
  the rank *within* that shard). You must count higher scorers across **all**
  shards.

**The practical lesson:** for a leaderboard, shard by **game or region** so each
shard is a **self-contained board** (most views are per-game or per-region
anyway). Only keep a single global board, with scatter/gather, if the product
truly needs one.

## 3. Consistency vs availability (the CAP theorem)
The **CAP theorem** says that when a network **partition** (P — servers can't
talk to each other) happens, a distributed system must choose between
**Consistency** (C — every read sees the latest write) and **Availability**
(A — every request still gets an answer).

Replication makes this concrete. Redis replicas are **asynchronous**: a write on
the primary reaches replicas a moment later. So a read from a replica can be
very slightly **stale** (a player's new score might show a beat late). This is
**eventual consistency**, and for a leaderboard it's a fine trade: showing a rank
that's a second out of date is far better than the board going down. We keep
**strong consistency where it matters** — the authoritative score is written to
PostgreSQL — and accept **eventual consistency** on the fast Redis read path.

## 4. Cloud deployment
In production this runs on managed cloud services (see `architecture.png`):
- **Redis** → a managed service such as **Redis Cloud** or **AWS ElastiCache**,
  with primary + replicas and automatic failover.
- **PostgreSQL** → a managed database such as **Supabase**, **AWS RDS** or
  **Neon**, with a primary, read replicas and automated backups.
- **App servers** → stateless containers behind a **load balancer**, scaled
  horizontally.
- **Multi-AZ** (multiple availability zones) so a whole data-centre zone can fail
  without taking the service down.

**The overall design:** PostgreSQL is the durable **source of truth**; Redis
(replicated, and sharded by game/region) is the fast **serving layer** for the
live leaderboard; both are replicated for availability, and the app layer scales
out behind a load balancer. This is how a real-time leaderboard is run at scale.
