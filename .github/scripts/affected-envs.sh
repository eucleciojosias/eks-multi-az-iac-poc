#!/usr/bin/env bash

set -euo pipefail

changed_envs() {
  git diff --name-only "$1...HEAD" |
    sed -nE 's|^infra/envs/([^/]+)/.*|\1|p' | sort -u
}

case "${EVENT:-}" in
  workflow_dispatch)
    envs="${DISPATCH_ENV:-}"
    ;;
  pull_request)
    envs=$(changed_envs "origin/${BASE_REF:-main}")
    ;;
  *)
    envs=$(changed_envs "HEAD~1")
    ;;
esac

json=$(printf '%s' "$envs" | jq -Rsc 'split("\n") | map(select(length > 0))')

out="${GITHUB_OUTPUT:-/dev/stdout}"
echo "envs=$json" >>"$out"
[ "$(jq length <<<"$json")" -gt 0 ] && echo "any=true" >>"$out" || echo "any=false" >>"$out"
