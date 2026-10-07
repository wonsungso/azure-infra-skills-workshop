#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

[ "${1:-}" = --approved ] && [ $# -eq 1 ] || {
  echo "사용법: 대상과 역할 변경을 승인한 뒤 bash scripts/prepare-aks-access.sh --approved" >&2
  exit 2
}
for tool in az jq kubectl kubelogin; do
  command -v "$tool" >/dev/null || {
    echo "필수 도구가 없습니다: $tool" >&2
    exit 1
  }
done
set -a
. ./.env
set +a
for key in SUBSCRIPTION_ID RESOURCE_GROUP AKS_NAME WORKSHOP_ID NAMESPACE; do
  [ -n "${!key:-}" ] || {
    echo ".env의 $key 값이 비어 있습니다." >&2
    exit 1
  }
done
[ "$NAMESPACE" = lab ] || {
  echo "이 접근 구성은 lab Namespace 전용입니다." >&2
  exit 1
}
current=$(az account show --query id -o tsv --only-show-errors)
[ "$current" = "$SUBSCRIPTION_ID" ] || {
  echo "CLI Subscription과 .env가 다릅니다. 역할을 변경하지 않습니다." >&2
  exit 1
}
aks_id=$(az aks show --resource-group "$RESOURCE_GROUP" --name "$AKS_NAME" \
  --subscription "$SUBSCRIPTION_ID" --query id -o tsv --only-show-errors)
user_id=$(az ad signed-in-user show --query id -o tsv --only-show-errors)
[ -n "$aks_id" ] && [ -n "$user_id" ] || {
  echo "클러스터 또는 현재 사용자 조회 결과가 비어 있습니다." >&2
  exit 1
}
role_name="Workshop bootstrap $WORKSHOP_ID"
rg_scope="/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP"
mkdir -p .azure
definition=.azure/bootstrap-role.json
jq -n --arg name "$role_name" --arg scope "$rg_scope" '{
  Name: $name,
  Description: "Workshop cluster observation and namespace preparation only",
  IsCustom: true,
  Actions: [],
  NotActions: [],
  DataActions: [
    "Microsoft.ContainerService/managedClusters/*/read",
    "Microsoft.ContainerService/managedClusters/namespaces/write"
  ],
  NotDataActions: ["Microsoft.ContainerService/managedClusters/secrets/read"],
  AssignableScopes: [$scope]
}' > "$definition"
existing=$(az role definition list --name "$role_name" --subscription "$SUBSCRIPTION_ID" \
  --scope "$rg_scope" --query '[0]' -o json --only-show-errors)
if [ "$existing" = null ] || [ -z "$existing" ]; then
  role_guid=$(az role definition create --role-definition "@$definition" \
    --subscription "$SUBSCRIPTION_ID" --query name -o tsv --only-show-errors)
  echo "Bootstrap Role 정의 생성. 조회 가능해질 때까지 기다립니다."
  deadline=$((SECONDS+180))
  while :; do
    count=$(az role definition list --name "$role_guid" --subscription "$SUBSCRIPTION_ID" \
      --scope "$rg_scope" --query 'length(@)' -o tsv --only-show-errors)
    [ "$count" = 1 ] && break
    [ "$SECONDS" -lt "$deadline" ] || {
      echo "Bootstrap Role 정의 전파가 180초 안에 완료되지 않았습니다." >&2
      exit 1
    }
    echo "Role Definition 전파 대기..."
    sleep 10
  done
else
  actual=$(printf '%s' "$existing" | jq -c '{
    Actions: (.permissions[0].actions | sort),
    NotActions: (.permissions[0].notActions | sort),
    DataActions: (.permissions[0].dataActions | sort),
    NotDataActions: (.permissions[0].notDataActions | sort),
    AssignableScopes: (.assignableScopes | sort)
  }')
  expected=$(jq -c '{
    Actions: (.Actions | sort), NotActions: (.NotActions | sort),
    DataActions: (.DataActions | sort), NotDataActions: (.NotDataActions | sort),
    AssignableScopes: (.AssignableScopes | sort)
  }' "$definition")
  [ "$actual" = "$expected" ] || {
    echo "기존 bootstrap Role 정의가 다릅니다. 덮어쓰지 않고 멈춥니다." >&2
    exit 1
  }
  role_guid=$(printf '%s' "$existing" | jq -r .name)
fi
[ -n "$role_guid" ] && [ "$role_guid" != null ] || {
  echo "Bootstrap Role ID가 비어 있습니다." >&2
  exit 1
}
assign() {
  local role_id=$1 scope=$2 label=$3 count
  count=$(az role assignment list --scope "$scope" --subscription "$SUBSCRIPTION_ID" \
    -o json --only-show-errors | jq --arg user "$user_id" --arg role "$role_id" --arg scope "$scope" \
    '[.[] | select(
      (.principalId | ascii_downcase) == ($user | ascii_downcase) and
      (.roleDefinitionId | ascii_downcase) == ($role | ascii_downcase) and
      (.scope | ascii_downcase) == ($scope | ascii_downcase)
    )] | length')
  if [ "$count" = 0 ]; then
    az role assignment create --assignee-object-id "$user_id" --assignee-principal-type User \
      --role "${role_id##*/}" --scope "$scope" --subscription "$SUBSCRIPTION_ID" \
      --output none --only-show-errors
    echo "역할 할당: $label"
  else
    echo "기존 역할 유지: $label"
  fi
}
assign "/subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Authorization/roleDefinitions/$role_guid" \
  "$aks_id" "cluster bootstrap"
for grant in 'Azure Kubernetes Service Cluster User Role|cluster' \
             'Azure Kubernetes Service RBAC Admin|lab' \
             'Azure Kubernetes Service RBAC Reader|kube-system'; do
  name=${grant%|*} target=${grant##*|}
  role_id=$(az role definition list --name "$name" --subscription "$SUBSCRIPTION_ID" \
    --query '[0].id' -o tsv --only-show-errors)
  [ -n "$role_id" ] && [ "$role_id" != null ] || {
    echo "필수 Role 정의 조회 실패: $name" >&2
    exit 1
  }
  scope=$aks_id
  [ "$target" = cluster ] || scope="$aks_id/namespaces/$target"
  assign "$role_id" "$scope" "$name ($target)"
done
export KUBECONFIG=${KUBECONFIG:-"$PWD/.azure/workshop.kubeconfig"}
if command -v cygpath >/dev/null; then
  export KUBECONFIG
  KUBECONFIG=$(cygpath -m "$KUBECONFIG")
fi
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$AKS_NAME" \
  --subscription "$SUBSCRIPTION_ID" --file "$KUBECONFIG" --overwrite-existing --only-show-errors
kubelogin convert-kubeconfig -l azurecli
deadline=$((SECONDS+600))
while ! { kubectl auth can-i get nodes --all-namespaces --quiet &&
          kubectl auth can-i create namespaces --all-namespaces --quiet &&
          kubectl auth can-i list gatewayclasses.gateway.networking.k8s.io --all-namespaces --quiet &&
          kubectl auth can-i list pods -n kube-system --quiet &&
          kubectl auth can-i create deployments -n lab --quiet &&
          kubectl auth can-i create gateways.gateway.networking.k8s.io -n lab --quiet; }; do
  [ "$SECONDS" -lt "$deadline" ] || {
    echo "Kubernetes 역할 전파가 600초 안에 완료되지 않았습니다. Scope와 기존 역할을 확인하세요." >&2
    exit 1
  }
  echo "Kubernetes 역할 전파 대기..."
  sleep 15
done
if kubectl auth can-i create deployments -n kube-system --quiet; then
  echo "기존 권한이 kube-system 쓰기를 허용합니다. Namespace 격리를 검증할 수 없습니다." >&2
  exit 1
fi
if kubectl auth can-i list secrets -n kube-system --quiet; then
  echo "기존 권한이 kube-system Secrets 읽기를 허용합니다. bootstrap 경계를 검증할 수 없습니다." >&2
  exit 1
fi
deadline=$((SECONDS+600))
while :; do
  classes=$(kubectl get gatewayclasses -o json)
  controllers=$(kubectl -n kube-system get pods -o json)
  if printf '%s' "$classes" | jq -e 'any(.items[];
      .metadata.name == "azure-alb-external" and
      any(.status.conditions[]?; .type == "Accepted" and .status == "True"))' >/dev/null &&
     printf '%s' "$controllers" | jq -e '
      [.items[] | select(.metadata.name | startswith("alb-controller-"))] |
      length > 0 and all(.[];
        .status.phase == "Running" and
        any(.status.conditions[]?; .type == "Ready" and .status == "True"))' >/dev/null; then
    break
  fi
  [ "$SECONDS" -lt "$deadline" ] || {
    echo "GatewayClass와 ALB Controller가 600초 안에 준비되지 않았습니다." >&2
    exit 1
  }
  echo "GatewayClass / ALB Controller 준비 대기..."
  sleep 15
done
echo "접근 준비 완료: lab 쓰기 허용 / kube-system 쓰기 거부 / cluster Secrets 읽기 제외"
echo "다음 명령 전에 같은 KUBECONFIG를 사용하세요: export KUBECONFIG=\"${KUBECONFIG}\""
