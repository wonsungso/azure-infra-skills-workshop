# Lab 03: 계획 승인 + Bicep 생성

**Lab 3 / 8** · 1부 · 설계와 검증

🎯 설계 결정을 승인 가능한 계획 문서로 / 계획이 바뀌면 무엇이 따라 바뀌는지 / 승인된 계획을 Bicep 코드로

🧠 `azure-enterprise-infra-planner`

> 🎬 팀장의 첫 번째 조건을 기억하세요 - **클릭이 아니라 승인 기반으로.** 계획을 먼저 승인받고, 그제서야 코드를 만듭니다.

## 왜 필요한가요?

`azure-enterprise-infra-planner`는 요구사항으로 계획을 먼저 만들고, 사람이 승인한 뒤에야 Bicep을 생성합니다. **계획 → 승인 → 코드** 순서가 잘못된 자원의 배포를 막는 핵심 안전장치입니다.

계획이 파일로 남으면 하나가 더 가능해집니다. **값을 바꿔보고 무엇이 따라 움직이는지 확인한 뒤에 승인**할 수 있습니다. 이 Lab에서 직접 해봅니다.

## 시작 전에

- [Lab 02](02-design-aks.md)의 Day-0 결정표와 권한 매트릭스가 있나요?
- `.env`에 `POD_CIDR`, `SERVICE_CIDR`, `DNS_SERVICE_IP`까지 채워져 있나요? 비어 있으면 아래 프롬프트가 멈춥니다.

> 💻 **터미널에서 실행**

```bash
cat .env
```

## Step 1. 인프라 계획 만들고 검토하기

> 🧠 **Skill** `azure-enterprise-infra-planner` &nbsp;·&nbsp; 💬 **Copilot 채팅에 붙여넣기**

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

[제약]
- 계획 승인 전에는 멈춰
- 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘
```

**진행 방식**

이 Skill은 7단계를 순서대로 밟으며, 단계마다 자신의 참조 문서를 읽고 검증합니다.

- 1. 기존 환경 정보 수집 - `.azure/insights.json`에 기록
- 2. 모범 사례 조사 - MCP와 Well-Architected Framework 기준 확인
- 3. 필요한 Azure 자원 조사 - 자원 목록을 보여주고 **첫 승인** 요청
- 4. 인프라 계획 작성 - `.azure/infrastructure-plan.json`에 `draft`로 저장
- 5. 계획 검증 - 검토 결과를 보여주고 **두 번째 승인** 요청
- 6. Bicep 또는 Terraform 생성 - 승인된 계획에서 IaC 파일 생성
- 7. Azure 배포 - 실제 자원 생성 또는 변경 전 최종 승인 요청

- **답이 나오기까지 몇 분 걸립니다**
- 파일을 수십 개 읽는 것이 정상입니다
- 빠른 답을 원했다면 그건 일반 프롬프트지 이 Skill을 쓰는 이유가 아닙니다

중간에 **두 번 멈춰 승인**을 요청합니다.

- 먼저 만들 자원 목록을 확인합니다
- 다음으로 완성된 계획을 확인합니다
- 이때 멈추는 것은 정상 동작입니다

1. 프롬프트를 실행하면 대안·위험·예상 비용 요인이 정리되어 나옵니다.
2. 다음 세 가지를 직접 검토합니다.
   - Lab 01에서 기록해 둔 기존 자원을 "참조"만 하고 덮어쓰지 않는지
   - API authorized IP ranges, Entra 인증, local accounts 비활성화가 모두 들어있는지
   - Lab 02에서 결정한 region·SKU·node 개수·CIDR과 정확히 일치하는지

승인자는 여러분 자신입니다. 판단이 서지 않으면, 이유를 더 물어본 뒤 결정하면 됩니다.

### 승인 / 거절 버튼이 떴다면

Skill이 멈추는 자리에서 채팅에 **승인 / 거절** 버튼이 나타납니다.

- Azure에 무언가를 만들겠다는 뜻이 아닙니다
- **Skill이 다음 단계로 넘어가도 되는지 묻는 것**입니다
- 여기서 승인해도 리소스는 생성되지 않습니다

- **내용을 읽은 뒤 이상이 없으면 승인**을 선택합니다.
- 다르거나 빠진 게 있으면 **거절**을 선택하고, 이유를 알려주면 Skill이 고쳐서 다시 제시합니다.
- 버튼이 보이지 않으면 채팅에 "승인합니다"라고 입력해도 같습니다.

**버튼을 눌렀다고 끝이 아닙니다.** 그건 대화의 흐름일 뿐이고, 계획 파일에 `approved`로 남았는지는 별개입니다. Step 3에서 그것을 확인합니다.

## Step 2. 값을 하나 바꿔 계획이 따라오는지 보기

계획이 `.env`를 실제로 읽고 만들어졌는지 확인해 봅니다. 값 하나를 바꾼 뒤, 계획이 따라 바뀌는지 봅니다.

user node pool의 크기를 한 단계 올려봅니다. 실제로 배포하려는 게 아니라, **바꾸면 무엇이 따라 움직이는지** 보려는 것입니다.

> 💻 **터미널에서 실행**

```bash
bash scripts/set-env.sh USER_VM_SIZE Standard_D4s_v5
```

> 🧠 **Skill** `azure-enterprise-infra-planner` &nbsp;·&nbsp; 💬 **Copilot 채팅에 붙여넣기**

```text
방금 .env의 USER_VM_SIZE를 바꿨어. azure-enterprise-infra-planner Skill로 계획을 갱신해줘.

[보여줄 것]
- 계획에서 바뀐 항목과 바뀌기 전후 값
- 이 변경으로 전체 vCPU가 몇 개가 되는지와 quota 여유
- 비용 요인이 어떻게 달라지는지

[제약]
- 내가 바꾼 값 때문에 달라지는 것만 바꿔 줘. 나머지는 그대로 둬.
- Azure 리소스를 만들거나 바꾸지 마
- 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘
```

**확인할 것**

- vCPU 합계가 **10에서 12로** 다시 계산됐나요? 옛 숫자를 그대로 쓰고 있다면 계획을 읽고 고친 게 아닙니다.
- 비용 요인이 함께 움직였나요?
- **부탁하지 않은 것까지 바뀌지 않았나요?** CIDR이나 보안 설정이 덩달아 달라졌다면 그게 더 큰 문제입니다.

이것이 계획을 파일로 남기는 이유입니다.

- 값 하나를 바꾸면 **무엇이 따라 바뀌는지 눈으로 보입니다**
- 바뀌지 말아야 할 것이 바뀌면 그것도 보입니다
- 머릿속 설계로는 안 되는 일입니다

이제 되돌립니다. 교육용 클러스터에 user node를 키울 이유가 없다는 것이 **방금 비용 비교로 확인한 판단**입니다.

> 💻 **터미널에서 실행**

```bash
bash scripts/set-env.sh USER_VM_SIZE Standard_D2s_v5
```

> 💬 **Copilot 채팅에 붙여넣기**

```text
USER_VM_SIZE를 Standard_D2s_v5로 되돌렸어. 계획도 원래대로 되돌리고,
지금 계획이 Lab 02에서 결정한 값과 다시 일치하는지 확인해줘.
```

**완료 기준:** 계획의 user node SKU가 `Standard_D2s_v5`로 돌아왔고, vCPU 합계가 다시 10입니다.

## Step 3. 계획을 승인하고 파일에 남기기

Step 1에서 버튼을 눌렀더라도 한 번 더 확인합니다.

- 계획 파일의 `meta.status`가 `draft`로 남아 있으면 **다음 프롬프트에서 Skill이 다시 읽고 멈춥니다**
- 승인은 대화가 아니라 **파일에 기록**되어야 합니다

> 🧠 **Skill** `azure-enterprise-infra-planner` &nbsp;·&nbsp; 💬 **검토를 마쳤다면 Copilot 채팅에 붙여넣기**

```text
이 계획을 승인해.

[해야 할 일]
- azure-enterprise-infra-planner Skill의 Phase 5에 따라
  .azure/infrastructure-plan.json의 meta.status를 approved로 바꿔줘
- 승인자와 승인 시각을 함께 기록해줘
- 어떤 값이 approved로 바뀌었는지 보여줘

[제약]
- 아직 IaC 생성이나 배포로 넘어가지 마
```

**확인할 것**

> 💻 **터미널에서 실행**

```bash
grep -A3 '"meta"' .azure/infrastructure-plan.json
```

`"status": "approved"`가 보여야 다음 Step이 진행됩니다. 아직 `draft`라면 승인이 파일에 반영되지 않은 것입니다.

**완료 기준:** `.azure/infrastructure-plan.json`의 `meta.status`가 `approved`이고, 승인자와 승인 시각이 들어 있습니다.

## Step 4. 승인된 계획으로 Bicep 생성하기

> 🧠 **Skill** `azure-enterprise-infra-planner` &nbsp;·&nbsp; 💬 **Copilot 채팅에 붙여넣기**

```text
azure-enterprise-infra-planner Skill을 사용해 Bicep을 생성해줘.

[읽을 값]
- 승인된 infrastructure plan
- 저장소 루트의 .env

[해야 할 일]
- 기존 foundation 자원은 참조만 하고 덮어쓰지 마
- 변경 대상과 생성 파일을 설명해줘
- 그 Skill이 요구하는 로컬 문법 확인(az bicep build)까지는 해도 돼

[제약]
- Azure에 자원을 만들거나 바꾸는 명령은 실행하지 마
- 보안 검사와 what-if는 Lab 04에서 하니 여기서는 하지 마
- 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘
```

이 Skill은 생성한 Bicep의 **문법 확인을 자기 절차의 일부로** 봅니다.

- 그래서 "검증하지 마"라고 막으면 **생성 자체를 거부**합니다
- 여기서 미루는 것은 **Azure를 건드리는 일**뿐입니다
- `az bicep build`는 로컬에서 끝나 비용도 영향도 없으므로 허용합니다

**확인할 것**

- 생성된 파일 목록과 위치(`infra/main.bicep`, `infra/modules/*.bicep`)
- 매개변수(authorized IP ranges, CIDR, SKU 등)가 계획과 정확히 일치하는지

[Bicep 기준본](../../reference/infra/main.bicep)은 비교용입니다.

- 그대로 복사해 쓰는 정답지가 아닙니다
- 차이가 있으면 이유를 확인해 봅니다

<details>
<summary>💡 <b>Skill을 안 썼다면?</b></summary>

| 방식 | 이 단계에서 벌어지는 일 |
| --- | --- |
| 🖐 수동 | 설계 문서와 Bicep을 각각 쓰고, 둘이 어긋나지 않게 사람이 계속 맞춰야 한다. |
| 💬 일반 프롬프트 | 승인 단계 없이 **바로 코드부터** 만든다. 계획 산출물이 남지 않아 나중에 "왜 이렇게 했지?"에 답할 수 없다. |
| ⚡ Skill | `계획 → 승인 → 코드` 순서를 강제하고, 승인된 계획을 파일로 남겨 코드의 근거로 삼는다. |

</details>

## ✅ 완료 체크리스트

- [ ] 계획이 `.env` 값을 실제로 읽고 만들어졌음을 값을 바꿔 확인함
- [ ] 바꿔 본 값을 원래대로 되돌렸고 vCPU 합계가 다시 10임
- [ ] 계획 파일의 `meta.status`가 `approved`이고 승인자/시각이 들어 있음
- [ ] Bicep 파일이 생성되고 계획과 일치함
- [ ] 아직 `az deployment` 등 실제 배포 명령은 실행하지 않음

## 🚧 문제가 생겼다면

<details>
<summary>🔎 <b>증상별 원인과 해결 방법</b></summary>

| 증상 | 원인일 가능성 | 해야 할 일 |
| --- | --- | --- |
| "값이 비어 있어 멈췄다"고 답함 | Lab 02의 `set-env.sh` 반영을 건너뜀 | `cat .env`로 빈 항목을 찾아 [Lab 02](02-design-aks.md)에서 반영 후 재실행 |
| 승인/거절 버튼이 떴는데 눌러도 되는지 모르겠다 | Skill이 다음 단계로 가도 되는지 묻는 gate | 내용을 확인하고 눌러도 됩니다. 리소스는 생성되지 않으며, 파일 기록은 Step 3에서 확인 |
| "plan 상태가 `draft`"라며 Bicep 생성을 거부 | 버튼을 눌렀을 뿐 파일에 반영되지 않음 | Step 3의 승인 프롬프트를 실행해 `meta.status`를 `approved`로 바꾼 뒤 재실행 |
| 값을 바꿨는데 계획이 그대로다 | Skill이 `.env`를 다시 읽지 않았음 | 어느 파일의 어떤 키를 바꿨는지 명시해 다시 요청 |
| 부탁하지 않은 항목까지 바뀜다 | 변경 범위를 제한하지 않음 | 바뀌면 안 되는 항목을 짚어 되돌리게 하고, 왜 바꿨는지 물어보기 |
| "검증하지 말라는 조건과 충돌"한다며 멈춤 | Skill은 문법 확인을 생성 절차의 일부로 봄 | Step 4 프롬프트처럼 **Azure 배포만** 막고 `az bicep build`는 허용 |
| 승인을 물어보는 단계가 두 번 나온다 | 자원 목록과 완성된 계획을 따로 확인하는 정상 동작 | 각각 내용을 확인하고 승인 |
| "WAF·Microsoft Learn 도구가 없다"고 적으며 진행 | MCP 서버가 꺼져 있음 | [Lab 01](01-orientation-and-setup.md) Step 2로 돌아가 `azure`와 `microsoft-learn`을 시작한 뒤 계획을 다시 생성 |
| 계획에 없던 자원이 생성 목록에 있다 | 기존 자원 참조가 누락됨 | "기존 자원은 참조만" 문구를 강조해 다시 요청 |
| 매개변수가 계획과 다르다 | `.env` 값이 최신이 아님 | `.env`를 갱신하고 재생성 요청 |

</details>

## 다음 Lab

[Lab 04: IaC 검증 + 배포 승인](04-validate-and-approve.md)
