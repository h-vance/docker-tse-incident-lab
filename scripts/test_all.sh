#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$ROOT_DIR"

cleanup() {
  docker compose down --remove-orphans >/dev/null 2>&1 || true
  rm -f compose.override.yaml .current-scenario
}
trap cleanup EXIT

python3 -m py_compile app.py

for incident in 1 2 3; do
  bash scripts/lab.sh start "$incident" >/dev/null
  if VERIFY_ATTEMPTS=3 bash scripts/verify.sh >/dev/null 2>&1; then
    printf 'FAIL: incident %s unexpectedly passed before correction.\n' "$incident" >&2
    exit 1
  fi

  case "$incident" in
    1) perl -pi -e 's/APP_SECRET: ""/APP_SECRET: lab-secret/' compose.override.yaml ;;
    2) perl -pi -e 's/DB_HOST: localhost/DB_HOST: postgres/' compose.override.yaml ;;
    3) perl -pi -e 's/DB_PASSWORD: stale-demo-password/DB_PASSWORD: demo-password/' compose.override.yaml ;;
  esac
  docker compose up -d --build --force-recreate >/dev/null
  bash scripts/verify.sh >/dev/null
  printf 'PASS: incident %s fails as designed and its scoped correction recovers.\n' "$incident"
  rm -f compose.override.yaml .current-scenario
done

printf 'All Docker incident lab tests passed.\n'
