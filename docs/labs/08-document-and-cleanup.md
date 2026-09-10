# Lab 08: 실제 구성 문서화하고 정리하기

⏱ **예상 시간:** 50분
🎯 **이 랩에서 배우는 것**
- 설계 문서가 아니라 "실제로 관측된" Azure/Kubernetes 상태로 인계 문서를 만드는 방법
- 승인된 절차로 정리(삭제 또는 잔여 자원 확인)하는 방법

## 왜 이 랩이 필요한가요?

Azure Resource Manager 그림만으로는 Kubernetes 내부의 Pod/Service 관계를 알 수 없습니다. 두 계층을 분리해서 문서화하고, 마지막에는 실제로 무엇이 남아있는지 확인한 뒤 인계해야 합니다.

## 시작 전에 확인하세요

- [Lab 06](06-run-sample-workload.md) (그리고 선택적으로 [Lab 07](07-diagnose-and-recover.md))의 결과가 있나요?

## Step 1. 실제 상태 문서화하기 (25분)

**사용 Skill:** `azure-resource-lookup`, `azure-resource-visualizer`

[문서화 프롬프트](../../prompts/workshop-prompts.md#문서화)를 사용하세요.

**확인할 것:** cluster resource group과 node resource group을 모두 조사했는지, Kubernetes 증거(Pod/Service/EndpointSlice)를 Azure ARM 그림과 별도 섹션으로 나눴는지.

[인계 양식](../../templates/handoff-template.md)에 관측/설계/추정/미검증을 구분해서 채웁니다.

## Step 2. 제출하고 정리하기 (25분)

**사용 Skill:** `azure-resource-lookup`

```text
azure-resource-lookup을 사용해 [resource-group]과 [node-resource-group]의 현재 리소스를 읽기 전용으로 확인해줘. 삭제 전에 대상과 의존 자원을 표로 보여주고, 실제 삭제 작업은 명시적 승인 전에는 수행하지 마.
```

삭제를 승인한 뒤 실제로 삭제하고, 다시 조회해서 잔여 자원이 없는지(또는 남은 것이 무엇인지) 확인합니다.

> ⚠️ **주의:** 삭제하지 않기로 했다면, 그것도 정상입니다. 다만 잔여 자원과 비용 책임자를 인계 문서에 반드시 남기세요.

## ✅ 완료 체크리스트

- [ ] Azure와 Kubernetes 증거가 분리되어 문서화됨
- [ ] 삭제 승인/실행/재조회가 모두 기록됨(또는 미삭제 사유가 기록됨)
- [ ] 인계 문서, 증거 로그, [체크포인트](../../templates/checkpoint.md)를 강사에게 제출함

## 🚧 문제가 생겼다면

| 증상 | 원인일 가능성 | 해야 할 일 |
| --- | --- | --- |
| ARM 그림에 Pod/Service가 안 보임 | 정상입니다 | Kubernetes API 조회로 별도 확인 |
| 삭제 후에도 리소스가 남아있음 | 종속 리소스 또는 지연 | 몇 분 후 재조회, 강사에게 보고 |

## 워크샵을 마칩니다 🎉

수고하셨습니다! 다음에 다시 시작해야 한다면 [재개 프롬프트](../../prompts/workshop-prompts.md#재개)로 현재 상태부터 이어갈 수 있습니다.
