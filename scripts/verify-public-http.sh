#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

[ $# -eq 0 ] || {
  echo "사용법: bash scripts/verify-public-http.sh" >&2
  exit 2
}
set -a
. ./.env
set +a
[ "${NAMESPACE:-}" = lab ] || {
  echo "이 검증은 lab Namespace 전용입니다." >&2
  exit 1
}
address=$(kubectl -n "$NAMESPACE" get gateway lab-gateway \
  --request-timeout=30s -o jsonpath='{.status.addresses[0].value}')
[ -n "$address" ] || {
  echo "Gateway 주소가 비어 있습니다. Accepted·Programmed를 먼저 확인하세요." >&2
  exit 1
}
url="http://$address"
errors=$(mktemp)
trap 'rm -f -- "$errors"' EXIT
deadline=$((SECONDS+180))
while :; do
  reason=""
  if page=$(curl -4 -fsS --connect-timeout 5 --max-time 20 "$url" 2>"$errors"); then
    if [[ "$page" != *"Contoso Shop"* ]]; then
      reason="HTTP body does not contain Contoso Shop"
    elif product=$(curl -4 -fsS --connect-timeout 5 --max-time 20 \
      "$url/data/products.txt" 2>"$errors"); then
      [ "$product" = 'Dune Light DL-12 · KRW 250000' ] \
        || reason="HTTP product does not match the expected SQL row"
    else
      reason="SQL-derived product endpoint is not ready"
    fi
  else
    reason="Public HTTP endpoint is not ready"
  fi
  if [ -z "$reason" ]; then
    break
  fi
  if [ "$SECONDS" -ge "$deadline" ]; then
    echo "Public HTTP 준비 확인이 180초 안에 완료되지 않았습니다: $reason" >&2
    cat "$errors" >&2
    exit 1
  fi
  echo "Waiting for public HTTP: $reason"
  sleep 5
done
echo "Public HTTP 200: Contoso Shop"
printf '%s\n' "$product"
echo "Open: $url"
