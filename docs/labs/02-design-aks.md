# Lab 02: 3계층 설계 결정하기

**Lab 2 / 8** · 1부 · 설계와 검증

🎯 Quota 확인 / Ingress·AKS·Database Day-0 결정 / Least Privilege

🧠 `azure-quotas` · `azure-kubernetes` · `azure-enterprise-infra-planner`

> 🎬 배포할 Region·Network·SKU와 권한을 결정합니다.

## 왜 필요한가요?

AKS Network·AGC Subnet·PostgreSQL Private Access는 배포 후 변경이 어렵습니다.
**배포 전에 검토하고 근거를 기록합니다. 이 Lab에서는 리소스를 만들지 않습니다.**

## 시작 전에

- [Lab 01](01-orientation-and-setup.md)에서 Scope 확인을 마쳤나요?
- `.env`에 `SUBSCRIPTION_ID`와 `EGRESS_IP_CIDR`이 채워져 있나요?

## Step 1. Quota와 용량 확인하기

Quota는 생성할 수 있는 리소스의 한도입니다. CLI로 조회한 뒤 필요한 용량과 비교합니다.

> 💻 **터미널에서 실행**

```bash
set -a; . ./.env; set +a
SCOPE="/subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Compute/locations/$REGION"
az quota show --resource-name standardDSv5Family --scope "$SCOPE" \
  --query "{name:properties.name.localizedValue, limit:properties.limit.value}" -o tsv
az quota show --resource-name cores --scope "$SCOPE" \
  --query "{name:properties.name.localizedValue, limit:properties.limit.value}" -o tsv
az postgres flexible-server list-skus -l "$REGION" --subscription "$SUBSCRIPTION_ID" \
  --query "[].supportedServerEditions[].supportedServerSkus[?name=='Standard_B1ms'][] | [].{name:name,vCores:vCores}" -o table
```

Skill로 용량과 대안 Region을 검토합니다.

> 🧠 **Skill** `azure-quotas` &nbsp;·&nbsp; 💬 **Copilot 채팅에 붙여넣기**

```text
azure-quotas Skill을 사용해 AKS Node를 만들 Quota가 남아 있는지 확인해줘.

[읽을 값]
- 저장소 루트 .env의 SUBSCRIPTION_ID, REGION

[확인할 것]
- 해당 Region의 Standard DSv5 Family vCPU Quota와 현재 사용량
- 해당 Region의 Total Regional vCPU Quota와 현재 사용량
- 장치명은 standardDSv5Family와 cores
- 값은 properties.limit.value와 properties.usages.value에 있음

[판단할 것]
- Node 3대를 만들 수 있는가
  (Standard_D4s_v5 2대 + Standard_D2s_v5 1대 = 10 vCPU)
- PostgreSQL `Standard_B1ms`를 사용할 수 있는가
- Application Gateway for Containers를 해당 Region에서 사용할 수 있는가
- 부족하면 대안 Region도 알려줘
- 어느 명령으로 확인했는지 같이 알려줘

[제약]
- Azure 리소스를 만들거나 바꾸지 마
- 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘

```

**확인할 것**

- 기본 구성의 **10 vCPU**를 확보할 수 있는가?
- 부족하면 Region 또는 Node 개수·SKU를 변경합니다
- 실제 조회 명령과 결과가 있는가?

기본 `REGION`은 `koreacentral`입니다. Quota를 확인하고 결정한 Region·SKU를 반영합니다.

[`set-env.sh`](../../scripts/set-env.sh)는 입력 쌍을 모두 검사한 뒤 한 번에 반영합니다.

- 잘못된 항목·값은 `.env`를 바꾸지 않고 거부합니다
- Shell이 `.env`를 읽으므로 값에 공백·따옴표·Shell 특수문자를 넣지 않습니다

> 💻 **터미널에서 실행**

```bash
bash scripts/set-env.sh \
  REGION koreacentral \
  SYSTEM_VM_SIZE Standard_D4s_v5 \
  USER_VM_SIZE Standard_D2s_v5
```

위 값은 **예시입니다. Region·SKU·Node 개수는 사람이 결정합니다.**

## Step 2. Day-0 결정 검토하기

Day-0는 배포 전에 결정할 Network·인증·운영 구성입니다.

> 🧠 **Skill** `azure-kubernetes`, `azure-enterprise-infra-planner` &nbsp;·&nbsp; 💬 **Copilot 채팅에 붙여넣기**

```text
azure-kubernetes Skill과 azure-enterprise-infra-planner Skill을 사용해
3계층 구성을 검토해줘.

[나눌 검토]
- azure-kubernetes Skill: AKS Day-0 결정
- azure-enterprise-infra-planner Skill: PostgreSQL Network·Entra 인증과 계층 간 연결

[검토 기준]
- Standard 운영 모드
- System/User Pool 분리
- Azure CNI Overlay + Cilium
- Application Gateway for Containers Add-on + Gateway API
- Workload Identity
- Public API Server의 Authorized IP Ranges
- PostgreSQL Flexible Server Private Access + Entra 인증
- VNet 안의 Node / ALB / PostgreSQL 전용 Subnet

[출력]
- 기준별 대안과 위험을 표로 정리

[제약]
- Azure 리소스를 만들거나 바꾸지 마
- 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘

```

**사람이 판단할 것**

- System 2대 + User 1대가 교육 목적에 맞는가 (운영용 고가용성 구성이 아님)
- Pod·Service CIDR이 서로 또는 기존 Network와 겹치지 않는가
- DNS Service IP가 Service CIDR 안에 있는가
- 공개 API Server를 Authorized IP Ranges로 제한하는가

접속 편의를 위해 Authorized IP Ranges를 넓히지 않습니다.

CIDR은 IP 주소 범위입니다. `.env`에 반영해야 Lab 03에서 계획을 생성할 수 있습니다.

> 💻 **터미널에서 실행**

```bash
bash scripts/set-env.sh \
  POD_CIDR 10.245.0.0/16 \
  SERVICE_CIDR 10.1.48.0/20 \
  DNS_SERVICE_IP 10.1.48.10 \
  ALB_SUBNET_CIDR 10.60.1.0/24 \
  POSTGRES_SUBNET_CIDR 10.60.2.0/28 \
  POSTGRES_SKU Standard_B1ms
```

위 값은 **예시입니다.** 다음 조건을 지킵니다.

- VNet은 `10.60.0.0/16`을 씁니다
- Pod·Service 대역이 VNet과, 그리고 서로 겹치지 않아야 합니다
- `DNS_SERVICE_IP`는 반드시 `SERVICE_CIDR` **안에** 있어야 합니다
- ALB Subnet은 최소 `/24`, PostgreSQL Subnet은 최소 `/28`입니다

## Step 3. Least Privilege 매트릭스 만들기

> 🧠 **Skill** `azure-enterprise-infra-planner` &nbsp;·&nbsp; 💬 **Copilot 채팅에 붙여넣기**

```text
azure-enterprise-infra-planner Skill을 사용해 이 교육용 AKS의
Least Privilege 매트릭스를 작성해줘.

[분리할 주체]
- Azure 리소스 배포자
- 역할 할당자
- AKS Control Plane Managed Identity
- Application Gateway for Containers Add-on Identity
- PostgreSQL Workload Identity
- lab Namespace 사용자

[출력]
- 주체별 Scope와 필요한 작업을 표로

[제약]
- 계획만 세우고 권한을 변경하지 마
- 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘

```

Least Privilege는 필요한 작업과 Scope에만 권한을 부여하는 원칙입니다.

- 배포 권한과 역할 할당 권한을 구분합니다
- Azure 권한과 Kubernetes 내부 권한을 구분합니다
- 매트릭스를 Lab 08 인계 문서에 포함합니다

**Owner나 Cluster Admin을 부여하는 제안이 없는지 확인합니다. 이 Lab에서는 권한을 바꾸지 않습니다.**

- Namespace 생성은 cluster Scope입니다. [Lab 05](05-deploy-and-connect.md)에서 bootstrap Custom Role을 사용합니다
- 워크로드 쓰기는 `lab` Namespace Scope로 제한합니다
- Custom Role 생성·할당 권한을 배포 전에 확인합니다

<details>
<summary>💡 <b>Skill을 안 썼다면?</b></summary>

| 방식 | 이 단계에서 벌어지는 일 |
| --- | --- |
| 🖐 수동 | Quota·Day-0·역할을 직접 조회하고 판단한다. |
| 💬 일반 프롬프트 | 실제 사용량·설계 기준·최소 권한을 명시해야 한다. |
| ⚡ Skill | 조회 결과로 용량을 판단하고 설계 대안·위험·역할 Scope를 제시한다. |

</details>

## ✅ 완료 체크리스트

- [ ] Quota를 조회해 Region·SKU·Node 개수를 결정했다
- [ ] Ingress·AKS·Database Day-0 결정을 설명할 수 있다
- [ ] `.env`의 Node·Database SKU와 Subnet CIDR이 채워졌다
- [ ] 세 Step의 검토 결과가 `infra-report.md`에 섹션으로 남았다
- [ ] 아직 아무것도 생성하지 않았다

## 🚧 문제가 생겼다면

<details>
<summary>🔎 <b>증상별 원인과 해결 방법</b></summary>

| 증상 | 해야 할 일 |
| --- | --- |
| vCPU Quota 부족 | Node 개수·SKU를 줄이거나 다른 Region 선택 (증설은 승인에 시간이 걸림) |
| Skill이 `quota` Extension이 없다고 함 | `az extension add --name quota --upgrade --yes` 후 다시 실행 |
| `az quota`가 `MissingSubscription`으로 실패 | [Lab 01](01-orientation-and-setup.md)의 `Microsoft.Quota` 등록 확인. 직접 조회할 때는 `az vm list-usage --location "$REGION"`도 사용 가능 |
| CIDR 겹침 경고 | 겹치지 않는 대역으로 변경 (예: `10.244.0.0/16` → `10.245.0.0/16`) |
| Skill이 SKU를 추측함 | Step 1의 Quota 결과를 붙여넣고 다시 요청 |
| 매트릭스에 Owner/Cluster Admin 등장 | Least Privilege 원칙을 다시 언급하며 다시 요청 |

</details>

## 다음 Lab

[Lab 03: 계획 승인 + Bicep 생성](03-plan-and-bicep.md)
