#!/usr/bin/env bash
# 워크샵용 .env를 만든다. workshop ID는 랜덤 생성하고 리소스 이름은 그로부터 파생한다.
# 이미 .env가 있으면 덮어쓰지 않는다(진행 중이던 값 보호).
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

OUT=.env

if [ -f "$OUT" ]; then
  echo "$OUT 이(가) 이미 있어 그대로 둡니다."
  exit 0
fi

# 3바이트를 16진수로 = 소문자·숫자 6글자. xxd와 달리 od는 어디서나 있다.
ID=$(od -An -tx1 -N3 /dev/urandom | tr -d ' \n')

cat > "$OUT" <<EOF
# 이 워크샵의 공용 값. 커밋되지 않습니다(.gitignore).
# 비밀번호, token, kubeconfig 내용은 여기에 적지 마세요.

# 자동 생성됨
WORKSHOP_ID=$ID
RESOURCE_GROUP=rg-aks-lab-$ID
VNET_NAME=vnet-aks-lab-$ID
AKS_NAME=aks-lab-$ID
NAMESPACE=lab
IMAGE_TAG=nginxinc/nginx-unprivileged:1.27-alpine

# Lab 01에서 채움
SUBSCRIPTION_ID=
EGRESS_IP_CIDR=

# Lab 02에서 채움
REGION=
POD_CIDR=
SERVICE_CIDR=
DNS_SERVICE_IP=
SYSTEM_VM_SIZE=
USER_VM_SIZE=

# Lab 05 배포 후 output으로 채움
NODE_RESOURCE_GROUP=
EOF

echo "$OUT 생성 완료 (WORKSHOP_ID=$ID)"
