#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"
[[ $# -eq 4 ]] || die "usage: $0 RUN_ID EPOCH_NUMBER WORK_REPO LIVE_DIR"
RUN_ID="$1"; N="$2"; WORK_REPO="$(readlink -m "$3")"; LIVE_DIR="$(readlink -m "$4")"
NAME="$(printf 'epoch-%02d' "$N")"; OUT="$SPOOL_DIR/$RUN_ID/$NAME"; START="$(date --iso-8601=ns)"; START_NS="$(date +%s%N)"
mkdir -p "$OUT/sql" "$OUT/runtime" "$OUT/postgres" "$OUT/feedback" "$OUT/coverage"
psql_cov -Atc 'SELECT pg_rotate_logfile();' >/dev/null; sleep 1
ACTIVE="$(basename "$(psql_cov -Atc "SELECT pg_current_logfile('csvlog');")")"
python3 "$HARNESS_ROOT/scripts/snapshot_sql_logs.py" --source "$WORK_REPO/logs" --state "$STATE_DIR/$RUN_ID-sql-offsets.json" --output "$OUT/sql"
python3 "$HARNESS_ROOT/scripts/snapshot_sql_logs.py" --source "$LIVE_DIR" --state "$STATE_DIR/$RUN_ID-runtime-offsets.json" --output "$OUT/runtime"
python3 "$HARNESS_ROOT/scripts/snapshot_sql_logs.py" --source "$LOCAL_ROOT/postgres/logs" --state "$STATE_DIR/$RUN_ID-postgres-offsets.json" --output "$OUT/postgres" --exclude "$ACTIVE"
find "$WORK_REPO/logs" -type f \( -iname '*feature*' -o -iname '*statistic*' -o -iname '*example*' -o -iname '*options*' \) -exec cp --parents {} "$OUT/feedback" \; 2>/dev/null || true
"$HARNESS_ROOT/scripts/collect_coverage.sh" "$OUT/coverage"
python3 "$HARNESS_ROOT/scripts/analyze_epoch.py" --epoch "$OUT"
{
 echo "run_id=$RUN_ID"; echo "epoch=$N"; echo "snapshot_started_at=$START"; echo "captured_at=$(date --iso-8601=seconds)";
 echo "snapshot_elapsed_seconds=$(( ($(date +%s%N)-START_NS)/1000000000 ))"; "$HARNESS_ROOT/scripts/verify_target.sh";
} > "$OUT/epoch-manifest.txt"
(cd "$OUT" && find . -type f ! -name checksums.sha256 -print0 | sort -z | xargs -0 sha256sum > checksums.sha256)
date --iso-8601=seconds > "$OUT/COMPLETE"
"$HARNESS_ROOT/scripts/upload_epoch.sh" "$RUN_ID" "$NAME" "$OUT"
python3 "$HARNESS_ROOT/scripts/prune_uploaded_epoch.py" --local-root "$LOCAL_ROOT" --run-id "$RUN_ID" --epoch "$NAME" --remote "$NFS_ROOT/$RUN_ID/$NAME" --postgres-logs "$LOCAL_ROOT/postgres/logs" --offset-state "$STATE_DIR/$RUN_ID-postgres-offsets.json" --active-log "$ACTIVE" --sql-logs "$WORK_REPO/logs" --sql-offset-state "$STATE_DIR/$RUN_ID-sql-offsets.json"
