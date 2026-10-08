# Lab 07: 진단과 복구 (선택)

**Lab 7 / 8** · 2부 · 실행과 마무리 · 생략 가능

🎯 Events·Pod·이미지로 원인 분석 / 승인 후 복구·재검증

🧠 `azure-diagnostics`

> 🎬 장애를 주입하고 증거로 원인을 확인한 뒤 복구합니다.

## 왜 필요한가요?

의도적인 장애로 **증거 수집 → 원인 분석 → 승인 → 복구 → 재검증**을 연습합니다.

## 시작 전에

- 복구 기준으로 사용할 [Lab 06](06-run-sample-workload.md)의 정상 상태 증거가 있나요?
- **내 실습용 클러스터에서만** 진행합니다. 공용 환경에는 장애를 주입하지 않습니다.
- Lab 05의 `KUBECONFIG`를 사용합니다. 새 터미널이면 환경 설정만 다시 실행합니다

## Step 1. 장애를 직접 주입하기

존재하지 않는 이미지 태그로 새 Pod의 시작을 막습니다.
**`lab-web` 이미지 변경의 대상·영향을 승인한 뒤** 아래를 실행합니다.

> 💻 **터미널에서 실행**

```bash
kubectl set image deployment/lab-web web=nginxinc/nginx-unprivileged:does-not-exist -n lab
```

다음 Step에서는 **주입한 변경이 아니라 실제 Events·Pod 상태를 근거로** 결론을 냅니다.
`ImagePullBackOff`는 이 실습의 예상 결과입니다. 실패한 rollout 완료를 기다리지 말고 Step 2로 이동합니다.

## Step 2. 증거로 원인 분석하기

> 🧠 **Skill** `azure-diagnostics` &nbsp;·&nbsp; 💬 **Copilot 채팅에 붙여넣기**

```text
azure-diagnostics Skill을 사용해 샘플 Deployment가 준비되지 않는
원인을 찾아줘.

[읽을 값]
- 저장소 루트 .env의 RESOURCE_GROUP, AKS_NAME, NAMESPACE

[근거로 볼 것]
- Events
- Pod 상태
- 이미지 참조

[그다음]
- 원인과 영향 범위를 설명해줘
- 복구를 위해 무엇을 바꿔야 하는지 설명해줘

[제약]
- 조회 위주로 분석하고 클러스터를 바꾸지 마
- 복구 변경은 적용 승인 전에는 하지 마
- 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘

```

**확인할 것**

- 원인이 **실제 Events 문구**에 근거하는가?
- 기존 Pod와 Gateway Public URL이 계속 응답하는가?

새 Pod의 `ImagePullBackOff`와 기존 Pod의 `1/1 Running`, Public HTTP 응답을 함께 확인합니다.

<img src="../../img/lab07-diagnose.png" alt="장애 주입 후 kubectl 출력 - 새 Pod는 ImagePullBackOff, 기존 Pod는 Running 상태이며 Events에 이미지 pull 실패가 기록되고 rollout undo로 복구된 터미널 화면" width="760">

<details>
<summary>💡 <b>Skill을 안 썼다면?</b></summary>

| 방식 | 이 단계에서 벌어지는 일 |
| --- | --- |
| 🖐 수동 | 증거 수집 순서와 진단 기준을 직접 정한다. |
| 💬 일반 프롬프트 | 실제 Events·Pod 상태를 근거로 분석하도록 지시해야 한다. |
| ⚡ Skill | 증거 수집 절차에 따라 원인과 복구 변경을 설명한다. |

</details>

## Step 3. 승인 후 복구하고 재검증하기

Step 2의 원인·변경 내용을 확인하고 원래 이미지 복원을 승인합니다.
복구 뒤에는 [Lab 06](06-run-sample-workload.md) **Step 3의 읽기 전용 재검증 블록**과 Pod·Node 조회만 반복합니다.
Manifest 적용이나 Pod 삭제·재생성은 반복하지 않습니다.

> 💻 **터미널에서 실행**

```bash
kubectl rollout undo deployment/lab-web -n lab
kubectl -n lab rollout status deployment/lab-web --timeout=600s
```

기존 Pod가 유지됐다면 복구 후 이름도 같습니다.
**Pod 상태와 HTTP 응답을 함께 확인해** 서비스 유지 여부를 판단합니다.

권한 확대, IP 제한 완화, Namespace 삭제는 복구 수단이 아닙니다.

## ✅ 완료 체크리스트

- [ ] 장애를 주입하고 증상을 기록함
- [ ] 원인을 실제 증거(Events/Pod 상태)로 설명함
- [ ] 장애 중에도 기존 Pod가 살아 있어 서비스가 끊기지 않았음을 확인함
- [ ] Application Gateway for Containers 경로가 계속 응답함
- [ ] 복구 변경을 승인 후 적용함
- [ ] 재검증으로 정상 상태를 다시 확인함

## 🚧 문제가 생겼다면

<details>
<summary>🔎 <b>증상별 원인과 해결 방법</b></summary>

| 증상 | 원인일 가능성 | 해야 할 일 |
| --- | --- | --- |
| 원인이 불명확 | 증거 부족 | `kubectl describe pod`와 `kubectl get events -n lab --sort-by=.lastTimestamp` 결과를 더 수집 |
| 복구 후에도 실패 | 다른 근본 원인 존재 | 증상을 처음부터 다시 수집하고, 방금 바꾼 것 외에 달라진 것이 없는지 확인 |
| 원래 이미지 태그가 기억나지 않음 | 기록 누락 | [Manifest](../../reference/kubernetes/lab-web.yaml)의 이미지 값을 확인하거나 `kubectl rollout undo deployment/lab-web -n lab` |

</details>

## 다음 Lab

복구와 읽기 전용 재검증을 마친 뒤 진행합니다. 복구 실패 상태라면 먼저 원인을 해결합니다.

[Lab 08: 문서화 + 정리](08-document-and-cleanup.md)
