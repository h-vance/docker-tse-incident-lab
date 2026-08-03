#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
URL=http://127.0.0.1:8099/customers

for _ in $(seq 1 "${VERIFY_ATTEMPTS:-20}"); do
  if response=$(curl --fail --silent --show-error --max-time 2 "$URL" 2>/dev/null); then
    if printf '%s' "$response" | grep -q '"customer_count": 10'; then
      printf 'PASS: customer workflow returned HTTP 200 with customer_count=10.\n'
      exit 0
    fi
  fi
  sleep 1
done

printf 'FAIL: customer workflow did not recover. Inspect docker ps -a and docker compose logs app.\n' >&2
exit 1
