#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"; RUN="$1"; OUT="${2:-$LOCAL_ROOT/replay/$RUN}"; mkdir -p "$OUT/postgres-logs" "$OUT/sqlancer-logs"
python3 "$HARNESS_ROOT/scripts/reconstruct_postgres_logs.py" --run "$NFS_ROOT/$RUN" --output "$OUT/postgres-logs"
python3 "$HARNESS_ROOT/scripts/reconstruct_sql_logs.py" --run "$NFS_ROOT/$RUN" --output "$OUT/sqlancer-logs"
python3 "$HARNESS_ROOT/scripts/extract_replay_sql.py" --logs "$OUT/postgres-logs" --application SQLancerPlusPlus-24h --output "$OUT/replay.sql" --events "$OUT/execution-events.jsonl" --summary "$OUT/execution-summary.json"
zstd -q -f -T0 "$OUT/replay.sql" -o "$OUT/replay.sql.zst"; zstd -q -f -T0 "$OUT/execution-events.jsonl" -o "$OUT/execution-events.jsonl.zst"; echo "$OUT"

