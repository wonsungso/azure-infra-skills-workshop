#!/usr/bin/env bash
# 실행 결과나 Skill의 결론을 evidence-log.md 표에 한 줄로 덧붙인다.
# 명령 실행:  bash scripts/log-evidence.sh "<단계>" "<Skill 또는 도구>" -- <명령...>
# 결론 기록:  bash scripts/log-evidence.sh --note "<단계>" "<Skill 또는 도구>" "<수행 작업>" "<결과>" [상태]
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

LOG_FILE=evidence-log.md
USAGE='사용법:
  bash scripts/log-evidence.sh "<단계>" "<Skill 또는 도구>" -- <명령...>
  bash scripts/log-evidence.sh --note "<단계>" "<Skill 또는 도구>" "<수행 작업>" "<결과>" [상태]'

NOTE_MODE=0
if [ "${1:-}" = "--note" ]; then NOTE_MODE=1; shift; fi

STEP=${1:-}
TOOL=${2:-}
if [ -z "$STEP" ] || [ -z "$TOOL" ]; then echo "$USAGE" >&2; exit 2; fi

if [ "$NOTE_MODE" -eq 1 ]; then
  ACTION=${3:-}; RESULT=${4:-}; STATUS=${5:-관측}
  if [ -z "$ACTION" ] || [ -z "$RESULT" ]; then echo "$USAGE" >&2; exit 2; fi
else
  if [ "${3:-}" != "--" ]; then echo "$USAGE" >&2; exit 2; fi
  shift 3
  [ $# -gt 0 ] || { echo "실행할 명령이 없습니다" >&2; exit 2; }
fi

if [ ! -f "$LOG_FILE" ]; then
  cat > "$LOG_FILE" <<'EOF'
# 검증 증거 로그

이 파일은 `scripts/log-evidence.sh`가 자동으로 채웁니다. 커밋되지 않습니다(.gitignore).
`대상`과 `승인/담당자`는 판단이 필요하므로 직접 채우세요.

실제 출력에 token이나 kubeconfig 내용을 넣지 않습니다. subscription·tenant ID와 IP는 자동으로 가려집니다.
오류는 요약만 남기고 원본 로그 위치를 연결하세요.

| 시각 | 단계 | Skill 또는 도구 | 대상 | 수행 작업 | 실제 결과 | 상태 | 승인/담당자 |
| --- | --- | --- | --- | --- | --- | --- | --- |
EOF
fi

# 식별자를 가리고 표 한 칸에 들어가게 다듬는다
redact() {
  sed -E \
    -e 's/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/<id>/g' \
    -e 's/[0-9]{1,3}(\.[0-9]{1,3}){3}/<ip>/g' \
    -e 's/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+/<user>/g' \
    -e 's/[A-Za-z0-9-]+\.onmicrosoft\.com/<tenant>/g' \
    -e 's/\|/／/g'
}

if [ "$NOTE_MODE" -eq 1 ]; then
  CMD=$(printf '%s' "$ACTION" | redact | tr '\n' ' ' | cut -c1-90)
  DIGEST=$(printf '%s' "$RESULT" | redact | tr '\n' ' ' | cut -c1-200)
  CODE=0
else
  OUT=$("$@" 2>&1); CODE=$?
  DIGEST=$(printf '%s' "$OUT" | grep -v '^[[:space:]]*$' | tail -1 | redact | cut -c1-200)
  CMD=$(printf '%s ' "$@" | sed -e 's/[[:space:]]*$//' | redact | cut -c1-90)
  if [ "$CODE" -eq 0 ]; then STATUS='관측'; else STATUS="실패(exit $CODE)"; fi
fi

printf '| %s | %s | %s |  | `%s` | %s | %s |  |\n' \
  "$(date '+%Y-%m-%d %H:%M')" "$STEP" "$TOOL" "$CMD" "${DIGEST:-출력 없음}" "$STATUS" >> "$LOG_FILE"

[ "$NOTE_MODE" -eq 1 ] || printf '%s\n' "$OUT"
echo ""
echo "[$STATUS] $LOG_FILE 에 기록했습니다. '대상'과 '승인/담당자'는 직접 채우세요."
exit "$CODE"
