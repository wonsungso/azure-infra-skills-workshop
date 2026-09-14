#!/usr/bin/env bash
# Skill과 도구가 만들어낸 결과를 infra-report.md에 섹션으로 덧붙인다.
# 본문 기록:  bash scripts/add-report.sh "<제목>" "<Skill 또는 도구>" <<'EOF'
#               <markdown 본문>
#             EOF
# 명령 기록:  bash scripts/add-report.sh --run "<제목>" "<도구>" -- <명령...>
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

REPORT=infra-report.md
USAGE='사용법:
  bash scripts/add-report.sh "<제목>" "<Skill 또는 도구>" < 본문
  bash scripts/add-report.sh --run "<제목>" "<도구>" -- <명령...>'

RUN_MODE=0
if [ "${1:-}" = "--run" ]; then RUN_MODE=1; shift; fi

TITLE=${1:-}
TOOL=${2:-}
[ -n "$TITLE" ] && [ -n "$TOOL" ] || { echo "$USAGE" >&2; exit 2; }

# 화면 공유나 이슈에 그대로 붙여넣어도 안전하도록 식별자를 가린다
redact() {
  sed -E \
    -e 's/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/<subscription-id>/g' \
    -e 's/([0-9]{1,3}\.){3}[0-9]{1,3}/<ip>/g' \
    -e 's/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+/<user>/g' \
    -e 's/[A-Za-z0-9-]+\.onmicrosoft\.com/<tenant>/g'
}

if [ ! -f "$REPORT" ]; then
  cat > "$REPORT" <<'EOF'
# 인프라 보고서

Lab을 진행하는 동안 Skill과 도구가 내놓은 조사·검토·결정 결과가 순서대로 쌓입니다.
`scripts/add-report.sh`가 덧붙이며, 커밋되지 않습니다(.gitignore).

subscription·tenant ID, IP, 계정 이메일은 기록될 때 자동으로 가려집니다.
Lab 08의 인계 문서는 이 보고서를 근거로 작성합니다.
EOF
fi

STAMP=$(date '+%Y-%m-%d %H:%M')

if [ "$RUN_MODE" -eq 1 ]; then
  [ "${3:-}" = "--" ] || { echo "$USAGE" >&2; exit 2; }
  shift 3
  [ $# -gt 0 ] || { echo "실행할 명령이 없습니다" >&2; exit 2; }

  OUT=$("$@" 2>&1); CODE=$?
  [ "$CODE" -eq 0 ] && STATUS=관측 || STATUS="실패(exit $CODE)"

  {
    printf '\n## %s\n\n' "$TITLE"
    printf '`%s` · %s · %s\n\n' "$TOOL" "$STAMP" "$STATUS"
    printf '```bash\n%s\n```\n\n' "$(printf '%s ' "$@" | sed 's/[[:space:]]*$//' | redact)"
    printf '```text\n%s\n```\n' "$(printf '%s' "$OUT" | redact)"
  } >> "$REPORT"

  printf '%s\n' "$OUT"
  echo ""
  echo "[$STATUS] $REPORT 에 기록했습니다."
  exit "$CODE"
fi

if [ -t 0 ]; then
  echo "본문을 표준 입력으로 넘겨야 합니다." >&2
  echo "$USAGE" >&2
  exit 2
fi

BODY=$(cat | redact)
[ -n "${BODY//[[:space:]]/}" ] || { echo "본문이 비어 있습니다" >&2; exit 2; }

{
  printf '\n## %s\n\n' "$TITLE"
  printf '`%s` · %s\n\n' "$TOOL" "$STAMP"
  printf '%s\n' "$BODY"
} >> "$REPORT"

echo "$REPORT 에 \"$TITLE\" 섹션을 추가했습니다."
