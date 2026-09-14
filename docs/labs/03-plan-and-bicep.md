# Lab 03: 계획 승인 + Bicep 생성

**Lab 3 / 8** · 1부 · 설계와 검증 · ⏱ 55분

🎯 설계 결정을 승인 가능한 계획 문서로 / 승인된 계획을 Bicep 코드로

🧠 `azure-enterprise-infra-planner`

> 🎬 팀장의 첫 번째 조건을 기억하세요 - **클릭이 아니라 승인 기반으로.** 계획을 먼저 승인받고, 그제서야 코드를 만듭니다.

## 왜 필요한가요?

`azure-enterprise-infra-planner`는 요구사항으로 계획을 먼저 만들고, 사람이 승인한 뒤에야 Bicep을 생성합니다. **계획 → 승인 → 코드** 순서가 잘못된 자원의 배포를 막는 핵심 안전장치입니다.

## 시작 전에

- [Lab 02](02-design-aks.md)의 Day-0 결정표와 권한 매트릭스가 있나요?
- `.env`에 `POD_CIDR`, `SERVICE_CIDR`, `DNS_SERVICE_IP`까지 채워져 있나요? 비어 있으면 아래 프롬프트가 멈춥니다.

```bash
cat .env
```

## Step 1. 인프라 계획 만들고 검토하기

> 🧠 **Skill** `azure-enterprise-infra-planner` &nbsp;·&nbsp; 📋 **아래 프롬프트를 복사해 실행**

```text
azure-enterprise-infra-planner Skill을 사용해 인프라 계획을 작성해줘.

[읽을 값]
- 저장소 루트 .env의 RESOURCE_GROUP, AKS_NAME, REGION, EGRESS_IP_CIDR,
  POD_CIDR, SERVICE_CIDR, DNS_SERVICE_IP, SYSTEM_VM_SIZE, USER_VM_SIZE
- 비어 있는 값이 있으면 추측하지 말고 먼저 알려줘
- Lab 02의 Day-0 검토와 least privilege 매트릭스를 반영해줘

[보안 요구]
- public API server의 authorized IP ranges는 EGRESS_IP_CIDR만 사용
- Entra와 Azure RBAC for Kubernetes 사용
- local accounts는 비활성화

[구성 요구]
- system/user node pool 분리
- Azure CNI Overlay + Cilium
- load balancer egress
- 서로 겹치지 않는 CIDR

[출력]
- 대안, 위험, 비용 요인

[하지 말 것]
- 계획 승인 전에는 멈춰
- 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘
```

**진행 방식**

이 Skill은 7단계를 순서대로 밟으며, 중간에 **두 번 멈춰 승인을 요청**합니다. 먼저 만들 자원 목록을, 그다음 완성된 계획을 확인합니다. 멈췄다고 실패한 게 아니라 설계된 동작입니다.

1. 프롬프트를 실행하면 대안·위험·예상 비용 요인이 정리되어 나옵니다.
2. 다음 세 가지를 직접 검토합니다.
   - Lab 01에서 기록해 둔 기존 자원을 "참조"만 하고 덮어쓰지 않는지
   - API authorized IP ranges, Entra 인증, local accounts 비활성화가 모두 들어있는지
   - Lab 02에서 결정한 region·SKU·node 개수·CIDR과 정확히 일치하는지

승인자는 여러분 자신입니다. 애매하면 질문을 더 하세요.

## Step 2. 계획을 승인하고 파일에 남기기

채팅에 "승인합니다"라고 쓰는 것만으로는 부족합니다. 계획 파일의 `meta.status`가 `draft`로 남아 있으면, **다음 프롬프트에서 Skill이 다시 읽고 멈춥니다.** 승인은 파일에 기록되어야 합니다.

> 🧠 **Skill** `azure-enterprise-infra-planner` &nbsp;·&nbsp; 📋 **검토를 마쳤다면 아래 프롬프트를 복사해 실행**

```text
이 계획을 승인합니다.

[해야 할 일]
- azure-enterprise-infra-planner Skill의 Phase 5에 따라
  .azure/infrastructure-plan.json의 meta.status를 approved로 바꿔줘
- 승인자와 승인 시각을 함께 기록해줘
- 어떤 값이 approved로 바뀌었는지 보여줘

[하지 말 것]
- 아직 IaC 생성이나 배포로 넘어가지 마
```

**확인할 것**

```bash
grep -A3 '"meta"' .azure/infrastructure-plan.json
```

`"status": "approved"`가 보여야 다음 Step이 진행됩니다. 아직 `draft`라면 승인이 파일에 반영되지 않은 것입니다.

**완료 기준:** `.azure/infrastructure-plan.json`의 `meta.status`가 `approved`이고, 승인자와 승인 시각이 들어 있습니다.

## Step 3. 승인된 계획으로 Bicep 생성하기

> 🧠 **Skill** `azure-enterprise-infra-planner` &nbsp;·&nbsp; 📋 **아래 프롬프트를 복사해 실행**

```text
azure-enterprise-infra-planner Skill을 사용해 Bicep을 생성해줘.

[읽을 값]
- 승인된 infrastructure plan
- 저장소 루트의 .env

[해야 할 일]
- 기존 foundation 자원은 참조만 하고 덮어쓰지 마
- 변경 대상과 생성 파일을 설명해줘
- 그 Skill이 요구하는 로컬 문법 확인(az bicep build)까지는 해도 돼

[하지 말 것]
- Azure에 자원을 만들거나 바꾸는 명령은 실행하지 마
- 보안 검사와 what-if는 Lab 04에서 하니 여기서는 하지 마
- 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘
```

이 Skill은 생성한 Bicep의 **문법 확인을 자기 절차의 일부로** 봅니다. 그래서 "검증하지 마"라고 막으면 생성 자체를 거부합니다. 여기서 미루는 것은 **Azure를 건드리는 일**뿐이고, 로컬에서 끝나는 `az bicep build`는 비용도 영향도 없으므로 허용합니다.

**확인할 것**

- 생성된 파일 목록과 위치(`infra/main.bicep`, `infra/modules/*.bicep`)
- 매개변수(authorized IP ranges, CIDR, SKU 등)가 계획과 정확히 일치하는지

[Bicep 기준본](../../reference/infra/main.bicep)을 열어 내가 받은 결과와 **비교**해 볼 수 있습니다. 그대로 복사해 쓰는 정답지가 아니니, 차이가 있다면 "왜 다른가"를 따져보세요.

<details>
<summary>💡 <b>Skill을 안 썼다면?</b></summary>

| 방식 | 이 단계에서 벌어지는 일 |
| --- | --- |
| 🖐 수동 | 설계 문서와 Bicep을 각각 쓰고, 둘이 어긋나지 않게 사람이 계속 맞춰야 한다. |
| 💬 일반 프롬프트 | 승인 단계 없이 **바로 코드부터** 만든다. 계획 산출물이 남지 않아 나중에 "왜 이렇게 했지?"에 답할 수 없다. |
| ⚡ Skill | `계획 → 승인 → 코드` 순서를 강제하고, 승인된 계획을 파일로 남겨 코드의 근거로 삼는다. |

</details>

## ✅ 완료 체크리스트

- [ ] 계획 파일의 `meta.status`가 `approved`이고 승인자/시각이 들어 있음
- [ ] Bicep 파일이 생성되고 계획과 일치함
- [ ] 아직 `az deployment` 등 실제 배포 명령은 실행하지 않음

## 🚧 문제가 생겼다면

| 증상 | 원인일 가능성 | 해야 할 일 |
| --- | --- | --- |
| "값이 비어 있어 멈췄다"고 답함 | Lab 02의 `set-env.sh` 반영을 건너뜀 | `cat .env`로 빈 항목을 찾아 [Lab 02](02-design-aks.md)에서 반영 후 재실행 |
| "plan 상태가 `draft`"라며 Bicep 생성을 거부 | 채팅으로만 승인해 파일에 반영되지 않음 | Step 2의 승인 프롬프트를 실행해 `meta.status`를 `approved`로 바꾼 뒤 재실행 |
| "검증하지 말라는 조건과 충돌"한다며 멈춤 | Skill은 문법 확인을 생성 절차의 일부로 봄 | Step 3 프롬프트처럼 **Azure 배포만** 막고 `az bicep build`는 허용 |
| 승인을 물어보는 단계가 두 번 나온다 | 자원 목록과 완성된 계획을 따로 확인하는 정상 동작 | 각각 내용을 확인하고 승인 |
| 계획에 없던 자원이 생성 목록에 있다 | 기존 자원 참조가 누락됨 | "기존 자원은 참조만" 문구를 강조해 재요청 |
| 매개변수가 계획과 다르다 | `.env` 값이 최신이 아님 | `.env`를 갱신하고 재생성 요청 |

## 다음 Lab

[Lab 04: IaC 검증 + 배포 승인](04-validate-and-approve.md)
