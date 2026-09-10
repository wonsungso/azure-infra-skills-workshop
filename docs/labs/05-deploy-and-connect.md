# Lab 05: AKS 배포하고 접속 확인하기

⏱ **예상 시간:** 45분
🎯 **이 랩에서 배우는 것**
- 승인된 배포를 실제로 실행했을 때 무엇을 확인해야 하는지
- Entra 인증 기반 접속과 최소 권한이 실제로 동작하는지 검증하는 방법

🟦🟦🟦🟦🟩⬜⬜⬜ **Lab 5 / 8** · 🚀 2부 실행과 마무리 · 🏆 획득 배지 `배포 엔지니어`

> 🎬 **미션 진행 상황**
> 승인 완료. 이제 문서 속 설계가 **실제 Azure 리소스**로 바뀝니다. 지금부터는 진짜 비용이 발생하고, 진짜로 고칠 수 있는 것을 다룹니다.

## 왜 이 랩이 필요한가요?

배포 명령이 "성공"이라고 응답해도, 실제로 노드가 Ready 상태가 되고 참가자가 허용된 범위 내에서만 접속할 수 있는지는 별도로 확인해야 합니다. 이 랩에서는 배포 대기 시간을 포함해 실제 상태를 관찰합니다.

## 시작 전에 확인하세요

- [Lab 04](04-validate-and-approve.md)의 배포 승인이 있나요?

## Step 1. 클러스터 배포 관찰하기 (25분)

**사용 Skill:** `azure-enterprise-infra-planner`

```text
승인된 계획을 대상으로 azure-enterprise-infra-planner의 배포 단계를 진행해줘. 배포 진행 상태와 생성된 자원을 기록하고, 실패하면 실제 오류를 분류해줘. 승인 범위를 벗어난 변경은 하지 마.
```

배포는 시간이 걸립니다(보통 여러 분). 기다리는 동안 [Lab 06](06-run-sample-workload.md)의 manifest를 미리 읽어볼 수 있지만, 실제 성공 여부는 클러스터가 Ready 상태가 된 뒤에만 판단합니다.

> [!TIP]
> 배포된 클러스터의 **실제 이름은 입력표에 적은 이름과 다릅니다.** Bicep이 고유 접미사를 자동으로 붙이기 때문입니다. 출력값 `aksResourceName`을 확인해 증거 로그에 기록하세요.

## Step 2. 접속하고 `lab` namespace 만들기 (20분)

**사용 Skill:** `azure-resource-lookup`

```text
azure-resource-lookup을 사용해 [aks-name]의 실제 상태와 node resource group을 읽기 전용으로 확인해줘. 이후 Entra 기반으로 클러스터에 접속하는 데 필요한 점검 항목을 제시해줘. 역할을 변경하지 마.
```

클러스터가 Ready라면 자격 증명을 가져와 노드를 확인하고, 실습용 namespace를 **직접** 만듭니다.

```bash
az aks get-credentials --resource-group <resource-group> --name <aksResourceName>
kubectl get nodes
kubectl create namespace lab
```

**당신이 실제로 확인할 것**
- 노드가 모두 `Ready` 상태인가?
- system pool과 user pool이 설계대로 분리되어 있는가? (`kubectl get nodes -L kubernetes.azure.com/mode`)
- `lab` namespace가 생성됐는가?

> [!NOTE]
> 지금 여러분은 클러스터를 만든 사람이므로 **모든 namespace에 쓸 수 있습니다.** 그래서 "다른 namespace 쓰기 거부"는 지금 검증할 수 없습니다. 대신 Lab 02에서 만든 최소 권한 매트릭스를 다시 보고, **팀원에게 `lab`만 허용하려면 어떤 역할을 어느 scope에 줘야 하는지**를 확인해 인계 문서에 적어두세요. 실제 팀에서는 이것이 다음 사람의 첫 질문입니다.

> [!WARNING]
> 접속이 안 될 때 허용 IP 목록에 `0.0.0.0/0`을 넣지 않습니다. 먼저 내 공인 출구 IP가 바뀌지 않았는지 `curl -s https://api.ipify.org`로 다시 확인하세요.

## ✅ 완료 체크리스트

- [ ] 클러스터가 실제로 Ready 상태임을 확인
- [ ] 실제 배포된 클러스터 이름(`aksResourceName`)을 기록
- [ ] system/user 노드풀 분리를 확인
- [ ] `lab` namespace를 직접 생성
- [ ] 위 결과를 증거 로그에 기록

## 🚧 문제가 생겼다면

| 증상 | 원인일 가능성 | 해야 할 일 |
| --- | --- | --- |
| 배포가 쿼터 오류로 실패 | vCPU 한도 초과 또는 리전 용량 부족 | [Lab 02](02-design-aks.md) Step 1로 돌아가 노드 수·SKU를 줄이거나 리전 변경 |
| 배포가 정책 오류로 실패 | Azure Policy 제약 | 위반한 정책 이름을 확인하고 해당 설정만 조정 |
| API 서버 접속 불가 | 허용 IP 미반영, 전파 지연, 또는 내 IP 변경 | 내 공인 출구 IP를 다시 조회해 비교, 몇 분 대기 후 재시도 |
| `kubectl`에서 권한 거부 | 클러스터에 대한 Kubernetes RBAC 역할 미부여 | `azure-rbac`으로 내 계정에 필요한 AKS RBAC 역할을 확인하고 부여 |
| 역할 할당 자체가 실패 | 구독에서 `Microsoft.Authorization` 작업이 제한됨 | [설계 결정](../00-design-decisions.md)의 "제한된 구독에서의 테스트" 항목 참고 |

## 다음 Lab

[Lab 06: Mission Control 대시보드 배포하고 검증하기](06-run-sample-workload.md)로 이동합니다.
