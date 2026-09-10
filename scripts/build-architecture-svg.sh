#!/usr/bin/env bash
# 레이어 스펙(JSON)을 받아 Azure 공식 아이콘이 들어간 아키텍처 SVG를 만든다.
# 아이콘은 SVG 안에 그대로 인라인되므로 결과 파일 하나만 있으면 어디서든 렌더링된다.
#
# 사용법: bash scripts/build-architecture-svg.sh <spec.json> <out.svg>
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

SPEC=${1:?스펙 JSON 경로가 필요합니다}
OUT=${2:?출력 SVG 경로가 필요합니다}
ICON_DIR=assets/azure-icons

command -v jq >/dev/null || { echo "jq가 필요합니다"; exit 1; }
[ -f "$SPEC" ] || { echo "스펙 파일이 없습니다: $SPEC"; exit 1; }

# 레이아웃 상수
PAD=28; TITLE_H=46; LAYER_LABEL_H=26; NODE_W=170; NODE_H=96; GAP_X=22; GAP_Y=54; ICON=40

TITLE=$(jq -r '.title // "Architecture"' "$SPEC")
LAYERS=$(jq '.layers | length' "$SPEC")
MAXN=$(jq '[.layers[].nodes | length] | max' "$SPEC")

WIDTH=$(( PAD*2 + MAXN*NODE_W + (MAXN-1)*GAP_X ))
[ "$WIDTH" -lt 560 ] && WIDTH=560
HEIGHT=$(( TITLE_H + PAD + LAYERS*(LAYER_LABEL_H+NODE_H) + (LAYERS-1)*GAP_Y + PAD ))

# 아이콘 파일의 내부 요소만 꺼내 중첩 <svg>로 감싼다(원본 비율 유지, 변형 없음)
emit_icon() {
  local name=$1 x=$2 y=$3 f="$ICON_DIR/$1.svg"
  if [ ! -f "$f" ]; then
    printf '<rect x="%s" y="%s" width="%s" height="%s" fill="#C8D1DC" rx="4"/>\n' "$x" "$y" "$ICON" "$ICON"
    return
  fi
  printf '<svg x="%s" y="%s" width="%s" height="%s" viewBox="0 0 18 18">' "$x" "$y" "$ICON" "$ICON"
  # xml 선언과 바깥 <svg>/</svg> 껍데기를 제거하고 알맹이만 남긴다
  tr -d '\n' < "$f" \
    | sed -e 's/<?xml[^>]*?>//' -e 's/<!--.*-->//g' -e 's/^.*<svg[^>]*>//' -e 's/<\/svg>[[:space:]]*$//'
  printf '</svg>\n'
}

esc() { sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }

{
printf '<svg xmlns="http://www.w3.org/2000/svg" width="%s" height="%s" viewBox="0 0 %s %s" font-family="Segoe UI, Helvetica, Arial, sans-serif">\n' \
  "$WIDTH" "$HEIGHT" "$WIDTH" "$HEIGHT"
cat <<'DEFS'
<defs>
  <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
    <path d="M0,0 L10,5 L0,10 z" fill="#5B6B7F"/>
  </marker>
</defs>
DEFS
printf '<rect width="100%%" height="100%%" fill="#FFFFFF"/>\n'
printf '<text x="%s" y="30" font-size="17" font-weight="600" fill="#16233A">%s</text>\n' "$PAD" "$(printf '%s' "$TITLE" | esc)"

y=$(( TITLE_H + PAD/2 ))
prev_cy=0
for i in $(seq 0 $((LAYERS-1))); do
  LLABEL=$(jq -r ".layers[$i].label // \"\"" "$SPEC")
  N=$(jq ".layers[$i].nodes | length" "$SPEC")
  row_w=$(( N*NODE_W + (N-1)*GAP_X ))
  x0=$(( (WIDTH - row_w) / 2 ))

  # 레이어 배경과 이름
  printf '<rect x="%s" y="%s" width="%s" height="%s" fill="#F4F7FB" stroke="#D8E0EA" rx="10"/>\n' \
    $(( PAD/2 )) "$y" $(( WIDTH - PAD )) $(( LAYER_LABEL_H + NODE_H )) 
  printf '<text x="%s" y="%s" font-size="12" font-weight="600" fill="#5B6B7F">%s</text>\n' \
    "$PAD" $(( y + 18 )) "$(printf '%s' "$LLABEL" | esc)"

  ny=$(( y + LAYER_LABEL_H ))
  for j in $(seq 0 $((N-1))); do
    ICONNAME=$(jq -r ".layers[$i].nodes[$j].icon // \"\"" "$SPEC")
    LABEL=$(jq -r ".layers[$i].nodes[$j].label // \"\"" "$SPEC")
    SUB=$(jq -r ".layers[$i].nodes[$j].sub // \"\"" "$SPEC")
    nx=$(( x0 + j*(NODE_W+GAP_X) ))

    printf '<rect x="%s" y="%s" width="%s" height="%s" fill="#FFFFFF" stroke="#C8D1DC" rx="8"/>\n' \
      "$nx" "$ny" "$NODE_W" $(( NODE_H - 10 ))
    emit_icon "$ICONNAME" $(( nx + NODE_W/2 - ICON/2 )) $(( ny + 10 ))
    printf '<text x="%s" y="%s" font-size="12" font-weight="600" text-anchor="middle" fill="#16233A">%s</text>\n' \
      $(( nx + NODE_W/2 )) $(( ny + ICON + 26 )) "$(printf '%s' "$LABEL" | esc)"
    [ -n "$SUB" ] && printf '<text x="%s" y="%s" font-size="10" text-anchor="middle" fill="#5B6B7F">%s</text>\n' \
      $(( nx + NODE_W/2 )) $(( ny + ICON + 41 )) "$(printf '%s' "$SUB" | esc)"
  done

  cy=$(( y + LAYER_LABEL_H + NODE_H - 10 ))
  if [ "$i" -gt 0 ]; then
    printf '<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="#5B6B7F" stroke-width="1.6" marker-end="url(#arrow)"/>\n' \
      $(( WIDTH/2 )) "$prev_cy" $(( WIDTH/2 )) $(( y - 4 ))
  fi
  prev_cy=$cy
  y=$(( y + LAYER_LABEL_H + NODE_H + GAP_Y ))
done

printf '<text x="%s" y="%s" font-size="9" fill="#8A97A8">Azure architecture icons (c) Microsoft. Used in an architecture diagram per the Azure icon terms.</text>\n' \
  "$PAD" $(( HEIGHT - 10 ))
printf '</svg>\n'
} > "$OUT"

echo "생성 완료: $OUT ($(wc -c < "$OUT") bytes, ${WIDTH}x${HEIGHT})"
