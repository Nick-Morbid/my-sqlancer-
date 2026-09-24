#!/usr/bin/env bash
set -Eeuo pipefail
source "$(dirname "$0")/common.sh"
if [[ ! -d "$SQLANCER_SOURCE/.git" ]]; then
  git clone "$SQLANCER_REPO_URL" "$SQLANCER_SOURCE"
fi
git -C "$SQLANCER_SOURCE" fetch --all --tags
git -C "$SQLANCER_SOURCE" checkout "$SQLANCER_REF"
RESOLVED_COMMIT="$(git -C "$SQLANCER_SOURCE" rev-parse HEAD)"
mkdir -p "$(dirname "$SQLANCER_WORK")"
rsync -a --delete --exclude=.git/ --exclude=logs/ --exclude=databases/ --exclude=target/ \
  "$SQLANCER_SOURCE/" "$SQLANCER_WORK/"
(cd "$SQLANCER_WORK" && mvn -q -DskipTests package)
printf '%s\n' "$RESOLVED_COMMIT" > "$SQLANCER_WORK/SOURCE_COMMIT"
