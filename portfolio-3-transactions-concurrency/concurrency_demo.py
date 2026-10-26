#!/usr/bin/env python3
"""
Portfolio 3 — Concurrency demonstrations for the ArenaPulse leaderboard.

Scenario: a player finishes two game sessions at almost the same instant, and
each one tries to ADD its points to the player's running total
(leaderboard_totals). We show:

  A. THE BUG  — a naive "read, add in app code, write back" loses one update.
  B. FIX 1    — an atomic "UPDATE ... SET total = total + x" (database does the add).
  C. FIX 2    — "SELECT ... FOR UPDATE" locks the row so the second txn waits.
  D. ISOLATION— SERIALIZABLE isolation detects the conflict and makes one txn
                retry, giving the correct result.

Every scenario resets the row to a known 1000 first. Two sessions each add 500,
so the CORRECT final total is always 2000.
"""
import threading
import time
import psycopg2

DSN = "host=/var/run/postgresql port=5433 user=postgres dbname=arenapulse"
PID, GID = 42, 2
START, ADD = 1000, 500
CORRECT = START + 2 * ADD  # 2000


def connect():
    return psycopg2.connect(DSN)


def reset():
    c = connect(); c.autocommit = True
    with c.cursor() as cur:
        cur.execute("UPDATE leaderboard_totals SET total_points=%s WHERE player_id=%s AND game_id=%s",
                    (START, PID, GID))
    c.close()


def current_total():
    c = connect()
    with c.cursor() as cur:
        cur.execute("SELECT total_points FROM leaderboard_totals WHERE player_id=%s AND game_id=%s", (PID, GID))
        v = cur.fetchone()[0]
    c.close()
    return v


def line(s=""):
    print(s)


# ---------------------------------------------------------------------------
# A. THE BUG: lost update via naive read-modify-write
# ---------------------------------------------------------------------------
def demo_lost_update():
    line("=" * 70)
    line("A. THE BUG — naive read / add-in-code / write-back (READ COMMITTED)")
    line("=" * 70)
    reset()
    a, b = connect(), connect()
    a.autocommit = b.autocommit = False
    ca, cb = a.cursor(), b.cursor()

    ca.execute("SELECT total_points FROM leaderboard_totals WHERE player_id=%s AND game_id=%s", (PID, GID))
    a_read = ca.fetchone()[0]
    line(f"  Session A reads total = {a_read}")

    cb.execute("SELECT total_points FROM leaderboard_totals WHERE player_id=%s AND game_id=%s", (PID, GID))
    b_read = cb.fetchone()[0]
    line(f"  Session B reads total = {b_read}")

    a_new = a_read + ADD
    ca.execute("UPDATE leaderboard_totals SET total_points=%s WHERE player_id=%s AND game_id=%s", (a_new, PID, GID))
    a.commit()
    line(f"  Session A writes {a_read} + {ADD} = {a_new} and COMMITs")

    b_new = b_read + ADD
    cb.execute("UPDATE leaderboard_totals SET total_points=%s WHERE player_id=%s AND game_id=%s", (b_new, PID, GID))
    b.commit()
    line(f"  Session B writes {b_read} + {ADD} = {b_new} and COMMITs")

    a.close(); b.close()
    final = current_total()
    line(f"  --> FINAL total = {final}   (correct would be {CORRECT})")
    line(f"  --> RESULT: {'LOST UPDATE! B overwrote A — 500 points vanished.' if final != CORRECT else 'ok'}")
    line()


# ---------------------------------------------------------------------------
# B. FIX 1: atomic UPDATE ... SET total = total + x  (run concurrently)
# ---------------------------------------------------------------------------
def worker_atomic(name, barrier, results):
    c = connect(); c.autocommit = False
    cur = c.cursor()
    barrier.wait()  # line both workers up so they really race
    cur.execute("UPDATE leaderboard_totals SET total_points = total_points + %s "
                "WHERE player_id=%s AND game_id=%s", (ADD, PID, GID))
    c.commit(); c.close()
    results.append(name)


def demo_atomic_fix():
    line("=" * 70)
    line("B. FIX 1 — atomic 'UPDATE ... SET total = total + 500' (two threads race)")
    line("=" * 70)
    reset()
    barrier = threading.Barrier(2)
    results = []
    t1 = threading.Thread(target=worker_atomic, args=("A", barrier, results))
    t2 = threading.Thread(target=worker_atomic, args=("B", barrier, results))
    t1.start(); t2.start(); t1.join(); t2.join()
    final = current_total()
    line(f"  Both sessions ran the add concurrently; the database serialised them.")
    line(f"  --> FINAL total = {final}   (correct = {CORRECT})")
    line(f"  --> RESULT: {'CORRECT — no points lost.' if final == CORRECT else 'WRONG'}")
    line()


# ---------------------------------------------------------------------------
# C. FIX 2: SELECT ... FOR UPDATE row lock (second txn waits)
# ---------------------------------------------------------------------------
def worker_for_update(name, start_delay, log):
    time.sleep(start_delay)
    c = connect(); c.autocommit = False
    cur = c.cursor()
    t0 = time.time()
    cur.execute("SELECT total_points FROM leaderboard_totals WHERE player_id=%s AND game_id=%s "
                "FOR UPDATE", (PID, GID))
    waited = time.time() - t0
    val = cur.fetchone()[0]
    log.append(f"  Session {name}: got the lock after waiting {waited:.2f}s, read total = {val}")
    time.sleep(0.5)  # hold the lock a moment to force the other to wait
    cur.execute("UPDATE leaderboard_totals SET total_points=%s WHERE player_id=%s AND game_id=%s",
                (val + ADD, PID, GID))
    c.commit(); c.close()
    log.append(f"  Session {name}: wrote {val} + {ADD} = {val+ADD} and COMMITted (lock released)")


def demo_for_update():
    line("=" * 70)
    line("C. FIX 2 — 'SELECT ... FOR UPDATE' locks the row; the 2nd session waits")
    line("=" * 70)
    reset()
    log = []
    t1 = threading.Thread(target=worker_for_update, args=("A", 0.0, log))
    t2 = threading.Thread(target=worker_for_update, args=("B", 0.1, log))  # B starts just after A
    t1.start(); t2.start(); t1.join(); t2.join()
    for entry in log:
        line(entry)
    final = current_total()
    line(f"  --> FINAL total = {final}   (correct = {CORRECT})")
    line(f"  --> RESULT: {'CORRECT — B waited for A, so both adds counted.' if final == CORRECT else 'WRONG'}")
    line()


# ---------------------------------------------------------------------------
# D. ISOLATION: SERIALIZABLE detects the conflict; loser retries
# ---------------------------------------------------------------------------
def worker_serializable(name, barrier, outcome):
    attempts = 0
    while True:
        attempts += 1
        c = connect(); c.autocommit = False
        c.set_isolation_level(psycopg2.extensions.ISOLATION_LEVEL_SERIALIZABLE)
        cur = c.cursor()
        try:
            cur.execute("SELECT total_points FROM leaderboard_totals WHERE player_id=%s AND game_id=%s", (PID, GID))
            val = cur.fetchone()[0]
            if attempts == 1:
                barrier.wait()  # both read the old value before either writes
            cur.execute("UPDATE leaderboard_totals SET total_points=%s WHERE player_id=%s AND game_id=%s",
                        (val + ADD, PID, GID))
            c.commit(); c.close()
            outcome.append(f"  Session {name}: committed on attempt {attempts} (read {val}, wrote {val+ADD})")
            return
        except psycopg2.errors.SerializationFailure:
            c.rollback(); c.close()
            outcome.append(f"  Session {name}: attempt {attempts} hit a SERIALIZATION conflict -> retrying")
            time.sleep(0.2)


def demo_serializable():
    line("=" * 70)
    line("D. ISOLATION — SERIALIZABLE detects the conflict and forces a safe retry")
    line("=" * 70)
    reset()
    barrier = threading.Barrier(2)
    outcome = []
    t1 = threading.Thread(target=worker_serializable, args=("A", barrier, outcome))
    t2 = threading.Thread(target=worker_serializable, args=("B", barrier, outcome))
    t1.start(); t2.start(); t1.join(); t2.join()
    for entry in sorted(outcome):
        line(entry)
    final = current_total()
    line(f"  --> FINAL total = {final}   (correct = {CORRECT})")
    line(f"  --> RESULT: {'CORRECT — the conflict was caught and the loser retried.' if final == CORRECT else 'WRONG'}")
    line()


if __name__ == "__main__":
    line("ArenaPulse — Portfolio 3 concurrency demonstrations")
    line("Two sessions each add 500 to a starting total of 1000; correct final = 2000.")
    line()
    demo_lost_update()
    demo_atomic_fix()
    demo_for_update()
    demo_serializable()
    line("Done.")
