#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
STATE_FILE="$ROOT_DIR/.current-scenario"
OVERRIDE_FILE="$ROOT_DIR/compose.override.yaml"

ticket() {
  case "$1" in
    1)
      printf '%s\n' \
        'CUSTOMER TICKET — Application unavailable after deployment' \
        'The web application never becomes available after this morning deployment.' \
        'Determine the root cause, restore service, and verify the customer workflow.'
      ;;
    2)
      printf '%s\n' \
        'CUSTOMER TICKET — API cannot load customer data' \
        'The application starts, but /customers returns 503 after a Compose change.' \
        'Determine whether the failure is application, database, or connectivity related.'
      ;;
    3)
      printf '%s\n' \
        'CUSTOMER TICKET — Database access failed after credential rotation' \
        'The database is healthy, but the application returns 503 after credentials changed.' \
        'Identify the mismatched configuration, restore service, and verify the request.'
      ;;
    *) printf 'No active incident. Start one with make incident-1, make incident-2, or make incident-3.\n' ;;
  esac
}

answer() {
  case "$1" in
    1) printf '%s\n' 'Root cause: APP_SECRET is empty. Set APP_SECRET to a non-empty demo value, run make apply, then make verify.' ;;
    2) printf '%s\n' 'Root cause: localhost points back to the app container. Set DB_HOST to postgres, run make apply, then make verify.' ;;
    3) printf '%s\n' 'Root cause: the app password differs from PostgreSQL. Set DB_PASSWORD to demo-password, run make apply, then make verify.' ;;
    *) printf 'No active incident.\n' ;;
  esac
}

start_incident() {
  local incident=$1
  local scenario="$ROOT_DIR/scenarios/incident-$incident.compose.yaml"
  test -f "$scenario" || { printf 'Unknown incident: %s\n' "$incident" >&2; exit 1; }

  cp "$scenario" "$OVERRIDE_FILE"
  printf '%s\n' "$incident" > "$STATE_FILE"
  cd "$ROOT_DIR"
  docker compose up -d --build --force-recreate
  printf '\n'
  ticket "$incident"
  printf '\nStart with: docker ps -a\n'
}

reset_lab() {
  cd "$ROOT_DIR"
  docker compose down --remove-orphans
  rm -f "$OVERRIDE_FILE" "$STATE_FILE"
  docker compose up -d --build
  printf 'Lab reset to the healthy baseline. Run make verify.\n'
}

action=${1:-}
case "$action" in
  start) start_incident "${2:-}" ;;
  reset) reset_lab ;;
  ticket) ticket "$(cat "$STATE_FILE" 2>/dev/null || true)" ;;
  answer) answer "$(cat "$STATE_FILE" 2>/dev/null || true)" ;;
  *) printf 'Usage: %s {start N|reset|ticket|answer}\n' "$0" >&2; exit 1 ;;
esac
