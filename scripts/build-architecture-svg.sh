#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

SPEC=${1:?스펙 JSON 경로가 필요합니다}
OUT=${2:?출력 SVG 경로가 필요합니다}
ICON_DIR=assets/azure-icons

command -v jq >/dev/null || { echo "jq가 필요합니다"; exit 1; }
[ -f "$SPEC" ] || { echo "스펙 파일이 없습니다: $SPEC"; exit 1; }

PAD=28; TITLE_H=46; LABEL_H=26; NODE_W=190; NODE_H=96; GAP=40; ICON=40
TITLE=$(jq -r '.title // "Architecture"' "$SPEC")
DIR=$(jq -r '.direction // "TB"' "$SPEC")
LAYERS=$(jq '.layers | length' "$SPEC")
MAXN=$(jq '[.layers[].nodes | length] | max' "$SPEC")

if [ "$DIR" = "LR" ]; then
  WIDTH=$(( PAD*2 + LAYERS*NODE_W + (LAYERS-1)*GAP ))
  HEIGHT=$(( TITLE_H + PAD + LABEL_H + MAXN*NODE_H + (MAXN-1)*GAP + PAD ))
else
  WIDTH=$(( PAD*2 + MAXN*NODE_W + (MAXN-1)*GAP ))
  [ "$WIDTH" -lt 560 ] && WIDTH=560
  HEIGHT=$(( TITLE_H + PAD + LAYERS*(LABEL_H+NODE_H) + (LAYERS-1)*GAP + PAD ))
fi

emit_icon() {
  local name=$1 x=$2 y=$3 file="$ICON_DIR/$1.svg"
  if [ ! -f "$file" ]; then
    printf '<rect x="%s" y="%s" width="%s" height="%s" fill="#C8D1DC" rx="4"/>\n' "$x" "$y" "$ICON" "$ICON"
    return
  fi
  printf '<svg x="%s" y="%s" width="%s" height="%s" viewBox="0 0 18 18">' "$x" "$y" "$ICON" "$ICON"
  tr -d '\n' < "$file" \
    | sed -e 's/<?xml[^>]*?>//' -e 's/<!--.*-->//g' -e 's/^.*<svg[^>]*>//' -e 's/<\/svg>[[:space:]]*$//'
  printf '</svg>\n'
}

esc() { sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'; }

emit_node() {
  local layer=$1 node=$2 x=$3 y=$4 icon label sub
  icon=$(jq -r ".layers[$layer].nodes[$node].icon // \"\"" "$SPEC")
  label=$(jq -r ".layers[$layer].nodes[$node].label // \"\"" "$SPEC")
  sub=$(jq -r ".layers[$layer].nodes[$node].sub // \"\"" "$SPEC")
  printf '<rect x="%s" y="%s" width="%s" height="%s" fill="#FFFFFF" stroke="#C8D1DC" rx="8"/>\n' \
    "$x" "$y" "$NODE_W" $(( NODE_H - 10 ))
  emit_icon "$icon" $(( x + NODE_W/2 - ICON/2 )) $(( y + 10 ))
  printf '<text x="%s" y="%s" font-size="12" font-weight="600" text-anchor="middle" fill="#16233A">%s</text>\n' \
    $(( x + NODE_W/2 )) $(( y + ICON + 26 )) "$(printf '%s' "$label" | esc)"
  [ -n "$sub" ] && printf '<text x="%s" y="%s" font-size="10" text-anchor="middle" fill="#5B6B7F">%s</text>\n' \
    $(( x + NODE_W/2 )) $(( y + ICON + 41 )) "$(printf '%s' "$sub" | esc)"
}

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
  printf '<text x="%s" y="30" font-size="17" font-weight="600" fill="#16233A">%s</text>\n' \
    "$PAD" "$(printf '%s' "$TITLE" | esc)"

  if [ "$DIR" = "LR" ]; then
    base_y=$(( TITLE_H + PAD/2 ))
    for i in $(seq 0 $((LAYERS-1))); do
      label=$(jq -r ".layers[$i].label // \"\"" "$SPEC")
      count=$(jq ".layers[$i].nodes | length" "$SPEC")
      x=$(( PAD + i*(NODE_W+GAP) ))
      col_h=$(( LABEL_H + count*NODE_H + (count-1)*GAP ))
      printf '<rect x="%s" y="%s" width="%s" height="%s" fill="#F4F7FB" stroke="#D8E0EA" rx="10"/>\n' \
        "$x" "$base_y" "$NODE_W" "$col_h"
      printf '<text x="%s" y="%s" font-size="12" font-weight="600" fill="#5B6B7F">%s</text>\n' \
        $(( x + 12 )) $(( base_y + 18 )) "$(printf '%s' "$label" | esc)"
      for j in $(seq 0 $((count-1))); do
        emit_node "$i" "$j" "$x" $(( base_y + LABEL_H + j*(NODE_H+GAP) ))
      done
      if [ "$i" -gt 0 ]; then
        mid_y=$(( base_y + LABEL_H + NODE_H/2 - 5 ))
        printf '<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="#5B6B7F" stroke-width="1.6" marker-end="url(#arrow)"/>\n' \
          $(( x - GAP )) "$mid_y" $(( x - 4 )) "$mid_y"
      fi
    done
  else
    y=$(( TITLE_H + PAD/2 ))
    previous_bottom=0
    for i in $(seq 0 $((LAYERS-1))); do
      label=$(jq -r ".layers[$i].label // \"\"" "$SPEC")
      count=$(jq ".layers[$i].nodes | length" "$SPEC")
      row_w=$(( count*NODE_W + (count-1)*GAP ))
      x0=$(( (WIDTH-row_w)/2 ))
      printf '<rect x="%s" y="%s" width="%s" height="%s" fill="#F4F7FB" stroke="#D8E0EA" rx="10"/>\n' \
        $(( PAD/2 )) "$y" $(( WIDTH-PAD )) $(( LABEL_H+NODE_H ))
      printf '<text x="%s" y="%s" font-size="12" font-weight="600" fill="#5B6B7F">%s</text>\n' \
        "$PAD" $(( y+18 )) "$(printf '%s' "$label" | esc)"
      for j in $(seq 0 $((count-1))); do
        emit_node "$i" "$j" $(( x0+j*(NODE_W+GAP) )) $(( y+LABEL_H ))
      done
      if [ "$i" -gt 0 ]; then
        printf '<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="#5B6B7F" stroke-width="1.6" marker-end="url(#arrow)"/>\n' \
          $(( WIDTH/2 )) "$previous_bottom" $(( WIDTH/2 )) $(( y-4 ))
      fi
      previous_bottom=$(( y+LABEL_H+NODE_H-10 ))
      y=$(( y+LABEL_H+NODE_H+GAP ))
    done
  fi

  printf '<text x="%s" y="%s" font-size="9" fill="#8A97A8">Azure architecture icons (c) Microsoft. Used under the Azure icon terms.</text>\n' \
    "$PAD" $(( HEIGHT-10 ))
  printf '</svg>\n'
} > "$OUT"

echo "생성 완료: $OUT ($(wc -c < "$OUT") bytes, ${WIDTH}x${HEIGHT}, $DIR)"
