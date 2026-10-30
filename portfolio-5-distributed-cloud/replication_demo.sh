#!/usr/bin/env bash
# =====================================================================
# Portfolio 5 — REPLICATION demo (Redis)
# Replication = keeping live COPIES of the data on other servers.
# We run a PRIMARY (accepts writes) and a REPLICA (a read-only copy that
# follows the primary). This gives:
#   * High availability — if the primary fails, a replica can take over.
#   * Read scaling — leaderboard reads can be spread across replicas.
# We write a score to the PRIMARY and watch it appear on the REPLICA.
# =====================================================================
PRIMARY=6380
REPLICA=6381
KEY="leaderboard:game:2"

echo "########## 1. Start a REPLICA on port $REPLICA that follows the primary ##########"
redis-cli -p $REPLICA shutdown nosave 2>/dev/null; sleep 1   # clear any previous replica
redis-server --port $REPLICA --daemonize yes --save "" --appendonly no \
             --replicaof 127.0.0.1 $PRIMARY >/tmp/redis-replica.log 2>&1
# Wait until the replica has actually linked to the primary (handshake takes a moment).
for i in $(seq 1 15); do
  status=$(redis-cli -p $REPLICA INFO replication | grep -oP 'master_link_status:\K\w+')
  [ "$status" = "up" ] && break
  sleep 1
done
echo "# Replica role and link status:"
redis-cli -p $REPLICA INFO replication | grep -E "role:|master_host:|master_link_status:"
echo

echo "########## 2. Write a score on the PRIMARY ##########"
redis-cli -p $PRIMARY DEL $KEY >/dev/null
redis-cli -p $PRIMARY ZADD $KEY 1580 luna_star 1340 mr_rapid 1120 byte_knight >/dev/null
echo "# wrote 3 players to the primary."
echo -n "# primary top 3: "; redis-cli -p $PRIMARY ZREVRANGE $KEY 0 2 WITHSCORES | tr '\n' ' '
echo; echo

echo "########## 3. Read the SAME data from the REPLICA (it copied automatically) ##########"
sleep 1
echo -n "# replica top 3: "; redis-cli -p $REPLICA ZREVRANGE $KEY 0 2 WITHSCORES | tr '\n' ' '
echo; echo

echo "########## 4. Update on PRIMARY propagates to REPLICA ##########"
redis-cli -p $PRIMARY ZINCRBY $KEY 500 byte_knight >/dev/null
echo "# byte_knight +500 on primary; re-check replica after a moment:"
sleep 1
echo -n "# replica top 3 now: "; redis-cli -p $REPLICA ZREVRANGE $KEY 0 2 WITHSCORES | tr '\n' ' '
echo; echo

echo "########## 5. The REPLICA is READ-ONLY (writes must go to the primary) ##########"
echo -n "# trying to write to the replica: "
redis-cli -p $REPLICA ZADD $KEY 9999 hacker 2>&1
echo "# ^ rejected: a replica refuses writes, which keeps the copies consistent."
echo
echo "Done."
