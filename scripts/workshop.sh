#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

fail() { echo "$*" >&2; exit 1; }
action=${1:-}
case "$action" in
  check|verify)
    [ $# -eq 1 ] || fail "Usage: bash scripts/workshop.sh $action"
    ;;
  setup|connect|apply|restart)
    [ $# -eq 2 ] && [ "$2" = --approved ] \
      || fail "Explicit approval required: bash scripts/workshop.sh $action --approved"
    ;;
  *) fail "Usage: bash scripts/workshop.sh check|verify|setup|connect|apply|restart [--approved]" ;;
esac
for tool in az jq kubectl kubelogin curl; do
  command -v "$tool" >/dev/null || fail "Missing required tool: $tool"
done

current=$(az account show --query id -o tsv --only-show-errors)
[ -n "$current" ] || fail "Azure login required"
if [ -f .env ]; then
  configured=$(grep '^SUBSCRIPTION_ID=' .env | cut -d= -f2-)
  [ -z "$configured" ] || [ "$configured" = "$current" ] \
    || fail "CLI Subscription differs from .env; stop and confirm the intended Scope"
elif [ "$action" != check ]; then
  fail "Missing .env; run check after human login"
fi
if [ "$action" = check ]; then
  for skill in azure-quotas azure-kubernetes azure-enterprise-infra-planner \
               azure-resource-lookup azure-diagnostics azure-resource-visualizer; do
    [ -f ".github/skills/$skill/SKILL.md" ] || fail "Missing required Skill: $skill"
  done
  az version --query '"azure-cli"' -o tsv
  az bicep version
  kubectl version --client
  kubelogin --version
  jq --version
  bash scripts/init-workshop.sh --strict
fi
set -a
. ./.env
set +a
for key in SUBSCRIPTION_ID RESOURCE_GROUP REGION; do
  [ -n "${!key:-}" ] || fail "Missing .env value: $key"
done
[ "$current" = "$SUBSCRIPTION_ID" ] || fail "Subscription mismatch"

if [ "$action" = check ]; then
  [ -n "${EGRESS_IP_CIDR:-}" ] || fail "Egress lookup failed; rerun check after fixing connectivity"
  az account show --query '{subscription:name,state:state}' -o table --only-show-errors
  az group exists -n "$RESOURCE_GROUP" --subscription "$SUBSCRIPTION_ID" --only-show-errors
  echo "Tools, Skill files and environment checked; no Azure changes"
  exit 0
fi
if [ "$action" = setup ]; then
  for provider in Microsoft.Quota Microsoft.NetworkFunction Microsoft.ContainerService \
                  Microsoft.Network Microsoft.ServiceNetworking Microsoft.DBforPostgreSQL \
                  Microsoft.ManagedIdentity; do
    az provider register --namespace "$provider" --subscription "$SUBSCRIPTION_ID" --wait --only-show-errors
  done
  for feature in ManagedGatewayAPIPreview ApplicationLoadBalancerPreview; do
    az feature register --namespace Microsoft.ContainerService --name "$feature" \
      --subscription "$SUBSCRIPTION_ID" --only-show-errors >/dev/null
    deadline=$((SECONDS+1800))
    while :; do
      state=$(az feature show --namespace Microsoft.ContainerService --name "$feature" \
        --subscription "$SUBSCRIPTION_ID" --query properties.state -o tsv --only-show-errors)
      [ "$state" = Registered ] && break
      [ "$SECONDS" -lt "$deadline" ] || fail "Feature registration timeout: $feature ($state)"
      echo "Waiting for Feature: $feature ($state)"
      sleep 15
    done
  done
  az provider register --namespace Microsoft.ContainerService --subscription "$SUBSCRIPTION_ID" \
    --wait --only-show-errors
  echo "Required Providers and Features Registered"
  exit 0
fi

for key in AKS_NAME NAMESPACE; do
  [ -n "${!key:-}" ] || fail "Missing .env value: $key"
done
[ "$NAMESPACE" = lab ] || fail "Only the lab Namespace is supported"
export KUBECONFIG="$PWD/.azure/workshop.kubeconfig"
if command -v cygpath >/dev/null; then
  KUBECONFIG=$(cygpath -m "$KUBECONFIG")
fi
if [ "$action" = connect ]; then
  node_group=$(az aks show -g "$RESOURCE_GROUP" -n "$AKS_NAME" --subscription "$SUBSCRIPTION_ID" \
    --query nodeResourceGroup -o tsv --only-show-errors)
  [ -n "$node_group" ] || fail "AKS Node Resource Group is empty"
  bash scripts/set-env.sh NODE_RESOURCE_GROUP "$node_group"
  bash scripts/prepare-aks-access.sh --approved
else
  [ -f "$KUBECONFIG" ] || fail "Missing workshop kubeconfig; complete approved connect first"
fi
fqdn=$(az aks show -g "$RESOURCE_GROUP" -n "$AKS_NAME" --subscription "$SUBSCRIPTION_ID" \
  --query fqdn -o tsv --only-show-errors)
server=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
[ -n "$fqdn" ] && [ "$server" = "https://$fqdn:443" -o "$server" = "https://$fqdn" ] \
  || fail "Kubeconfig does not target the configured AKS; refusing Kubernetes operations"

if [ "$action" = connect ]; then
  existing=$(kubectl get namespace "$NAMESPACE" --ignore-not-found -o name)
  [ -n "$existing" ] || kubectl create namespace "$NAMESPACE"
  kubectl auth can-i create deployments -n "$NAMESPACE" --quiet
  kubectl auth can-i create gateways.gateway.networking.k8s.io -n "$NAMESPACE" --quiet
  kubectl get nodes -L kubernetes.azure.com/mode
  nodes=$(kubectl get nodes -o json)
  printf '%s' "$nodes" | jq -e '.items | length > 0 and all(.[];
    any(.status.conditions[]?; .type == "Ready" and .status == "True"))' >/dev/null \
    || fail "Not all AKS Nodes are Ready"
  echo "Namespace and node readiness verified; inspect pool counts against the approved plan"
  exit 0
fi

verify() {
  kubectl -n lab rollout status deployment/lab-web --timeout=600s
  kubectl -n lab wait --for=condition=complete job/postgres-check --timeout=600s
  kubectl -n lab wait --for=condition=Accepted gateway/lab-gateway --timeout=900s
  kubectl -n lab wait --for=condition=Programmed gateway/lab-gateway --timeout=900s
  for condition in Accepted ResolvedRefs; do
    kubectl -n lab wait \
      --for="jsonpath={.status.parents[0].conditions[?(@.type==\"$condition\")].status}=True" \
      httproute/lab-web --timeout=180s
  done
  bash scripts/verify-public-http.sh
  logs=$(kubectl -n lab logs job/postgres-check -c psql)
  printf '%s\n' "$logs"
  printf '%s\n' "$logs" | awk '
    /successful_checks/ { header=1; next }
    header && /^[[:space:]]*[1-9][0-9]*[[:space:]]*$/ { found=1 }
    END { exit !found }
  ' || fail "SQL Job log has no positive successful_checks result"
  address=$(kubectl -n lab get gateway lab-gateway -o jsonpath='{.status.addresses[0].value}')
  [ -n "$address" ] || fail "Gateway address is empty"
  url="http://$address"
  response_pod=$(curl -4 -fsS --connect-timeout 5 --max-time 20 "$url/pod-name.txt")
  response_namespace=$(curl -4 -fsS --connect-timeout 5 --max-time 20 "$url/pod-namespace.txt")
  [ "$response_namespace" = lab ] || fail "Response Namespace is not lab"
  [[ "$response_pod" =~ ^lab-web-[a-z0-9-]+$ ]] || fail "Unexpected response Pod name"
  pod=$(kubectl -n lab get pod "$response_pod" -o json)
  printf '%s' "$pod" | jq -e '.metadata.labels.app == "lab-web" and
    any(.status.conditions[]?; .type == "Ready" and .status == "True")' >/dev/null \
    || fail "Response Pod is not a Ready lab-web Pod"
  node=$(printf '%s' "$pod" | jq -er '.spec.nodeName')
  pool=$(kubectl get node "$node" -o jsonpath='{.metadata.labels.kubernetes\.azure\.com/mode}')
  [ "$pool" = user ] || fail "Response Pod is not on the User Pool"
  echo "Verified HTTP, SQL, response Pod and User Pool: $response_pod"
}

case "$action" in
  apply)
    bash scripts/render-workload.sh | kubectl apply -f -
    verify
    ;;
  verify) verify ;;
  restart)
    verify
    old_url=$url old_pod=$response_pod
    kubectl delete pod -n lab -l app=lab-web --timeout=180s
    kubectl -n lab rollout status deployment/lab-web --timeout=600s
    kubectl -n lab wait --for=condition=Ready pod -l app=lab-web --timeout=600s
    verify
    [ "$url" = "$old_url" ] || fail "Gateway URL changed after Pod recreation"
    [ "$response_pod" != "$old_pod" ] || fail "Response Pod did not change after recreation"
    echo "Recreated Pod verified: same URL, new Pod, exact SQL product"
    ;;
esac
