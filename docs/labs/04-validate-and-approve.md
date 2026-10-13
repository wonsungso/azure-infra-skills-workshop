# Lab 04: IaC 검증 + 배포 승인

**Lab 4 / 8** · 1부 · 설계와 검증

🎯 실행 증거 확인 → 배포 승인

🧠 `azure-enterprise-infra-planner`

> 🎬 검사가 통과해도 배포는 사람이 따로 승인합니다.

## 왜 필요한가요?

배포 전에 오류·정책·변경 영향·비용을 확인합니다.

## 시작 전에

- [Lab 03](03-plan-and-bicep.md)의 승인된 계획과 생성 IaC를 준비합니다.

## Step 1. 검증하고 배포 승인하기

> 🧠 **Skill** `azure-enterprise-infra-planner` &nbsp;·&nbsp; 💬 **Copilot 채팅에 붙여넣기**

```text
azure-enterprise-infra-planner Skill로 IaC를 검증하고 배포 승인을 요청해줘.

[진행 순서]
- .env의 Scope, Infrastructure Plan의 approved 상태와 infra/ 파일 확인
- 대상 Resource Group 조회, 없으면 영향·승인 확인 후 빈 그룹만 생성
- 두 Preview Feature가 Registered인지 조회
- Bicep build·보안 검사·ARM Validation·What-if를 실제 실행
- 계획 일치, 권한·Quota·Policy 오류와 예상 밖 Modify/Delete를 구분
- 실제 명령·종료 코드·결과를 infra-report.md의 Validate 장에 기록
- 모두 통과하면 생성·변경 대상, 권한, 비용·삭제 책임을 요약
- 명시적 배포 승인을 요청하고 승인자·시각을 기록

[제약]
- 기존 그룹은 변경하지 마
- 검사 실패·미검증 항목이 있으면 승인 단계로 넘어가지 마
- 코드를 다시 생성하거나 실제 인프라를 배포하지 마
- 배포 승인을 받아도 여기서는 기록 후 멈춰
- 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘
```

**완료 기준:** 모든 검사 통과 **및** 명시적 배포 승인 기록.

## ✅ 완료 체크리스트

- [ ] 실제 검사와 실패·성공 결과가 기록됐다
- [ ] 대상·비용·삭제 책임을 확인했다
- [ ] 배포를 명시적으로 승인했다

## 🚧 문제가 생겼다면

<details>
<summary>🔎 <b>검증 실패 시</b></summary>

| 문제 | 다음 조치 |
| --- | --- |
| ResourceGroupNotFound | 승인 후 빈 그룹 준비, 같은 검사 재실행 |
| Feature 미등록 | [Lab 01](01-orientation-and-setup.md)의 등록 완료부터 확인 |
| Policy·권한 오류 | 해당 오류를 해결. Policy를 끄거나 권한을 넓히지 않음 |
| Quota·용량 부족 | [Lab 02](02-design-aks.md)의 구성 다시 선택 |
| 예상 밖 Modify/Delete | 기존 리소스 영향을 검토, 승인 범위 밖이면 중단 |
| 보안 스캐너 지적 | 기본값·모델 해석과 실제 결함을 구분. 근거·미해결 항목을 기록하고 통과로 숨기지 않음 |

What-if는 배포 시 변경을 미리 보는 검사입니다. 빈 Resource Group 자체는 비용이 없습니다.

</details>

## 다음 Lab

검증·승인 모두 확인한 뒤 [Lab 05: 3계층 인프라 배포](05-deploy-and-connect.md)로 이동합니다.
