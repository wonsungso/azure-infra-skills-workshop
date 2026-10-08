# Lab 08: 문서화 + 정리

**Lab 8 / 8** · 2부 · 실행과 마무리

🎯 관측 기반 인계 문서 / 승인 후 삭제·잔여 확인

🧠 `azure-resource-lookup` · `azure-resource-visualizer`

> 🎬 실제 구성·검증 결과를 인계하고 승인된 리소스를 정리합니다.

## 왜 필요한가요?

Azure·Kubernetes의 실제 구성과 검증 결과를 남깁니다.
삭제 후 잔여 리소스를 확인해 비용 책임을 명확히 합니다.

## 시작 전에

- [Lab 06](06-run-sample-workload.md)의 결과가 있나요? ([Lab 07](07-diagnose-and-recover.md)은 선택)
- Lab 07을 했다면 복구·재검증이 끝났나요?
- 중간에 중단해 정리만 한다면 E2E 성공을 전제로 하지 않습니다. 미완료 항목을 기록하고 Step 2로 진행합니다

## Step 1. 실제 상태 문서화하기

> 🧠 **Skill** `azure-resource-lookup`, `azure-resource-visualizer` &nbsp;·&nbsp; 💬 **Copilot 채팅에 붙여넣기**

```text
azure-resource-lookup과 azure-resource-visualizer Skill을 사용해
아키텍처 문서를 Mermaid로 작성해줘.

[읽을 값]
- 저장소 루트 .env의 RESOURCE_GROUP, NODE_RESOURCE_GROUP
- 저장소 루트 .env의 NAMESPACE
- 저장소 루트의 infra-report.md
  (Lab 01부터 쌓인 결정과 관측 기록)

[작성할 것]
- AGC, AKS, PostgreSQL, VNet, Identity 관계를 Mermaid로
- Gateway, HTTPRoute, Pod, Service, Job은 별도 섹션으로

[구분할 것]
- 관측 사실 / 설계값 / 추정 / 미검증
- 보고서에 근거가 없는 항목은 미검증으로 표시해줘

[제약]
- Azure 리소스를 만들거나 바꾸지 마
- 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘

```

**확인할 것**

- Cluster Resource Group과 Node Resource Group을 모두 조사했는가
- Kubernetes Gateway와 PostgreSQL Job 증거가 포함됐는가

실제 조회와 Mermaid 작성을 마친 뒤 아래 SVG 생성으로 진행합니다.

### Azure 공식 아이콘으로 그림 만들기

같은 조회 결과로 **Azure 공식 아이콘 SVG**도 만듭니다.

> 💬 **Copilot 채팅에 붙여넣기**

```text
방금 조회한 실제 리소스로 assets/azure-icons/README.md의
스펙 형식에 맞는 JSON을 만들어줘.

[레이어 구성]
- Ingress
- Application
- Data
- Network

[각 항목에 들어갈 값]
- Label에는 실제 리소스 이름
- sub에는 실제 SKU나 CIDR

[그다음]
- 저장소 루트의 .azure/architecture-spec.json에 스펙을 저장해줘
- 아래를 실행해줘
  bash scripts/build-architecture-svg.sh .azure/architecture-spec.json .azure/my-architecture.svg

[제약]
- 추측한 값은 넣지 말고 조회로 확인한 것만 써줘
- 실제 환경값이 포함된 스펙·그림은 커밋하지 마

```

<img src="../../img/example-architecture.svg" alt="Azure 공식 아이콘으로 그린 아키텍처 예시 - Resource Group, Network, Compute 세 레이어에 각 리소스 이름과 SKU가 표기된 그림" width="620">

위 그림은 [예시 스펙](../../assets/azure-icons/example-architecture.json)으로 생성했습니다.
아이콘을 포함한 SVG 파일 하나로 인계할 수 있습니다.

- 아키텍처 다이어그램과 교육 자료 용도로만 쓸 수 있습니다
- 자르거나 회전하거나 변형하면 안 됩니다
- 이용 조건: [`README.md`](../../assets/azure-icons/README.md)

그림을 확인한 뒤 `infra-report.md`를 근거로 [인계 양식](../../templates/handoff-template.md)을 채웁니다.
양식 원본은 유지하고 **로컬 인계 파일**로 저장합니다. 관측·설계·추정·미검증을 구분합니다.

> 💬 **Copilot 채팅에 붙여넣기**

```text
관측 결과로 인계 문서를 작성해줘.

[읽을 값]
- templates/handoff-template.md
- 저장소 루트의 infra-report.md와 .env
- 방금 작성한 실제 아키텍처

[작성할 것]
- .azure/handoff.md에 인계 문서 저장
- E2E 증거, 미검증 항목, 잔여 리소스·권한과 비용 책임
- .azure/my-architecture.svg를 상대 링크로 포함

[제약]
- 양식 원본은 수정하지 마
- 검증하지 않은 항목은 미검증으로 표시해줘
- Credentials·Token은 기록하지 마
- 실제 환경값이 포함된 인계 파일은 커밋하지 마
- Azure 리소스를 만들거나 바꾸지 마
```

<details>
<summary>💡 <b>Skill을 안 썼다면?</b></summary>

| 방식 | 이 단계에서 벌어지는 일 |
| --- | --- |
| 🖐 수동 | 실제 리소스와 관계를 조회해 직접 그린다. |
| 💬 일반 프롬프트 | 실제 조회 결과를 사용하도록 명시해야 한다. |
| ⚡ Skill | 조회한 리소스와 관계로 다이어그램을 만든다. |

</details>

## Step 2. 삭제 대상 확인하기

> 🧠 **Skill** `azure-resource-lookup` &nbsp;·&nbsp; 💬 **Copilot 채팅에 붙여넣기**

```text
azure-resource-lookup Skill을 사용해 삭제 대상을 확인해줘.

[읽을 값]
- 저장소 루트 .env의 RESOURCE_GROUP, NODE_RESOURCE_GROUP
- infra-report.md의 Access 장에 기록한 bootstrap Custom Role과 Namespace 역할

[보여줄 것]
- 두 그룹의 현재 리소스 (읽기 전용)
- 해당 AKS에 연결된 실습용 역할 할당과 bootstrap Custom Role 정의
- 삭제 대상과 그에 의존하는 자원을 표로

[제약]
- 기존에 있던 역할과 공용 Custom Role은 삭제 대상에서 제외
- 실제 삭제 작업은 명시적 승인 전에는 수행하지 마
- 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘

```

이 프롬프트는 **조회만** 합니다. 결과 표를 확인한 뒤 Step 3에서 삭제 여부를 결정합니다.

## Step 3. 삭제 승인·실행·재조회하기

삭제하지 않으면 이 단계의 실행을 건너뛰고, 잔여 리소스·권한·비용 책임을 인계 문서에 기록합니다.
삭제한다면 **조회한 대상과 순서를 명시적으로 승인한 뒤** 실행합니다.

**클러스터 삭제 전에** Controller가 관리하는 AGC를 정리합니다.

- 승인한 Namespace의 Gateway와 ApplicationLoadBalancer를 삭제합니다
- ALB Finalizer는 Azure 삭제 완료를 기다리는 표시입니다. **강제로 지우지 않습니다**
- Azure AGC·Association·Frontend와 Finalizer가 정리된 뒤 Resource Group을 삭제합니다
- Node Resource Group 삭제까지 기다리고 두 그룹을 다시 조회합니다

[Lab 05](05-deploy-and-connect.md)의 bootstrap Custom Role 정의는 Resource Group 밖에 남을 수 있습니다.

- 실습에서 만든 역할 정의·할당도 삭제 계획과 재조회에 포함합니다
- 유지한 권한과 Scope는 인계 문서에 기록합니다

> 💬 **Copilot 채팅에 붙여넣기**

```text
Step 2에서 확인한 실습 리소스의 정리를 진행해줘.

[읽을 값]
- 저장소 루트 .env의 SUBSCRIPTION_ID, RESOURCE_GROUP, NODE_RESOURCE_GROUP, NAMESPACE
- Step 2의 삭제 대상 표와 infra-report.md의 역할 기록

[진행 순서]
- 대상·의존성·데이터 손실 영향을 다시 요약하고 명시적 삭제 승인을 요청
- 승인 후 Gateway와 ApplicationLoadBalancer를 먼저 삭제
- AGC·Association·Frontend와 Finalizer 정리가 끝날 때까지 대기
- 실습에서 만든 역할 할당·bootstrap Custom Role 정의만 정리
- Resource Group을 삭제하고 AKS 소유 Node Resource Group 삭제 완료까지 대기
- 두 그룹·리소스·역할을 다시 조회해 잔여 항목을 확인
- 명령·결과를 infra-report.md의 Cleanup 장에 기록하고 .azure/handoff.md를 갱신

[제약]
- 승인 전에는 삭제하지 마
- 조회한 실습 대상 외 리소스와 기존 공용 역할은 삭제하지 마
- Finalizer를 강제로 제거하거나 권한을 넓히지 마
- 실패하면 원인과 남은 항목을 기록하고 멈춰
```

> [!WARNING]
> **리소스를 유지하면 과금이 계속됩니다.** 잔여 리소스와 비용 책임자를 인계 문서에 기록합니다.

## ✅ 완료 체크리스트

- [ ] AGC → AKS → PostgreSQL 흐름이 문서화됨
- [ ] Public HTTP와 Private SQL 증거가 기록됨
- [ ] 삭제 승인/실행/재조회가 모두 기록됨(또는 미삭제 사유가 기록됨)
- [ ] 인계 문서와 `infra-report.md`가 모두 채워짐
- [ ] 삭제를 선택했다면 재조회로 잔여 리소스 확인

## 🚧 문제가 생겼다면

<details>
<summary>🔎 <b>증상별 원인과 해결 방법</b></summary>

| 증상 | 원인일 가능성 | 해야 할 일 |
| --- | --- | --- |
| ARM 그림에 Pod/Service가 안 보임 | 정상입니다 | Kubernetes API 조회로 별도 확인 |
| 삭제 후에도 리소스가 남아있음 | 종속 리소스 또는 삭제 지연 | 몇 분 후 재조회. Node Resource Group(`MC_...`)이 함께 지워졌는지도 확인 |
| Resource Group 삭제가 거부됨 | 리소스 잠금 또는 권한 부족 | 잠금 여부를 확인하고, 내 권한 범위 안에서 개별 리소스부터 삭제 |

</details>

## 워크샵을 마칩니다 🎉

완료 체크리스트와 삭제 결과 또는 미삭제 사유를 확인한 뒤 마칩니다.
사용하지 않는 Codespace는 GitHub의 Codespaces 목록에서 중지하거나 삭제합니다.
