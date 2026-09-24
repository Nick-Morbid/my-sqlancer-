#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"

ROOT="$(readlink -m "$LOCAL_ROOT")"
[[ "$ROOT" != / && "$ROOT" != /app ]] || die "unsafe LOCAL_ROOT: $ROOT"

for item in "$SQLANCER_SOURCE" "$SQLANCER_WORK" "$PG_SOURCE" "$PG_INSTALL" "$PG_DATA" "$PG_SOCKET"; do
  resolved="$(readlink -m "$item")"
  [[ "$resolved" == "$ROOT"/* ]] || die "path escapes LOCAL_ROOT: $resolved"
done

[[ "$(readlink -m "$PG_DATA")" == "$ROOT/postgres/data" ]] || die "unexpected PG_DATA: $PG_DATA"
[[ "$PG_PORT" =~ ^[0-9]+$ && "$PG_PORT" -ge 1024 && "$PG_PORT" -le 65535 ]] || die "invalid PG_PORT: $PG_PORT"
case "$PG_PORT" in
  5432|5433|55433) die "PG_PORT $PG_PORT is reserved by another DBMS/experiment" ;;
esac

[[ "$(readlink -m "$NFS_ROOT")" != "$ROOT" && "$(readlink -m "$NFS_ROOT")" != "$ROOT"/* ]] || \
  die "NFS_ROOT must not be inside LOCAL_ROOT"

printf 'ISOLATION_OK\nlocal_root=%s\npostgres_port=%s\npostgres_data=%s\nsqlancer_work=%s\nnfs_root=%s\n' \
  "$ROOT" "$PG_PORT" "$(readlink -m "$PG_DATA")" "$(readlink -m "$SQLANCER_WORK")" "$(readlink -m "$NFS_ROOT")"
