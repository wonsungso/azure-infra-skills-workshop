#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

set -a
. ./.env
set +a

ALB_SUBNET_ID=$(az network vnet subnet show \
  --resource-group "$RESOURCE_GROUP" \
  --vnet-name "$VNET_NAME" \
  --name "$ALB_SUBNET_NAME" \
  --query id -o tsv)
POSTGRES_HOST=$(az postgres flexible-server show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$POSTGRES_NAME" \
  --query fullyQualifiedDomainName -o tsv)
POSTGRES_IDENTITY_CLIENT_ID=$(az identity show \
  --resource-group "$RESOURCE_GROUP" \
  --name "$POSTGRES_IDENTITY_NAME" \
  --query clientId -o tsv)

sed \
  -e "s|__ALB_SUBNET_ID__|$ALB_SUBNET_ID|g" \
  -e "s|__POSTGRES_HOST__|$POSTGRES_HOST|g" \
  -e "s|__POSTGRES_IDENTITY_CLIENT_ID__|$POSTGRES_IDENTITY_CLIENT_ID|g" \
  -e "s|__POSTGRES_IDENTITY_NAME__|$POSTGRES_IDENTITY_NAME|g" \
  reference/kubernetes/lab-web.yaml