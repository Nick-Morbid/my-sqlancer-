#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"

commands=(git rsync mvn curl tar sudo ss lcov genhtml zstd python3 gcc g++ make bison flex perl findmnt df)
missing=()
for command in "${commands[@]}"; do
  command -v "$command" >/dev/null 2>&1 || missing+=("$command")
done
[[ "$(id -u postgres 2>/dev/null || true)" =~ ^[0-9]+$ ]] || missing+=("postgres-user")
if ((${#missing[@]})); then
  printf 'ERROR: missing prerequisites: %s\n' "${missing[*]}" >&2
  printf 'Install the missing packages before running bootstrap.sh.\n' >&2
  exit 1
fi
printf 'PREREQUISITES_OK\n'
