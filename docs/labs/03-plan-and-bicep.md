# Lab 03: 계획 승인 + Bicep 생성

**Lab 3 / 8** · 1부 · 설계와 검증

🎯 계획 작성·변경 검토 / 계획 승인 / Bicep 생성

🧠 `azure-enterprise-infra-planner`

> 🎬 계획을 검토·승인한 뒤 Bicep을 생성합니다.

## 왜 필요한가요?

**계획 → 승인 → 코드** 순서로 설계와 IaC의 불일치를 줄입니다.
값을 바꿔 계획·Quota·비용이 함께 갱신되는지도 확인합니다.

## 시작 전에

- [Lab 02](02-design-aks.md)의 Day-0 결정표와 권한 매트릭스가 있나요?
- `.env`의 Subnet CIDR과 Node·Database SKU가 모두 채워져 있나요?

> 💻 **터미널에서 실행**

```bash
cat .env
```

## Step 1. 인프라 계획 만들고 검토하기

> 🧠 **Skill** `azure-enterprise-infra-planner` &nbsp;·&nbsp; 💬 **Copilot 채팅에 붙여넣기**

```text
azure-enterprise-infra-planner Skill을 사용해 인프라 계획을 작성해줘.

[읽을 값]
- 저장소 루트 .env의 RESOURCE_GROUP, AKS_NAME, POSTGRES_NAME, REGION,
  EGRESS_IP_CIDR, POD_CIDR, SERVICE_CIDR, DNS_SERVICE_IP,
  ALB_SUBNET_CIDR, POSTGRES_SUBNET_CIDR, SYSTEM_VM_SIZE,
  USER_VM_SIZE, POSTGRES_SKU
- 비어 있는 값이 있으면 추측하지 말고 먼저 알려줘
- Lab 02의 Day-0 검토와 Least Privilege 매트릭스를 반영해줘

[보안 요구]
- Public API Server의 Authorized IP Ranges는 EGRESS_IP_CIDR만 사용
- Entra와 Azure RBAC for Kubernetes 사용
- Local Accounts는 비활성화
- PostgreSQL Public Access와 Password Authentication은 비활성화

[구성 요구]
- System/User Node Pool 분리
- Azure CNI Overlay + Cilium
- Gateway API + Application Gateway for Containers Add-on
- OIDC + Workload Identity
- Private PostgreSQL Flexible Server + Private DNS
- Node / ALB / PostgreSQL Subnet 분리
- 서로 겹치지 않는 CIDR

[출력]
- 대안, 위험, 비용 요인

[제약]
- 계획 승인 전에는 멈춰
- 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘
```

**진행 방식**

Skill은 다음 7단계를 순서대로 진행합니다.

1. 기존 환경 정보 수집 - `.azure/insights.json`에 기록
2. 모범 사례 조사 - MCP와 Well-Architected Framework 기준 확인
3. 필요한 Azure 자원 조사 - 자원 목록을 보여주고 **첫 승인** 요청
4. 인프라 계획 작성 - `.azure/infrastructure-plan.json`에 `draft`로 저장
5. 계획 검증 - 검토 결과를 보여주고 **두 번째 승인** 요청
6. Bicep 또는 Terraform 생성 - 승인된 계획에서 IaC 파일 생성
7. Azure 배포 - 실제 자원 생성 또는 변경 전 최종 승인 요청

**이 Step은 1~5단계만 진행합니다.** 자원 목록과 계획을 각각 승인합니다.

다음을 확인합니다.

- 기존 자원을 "참조"만 하고 덮어쓰지 않는가
- API 제한, Workload Identity, Passwordless PostgreSQL이 들어 있는가
- Lab 02의 Region·SKU·Node 수·Subnet CIDR과 일치하는가

### 승인 요청에 응답하기

채팅의 **승인 / 거절**은 다음 단계 진행을 결정합니다. **계획 승인만으로 리소스가 생성되지는 않습니다.**

- 계획이 맞으면 **승인**, 수정이 필요하면 **거절**과 이유를 전달합니다
- 버튼이 없으면 "승인합니다"라고 입력합니다

계획 파일의 `meta.status`는 Step 3에서 별도로 확인합니다.

## Step 2. 값 변경과 계획 갱신 확인하기

User Node SKU를 바꿔 `.env`와 계획이 일치하는지 확인합니다. **Azure 리소스는 변경하지 않습니다.**

> 💻 **터미널에서 실행**

```bash
bash scripts/set-env.sh USER_VM_SIZE Standard_D4s_v5
```

> 🧠 **Skill** `azure-enterprise-infra-planner` &nbsp;·&nbsp; 💬 **Copilot 채팅에 붙여넣기**

```text
방금 .env의 USER_VM_SIZE를 바꿨어. azure-enterprise-infra-planner Skill로 계획을 갱신해줘.

[보여줄 것]
- 계획에서 바뀐 항목과 바뀌기 전후 값
- 이 변경으로 전체 vCPU가 몇 개가 되는지와 Quota 여유
- 비용 요인이 어떻게 달라지는지

[제약]
- 내가 바꾼 값 때문에 달라지는 것만 바꿔 줘. 나머지는 그대로 둬.
- Azure 리소스를 만들거나 바꾸지 마
- 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘
```

**확인할 것**

- vCPU 합계가 **10 → 12**로 갱신됐는가?
- 비용 증가 요인이 반영됐는가?
- CIDR·보안 등 요청하지 않은 설정은 유지됐는가?

비교 후 원래 교육용 SKU로 되돌립니다.

> 💻 **터미널에서 실행**

```bash
bash scripts/set-env.sh USER_VM_SIZE Standard_D2s_v5
```

> 💬 **Copilot 채팅에 붙여넣기**

```text
USER_VM_SIZE를 Standard_D2s_v5로 되돌렸어. 계획도 원래대로 되돌리고,
지금 계획이 Lab 02에서 결정한 값과 다시 일치하는지 확인해줘.
```

**완료 기준:** 계획의 User SKU는 `Standard_D2s_v5`, vCPU 합계는 10입니다.

## Step 3. 계획 상태 확인하기

**승인된 원본과 동일하게 복원됐다면 재승인이 필요 없습니다.** 예: `0.1-approved`.

> 💻 **터미널에서 실행**

```bash
jq '.meta | {status, version, approvedBy, approvedAt}' .azure/infrastructure-plan.json
```

- `"status": "approved"`이고 원본 버전이 복원됐다면 Step 4로 진행합니다
- `"status": "draft"`이거나 원본과 다른 값이 남아 있으면 아래 프롬프트로 승인합니다

> 🧠 **Skill** `azure-enterprise-infra-planner` &nbsp;·&nbsp; 💬 **`draft`일 때만 Copilot 채팅에 붙여넣기**

```text
이 계획을 승인해.

[해야 할 일]
- azure-enterprise-infra-planner Skill의 Phase 5에 따라
  .azure/infrastructure-plan.json의 meta.status를 approved로 바꿔줘
- 승인자와 승인 시각을 함께 기록해줘
- 어떤 값이 approved로 바뀌었는지 보여줘

[제약]
- 아직 IaC 생성이나 배포로 넘어가지 마
- 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘
```

**완료 기준:** `meta.status`가 `approved`이며, 새 승인에는 승인자·시각이 기록됩니다.

## Step 4. 승인된 계획으로 Bicep 생성하기

> 🧠 **Skill** `azure-enterprise-infra-planner` &nbsp;·&nbsp; 💬 **Copilot 채팅에 붙여넣기**

```text
azure-enterprise-infra-planner Skill을 사용해 Bicep을 생성해줘.

[읽을 값]
- 승인된 Infrastructure Plan
- 저장소 루트의 .env

[해야 할 일]
- 기존 Foundation 자원은 참조만 하고 덮어쓰지 마
- 변경 대상과 생성 파일을 설명해줘
- 그 Skill이 요구하는 로컬 문법 확인(az bicep build)까지는 해도 돼

[제약]
- Azure에 자원을 만들거나 바꾸는 명령은 실행하지 마
- 보안 검사와 What-if는 Lab 04에서 하니 여기서는 하지 마
- 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘
```

Skill의 Bicep 생성 절차에는 **로컬 문법 검사**가 포함됩니다.
`az bicep build`는 허용하고, 보안 검사·What-if·Azure 변경은 다음 Lab으로 미룹니다.

**확인할 것**

- 생성된 파일 목록과 위치(`infra/main.bicep`, `infra/modules/*.bicep`)
- Ingress·AKS·PostgreSQL 매개변수가 계획과 일치하는지

[Bicep 기준본](../../reference/infra/main.bicep)은 비교용입니다. 생성 결과와 다르면 이유를 확인합니다.

<details>
<summary>💡 <b>Skill을 안 썼다면?</b></summary>

| 방식 | 이 단계에서 벌어지는 일 |
| --- | --- |
| 🖐 수동 | 계획과 Bicep의 일치를 직접 관리한다. |
| 💬 일반 프롬프트 | 계획 기록과 승인 단계를 명시해야 한다. |
| ⚡ Skill | 승인된 계획을 기록하고 그 계획으로 IaC를 생성한다. |

</details>

## ✅ 완료 체크리스트

- [ ] 계획이 `.env` 값을 실제로 읽고 만들어졌음을 값을 바꿔 확인함
- [ ] 바꿔 본 값을 원래대로 되돌렸고 vCPU 합계가 다시 10임
- [ ] 계획 파일의 `meta.status`가 `approved`이고 승인자/시각이 들어 있음
- [ ] Bicep에 AGC Add-on, AKS, Private PostgreSQL이 들어 있음
- [ ] 아직 `az deployment` 등 실제 배포 명령은 실행하지 않음

## 🚧 문제가 생겼다면

<details>
<summary>🔎 <b>증상별 원인과 해결 방법</b></summary>

| 증상 | 원인일 가능성 | 해야 할 일 |
| --- | --- | --- |
| "값이 비어 있어 멈췄다"고 답함 | Lab 02의 `set-env.sh` 반영을 건너뜀 | `cat .env`로 빈 항목을 찾아 [Lab 02](02-design-aks.md)에서 반영 후 재실행 |
| 승인 버튼의 의미가 불명확 | 다음 단계 진행을 묻는 승인 요청 | 대상 단계를 확인한 뒤 응답. 계획 상태는 Step 3에서 확인 |
| "Plan 상태가 `draft`"라며 Bicep 생성을 거부 | 버튼을 눌렀을 뿐 파일에 반영되지 않음 | Step 3의 승인 프롬프트를 실행해 `meta.status`를 `approved`로 바꾼 뒤 재실행 |
| 값을 바꿨는데 계획이 그대로다 | Skill이 `.env`를 다시 읽지 않았음 | 어느 파일의 어떤 키를 바꿨는지 명시해 다시 요청 |
| 요청하지 않은 항목도 바뀜 | 변경 범위 누락 | 변경 이유를 확인하고 요청 범위 밖의 항목은 복원 |
| "검증하지 말라는 조건과 충돌"한다며 멈춤 | Skill은 문법 확인을 생성 절차의 일부로 봄 | Step 4 프롬프트처럼 **Azure 배포만** 막고 `az bicep build`는 허용 |
| 승인을 물어보는 단계가 두 번 나온다 | 자원 목록과 완성된 계획을 따로 확인하는 정상 동작 | 각각 내용을 확인하고 승인 |
| "WAF·Microsoft Learn 도구가 없다"고 적으며 진행 | MCP 서버가 꺼져 있음 | [Lab 01](01-orientation-and-setup.md) Step 2로 돌아가 `azure`와 `microsoft-learn`을 시작한 뒤 계획을 다시 생성 |
| 계획에 없던 자원이 생성 목록에 있다 | 기존 자원 참조가 누락됨 | "기존 자원은 참조만" 문구를 강조해 다시 요청 |
| 매개변수가 계획과 다르다 | `.env` 값이 최신이 아님 | `.env`를 갱신하고 재생성 요청 |

</details>

## 다음 Lab

[Lab 04: IaC 검증 + 배포 승인](04-validate-and-approve.md)
