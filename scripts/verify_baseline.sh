#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"
require_file "$SQLANCER_WORK/SOURCE_COMMIT"
ACTUAL="$(<"$SQLANCER_WORK/SOURCE_COMMIT")"
[[ "$ACTUAL" == "$SQLANCER_REF" ]] || die "work copy commit $ACTUAL differs from pinned baseline $SQLANCER_REF"
require_file "$SQLANCER_WORK/target/sqlancer-2.0.0.jar"
if rg -n -- '--enable-learning|--enable-extra-features|--load-learned-fragments|--resume-learned-fragments' "$HARNESS_ROOT/profiles"; then
  die 'ShQveL-only option found in baseline profile'
fi
printf 'baseline_commit=%s\nshqvel_flags_in_profiles=none\n' "$ACTUAL"
