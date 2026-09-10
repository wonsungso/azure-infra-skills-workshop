#!/usr/bin/env bash
# workshop ID를 랜덤 생성하고 my-inputs.md를 만든다.
# 이미 파일이 있으면 덮어쓰지 않는다(진행 중이던 값 보호).
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

OUT=my-inputs.md

if [ -f "$OUT" ]; then
  echo "$OUT 이(가) 이미 있어 그대로 둡니다."
  exit 0
fi

# 3바이트를 16진수로 = 소문자·숫자 6글자. xxd와 달리 od는 어디서나 있다.
ID=$(od -An -tx1 -N3 /dev/urandom | tr -d ' \n')

cat > "$OUT" <<'EOF'
# 내 워크샵 입력값

workshop ID와 리소스 이름은 자동으로 채워졌습니다. 나머지는 Lab을 진행하며 직접 조사해 채웁니다.

> 이 파일은 `.gitignore`에 등록돼 있어 커밋되지 않습니다.
> 비밀번호, token, kubeconfig 내용은 적지 마세요.

| 항목 | 값 | 정하는 시점 |
| --- | --- | --- |
| workshop ID | `__ID__` | 생성 완료 |
| subscription ID 또는 scope | | Lab 01 |
| egress IP | | Lab 01 |
| resource group | `rg-aks-lab-__ID__` | 생성 완료 |
| region | | Lab 02 |
| Pod CIDR / Service CIDR / DNS IP | | Lab 02 |
| system·user node pool VM SKU와 개수 | | Lab 02 |
| VNet | `vnet-aks-lab-__ID__` | Bicep이 생성 |
| AKS | `aks-lab-__ID__` | Bicep이 생성 |
| node resource group | | Lab 05 배포 후 output |
| namespace | `lab` | 고정값 |
| 샘플 image tag | `nginxinc/nginx-unprivileged:1.27-alpine` | 고정값 |

Lab 프롬프트의 `[resource-group]`, `[region]`, `[aks-name]`, `[egress-ip-cidr]`,
`[node-resource-group]`은 모두 이 표의 값입니다.
EOF

sed -i "s/__ID__/$ID/g" "$OUT"

echo "workshop ID: $ID"
echo "$OUT 을(를) 만들었습니다."
