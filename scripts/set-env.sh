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

args=("$@")
for ((i=0; i<${#args[@]}; i+=2)); do
  key=${args[i]} val=${args[i+1]}
  [[ "$key" =~ ^[A-Z_][A-Z0-9_]*$ ]] || {
    echo "  항목 이름 형식이 잘못됐습니다: $key" >&2
    exit 1
  }
  [ "$(grep -c "^${key}=" "$ENV_FILE" || true)" -eq 1 ] || {
    echo "  알 수 없는 항목: $key" >&2
    echo "  항목이 중복된 경우에도 변경하지 않습니다." >&2
    echo "  사용 가능한 항목: $(grep -oE '^[A-Z_]+=' "$ENV_FILE" | tr -d '=' | tr '\n' ' ')" >&2
    exit 1
  }
  [[ "$val" =~ ^[A-Za-z0-9_./:@-]*$ ]] || {
    echo "  $key 값에 지원하지 않는 문자가 있습니다. 변경하지 않습니다." >&2
    exit 1
  }
done

TMP=$(mktemp "${ENV_FILE}.XXXXXX")
trap 'rm -f -- "$TMP"' EXIT
cp "$ENV_FILE" "$TMP"
messages=()
while [ $# -gt 0 ]; do
  key=$1 val=$2
  shift 2
  cur=$(grep "^${key}=" "$TMP" | cut -d= -f2-)
  if [ "$cur" = "$val" ]; then
    messages+=("  $key: $val (그대로)")
  else
    sed -i "s|^${key}=.*|${key}=${val}|" "$TMP"
    messages+=("  $key: ${cur:-(비어 있음)} -> $val")
  fi
done
mv "$TMP" "$ENV_FILE"
printf '%s\n' "${messages[@]}"
