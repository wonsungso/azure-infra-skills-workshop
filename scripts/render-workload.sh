#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

set -a
. ./.env
set +a

for key in SUBSCRIPTION_ID RESOURCE_GROUP VNET_NAME ALB_SUBNET_NAME POSTGRES_NAME POSTGRES_IDENTITY_NAME NAMESPACE; do
  [ -n "${!key:-}" ] || {
    echo "  .env의 $key 값이 비어 있습니다. 렌더링을 중단합니다." >&2
    exit 1
  }
done
[ "$NAMESPACE" = lab ] || {
  echo "  이 Manifest와 Federated Credential은 lab Namespace 전용입니다." >&2
  exit 1
}

ALB_SUBNET_ID=$(az network vnet subnet show \
  --subscription "$SUBSCRIPTION_ID" \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name "$VNET_NAME" \
  --name "$ALB_SUBNET_NAME" \
  --query id -o tsv)
POSTGRES_HOST=$(az postgres flexible-server show \
  --subscription "$SUBSCRIPTION_ID" \
  --resource-group "$RESOURCE_GROUP" \
  --name "$POSTGRES_NAME" \
  --query fullyQualifiedDomainName -o tsv)
POSTGRES_IDENTITY_CLIENT_ID=$(az identity show \
  --subscription "$SUBSCRIPTION_ID" \
  --resource-group "$RESOURCE_GROUP" \
  --name "$POSTGRES_IDENTITY_NAME" \
  --query clientId -o tsv)

for key in ALB_SUBNET_ID POSTGRES_HOST POSTGRES_IDENTITY_CLIENT_ID; do
  value=${!key}
  [[ -n "${value//[[:space:]]/}" && "$value" != null ]] || {
    echo "  Azure 조회 결과 $key 값이 비어 있습니다. 렌더링을 중단합니다." >&2
    exit 1
  }
done

sed \
  -e "s|__ALB_SUBNET_ID__|$ALB_SUBNET_ID|g" \
  -e "s|__POSTGRES_HOST__|$POSTGRES_HOST|g" \
  -e "s|__POSTGRES_IDENTITY_CLIENT_ID__|$POSTGRES_IDENTITY_CLIENT_ID|g" \
  -e "s|__POSTGRES_IDENTITY_NAME__|$POSTGRES_IDENTITY_NAME|g" \
  reference/kubernetes/lab-web.yaml