#!/usr/bin/env bash
# .env와 자동으로 알 수 있는 값을 채운다.
# 여러 번 실행해도 안전하다. 사람이 정한 값은 덮어쓰지 않는다.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

ENV_FILE=.env

if [ ! -f "$ENV_FILE" ]; then
  # 3바이트를 16진수로 = 소문자·숫자 6글자. xxd와 달리 od는 어디서나 있다.
  ID=$(od -An -tx1 -N3 /dev/urandom | tr -d ' \n')
  cat > "$ENV_FILE" <<EOF
# 이 워크샵의 공용 값. 커밋되지 않습니다(.gitignore).
# 비밀번호, token, kubeconfig 내용은 여기에 적지 마세요.
# scripts/init-workshop.sh 를 다시 실행하면 자동 채움 항목이 갱신됩니다.

# 자동 생성됨
WORKSHOP_ID=$ID
RESOURCE_GROUP=rg-aks-lab-$ID
VNET_NAME=vnet-aks-lab-$ID
AKS_NAME=aks-lab-$ID
NAMESPACE=lab
IMAGE_TAG=nginxinc/nginx-unprivileged:1.27-alpine

# 자동으로 채워짐 (로그인 후 재실행하면 갱신)
SUBSCRIPTION_ID=
EGRESS_IP_CIDR=

# 기본값 - Lab 02에서 quota를 보고 확인하거나 바꿈
REGION=koreacentral

# Lab 02에서 내가 결정
POD_CIDR=
SERVICE_CIDR=
DNS_SERVICE_IP=
SYSTEM_VM_SIZE=
USER_VM_SIZE=

# Lab 05 배포 후 output으로 채움
NODE_RESOURCE_GROUP=
EOF
  echo "$ENV_FILE 생성 (WORKSHOP_ID=$ID)"
fi

# 화면 공유나 스크린샷에 그대로 남지 않도록 식별자는 일부만 보여준다
mask() {
  case "$1" in
    SUBSCRIPTION_ID) printf '%s...' "$(printf '%s' "$2" | cut -c1-8)" ;;
    *) printf '%s' "$2" ;;
  esac
}

# 값이 실제로 달라졌을 때만 기록한다
set_env() {
  local key=$1 val=$2 cur
  [ -z "$val" ] && return 0
  cur=$(grep -E "^${key}=" "$ENV_FILE" 2>/dev/null | head -1 | cut -d= -f2- || true)
  [ "$cur" = "$val" ] && { echo "  $key 그대로 ($(mask "$key" "$val"))"; return 0; }
  sed -i "s|^${key}=.*|${key}=${val}|" "$ENV_FILE"
  if [ -n "$cur" ]; then
    echo "  $key 갱신: $(mask "$key" "$cur") -> $(mask "$key" "$val")"
  else
    echo "  $key = $(mask "$key" "$val")"
  fi
}

echo "자동 채움:"

# Codespace에서 조회하면 Codespace의 egress IP가 나온다. 재시작하면 바뀔 수 있다.
IP=$(curl -fsS --max-time 5 https://api.ipify.org 2>/dev/null || true)
if [ -n "$IP" ]; then
  set_env EGRESS_IP_CIDR "$IP/32"
else
  echo "  egress IP 조회 실패 - 네트워크를 확인하고 다시 실행하세요"
fi

if command -v az >/dev/null 2>&1; then
  SUB=$(az account show --query id -o tsv 2>/dev/null || true)
  if [ -n "$SUB" ]; then
    set_env SUBSCRIPTION_ID "$SUB"
  else
    echo "  SUBSCRIPTION_ID 비어 있음 - az login --use-device-code 후 이 스크립트를 다시 실행하세요"
  fi
else
  echo "  az CLI 없음 - SUBSCRIPTION_ID는 나중에 채워집니다"
fi
