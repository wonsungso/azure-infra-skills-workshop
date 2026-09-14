# Lab 05: AKS 배포 + 접속 확인

**Lab 5 / 8** · 2부 · 실행과 마무리 · ⏱ 45분

🎯 배포 실행 후 확인할 것 / Entra 인증 접속과 least privilege 검증

🧠 `azure-enterprise-infra-planner` · `azure-resource-lookup`

> 🎬 승인 완료. 문서 속 설계가 **실제 Azure 리소스**로 바뀝니다. 지금부터 진짜 비용이 발생합니다.

## 왜 필요한가요?

배포 명령이 "성공"이라고 답해도, node가 Ready인지와 허용된 범위에서만 접속되는지는 별도로 확인해야 합니다. 이 랩은 배포 대기 시간을 포함해 실제 상태를 관찰합니다.

## 시작 전에

- [Lab 04](04-validate-and-approve.md)의 배포 승인이 있나요?

## Step 1. 클러스터 배포 관찰하기 (25분)

> 🧠 **Skill** `azure-enterprise-infra-planner` &nbsp;·&nbsp; 📋 **아래 프롬프트를 복사해 실행**

```text
승인된 계획을 대상으로 azure-enterprise-infra-planner의 배포 단계를 진행해줘. 배포 진행 상태와 생성된 자원을 기록하고, 실패하면 실제 오류를 분류해줘. 승인 범위를 벗어난 변경은 하지 마.
```

배포는 여러 분이 걸립니다. 기다리는 동안 [Lab 06](06-run-sample-workload.md)의 manifest를 미리 읽어도 좋습니다. 다만 성공 여부는 클러스터가 Ready가 된 뒤에만 판단합니다.

배포가 끝나면 node resource group을 `.env`에 반영합니다. Azure가 만들어 준 이름이라 직접 보고 적을 필요가 없습니다.

```bash
set -a; . ./.env; set +a
bash scripts/set-env.sh NODE_RESOURCE_GROUP \
  "$(az aks show -g "$RESOURCE_GROUP" -n "$AKS_NAME" --query nodeResourceGroup -o tsv)"
```

<details>
<summary>💡 <b>Skill을 안 썼다면?</b></summary>

| 방식 | 이 단계에서 벌어지는 일 |
| --- | --- |
| 🖐 수동 | 배포 명령을 실행하고 상태를 직접 폴링하며 기다린다. |
| 💬 일반 프롬프트 | 실패해도 원인을 분류하지 않고 같은 명령을 다시 제안하곤 한다. |
| ⚡ Skill | 승인 범위를 벗어난 변경을 막고, 실패 시 **quota·정책·권한 중 무엇인지** 분류해준다. |

</details>

## Step 2. 접속하고 `lab` namespace 만들기 (20분)

> 🧠 **Skill** `azure-resource-lookup` &nbsp;·&nbsp; 📋 **아래 프롬프트를 복사해 실행**

```text
azure-resource-lookup을 사용해 [aks-name]의 실제 상태와 node resource group을 읽기 전용으로 확인해줘. 이후 Entra 기반으로 클러스터에 접속하는 데 필요한 점검 항목을 제시해줘. 역할을 변경하지 마.
```

클러스터가 Ready라면 credentials를 가져와 node를 확인하고, 실습용 namespace를 **직접** 만듭니다. 리소스 이름은 `.env`에 이미 있으므로 그대로 씁니다.

```bash
set -a; . ./.env; set +a
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$AKS_NAME"
bash scripts/log-evidence.sh "Lab 05 Step 2" "kubectl" -- kubectl get nodes -L kubernetes.azure.com/mode
kubectl create namespace "$NAMESPACE"
```

**확인할 것**

- node가 모두 `Ready` 상태인가?
- system pool과 user pool이 설계대로 분리되었는가? (`kubectl get nodes -L kubernetes.azure.com/mode`)
- `lab` namespace가 생성됐는가?

성공하면 아래와 같은 결과를 보게 됩니다. `MODE` 열에 `system` 2대와 `user` 1대가 보이는 것이 Lab 02의 node pool 분리 결정이 실제로 적용됐다는 증거입니다.

<img src="../../img/lab05-nodes.png" alt="kubectl get nodes 결과 - system 2대와 user 1대가 모두 Ready 상태이고 lab namespace가 생성된 터미널 출력" width="760">

지금 여러분은 클러스터를 만든 사람이라 **모든 namespace에 쓸 수 있습니다.** 그래서 "다른 namespace 쓰기 거부"는 지금 검증할 수 없습니다. 대신 Lab 02의 least privilege 매트릭스를 다시 보고, **팀원에게 `lab`만 허용하려면 어떤 역할을 어느 scope에 줘야 하는지**를 인계 문서에 적어두세요. 실제 팀에서는 이것이 다음 사람의 첫 질문입니다.

> [!WARNING]
> 접속이 안 될 때 authorized IP ranges에 `0.0.0.0/0`을 넣지 않습니다. 먼저 내 egress IP가 바뀌지 않았는지 `curl -s https://api.ipify.org`로 다시 확인하세요.

## ✅ 완료 체크리스트

- [ ] 클러스터가 실제로 Ready 상태임을 확인
- [ ] `NODE_RESOURCE_GROUP`이 `.env`에 반영됨
- [ ] system/user node pool 분리를 확인
- [ ] `lab` namespace를 직접 생성
- [ ] [증거 로그](../../templates/evidence-log.md) 형식의 `evidence-log.md`에 실행 기록이 남았다

## 🚧 문제가 생겼다면

| 증상 | 원인일 가능성 | 해야 할 일 |
| --- | --- | --- |
| 배포가 quota 오류로 실패 | vCPU 한도 초과 또는 region 용량 부족 | [Lab 02](02-design-aks.md) Step 1로 돌아가 node 개수·SKU를 줄이거나 region 변경 |
| 배포가 정책 오류로 실패 | Azure Policy 제약 | 위반한 정책 이름을 확인하고 해당 설정만 조정 |
| API server 접속 불가 | authorized IP ranges 미반영, 전파 지연, 또는 내 IP 변경 | 내 egress IP를 다시 조회해 비교, 몇 분 대기 후 재시도 |
| 어제까지 되던 접속이 갑자기 안 됨 | Codespace를 재시작해 egress IP가 바뀌었을 수 있음 | [`init-workshop.sh`](../../scripts/init-workshop.sh)로 `.env`를 갱신하고, 바뀌었다면 authorized IP ranges를 다시 적용 |
| `kubectl`에서 권한 거부 | 클러스터에 대한 Kubernetes RBAC 역할 미부여 | `azure-rbac`으로 내 계정에 필요한 AKS RBAC 역할을 확인하고 부여 |
| 역할 할당 자체가 실패 | subscription에서 `Microsoft.Authorization` 작업이 제한됨 | [설계 결정](../design-decisions.md)의 "제한된 subscription에서의 테스트" 항목 참고 |

## 다음 Lab

[Lab 06: 상품 페이지 배포](06-run-sample-workload.md)
