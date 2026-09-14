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

## Step 1. 인프라 계획 만들고 승인하기

> 🧠 **Skill** `azure-enterprise-infra-planner` &nbsp;·&nbsp; 📋 **아래 프롬프트를 복사해 실행**

```text
azure-enterprise-infra-planner Skill을 사용해 인프라 계획을 작성해줘. 저장소 루트의 .env에서 RESOURCE_GROUP, AKS_NAME, REGION, EGRESS_IP_CIDR, POD_CIDR, SERVICE_CIDR, DNS_SERVICE_IP, SYSTEM_VM_SIZE, USER_VM_SIZE를 읽어 쓰고, 비어 있는 값이 있으면 추측하지 말고 먼저 알려줘. Lab 02의 Day-0 검토와 least privilege 매트릭스를 반영해줘. public API server의 authorized IP ranges는 EGRESS_IP_CIDR만 사용하고, Entra와 Azure RBAC for Kubernetes를 사용하며 local accounts는 비활성화해줘. system/user node pool 분리, Azure CNI Overlay + Cilium, load balancer egress, 비중첩 CIDR을 포함해줘. 대안, 위험, 비용 요인을 보여주고 계획 승인 전에는 멈춰. 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘.
```

**진행 방식**

1. 프롬프트를 실행하면 대안·위험·예상 비용 요인이 정리되어 나옵니다.
2. 다음 세 가지를 직접 검토합니다.
   - Lab 01에서 기록해 둔 기존 자원을 "참조"만 하고 덮어쓰지 않는지
   - API authorized IP ranges, Entra 인증, local accounts 비활성화가 모두 들어있는지
   - Lab 02에서 결정한 region·SKU·node 개수·CIDR과 정확히 일치하는지
3. 검토가 끝나면 승인 여부를 말로 명확히 표현합니다(예: "이 계획을 승인합니다").

승인자는 여러분 자신입니다. **계획을 승인하기 전에는 다음 Step으로 진행하지 않습니다.** 애매하면 질문을 더 하세요.

**완료 기준:** `.azure/infrastructure-plan.json`(또는 동등한 계획 산출물)이 생성되고, 승인 여부와 승인 시각이 기록됩니다.

## Step 2. 승인된 계획으로 Bicep 생성하기

> 🧠 **Skill** `azure-enterprise-infra-planner` &nbsp;·&nbsp; 📋 **아래 프롬프트를 복사해 실행**

```text
azure-enterprise-infra-planner Skill을 사용해 승인된 infrastructure plan과 .env를 읽어 Bicep을 생성 또는 갱신해줘. 기존 foundation 자원은 참조하고, 변경 대상과 생성 파일을 설명해줘. 검증과 배포는 아직 하지 마. 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘.
```

**확인할 것**

- 생성된 파일 목록과 위치
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

- [ ] 계획이 승인되고 승인자/시각이 기록됨
- [ ] Bicep 파일이 생성되고 계획과 일치함
- [ ] 아직 `az deployment` 등 실제 배포 명령은 실행하지 않음

## 🚧 문제가 생겼다면

| 증상 | 원인일 가능성 | 해야 할 일 |
| --- | --- | --- |
| "값이 비어 있어 멈췄다"고 답함 | Lab 02의 `set-env.sh` 반영을 건너뜀 | `cat .env`로 빈 항목을 찾아 [Lab 02](02-design-aks.md)에서 반영 후 재실행 |
| 계획에 없던 자원이 생성 목록에 있다 | 기존 자원 참조가 누락됨 | "기존 자원은 참조만" 문구를 강조해 재요청 |
| 매개변수가 계획과 다르다 | `.env` 값이 최신이 아님 | `.env`를 갱신하고 재생성 요청 |
| 승인자가 불명확하다 | 팀 역할 미정 | Lab 01의 역할 정리로 돌아가기 |

## 다음 Lab

[Lab 04: IaC 검증 + 배포 승인](04-validate-and-approve.md)
