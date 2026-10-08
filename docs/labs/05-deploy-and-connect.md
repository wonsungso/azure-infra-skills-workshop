# Lab 05: 3계층 인프라 배포

**Lab 5 / 8** · 2부 · 실행과 마무리

🎯 AGC Add-on·AKS·Private PostgreSQL 배포 / Entra 기반 접속

🧠 `azure-enterprise-infra-planner` · `azure-resource-lookup`

> 🎬 승인된 인프라를 배포하고 상태·접근 권한을 확인합니다.

## 왜 필요한가요?

배포 성공과 서비스 준비 상태는 다릅니다.
Node·Controller 상태와 접근 권한을 별도로 확인합니다.

## 시작 전에

- [Lab 04](04-validate-and-approve.md)의 배포 승인이 있나요?

## Step 1. 3계층 인프라 배포하기

> 🧠 **Skill** `azure-enterprise-infra-planner` &nbsp;·&nbsp; 💬 **Copilot 채팅에 붙여넣기**

```text
azure-enterprise-infra-planner Skill을 사용해 승인된 계획을 배포해줘.

[해야 할 일]
- 배포 진행 상태와 생성된 자원을 기록해줘
- 실패하면 실제 오류를 분류해줘

[제약]
- 승인 범위를 벗어난 변경은 하지 마
- 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘

```

배포 완료와 각 서비스의 준비 상태를 확인합니다.
AKS가 관리하는 **Node Resource Group** 이름을 `.env`에 반영합니다.

> 💻 **터미널에서 실행**

```bash
set -a; . ./.env; set +a
bash scripts/set-env.sh NODE_RESOURCE_GROUP \
  "$(az aks show -g "$RESOURCE_GROUP" -n "$AKS_NAME" --query nodeResourceGroup -o tsv)"
```

> 💻 **터미널에서 실행**

```bash
set -a; . ./.env; set +a
az aks show -g "$RESOURCE_GROUP" -n "$AKS_NAME" \
  --query "{state:provisioningState,workloadIdentity:securityProfile.workloadIdentity.enabled}"
AKS_ID=$(az aks show -g "$RESOURCE_GROUP" -n "$AKS_NAME" --query id -o tsv)
az rest --method get --url "$AKS_ID?api-version=2026-01-02-preview" \
  --query "{alb:properties.ingressProfile.applicationLoadBalancer.enabled,gatewayApi:properties.ingressProfile.gatewayAPI.installation}"
az postgres flexible-server show -g "$RESOURCE_GROUP" -n "$POSTGRES_NAME" \
  --query "{state:state,publicAccess:network.publicNetworkAccess,version:version}"
```

Add-on 상태는 REST로 확인합니다.

오래된 CLI·Extension은 `ingressProfile`을 `null`로 표시할 수 있습니다.
비활성화로 단정하지 말고 실제 API의 `enabled`를 확인합니다.

AKS가 `Succeeded`, PostgreSQL이 `Ready`이고 Workload Identity·ALB가 `true`인지 확인한 뒤 Step 2로 이동합니다.
AGC 본체는 아직 생성되지 않습니다. Lab 06의 Manifest 적용 단계에서 생성합니다.

<details>
<summary>💡 <b>Skill을 안 썼다면?</b></summary>

| 방식 | 이 단계에서 벌어지는 일 |
| --- | --- |
| 🖐 수동 | 배포 상태를 조회하고 오류를 분석한다. |
| 💬 일반 프롬프트 | 승인 범위와 오류 분석을 명시해야 한다. |
| ⚡ Skill | 승인 범위를 지키고 Quota·정책·권한 오류를 분류한다. |

</details>

## Step 2. 접속하고 `lab` Namespace 만들기

> 🧠 **Skill** `azure-resource-lookup` &nbsp;·&nbsp; 💬 **Copilot 채팅에 붙여넣기**

```text
azure-resource-lookup Skill을 사용해 AKS의 실제 상태를 확인해줘.

[읽을 값]
- 저장소 루트 .env의 RESOURCE_GROUP, AKS_NAME

[확인할 것]
- 해당 AKS의 실제 상태와 Node Resource Group (읽기 전용)

[그다음]
- Entra 기반으로 클러스터에 접속하는 데 필요한 점검 항목을 제시해줘

[제약]
- 역할을 변경하지 마
- 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘

```

**클러스터 생성자도 Kubernetes 역할이 필요합니다.**

- Local Accounts는 꺼져 있고 Azure RBAC for Kubernetes를 사용합니다
- **Subscription Owner만으로는 Kubernetes 접근이 허용되지 않습니다**
- Namespace 생성은 cluster Scope, 워크로드 쓰기는 Namespace Scope로 분리합니다

> 🧠 **Skill** `azure-enterprise-infra-planner` &nbsp;·&nbsp; 💬 **Copilot 채팅에 붙여넣기**

```text
azure-enterprise-infra-planner Skill을 사용해 실습용 Kubernetes 접근을 준비해줘.

[읽을 값]
- 저장소 루트 .env의 SUBSCRIPTION_ID, RESOURCE_GROUP, AKS_NAME, NAMESPACE
- Lab 02의 Least Privilege 매트릭스
- 값이 비어 있거나 NAMESPACE가 lab이 아니면 멈춰

[분리할 권한]
- Entra 사용자 Credentials 조회 권한이 없다면
  Azure Kubernetes Service Cluster User Role을 해당 AKS Scope에만 할당
- cluster Scope의 bootstrap Custom Role:
  DataActions는 Microsoft.ContainerService/managedClusters/*/read와
  Microsoft.ContainerService/managedClusters/namespaces/write
- bootstrap의 NotDataActions에는
  Microsoft.ContainerService/managedClusters/secrets/read를 넣어 Secrets 읽기 제외
- 위 Role의 Actions는 비워 두고 Assignable Scope는 전용 Resource Group으로 제한
- 워크로드 관리는 Azure Kubernetes Service RBAC Admin을
  해당 AKS의 /namespaces/lab Scope에만 할당
- ALB Controller 상태·Log 조회는 Azure Kubernetes Service RBAC Reader를
  해당 AKS의 /namespaces/kube-system Scope에만 할당
- Gateway, HTTPRoute, ApplicationLoadBalancer는 Custom Resource이므로
  일반 RBAC Writer만으로 충분하다고 가정하지 마

[진행 순서]
- 현재 사용자와 기존 역할을 조회하고 이미 충족하는 권한은 중복 부여하지 마
- 기존 Custom Role 정의가 필요한 작업과 다르면 덮어쓰지 말고 멈춰
- 실제 Role Definition과 Provider DataActions로 필요한 작업을 검토
- Custom Role 생성·역할 할당의 대상과 영향을 보여주고 승인을 요청
- 승인 후 scripts/prepare-aks-access.sh --approved를 실행해
  Role ID로 할당하고 Credentials 변환·전파 준비 확인까지 수행
- 준비 완료 후 사용한 KUBECONFIG 경로와 Namespace 생성 명령을 제시
- 역할과 Scope, 승인 기록을 infra-report.md의 Access 장에 남겨줘

[제약]
- 승인 전에는 Azure 역할을 만들거나 바꾸지 마
- cluster Scope에 워크로드 쓰기 권한을 부여하지 마
- Owner나 Cluster Admin을 부여하지 마
- Custom Role 생성·할당 권한이 없으면 확대하지 말고 멈춰
- 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘
```

Custom Role은 필요한 작업 권한(DataActions)을 묶은 Azure 역할입니다.

| 역할 | 허용 범위 |
| --- | --- |
| bootstrap | cluster 조회·Namespace 생성/갱신. Secrets 읽기 제외 |
| `lab` Admin | `lab`의 워크로드·Custom Resource 관리 |
| `kube-system` Reader | Controller 상태·Log 조회만 허용 |

- GatewayClass 조회에 read wildcard를 사용합니다. **쓰기 wildcard는 사용하지 않습니다**
- bootstrap의 Namespace 쓰기는 cluster 전체에 적용됩니다
- 역할 전파 중 `Forbidden`이면 중복 할당하지 말고 기다립니다
- 기준: [AKS Kubernetes API 권한 문서](https://learn.microsoft.com/azure/aks/entra-id-authorization)

[`prepare-aks-access.sh`](../../scripts/prepare-aks-access.sh)는 승인 후에만 실행합니다.

- Role ID로 할당하고 `kubelogin`을 변환합니다
- 역할 전파와 GatewayClass·Controller 준비를 각각 최대 10분 기다립니다
- 시간 초과 시 멈춥니다. 권한을 넓히지 않습니다
- 프롬프트가 이미 실행했다면 스크립트 재실행만 건너뜁니다. **터미널 환경 설정은 필요합니다**

먼저 참가자 터미널의 환경을 설정합니다. Skill이 사용한 경로가 다르면 같은 `KUBECONFIG`를 사용합니다.

> 💻 **터미널에서 실행**

```bash
set -a; . ./.env; set +a
export KUBECONFIG="$PWD/.azure/workshop.kubeconfig"
if command -v cygpath >/dev/null; then
  export KUBECONFIG="$(cygpath -m "$KUBECONFIG")"
fi
```

**Skill이 아직 접근 준비를 실행하지 않은 경우에만** 대상·역할 변경을 승인하고 아래를 실행합니다.
이미 성공했다면 Node·Namespace 확인으로 이동합니다.

> 💻 **터미널에서 실행**

```bash
bash scripts/prepare-aks-access.sh --approved
```

- `-l azurecli`는 기존 Azure 로그인 Token을 사용합니다
- `--approved`는 승인 버튼이 아닙니다. **변경 내용을 승인한 뒤에만** 사용합니다
- 새 터미널에서는 위 환경 설정을 다시 실행합니다. 역할 준비 스크립트까지 반복할 필요는 없습니다

Node·Controller를 확인하고 실습용 Namespace를 만듭니다.

처음에는 Namespace를 생성하고, 재실행할 때는 기존 Namespace를 유지합니다.

> 💻 **터미널에서 실행**

```bash
set -a; . ./.env; set +a
kubectl get nodes -L kubernetes.azure.com/mode
kubectl get gatewayclass azure-alb-external
kubectl get pods -n kube-system | grep alb-controller
EXISTING_NAMESPACE=$(kubectl get namespace "$NAMESPACE" --ignore-not-found -o name) || exit 1
if [ -z "$EXISTING_NAMESPACE" ]; then
  kubectl create namespace "$NAMESPACE" || exit 1
fi
kubectl auth can-i create deployments -n "$NAMESPACE"
kubectl auth can-i create gateways.gateway.networking.k8s.io -n "$NAMESPACE"
if kubectl auth can-i create deployments -n kube-system --quiet; then
  echo "Namespace isolation failed" >&2
  false
else
  echo "kube-system write denied - expected"
fi
```

**확인할 것**

- Node가 모두 `Ready` 상태인가?
- GatewayClass `azure-alb-external`이 있는가?
- ALB Controller Pod가 `Running`인가?
- System Pool과 User Pool이 설계대로 분리되었는가? (`kubectl get nodes -L kubernetes.azure.com/mode`)
- `lab` Namespace가 생성됐는가?
- `lab`의 Deployment·Gateway 생성 확인은 `yes`, `kube-system` 쓰기는 예상대로 거부되는가?

- Node Resource Group의 Standard Load Balancer는 AKS Egress용입니다
- AGC는 [Lab 06](06-run-sample-workload.md)의 `ApplicationLoadBalancer` 적용 시 생성됩니다
- `MODE` 열의 `system` 2대·`user` 1대를 Lab 02 계획과 비교합니다

<img src="../../img/lab05-nodes.png" alt="kubectl get nodes 결과 - System 2대와 User 1대가 모두 Ready 상태이고 lab Namespace가 생성된 터미널 출력" width="760">

`kube-system` 쓰기가 허용되면 기존 역할과 Scope를 조회합니다.
**역할을 임의로 삭제하거나 Namespace 격리 성공으로 기록하지 않습니다.**
실제 Scope를 인계 문서에 남깁니다.

> [!WARNING]
> 접속이 안 될 때 Authorized IP Ranges에 `0.0.0.0/0`을 넣지 않습니다. 먼저 `curl -s https://api.ipify.org`로 Egress IP가 바뀌지 않았는지 확인합니다.

## ✅ 완료 체크리스트

- [ ] 클러스터가 실제로 Ready 상태임을 확인
- [ ] ALB Controller와 GatewayClass를 확인
- [ ] PostgreSQL Public Access가 꺼져 있음
- [ ] `NODE_RESOURCE_GROUP`이 `.env`에 반영됨
- [ ] 승인 후 bootstrap·Namespace 역할을 준비하고 `kubectl`이 동작함
- [ ] `lab` 생성 허용과 `kube-system` 워크로드 쓰기 거부를 확인함
- [ ] System/User Node Pool 분리를 확인
- [ ] `lab` Namespace가 생성됐거나 기존 Namespace가 있음을 확인
- [ ] 배포와 검증 결과가 `infra-report.md`에 남았다

## 🚧 문제가 생겼다면

<details>
<summary>🔎 <b>증상별 원인과 해결 방법</b></summary>

| 증상 | 원인일 가능성 | 해야 할 일 |
| --- | --- | --- |
| 배포가 Quota 오류로 실패 | vCPU 한도 초과 또는 Region 용량 부족 | [Lab 02](02-design-aks.md) Step 1로 돌아가 Node 개수·SKU를 줄이거나 Region 변경 |
| 배포가 정책 오류로 실패 | Azure Policy 제약 | 위반한 정책 이름을 확인하고 해당 설정만 조정 |
| `kubectl`이 Device Code를 띄우고 멈춤 | `kubelogin convert-kubeconfig`를 건너뜀 | `kubelogin convert-kubeconfig -l azurecli`를 실행한 뒤 다시 시도 |
| `kubectl`이 `Forbidden`으로 거부 | AKS RBAC 역할 미부여, 또는 부여 직후라 전파 중 | Step 2의 역할과 Scope를 확인하고, 이미 부여했다면 잠시 뒤 재시도 |
| Custom Role 생성 직후 역할을 찾지 못함 | Azure Role Definition 전파 중 | 정의를 중복 생성하지 말고 30초 뒤 조회·할당 재시도 |
| API Server 접속 불가 | Authorized IP Ranges 미반영, 전파 지연, 또는 내 IP 변경 | 내 Egress IP를 다시 조회해 비교, 몇 분 대기 후 재시도 |
| 어제까지 되던 접속이 갑자기 안 됨 | Codespace를 재시작해 Egress IP가 바뀌었을 수 있음 | [`init-workshop.sh`](../../scripts/init-workshop.sh)로 `.env`를 갱신하고, 바뀌었다면 Authorized IP Ranges를 다시 적용 |
| 역할 할당 실패 | `Microsoft.Authorization` 작업 제한 | 권한을 넓히지 말고 허용된 다른 Subscription에서 진행 |

</details>

## 다음 Lab

배포 상태·접근 준비·Namespace·권한 경계를 모두 확인한 뒤 진행합니다.

[Lab 06: Gateway + DB 검증](06-run-sample-workload.md)
