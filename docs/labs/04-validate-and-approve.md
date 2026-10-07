# Lab 04: IaC 검증 + 배포 승인

**Lab 4 / 8** · 1부 · 설계와 검증

🎯 IaC 검증 / 배포 영향·비용 확인 / 배포 승인

🧠 `azure-enterprise-infra-planner`

> 🎬 코드가 계획과 일치하는지 검증한 뒤 배포를 승인합니다.

## 왜 필요한가요?

IaC(Infrastructure as Code)는 인프라 구성을 코드로 정의하는 방식입니다.

- 실행한 검사와 결과로 IaC를 검증합니다
- **검증 통과와 배포 승인은 별개입니다**
- 비용·삭제 책임을 확인한 뒤 배포를 승인합니다

## 시작 전에

- [Lab 03](03-plan-and-bicep.md)에서 생성한 Bicep 파일이 있나요?

> 💻 **터미널에서 실행**

```bash
ls infra/ && jq -e '.meta.status == "approved"' .azure/infrastructure-plan.json
```

### 배포 대상 Resource Group 만들기

What-if는 배포할 때의 변경 사항을 미리 보여줍니다.
Resource Group Scope의 Bicep은 그룹을 만들지 않으므로 **대상 그룹을 먼저 준비합니다.**

> 🧠 **Skill** `azure-enterprise-infra-planner` &nbsp;·&nbsp; 💬 **Copilot 채팅에 붙여넣기**

```text
azure-enterprise-infra-planner Skill을 사용해 배포 대상 Resource Group을 준비해줘.

[읽을 값]
- 저장소 루트 .env의 SUBSCRIPTION_ID, RESOURCE_GROUP, REGION

[해야 할 일]
- Resource Group이 있는지 먼저 조회
- 없으면 대상과 영향을 보여주고 명시적 승인을 요청
- 승인 후 빈 Resource Group만 생성
- 생성 결과를 infra-report.md의 Validate 장에 기록

[제약]
- Resource Group 안에 다른 Azure 리소스를 만들지 마
- 이미 있으면 변경하지 말고 현재 상태만 알려줘
- 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘
```

**빈 Resource Group은 비용이 없습니다.** 비용이 발생하는 리소스는 승인 후 [Lab 05](05-deploy-and-connect.md)에서 배포합니다.

Application Gateway for Containers Preview 상태도 확인합니다.

> 💻 **터미널에서 실행**

```bash
az feature show --namespace Microsoft.ContainerService \
    --name ManagedGatewayAPIPreview --query properties.state -o tsv
az feature show --namespace Microsoft.ContainerService \
    --name ApplicationLoadBalancerPreview --query properties.state -o tsv
```

## Step 1. IaC 검증하기

> 🧠 **Skill** `azure-enterprise-infra-planner` &nbsp;·&nbsp; 💬 **Copilot 채팅에 붙여넣기**

```text
azure-enterprise-infra-planner Skill을 사용해 IaC를 검증해줘.

[읽을 값]
- 승인된 Infrastructure Plan
- infra/ 아래의 기존 Bicep

[해야 할 일]
- 그 Skill의 검증 단계를 따라 Bicep build, 보안 검사,
    ARM Validation 또는 What-if를 수행해줘
- 실제로 실행한 명령과 그 결과, 실패 항목을 정리해줘
- 고쳐야 할 것이 있으면 어디를 왜 고쳐야 하는지 먼저 설명해줘
- 검증되지 않은 결과는 예상으로 표시해줘

[제약]
- 코드를 다시 생성하지 마
- 배포는 하지 마
- 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘

```

**확인할 것**

- 실행한 build·보안 검사·What-if 명령과 종료 코드
- 실패 원인이 코드인지 정책·Quota·권한인지 구분
- What-if에 AKS, VNet, PostgreSQL, Private DNS, Managed Identity가 포함됐는지
- PostgreSQL Public Access와 Password Authentication이 꺼졌는지

> [!WARNING]
> **검증 실패 상태에서 배포하지 않습니다.** 원인을 수정하고 같은 검사를 다시 실행합니다.

## Step 2. 배포 영향 확인·승인하기

> 🧠 **Skill** `azure-enterprise-infra-planner` &nbsp;·&nbsp; 💬 **Copilot 채팅에 붙여넣기**

```text
azure-enterprise-infra-planner Skill을 사용해 배포 승인을 요청해줘.

[읽을 값]
- 승인된 계획과 검증 증거

[요약할 것]
- 배포 대상
- 생성 또는 변경될 자원
- 권한 요구
- 비용과 삭제 책임

[그다음]
- 명시적 배포 승인을 요청해줘

[제약]
- 승인을 받기 전에는 Azure 리소스를 만들거나 바꾸지 마
- 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘

```

**확인할 것**

- 배포 대상(Resource Group, Region)이 `.env`와 같은가?
- 예상 비용과 삭제 책임자가 명확한가?
- Application Gateway for Containers와 PostgreSQL 비용이 포함됐는가?
- 승인자, 승인 시각이 `infra-report.md`에 남았는가?

<details>
<summary>💡 <b>Skill을 안 썼다면?</b></summary>

| 방식 | 이 단계에서 벌어지는 일 |
| --- | --- |
| 🖐 수동 | 검사를 실행하고 결과를 해석한다. |
| 💬 일반 프롬프트 | 실행 증거와 승인 단계를 명시해야 한다. |
| ⚡ Skill | 검사 결과를 기록하고 배포 승인을 요청한다. |

</details>

## ✅ 완료 체크리스트

- [ ] 실제 검증 명령과 결과가 기록됨(성공/실패 모두)
- [ ] 배포 대상과 비용·삭제 책임을 확인함
- [ ] 명시적 배포 승인이 기록됨

## 🚧 문제가 생겼다면

<details>
<summary>🔎 <b>증상별 원인과 해결 방법</b></summary>

| 증상 | 원인일 가능성 | 해야 할 일 |
| --- | --- | --- |
| What-if가 `ResourceGroupNotFound`로 실패 | 배포 대상 Resource Group을 안 만들었음 | 위 "배포 대상 Resource Group 만들기"를 실행한 뒤 재시도 |
| 빌드는 성공했지만 정책 위반 | Azure Policy 제약 | 정책 이름을 확인하고 설정 수정. 정책 자체를 끄지 않음 |
| Quota/용량 부족 오류 | Region 용량 부족 또는 vCPU 한도 초과 | [Lab 02](02-design-aks.md) Step 1로 돌아가 Node 개수·SKU를 줄이거나 Region 변경 |
| 승인이 모호하게 넘어감 | 명시적 승인 문구 없이 진행 | 승인자 이름과 "승인합니다" 문구를 다시 기록 |

</details>

## 다음 Lab

[Lab 05: 3계층 인프라 배포](05-deploy-and-connect.md)
