#!/usr/bin/env bash
# Lab 결과를 infra-report.md의 정해진 장에 채워 넣는다.
# 본문:  bash scripts/add-report.sh <장> "<제목>" "<Skill 또는 도구>" <<'EOF'
#          <markdown 본문>
#        EOF
# 명령:  bash scripts/add-report.sh --run <장> "<제목>" "<도구>" -- <명령...>
set -uo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

REPORT=infra-report.md
FOLD_AFTER=12   # 출력이 이보다 길면 접어 둔다

SECTION_KEYS=(env capacity design access plan validate deploy workload incident cleanup)
section_title() {
  case $1 in
    env)      echo "환경과 범위" ;;
    capacity) echo "용량 검토" ;;
    design)   echo "설계 결정" ;;
    access)   echo "권한 설계" ;;
    plan)     echo "인프라 계획과 코드" ;;
    validate) echo "배포 전 검증" ;;
    deploy)   echo "배포 결과" ;;
    workload) echo "워크로드" ;;
    incident) echo "장애와 복구" ;;
    cleanup)  echo "정리와 인계" ;;
    *) return 1 ;;
  esac
}
section_icon() {
  case $1 in
    env) echo "🌐" ;; capacity) echo "📊" ;; design) echo "🧭" ;; access) echo "🔐" ;;
    plan) echo "📐" ;; validate) echo "🔍" ;; deploy) echo "🚀" ;; workload) echo "📦" ;;
    incident) echo "🚨" ;; cleanup) echo "🧹" ;;
  esac
}
section_desc() {
  case $1 in
    env)      echo "subscription·scope 확인" ;;
    capacity) echo "quota와 용량 판정" ;;
    design)   echo "Day-0 선택과 CIDR·SKU" ;;
    access)   echo "역할과 scope" ;;
    plan)     echo "계획·승인·IaC" ;;
    validate) echo "build·보안·what-if" ;;
    deploy)   echo "배포 결과와 생성 자원" ;;
    workload) echo "샘플 워크로드 검증" ;;
    incident) echo "증상·원인·복구" ;;
    cleanup)  echo "삭제와 인계 사항" ;;
  esac
}

USAGE="사용법:
  bash scripts/add-report.sh <장> \"<제목>\" \"<Skill 또는 도구>\" < 본문
  bash scripts/add-report.sh --run <장> \"<제목>\" \"<도구>\" -- <명령...>

<장>: ${SECTION_KEYS[*]}"

RUN_MODE=0
if [ "${1:-}" = "--run" ]; then RUN_MODE=1; shift; fi

SECTION=${1:-}; TITLE=${2:-}; TOOL=${3:-}
if ! section_title "$SECTION" >/dev/null 2>&1 || [ -z "$TITLE" ] || [ -z "$TOOL" ]; then
  echo "$USAGE" >&2; exit 2
fi

# 화면 공유나 이슈에 붙여넣어도 안전하도록 식별자를 가린다.
# Pod·Service CIDR 같은 사설 대역은 설계값이므로 남긴다.
redact() {
  awk '
    function scrub_ip(s,   out, ip) {
      # 1.0.0.0 같은 버전 문자열이 IPv4와 구별되지 않으므로 같은 줄의 맥락으로 가린다
      if (s ~ /[Vv]ersion|templateHash/) return s
      out = ""
      while (match(s, /[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/)) {
        ip = substr(s, RSTART, RLENGTH)
        out = out substr(s, 1, RSTART - 1)
        if (ip ~ /^(0|10|127)\./ || ip ~ /^192\.168\./ || ip ~ /^172\.(1[6-9]|2[0-9]|3[01])\./)
          out = out ip
        else
          out = out "[ip]"
        s = substr(s, RSTART + RLENGTH)
      }
      return out s
    }
    {
      gsub(/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/, "[id]")
      gsub(/[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+/, "[user]")
      gsub(/[A-Za-z0-9-]+\.onmicrosoft\.com/, "[tenant]")
      gsub(/[A-Za-z]:\\Users\\[^\\]+/, "[home]")
      gsub(/\/(home|Users)\/[^\/ ]+/, "[home]")
      print scrub_ip($0)
    }
  '
}

# 보고서의 명령을 그대로 복사해 쓸 수 있도록 공백·특수문자 인자는 감싼다
quote_args() {
  local a esc out=""
  for a in "$@"; do
    case $a in
      *[!A-Za-z0-9_./:=-]*)
        esc=${a//\\/\\\\}      # 백슬래시를 먼저 escape해야 뒤의 따옴표 처리가 깨지지 않는다
        esc=${esc//\"/\\\"}
        out="$out\"$esc\" " ;;
      *) out="$out$a " ;;
    esac
  done
  printf '%s' "${out% }"
}

# az CLI가 매번 뿜는 확장·대체 경고는 보고서에서 잡음이다
drop_noise() {
  grep -avE 'pkg_resources|UserWarning|^[[:space:]]*__import__|^WARNING: The behavior of this command has been altered|^WARNING: A new Bicep release is available|^WARNING: Merged' || true
}

env_value() { grep -E "^$1=" .env 2>/dev/null | head -1 | cut -d= -f2- ; }
code_or_dash() { local v; v=$(env_value "$1"); [ -n "$v" ] && printf '`%s`' "$v" || printf '—'; }
text_or_dash() { local v; v=$(env_value "$1"); [ -n "$v" ] && printf '%s' "$v" || printf '—'; }

build_meta() {
  local rg aks region
  rg=$(text_or_dash RESOURCE_GROUP); aks=$(text_or_dash AKS_NAME); region=$(text_or_dash REGION)
  printf '**%s** · %s · `%s`\n\n' "$aks" "$region" "$rg"
  printf '> 이 문서는 Lab을 진행하는 동안 자동으로 작성됩니다. 최종 갱신 %s\n' "$(date '+%Y-%m-%d %H:%M')"
}

build_summary() {
  cat <<EOF
| 구성 항목 | 값 | 수행 Lab |
| --- | --- | --- |
| VNet | $(code_or_dash VNET_NAME) | Lab 03 |
| Node resource group | $(code_or_dash NODE_RESOURCE_GROUP) | Lab 05 |
| System node SKU | $(text_or_dash SYSTEM_VM_SIZE) | Lab 02 |
| User node SKU | $(text_or_dash USER_VM_SIZE) | Lab 02 |
| Pod CIDR | $(text_or_dash POD_CIDR) | Lab 02 |
| Service CIDR | $(text_or_dash SERVICE_CIDR) | Lab 02 |
| DNS service IP | $(text_or_dash DNS_SERVICE_IP) | Lab 02 |
| API server 허용 대역 | $(text_or_dash EGRESS_IP_CIDR) | Lab 01 |
| 워크로드 namespace | $(code_or_dash NAMESPACE) | Lab 05 |
EOF
}

if [ ! -f "$REPORT" ]; then
  {
    printf '# AKS 인프라 구성 보고서\n\n'
    printf '<!-- meta:begin -->\n<!-- meta:end -->\n\n'
    printf '## 진행 현황\n\n'
    printf '<!-- toc:begin -->\n<!-- toc:end -->\n\n'
    printf '## 구성 요약\n\n'
    printf '<!-- summary:begin -->\n<!-- summary:end -->\n'
    n=0
    for k in "${SECTION_KEYS[@]}"; do
      n=$((n+1))
      printf '\n---\n\n## %d. %s\n\n' "$n" "$(section_title "$k")"
      printf '<!-- section:%s -->\n' "$k"
      printf '아직 기록되지 않았습니다.\n'
      printf '<!-- end:%s -->\n' "$k"
    done
    printf '\n---\n\n'
    printf '<sub>`scripts/add-report.sh`가 작성 · subscription·tenant ID와 공인 IP, 계정, 로컬 경로는 가려짐 · 커밋되지 않음(.gitignore)</sub>\n'
  } > "$REPORT"
fi

STAMP=$(date '+%Y-%m-%d %H:%M')

if [ "$RUN_MODE" -eq 1 ]; then
  [ "${4:-}" = "--" ] || { echo "$USAGE" >&2; exit 2; }
  shift 4
  [ $# -gt 0 ] || { echo "실행할 명령이 없습니다" >&2; exit 2; }
  OUT=$("$@" 2>&1); CODE=$?
  if [ "$CODE" -eq 0 ]; then STATUS='🟢 관측'; else STATUS="🔴 실패 (exit $CODE)"; fi

  # Windows의 az는 콘솔 코드페이지로 출력해 비ASCII 투영 이름이 깨진다. 깨진 채로 묻지 않는다.
  if ! printf '%s' "$OUT" | iconv -f UTF-8 -t UTF-8 >/dev/null 2>&1; then
    STATUS="🟡 인코딩 깨짐"
    OUT="$OUT

[기록 도구] 이 출력은 UTF-8이 아닙니다. --query 투영 이름을 ASCII로 바꿔 다시 실행하세요."
  fi
  CLEAN_OUT=$(printf '%s' "$OUT" | drop_noise | redact)
  CLEAN_CMD=$(quote_args "$@" | redact)
  LINES=$(printf '%s\n' "$CLEAN_OUT" | wc -l)

  if [ "$LINES" -gt "$FOLD_AFTER" ]; then
    RESULT_BLOCK=$(printf '<details>\n<summary>실행 결과 %s줄</summary>\n\n```text\n%s\n```\n\n</details>' "$LINES" "$CLEAN_OUT")
  else
    RESULT_BLOCK=$(printf '```text\n%s\n```' "$CLEAN_OUT")
  fi

  ENTRY=$(printf '### %s\n\n%s · `%s` · %s\n\n%s\n\n<details>\n<summary>실행한 명령</summary>\n\n```bash\n%s\n```\n\n</details>\n' \
    "$TITLE" "$STATUS" "$TOOL" "$STAMP" "$RESULT_BLOCK" "$CLEAN_CMD")
else
  [ -t 0 ] && { echo "본문을 표준 입력으로 넘겨야 합니다." >&2; echo "$USAGE" >&2; exit 2; }
  BODY=$(cat | redact)
  [ -n "${BODY//[[:space:]]/}" ] || { echo "본문이 비어 있습니다" >&2; exit 2; }
  ENTRY=$(printf '### %s\n\n🔵 검토 · `%s` · %s\n\n%s\n' "$TITLE" "$TOOL" "$STAMP" "$BODY")
  CODE=0
fi

# -v는 값 안의 \를 escape로 해석하므로 본문은 환경변수로 넘긴다
REPORT_ENTRY=$ENTRY awk -v key="$SECTION" '
  $0 == "<!-- section:" key " -->" { print; inside=1; next }
  $0 == "<!-- end:" key " -->"     { print ""; print ENVIRON["REPORT_ENTRY"]; print; inside=0; next }
  inside && $0 == "아직 기록되지 않았습니다." { next }
  { print }
' "$REPORT" > "$REPORT.tmp" && mv "$REPORT.tmp" "$REPORT"

# 장별 기록 건수를 세어 현황표를 다시 만든다
build_toc() {
  local n=0 key count done_n=0 total=${#SECTION_KEYS[@]}
  for key in "${SECTION_KEYS[@]}"; do
    count=$(awk -v k="$key" '
      $0 == "<!-- section:" k " -->" { inside=1; next }
      $0 == "<!-- end:" k " -->"     { inside=0 }
      inside && /^### / { c++ }
      END { print c+0 }
    ' "$REPORT")
    [ "$count" -gt 0 ] && done_n=$((done_n+1))
  done

  printf '**%d / %d 장** 기록됨\n\n' "$done_n" "$total"
  printf '| | 장 | 내용 |\n| :-: | --- | --- |\n'
  for key in "${SECTION_KEYS[@]}"; do
    n=$((n+1))
    count=$(awk -v k="$key" '
      $0 == "<!-- section:" k " -->" { inside=1; next }
      $0 == "<!-- end:" k " -->"     { inside=0 }
      inside && /^### / { c++ }
      END { print c+0 }
    ' "$REPORT")
    if [ "$count" -gt 0 ]; then
      printf '| %s | [%d. %s](#%d-%s) | %s |\n' \
        "$(section_icon "$key")" "$n" "$(section_title "$key")" \
        "$n" "$(section_title "$key" | tr ' ' '-')" "$(section_desc "$key")"
    else
      printf '| %s | %d. %s | %s |\n' \
        "$(section_icon "$key")" "$n" "$(section_title "$key")" "$(section_desc "$key")"
    fi
  done
}

replace_block() {
  local marker=$1
  REPORT_BLOCK=$2 awk -v begin="<!-- ${marker}:begin -->" -v end="<!-- ${marker}:end -->" '
    $0 == begin { print; print ""; print ENVIRON["REPORT_BLOCK"]; print ""; skip=1; next }
    $0 == end   { skip=0 }
    !skip
  ' "$REPORT" > "$REPORT.tmp" && mv "$REPORT.tmp" "$REPORT"
}

replace_block meta "$(build_meta | redact)"
replace_block summary "$(build_summary | redact)"
replace_block toc "$(build_toc)"

if [ "$RUN_MODE" -eq 1 ]; then
  printf '%s\n' "$OUT"
  echo ""
  echo "[$STATUS] $REPORT · $(section_title "$SECTION") 에 기록했습니다."
  exit "$CODE"
fi
echo "$REPORT · $(section_title "$SECTION") 에 \"$TITLE\" 을(를) 추가했습니다."
