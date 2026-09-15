# Lab 04: IaC 검증 + 배포 승인

**Lab 4 / 8** · 1부 · 설계와 검증 · ⏱ 45분

🎯 배포 전 "검증"의 실제 의미 / 배포 승인이 계획 승인과 별개인 이유

🧠 `azure-enterprise-infra-planner`

> 🎬 코드는 나왔습니다. 배포 버튼을 누르기 전에 이 코드가 **정말 내 설계대로인지** 증명합니다. 1부의 마지막 관문입니다.

## 왜 필요한가요?

- "그럴듯해 보인다"와 "빌드와 검사를 통과했다"는 다릅니다
- 검증을 통과했다고 바로 배포해도 되는 것도 아닙니다
- **비용과 삭제 책임까지 확인한 뒤에만** 배포를 승인합니다

## 시작 전에

- [Lab 03](03-plan-and-bicep.md)에서 생성한 Bicep 파일이 있나요?

> 💻 **터미널에서 실행**

```bash
ls infra/ && grep -A3 '"meta"' .azure/infrastructure-plan.json
```

### 배포 대상 resource group 만들기

what-if는 "이 resource group에 적용하면 무엇이 바뀌는가"를 계산합니다.

- 그러므로 **비교 대상이 먼저 있어야** 합니다
- Bicep은 resource group scope라 그룹 자체를 만들지 않습니다

> 💻 **터미널에서 실행**

```bash
set -a; . ./.env; set +a
az group create -n "$RESOURCE_GROUP" -l "$REGION" -o table
```

**빈 resource group은 비용이 없습니다.** 안에 들어갈 AKS와 node가 비용을 만들고, 그건 [Lab 05](05-deploy-and-connect.md)에서 배포를 승인한 뒤입니다.

## Step 1. IaC를 실제로 검증하기

> 🧠 **Skill** `azure-enterprise-infra-planner` &nbsp;·&nbsp; 💬 **Copilot 채팅에 붙여넣기**

```text
azure-enterprise-infra-planner Skill을 사용해 IaC를 검증해줘.

[읽을 값]
- 승인된 infrastructure plan
- infra/ 아래의 기존 Bicep

[해야 할 일]
- 그 Skill의 검증 단계를 따라 Bicep build, 보안 검사,
  ARM validation 또는 what-if를 수행해줘
- 실제로 실행한 명령과 그 결과, 실패 항목을 정리해줘
- 고쳐야 할 것이 있으면 어디를 왜 고쳐야 하는지 먼저 설명해줘
- 검증되지 않은 결과는 예상으로 표시해줘

[제약]
- 코드를 다시 생성하지 마
- 배포는 하지 마
- 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘
```

**확인할 것**

- 실제로 실행된 명령(예: `az bicep build`, 보안 검사, what-if)과 그 종료 코드
- 실패가 있다면 "코드 문제"인지 "정책·quota·권한 문제"인지 구분

> [!WARNING]
> 검증 실패를 "일단 무시하고 배포"하지 않습니다. 원인을 고치고 같은 검사를 다시 통과시키세요.

## Step 2. 배포 전에 영향 다시 확인하고 승인받기

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

- 배포 대상(resource group, region)이 `.env`와 같은가?
- 예상 비용과 삭제 책임자가 명확한가?
- 승인자, 승인 시각이 `infra-report.md`에 남았는가?

<details>
<summary>💡 <b>Skill을 안 썼다면?</b></summary>

| 방식 | 이 단계에서 벌어지는 일 |
| --- | --- |
| 🖐 수동 | `az bicep build`, what-if를 직접 실행하고 결과를 스스로 해석한다. |
| 💬 일반 프롬프트 | 실행 없이 "문제 없어 보입니다"로 끝나기 쉽다. **검증과 추측이 구분되지 않는다.** |
| ⚡ Skill | 검증을 실제로 돌리고, 결과를 근거로 **명시적 배포 승인**을 요구한다. |

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
| what-if가 `ResourceGroupNotFound`로 실패 | 배포 대상 resource group을 안 만들었음 | 위 "배포 대상 resource group 만들기"를 실행한 뒤 재시도 |
| 빌드는 성공했지만 정책 위반 오류 | Azure Policy 제약 | 위반한 정책 이름을 확인하고, 해당 설정을 정책에 맞게 조정 (정책 자체를 끄려 하지 말 것) |
| quota/용량 부족 오류 | region 용량 부족 또는 vCPU 한도 초과 | [Lab 02](02-design-aks.md) Step 1로 돌아가 node 개수·SKU를 줄이거나 region 변경 |
| 승인이 모호하게 넘어감 | 명시적 승인 문구 없이 진행 | 승인자 이름과 "승인합니다" 문구를 다시 기록 |

</details>

## 다음 Lab

[Lab 05: AKS 배포 + 접속 확인](05-deploy-and-connect.md)
