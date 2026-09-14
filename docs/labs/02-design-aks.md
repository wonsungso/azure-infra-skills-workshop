# Lab 02: AKS 설계 결정하기

**Lab 2 / 8** · 1부 · 설계와 검증 · ⏱ 45분

🎯 quota 확인 / Day-0 결정(네트워크·node pool·접근) / least privilege 매트릭스

🧠 `azure-quotas` · `azure-kubernetes` · `azure-enterprise-infra-planner`

> 🎬 권한과 범위는 확인했습니다. 이제 **무엇을 만들 것인가**를 정합니다. 여기서 잘못 정하면 클러스터를 처음부터 다시 만들어야 합니다.

## 왜 필요한가요?

AKS는 만들고 나면 바꾸기 어려운 설정(네트워크 플러그인, CIDR 등)이 많습니다. 그래서 만들기 **전에** 결정을 검토하고 근거를 남깁니다. 이 랩에서는 아직 아무것도 만들지 않습니다.

## 시작 전에

- [Lab 01](01-orientation-and-setup.md)에서 scope 확인을 마쳤나요?
- `.env`에 `SUBSCRIPTION_ID`와 `EGRESS_IP_CIDR`이 채워져 있나요?

## Step 1. quota와 용량 확인하기

배포 실패의 가장 흔한 원인이 quota 부족입니다. **배포 직전이 아니라 지금** 확인합니다.

숫자는 CLI로 먼저 가져옵니다. 조회와 동시에 증거로 남습니다.

```bash
set -a; . ./.env; set +a
SCOPE="/subscriptions/$SUBSCRIPTION_ID/providers/Microsoft.Compute/locations/$REGION"
bash scripts/log-evidence.sh "Lab 02 Step 1" "az CLI" -- \
  az quota show --resource-name standardDSv5Family --scope "$SCOPE" \
    --query "{name:properties.name.localizedValue, limit:properties.limit.value}" -o tsv
bash scripts/log-evidence.sh "Lab 02 Step 1" "az CLI" -- \
  az quota show --resource-name cores --scope "$SCOPE" \
    --query "{name:properties.name.localizedValue, limit:properties.limit.value}" -o tsv
```

그다음 **충분한가**를 Skill에게 판단하게 합니다. 숫자 읽기가 아니라 region 대안까지 같이 봐야 하는 일입니다.

> 🧠 **Skill** `azure-quotas` &nbsp;·&nbsp; 📋 **아래 프롬프트를 복사해 실행**

```text
azure-quotas Skill을 사용해 저장소 루트의 .env에서 SUBSCRIPTION_ID와 REGION을 읽고, 해당 region의 Standard DSv5 family vCPU와 Total Regional vCPU의 quota와 현재 사용량을 확인해줘. 장치명은 standardDSv5Family와 cores이고, 값은 properties.limit.value와 properties.usages.value에 있어. AKS node 3대(Standard_D4s_v5 2대 + Standard_D2s_v5 1대 = 10 vCPU)를 만들 수 있는지 판단하고, 부족하면 대안 region도 알려줘. 어느 명령으로 확인했는지 같이 알려줘. Azure 리소스는 만들거나 바꾸지 마. 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘.
```

**확인할 것**

- 기본 구성은 **10 vCPU**가 필요합니다. 여유가 있나요?
- 부족하면 region을 바꾸거나 node 개수·SKU를 줄입니다.
- **어떤 명령으로 확인했다고 하나요?** 조회 없이 일반론으로 답했다면 근거가 아닙니다.

`REGION`은 `koreacentral`로 이미 채워져 있습니다. **방금 본 quota 결과로 이 값이 맞는지 확인하세요.** 결정한 값은 손으로 편집하지 말고 아래로 반영합니다.

```bash
bash scripts/set-env.sh \
  REGION koreacentral \
  SYSTEM_VM_SIZE Standard_D4s_v5 \
  USER_VM_SIZE Standard_D2s_v5
```

위 값은 **예시입니다.** region·SKU·node 개수는 기계가 대신 정해줄 수 없는 **사람의 판단**입니다.

## Step 2. Day-0 결정 검토하기

> 🧠 **Skill** `azure-kubernetes` &nbsp;·&nbsp; 📋 **아래 프롬프트를 복사해 실행**

```text
azure-kubernetes Skill을 사용해 교육용 AKS의 Day-0 선택을 검토해줘. Standard 운영 모드, system/user pool 분리, Azure CNI Overlay + Cilium, load balancer egress, public API authorized IP ranges를 기준으로 대안과 위험을 표로 정리해줘. Azure 리소스는 만들거나 바꾸지 마. 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘.
```

**사람이 판단할 것**

- system 2대 + user 1대가 교육 목적에 맞는가 (운영용 고가용성 구성이 아님)
- Pod CIDR / Service CIDR / DNS IP가 서로, 그리고 기존 네트워크와 겹치지 않는가
- API server를 공개하되 authorized IP ranges로만 제한한다는 의미

"authorized IP ranges를 넓히면 쉽지 않을까?"라는 제안은 승인하지 않습니다. 공개 API + authorized IP ranges 제한이 이 워크샵의 기본 보안 경계입니다.

## Step 3. least privilege 매트릭스 만들기

> 🧠 **Skill** `azure-enterprise-infra-planner` &nbsp;·&nbsp; 📋 **아래 프롬프트를 복사해 실행**

```text
azure-enterprise-infra-planner Skill을 사용해 이 교육용 AKS의 least privilege 매트릭스를 작성해줘. Azure 리소스 배포자, 역할 할당자, AKS control-plane managed identity, lab namespace 사용자를 분리하고 scope와 필요한 작업을 표로 보여줘. 계획만 세우고 권한을 변경하지 마. 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘.
```

"리소스를 배포하는 권한"과 "남에게 역할을 부여하는 권한"은 다릅니다. **Azure 권한과 Kubernetes 내부 권한도 완전히 다른 시스템**입니다. 이 표는 Lab 08 인계 문서에 그대로 들어갑니다.

**확인할 것** - 나에게 subscription Owner나 cluster-admin을 주는 제안이 없는지. 이 랩에서는 권한을 실제로 바꾸지 않습니다.

<details>
<summary>💡 <b>Skill을 안 썼다면?</b></summary>

| 방식 | 이 단계에서 벌어지는 일 |
| --- | --- |
| 🖐 수동 | quota 명령의 family 이름을 직접 매핑하고, AKS Day-0 항목과 수백 개 기본 역할을 문서에서 찾아야 한다. |
| 💬 일반 프롬프트 | 내 subscription quota를 모르니 일반론으로 답한다. 오래된 기본값(예: kubenet)이나 `Contributor` 같은 **과도한 권한**을 쉽게 제안한다. |
| ⚡ Skill | 실제 사용량을 조회해 가능/불가를 판정하고, Day-0 대안·위험과 **least privilege 후보를 scope와 함께** 제시한다. |

</details>

## ✅ 완료 체크리스트

- [ ] quota를 조회해 region·SKU·node 개수를 결정했다
- [ ] Day-0 결정을 스스로 설명할 수 있다
- [ ] 결정한 값을 [`set-env.sh`](../../scripts/set-env.sh)로 `.env`에 반영했다
- [ ] 세 Step의 결과가 `evidence-log.md`에 남았다
- [ ] 아직 아무것도 생성하지 않았다

## 🚧 문제가 생겼다면

| 증상 | 해야 할 일 |
| --- | --- |
| vCPU quota 부족 | node 개수·SKU를 줄이거나 다른 region 선택 (증설은 승인에 시간이 걸림) |
| Skill이 `quota` extension이 없다고 함 | `az extension add --name quota --upgrade --yes` 후 다시 실행 |
| `az quota`가 `MissingSubscription`으로 실패 | [Lab 01](01-orientation-and-setup.md)의 `Microsoft.Quota` provider 등록을 건너뛰었는지 확인. 즉시 진행해야 한다면 `az vm list-usage --location "$REGION"`로도 같은 숫자를 볼 수 있습니다 |
| CIDR 겹침 경고 | 겹치지 않는 대역으로 변경 (예: `10.244.0.0/16` → `10.245.0.0/16`) |
| Skill이 SKU를 추측함 | Step 1의 quota 결과를 붙여넣고 재요청 |
| 매트릭스에 Owner/cluster-admin 등장 | least privilege 원칙을 다시 언급하며 재요청 |

## 다음 Lab

[Lab 03: 계획 승인 + Bicep 생성](03-plan-and-bicep.md)
