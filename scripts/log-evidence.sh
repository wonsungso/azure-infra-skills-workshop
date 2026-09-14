#!/usr/bin/env bash
# 명령을 실행하고 그 결과를 evidence-log.md 표에 한 줄로 덧붙인다.
# 사용법: bash scripts/log-evidence.sh "<단계>" "<Skill 또는 도구>" -- <명령...>
#   예:  bash scripts/log-evidence.sh "Lab 01 Step 4" "az CLI" -- az account show -o table
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

LOG_FILE=evidence-log.md

STEP=${1:-}
TOOL=${2:-}
if [ -z "$STEP" ] || [ -z "$TOOL" ] || [ "${3:-}" != "--" ]; then
  echo '사용법: bash scripts/log-evidence.sh "<단계>" "<Skill 또는 도구>" -- <명령...>' >&2
  exit 2
fi
shift 3
[ $# -gt 0 ] || { echo "실행할 명령이 없습니다" >&2; exit 2; }

[ -f "$LOG_FILE" ] || cp templates/evidence-log.md "$LOG_FILE"

OUT=$("$@" 2>&1); CODE=$?

# 표 한 칸에 들어가야 하므로 마지막 의미 있는 줄만 남기고, 식별자는 가린다
DIGEST=$(printf '%s' "$OUT" \
  | grep -v '^[[:space:]]*$' \
  | tail -1 \
  | sed -E \
      -e 's/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/<id>/g' \
      -e 's/[0-9]{1,3}(\.[0-9]{1,3}){3}/<ip>/g' \
      -e 's/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+/<user>/g' \
      -e 's/[A-Za-z0-9-]+\.onmicrosoft\.com/<tenant>/g' \
      -e 's/\|//g' \
  | cut -c1-120)

if [ "$CODE" -eq 0 ]; then STATUS='관측'; else STATUS="실패(exit $CODE)"; fi

CMD=$(printf '%s ' "$@" | sed -e 's/[[:space:]]*$//' -e 's/|//g' | cut -c1-90)

printf '| %s | %s | %s |  | `%s` | %s | %s |  |\n' \
  "$(date '+%Y-%m-%d %H:%M')" "$STEP" "$TOOL" "$CMD" "${DIGEST:-출력 없음}" "$STATUS" >> "$LOG_FILE"

printf '%s\n' "$OUT"
echo ""
echo "[$STATUS] $LOG_FILE 에 기록했습니다. '대상'과 '승인/담당자'는 직접 채우세요."
exit "$CODE"
