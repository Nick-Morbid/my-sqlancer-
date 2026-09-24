#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"
"$HARNESS_ROOT/scripts/verify_isolation.sh"
require_file "$SQLANCER_WORK/target/sqlancer-2.0.0.jar"; require_file "$HARNESS_ROOT/profiles/$PROFILE.args"
"$HARNESS_ROOT/scripts/verify_baseline.sh"
findmnt -T "$NFS_ROOT" -n -o FSTYPE|grep -q '^nfs'; "$HARNESS_ROOT/scripts/verify_target.sh"
avail=$(df --output=avail "$LOCAL_ROOT"|tail -1); ((avail>=10*1024*1024))||die 'less than 10 GiB free'
python3 - "$NFS_ROOT" <<'PY'
import os,sys,uuid
from pathlib import Path
p=Path(sys.argv[1])/('.sqlancerpp-preflight-'+uuid.uuid4().hex); p.write_bytes(b'probe'); f=p.open('rb'); assert f.read()==b'probe'; os.fsync(f.fileno()); f.close(); p.unlink()
PY
printf 'PREFLIGHT_OK\nREADY_FOR_24H=YES\nprofile=%s\n' "$PROFILE" | tee "$STATE_DIR/preflight-report.txt"
