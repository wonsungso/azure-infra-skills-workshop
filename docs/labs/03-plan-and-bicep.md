# Lab 03: 계획 승인 + Bicep 생성

**Lab 3 / 8** · 1부 · 설계와 검증

🎯 계획 승인 → Bicep 생성

🧠 `azure-enterprise-infra-planner`

> 🎬 무엇을 만들지 승인한 다음 코드로 바꿉니다.

## 왜 필요한가요?

- Agent가 Lab 02의 결정으로 자원·연결·보안 계획을 작성하고, 승인 후 Bicep으로 바꿉니다.
- 사람은 코드 생성 전에 무엇이 만들어질지 검토하고, 생성된 코드가 계획과 같은지 확인합니다.
- 계획 승인과 코드 생성을 분리해 요청하지 않은 변경을 막습니다. 실제 배포는 아직 하지 않습니다.

## 시작 전에

- [Lab 02](02-design-aks.md)의 결정값과 권한 매트릭스를 준비합니다.

## Step 1. 계획 검토·승인하기

이 프롬프트는 설계값을 자원 목록과 계획으로 구체화하고, 각각의 승인을 받은 뒤 멈춥니다.

> 🧠 **Skill** `azure-enterprise-infra-planner` &nbsp;·&nbsp; 💬 **Copilot 채팅에 붙여넣기**

```text
azure-enterprise-infra-planner Skill로 인프라 계획을 작성해줘.

[읽을 값]
- 저장소 루트 .env와 infra-report.md의 Lab 02 결정·권한 매트릭스

[할 일]
- AKS·AGC·Private PostgreSQL·Network·Identity 계획을 결정값과 대조
- Egress /32 제한, Entra RBAC, Local Accounts 비활성화,
  Workload Identity, PostgreSQL Public·Password 비활성화를 반영
- 기존 Foundation은 참조만 하고 변경하지 않는지 확인
- Skill의 Phase 1~5를 따라 자원 목록·계획의 승인을 각각 요청
- 승인된 계획과 승인 기록을 로컬로 저장하고 결과를 보고서에 기록

[제약]
- 필수 값이 비어 있으면 추측하지 말고 멈춰
- 계획 승인 전에는 멈춰. 승인 후에도 IaC 생성·배포로 넘어가지 마
- 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘
```

**완료 기준:** 계획의 `meta.status`가 `approved`이고 결정값·승인 기록이 일치합니다.

## Step 2. 승인된 계획으로 Bicep 생성하기

이 프롬프트는 승인된 계획만 코드로 만들고, 로컬 검사 결과와 계획의 일치 여부를 보여줍니다.

> 🧠 **Skill** `azure-enterprise-infra-planner` &nbsp;·&nbsp; 💬 **Copilot 채팅에 붙여넣기**

```text
azure-enterprise-infra-planner Skill로 승인된 계획의 Bicep을 생성해줘.

[할 일]
- .env와 승인된 Infrastructure Plan을 읽고 approved 상태 확인
- infra/에 IaC 생성, Skill이 요구하는 로컬 build·보안 검사 수행
- 생성 파일과 계획의 일치 여부, 실제 명령·결과를 보고서에 기록

[제약]
- 승인되지 않은 계획으로 생성하지 마
- 기존 Foundation을 덮어쓰지 마
- Azure 리소스를 만들거나 바꾸지 마
- 실패하면 기록하고 멈춰
- 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘
```

**완료 기준:** IaC가 계획과 일치하고 Skill의 로컬 검사에 통과합니다.

<details>
<summary>🧪 <b>선택: SKU를 바꾸면 계획도 바뀔까요?</b></summary>

System D4s_v5 2대 + User D2s_v5 1대를 선택한 경우, Step 1과 Step 2 사이에만 실행합니다.

> 🧠 **Skill** `azure-enterprise-infra-planner` &nbsp;·&nbsp; 💬 **Copilot 채팅에 붙여넣기**

```text
azure-enterprise-infra-planner Skill로 계획 변경·복원 실험을 해줘.

[할 일]
- 승인된 원본 값·버전·승인 기록을 보존
- 다른 구성이면 실험하지 말고 멈춰
- scripts/set-env.sh로 USER_VM_SIZE를 Standard_D4s_v5로 변경해 vCPU 10→12,
  Quota·비용·변경 항목을 보여줘
- 검토 후 원래 Standard_D2s_v5로 되돌릴지 내 확인을 받아
- 원본 계획과 .env를 복원하고 vCPU 10·승인 기록 일치 확인

[제약]
- 변경된 계획을 자동 승인하거나 새 승인 기록을 꾸며내지 마
- 원본 복원에 실패하면 Step 2로 넘어가지 마
- Azure 리소스를 만들거나 바꾸지 마
- 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘
```

</details>

## ✅ 완료 체크리스트

- [ ] 계획을 검토·승인했다
- [ ] 생성된 IaC와 로컬 검사 결과가 기록됐다
- [ ] 아직 실제 인프라는 배포하지 않았다

## 🚧 문제가 생겼다면

<details>
<summary>🔎 <b>승인·생성 결과 확인</b></summary>

| 문제 | 다음 조치 |
| --- | --- |
| 상태가 draft | 변경 내용을 검토한 뒤 명시적으로 재승인 |
| 생성 코드가 결정값과 다름 | 차이를 설명받고 해당 항목만 수정·재검사 |
| 로컬 검사 실패 | 실제 오류를 수정. 통과 전 Lab 04로 가지 않음 |

[`main.bicep`](../../reference/infra/main.bicep)은 비교용 기준본이며 Skill 생성 품질을 대신 증명하지 않습니다.

</details>

## 다음 Lab

계획·IaC 확인을 마친 뒤 [Lab 04: IaC 검증 + 배포 승인](04-validate-and-approve.md)으로 이동합니다.
