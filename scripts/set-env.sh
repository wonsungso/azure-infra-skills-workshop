#!/usr/bin/env bash
# .env의 값을 안전하게 바꾼다. 손으로 편집하다 생기는 오타와 중복 키를 막는다.
# 사용법: bash scripts/set-env.sh KEY VALUE [KEY VALUE ...]
#   예:  bash scripts/set-env.sh REGION koreacentral SYSTEM_VM_SIZE Standard_D4s_v5
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

ENV_FILE=.env

[ -f "$ENV_FILE" ] || {
  echo "$ENV_FILE 이(가) 없습니다. 먼저 실행하세요: bash scripts/init-workshop.sh" >&2
  exit 1
}
[ $# -gt 0 ] && [ $(($# % 2)) -eq 0 ] || {
  echo '사용법: bash scripts/set-env.sh KEY VALUE [KEY VALUE ...]' >&2
  exit 2
}

while [ $# -gt 0 ]; do
  key=$1 val=$2
  shift 2

  # .env에 없는 키는 오타일 가능성이 높다. 조용히 추가하지 않고 멈춘다.
  grep -qE "^${key}=" "$ENV_FILE" || {
    echo "  알 수 없는 항목: $key" >&2
    echo "  사용 가능한 항목: $(grep -oE '^[A-Z_]+=' "$ENV_FILE" | tr -d '=' | tr '\n' ' ')" >&2
    exit 1
  }

  cur=$(grep -E "^${key}=" "$ENV_FILE" | head -1 | cut -d= -f2- || true)
  sed -i "s|^${key}=.*|${key}=${val}|" "$ENV_FILE"
  echo "  $key: ${cur:-(비어 있음)} -> $val"
done
