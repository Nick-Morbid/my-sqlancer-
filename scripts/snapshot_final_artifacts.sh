#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"
RUN_ID="$1"; WORK="$(readlink -m "$2")"; LIVE="$(readlink -m "$3")"; NAME=final-artifacts; OUT="$SPOOL_DIR/$RUN_ID/$NAME"
mkdir -p "$OUT/sql" "$OUT/runtime" "$OUT/postgres" "$OUT/feedback"
psql_cov -Atc 'SELECT pg_rotate_logfile();' >/dev/null; sleep 1
ACTIVE="$(basename "$(psql_cov -Atc "SELECT pg_current_logfile('csvlog');")")"
python3 "$HARNESS_ROOT/scripts/snapshot_sql_logs.py" --source "$WORK/logs" --state "$STATE_DIR/$RUN_ID-sql-offsets.json" --output "$OUT/sql"
python3 "$HARNESS_ROOT/scripts/snapshot_sql_logs.py" --source "$LIVE" --state "$STATE_DIR/$RUN_ID-runtime-offsets.json" --output "$OUT/runtime"
python3 "$HARNESS_ROOT/scripts/snapshot_sql_logs.py" --source "$LOCAL_ROOT/postgres/logs" --state "$STATE_DIR/$RUN_ID-postgres-offsets.json" --output "$OUT/postgres" --exclude "$ACTIVE"
find "$WORK/logs" -type f \( -iname '*feature*' -o -iname '*statistic*' -o -iname '*example*' -o -iname '*options*' \) -exec cp --parents {} "$OUT/feedback" \; 2>/dev/null || true
python3 "$HARNESS_ROOT/scripts/analyze_epoch.py" --epoch "$OUT"
{ echo "run_id=$RUN_ID"; echo "captured_at=$(date --iso-8601=seconds)"; "$HARNESS_ROOT/scripts/verify_target.sh"; } > "$OUT/final-manifest.txt"
(cd "$OUT" && find . -type f ! -name checksums.sha256 -print0 | sort -z | xargs -0 sha256sum > checksums.sha256)
date --iso-8601=seconds > "$OUT/COMPLETE"; "$HARNESS_ROOT/scripts/upload_epoch.sh" "$RUN_ID" "$NAME" "$OUT"
