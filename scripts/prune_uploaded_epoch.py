#!/usr/bin/env python3
"""Prune only data proven uploaded, while retaining active PostgreSQL logs."""
import argparse
import json
import shutil
from pathlib import Path

p = argparse.ArgumentParser()
p.add_argument("--local-root", required=True)
p.add_argument("--run-id", required=True)
p.add_argument("--epoch", required=True)
p.add_argument("--remote", required=True)
p.add_argument("--postgres-logs", required=True)
p.add_argument("--offset-state", required=True)
p.add_argument("--active-log", default="")
p.add_argument("--sql-logs", required=True)
p.add_argument("--sql-offset-state", required=True)
a = p.parse_args()

root = Path(a.local_root).resolve()
epoch = (root / "spool" / a.run_id / a.epoch).resolve()
remote = Path(a.remote).resolve()
logs = Path(a.postgres_logs).resolve()
sql_logs = Path(a.sql_logs).resolve()
if root not in epoch.parents or epoch.name != a.epoch or not a.epoch.startswith("epoch-"):
    raise SystemExit(f"unsafe epoch path: {epoch}")
if not (remote / "COMPLETE").is_file() or not (remote / "checksums.sha256").is_file():
    raise SystemExit(f"remote epoch is not committed: {remote}")
if not epoch.is_dir():
    raise SystemExit(f"local epoch is missing: {epoch}")

offsets = json.loads(Path(a.offset_state).read_text())
chunk_manifest = json.loads((epoch / "postgres" / "chunks.json").read_text())
eligible = {item["source"] for item in chunk_manifest}
active = Path(a.active_log).name
removed_logs = []
for rel, captured_size in offsets.items():
    path = (logs / rel).resolve()
    if rel not in eligible or logs not in path.parents or path.name == active or not path.is_file():
        continue
    # A growing or replaced file is never safe to unlink.
    if path.stat().st_size == int(captured_size) and path.suffix == ".csv":
        path.unlink()
        removed_logs.append(str(path))

# The byte-identical, checksum-verified NFS copy is now authoritative. The
# local epoch is removed only after both PostgreSQL and SQLancer cleanup below.

# SQLancer logs are append-only during a run too. Remove only files whose
# committed byte range did not grow while the NFS upload was in progress.
sql_offsets = json.loads(Path(a.sql_offset_state).read_text())
sql_manifest = json.loads((epoch / "sql" / "chunks.json").read_text())
sql_captured = {item["source"]: item["end"] for item in sql_manifest}
removed_sql_logs = []
for rel, captured_size in sql_offsets.items():
    path = (sql_logs / rel).resolve()
    if (rel not in sql_captured or sql_logs not in path.parents or
            not path.is_file() or path.stat().st_size != int(captured_size)):
        continue
    if path.suffix in {".log", ".txt"}:
        path.unlink()
        removed_sql_logs.append(str(path))
print(json.dumps({"removed_sql_logs": removed_sql_logs}))
shutil.rmtree(epoch)
print(json.dumps({"removed_local_epoch": str(epoch), "removed_logs": removed_logs,
                  "removed_sql_logs": removed_sql_logs}))
