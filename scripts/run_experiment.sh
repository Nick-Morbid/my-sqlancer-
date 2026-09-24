#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"
HOURS="${1:-$EXPERIMENT_HOURS}"; EPOCH="${2:-$EPOCH_SECONDS}"; PROFILE_NAME="${3:-$PROFILE}"
[[ "$HOURS" =~ ^[0-9]+$ && "$HOURS" -gt 0 && "$EPOCH" =~ ^[0-9]+$ && "$EPOCH" -gt 0 ]] || die 'invalid duration'
PROFILE_FILE="$HARNESS_ROOT/profiles/$PROFILE_NAME.args"; require_file "$PROFILE_FILE"
RUN_ID="${SQLANCERPP_RUN_ID:-$(date +%Y%m%d_%H%M%S)-$PROFILE_NAME}"
[[ ! -e "$SPOOL_DIR/$RUN_ID" && ! -e "$NFS_ROOT/$RUN_ID" ]] || die "run id exists: $RUN_ID"
WORK="$SQLANCER_WORK"; require_file "$WORK/target/sqlancer-2.0.0.jar"; LIVE="$SPOOL_DIR/$RUN_ID/live"; mkdir -p "$LIVE" "$NFS_ROOT/$RUN_ID"
LAUNCHER=''; PGROUP=''
cleanup(){ rc=$?; if ((rc)); then if [[ "$PGROUP" =~ ^[0-9]+$ ]]; then kill -TERM -- "-$PGROUP" 2>/dev/null||true; for _ in {1..10}; do kill -0 -- "-$PGROUP" 2>/dev/null||break; sleep 1; done; kill -KILL -- "-$PGROUP" 2>/dev/null||true; fi; [[ "$LAUNCHER" =~ ^[0-9]+$ ]]&&wait "$LAUNCHER" 2>/dev/null||true; pg_is_running||"$HARNESS_ROOT/scripts/start_postgres_cov.sh" >/dev/null 2>&1||true; printf '{"run_id":"%s","harness_exit":%s,"aborted_at":"%s"}\n' "$RUN_ID" "$rc" "$(date --iso-8601=seconds)" > "$LIVE/harness-abort.json"; fi; }
trap cleanup EXIT
"$HARNESS_ROOT/scripts/verify_target.sh" > "$LIVE/target-verification.txt"; "$HARNESS_ROOT/scripts/stop_postgres_cov.sh"; "$HARNESS_ROOT/scripts/reset_coverage.sh"; "$HARNESS_ROOT/scripts/start_postgres_cov.sh"; "$HARNESS_ROOT/scripts/verify_target.sh" >> "$LIVE/target-verification.txt"
python3 "$HARNESS_ROOT/scripts/initialize_offsets.py" --source "$LOCAL_ROOT/postgres/logs" --state "$STATE_DIR/$RUN_ID-postgres-offsets.json"
[[ ! -d "$WORK/logs" ]] || mv "$WORK/logs" "$WORK/logs.before-$RUN_ID"; mkdir -p "$WORK/logs"
export SQLANCER_POSTGRESQL_URL="jdbc:postgresql://127.0.0.1:$PG_PORT/$PG_DATABASE?user=$PG_USER&password=$PG_PASSWORD&ApplicationName=SQLancerPlusPlus-24h"
PROFILE_ARGS=()
while IFS= read -r line; do
  [[ "$line" =~ ^[[:space:]]*(#|$) ]] && continue
  read -r -a parts <<< "$line"
  PROFILE_ARGS+=("${parts[@]}")
done < "$PROFILE_FILE"
COMMIT="$(<"$WORK/SOURCE_COMMIT")"; JAR_HASH="$(sha256sum "$WORK/target/sqlancer-2.0.0.jar"|awk '{print $1}')"
printf '{"run_id":"%s","started_at":"%s","hours":%s,"epoch_seconds":%s,"profile":"%s","mode":"sqlancerpp-general-adaptive","feedback":%s,"source_commit":"%s","jar_sha256":"%s","threads":1,"num_queries":100000,"random_seed":%s}\n' "$RUN_ID" "$(date --iso-8601=seconds)" "$HOURS" "$EPOCH" "$PROFILE_NAME" "$([[ "$PROFILE_NAME" == *no-feedback* ]]&&echo false||echo true)" "$COMMIT" "$JAR_HASH" "$RANDOM_SEED" > "$LIVE/run-manifest.json"
GROUP_FILE="$STATE_DIR/$RUN_ID-group.pid"
(cd "$WORK"; exec python3 "$HARNESS_ROOT/scripts/run_process_group.py" --pid-file "$GROUP_FILE" -- timeout --signal=INT --kill-after=60 "$((HOURS*EPOCH))" java -jar target/sqlancer-2.0.0.jar --num-threads 1 --num-tries 1000000 --num-queries 100000 --random-seed "$RANDOM_SEED" --log-each-select true --log-execution-time true general --database-engine postgresql "${PROFILE_ARGS[@]}") > "$LIVE/sqlancerpp.stdout.log" 2>&1 &
LAUNCHER=$!; for _ in {1..100}; do [[ -s "$GROUP_FILE" ]]&&break; kill -0 "$LAUNCHER" 2>/dev/null||break; sleep .1; done; require_file "$GROUP_FILE"; PGROUP="$(<"$GROUP_FILE")"
START="$(date +%s)"; for ((n=1;n<=HOURS;n++)); do deadline=$((START+n*EPOCH)); while kill -0 "$LAUNCHER" 2>/dev/null; do now=$(date +%s); ((now>=deadline))&&break; s=$((deadline-now)); ((s>30))&&s=30; sleep "$s"; done; "$HARNESS_ROOT/scripts/snapshot_epoch.sh" "$RUN_ID" "$n" "$WORK" "$LIVE"; kill -0 "$LAUNCHER" 2>/dev/null||break; done
wait "$LAUNCHER"||STATUS=$?; STATUS="${STATUS:-0}"; echo "$STATUS" > "$LIVE/exit-status.txt"; printf '{"run_id":"%s","ended_at":"%s","process_status":%s,"completed_scheduled_duration":%s}\n' "$RUN_ID" "$(date --iso-8601=seconds)" "$STATUS" "$([[ "$STATUS" -eq 124 ]]&&echo true||echo false)" > "$LIVE/run-result.json"
"$HARNESS_ROOT/scripts/snapshot_final_artifacts.sh" "$RUN_ID" "$WORK" "$LIVE"; "$HARNESS_ROOT/scripts/stop_postgres_cov.sh"; FINAL="$SPOOL_DIR/$RUN_ID/final-coverage"; "$HARNESS_ROOT/scripts/collect_coverage.sh" "$FINAL"; "$HARNESS_ROOT/scripts/start_postgres_cov.sh"; (cd "$FINAL"&&find . -type f ! -name checksums.sha256 -print0|sort -z|xargs -0 sha256sum > checksums.sha256); date --iso-8601=seconds > "$FINAL/COMPLETE"; "$HARNESS_ROOT/scripts/upload_epoch.sh" "$RUN_ID" final-coverage "$FINAL"
echo "run_id=$RUN_ID status=$STATUS"
