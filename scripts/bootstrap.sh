#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd "$(dirname "$0")/.."&&pwd)"; ENV="${SQLANCERPP_EXPERIMENT_ENV:-$ROOT/config/experiment.env}"; [[ -f "$ENV" ]]||ENV="$ROOT/config/experiment.env.example"; source "$ENV"
mkdir -p "$LOCAL_ROOT"
# Never delete a previous run's PostgreSQL data or uncommitted spool on rerun.
if [[ "$(readlink -m "$ROOT")" != "$(readlink -m "$LOCAL_ROOT")" ]]; then
  rsync -a --exclude=.git/ --exclude=config/experiment.env --exclude=work/ --exclude=spool/ \
    --exclude=state/ --exclude=logs/ --exclude=postgres/ --exclude=replay/ "$ROOT/" "$LOCAL_ROOT/"
fi
export SQLANCERPP_EXPERIMENT_ENV="$LOCAL_ROOT/config/experiment.env"
if [[ -f "$ROOT/config/experiment.env" && "$(readlink -m "$ROOT/config/experiment.env")" != "$(readlink -m "$LOCAL_ROOT/config/experiment.env")" ]]; then
  cp "$ROOT/config/experiment.env" "$LOCAL_ROOT/config/experiment.env"
fi
"$LOCAL_ROOT/scripts/verify_isolation.sh"
"$LOCAL_ROOT/scripts/prepare_sqlancerpp.sh"; "$LOCAL_ROOT/scripts/build_postgres_cov.sh"; echo "Prepared: $LOCAL_ROOT"
