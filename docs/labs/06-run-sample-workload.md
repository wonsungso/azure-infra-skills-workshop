# Lab 06: Mission Control 대시보드 배포하고 검증하기

⏱ **예상 시간:** 40분
🎯 **이 랩에서 배우는 것**
- 이미지를 빌드하지 않고 **ConfigMap과 Downward API만으로** 화면을 가진 서비스를 올리기
- 제공된 Kubernetes manifest가 무엇을 하는지 이해하기
- 적용한 뒤 Deployment/Pod/Service를 각각 개별적으로 검증하는 방법

🟦🟦🟦🟦🟩🟩⬜⬜ **Lab 6 / 8** · 🚀 2부 실행과 마무리 · 🏆 획득 배지 `워크로드 운영자`

> 🎬 **미션 진행 상황**
> 클러스터는 살아있습니다. 하지만 팀장은 `kubectl get nodes` 결과를 보고 싶은 게 아닙니다. **눈으로 볼 수 있는 화면**을 올릴 차례입니다.

## 왜 이 랩이 필요한가요?

팀장이 요구한 세 번째 조건을 기억하나요? **"살아있다는 걸 증명하세요."** 지금까지는 `kubectl get nodes`로 클러스터가 있다는 것까지만 보였습니다. 이제 실제로 **트래픽을 처리하는 화면**을 올립니다.

다만 주의하세요. "배포했다"와 "정상 동작한다"는 다른 말입니다. Deployment가 `Available`이어도 Pod가 실제로 `Ready`가 아닐 수 있고, Service가 있어도 트래픽이 전달되지 않을 수 있습니다. 이 랩에서는 각 계층을 따로따로 확인하는 습관을 만듭니다.

## 시작 전에 확인하세요

- [Lab 05](05-deploy-and-connect.md)에서 `lab` namespace 접근을 확인했나요?

## Step 1. manifest 검토하기 (10분)

```text
reference/kubernetes/lab-web.yaml을 검토해줘. ConfigMap으로 주입되는 index.html, projected volume이 ConfigMap과 Downward API를 합치는 방식, namespace, nodeSelector, non-root 보안 설정, requests/limits, readiness/liveness, ClusterIP Service를 설명하고 적용 대상과 검증 순서를 제시해줘. 적용하지 마.
```

**이 manifest의 핵심 아이디어** — 화면을 보여주려고 새 컨테이너 이미지를 만들지 않습니다. 대신 세 조각을 조립니다.

| 조각 | 역할 |
| --- | --- |
| `ConfigMap/lab-web-content` | 대시보드 `index.html` (외부 CDN 없이 CSS 내장) |
| `projected` volume → Downward API | 실행 중인 Pod 이름과 namespace를 파일로 주입 |
| `nginx-unprivileged` 이미지 | 위 두 조각을 합쳐 `/usr/share/nginx/html`로 서빙 |

그래서 페이지에 뜼는 Pod 이름은 **하드코딩된 값이 아니라 지금 응답하는 실제 Pod**입니다.

**확인할 것:** 외부에 노출하는 LoadBalancer나 Ingress가 없는지, 그리고 `lab` 이외의 namespace를 건드리지 않는지.

## Step 2. 적용하고 계층별로 검증하기 (20분)

승인 후 `lab` namespace에만 manifest를 적용합니다. 아래 항목을 하나씩, 개별적으로 확인하세요.

| 확인 항목 | 무엇을 보는가 |
| --- | --- |
| ConfigMap | `lab-web-content`가 `lab` namespace에 생성됐는가? |
| Deployment | `Available` 상태인가? |
| Pod | user pool에 배치되고 `Ready`인가? |
| Service / EndpointSlice | selector가 실제 Pod와 연결되는가? |
| HTTP 응답 | localhost-bound port-forward로 응답이 오는가? |

> [!WARNING]
> port-forward 성공은 "로컬에서 접근이 됐다"는 것만 증명합니다. 외부 공개나 클러스터 내부 DNS 통신이 된다는 증거로 기록하지 마세요.

## Step 3. 대시보드 누려보기 (10분)

port-forward를 연 상태에서 브라우저로 접속해 **Contoso Mission Control** 화면을 확인하세요.

화면의 `POD` 카드에 뜼는 이름과, 터미널에서 조회한 Pod 이름이 **같은지** 비교해 보세요. 같다면 화면이 정말로 여러분의 클러스터에서 오고 있다는 증거입니다.

어느 노드에 올라갔는지도 함께 확인해 두세요. `-o wide` 조회 결과의 노드 이름이 **user pool**에 속하는지가 Lab 02 설계 결정이 실제로 지켜졌다는 증거입니다.

> [!TIP]
> Lab 07을 진행한다면, Pod를 지우고 재생성된 뒤 대시보드를 새로고침해 보세요. **`POD` 카드의 이름이 바뀝니다.** 재생성이 눈으로 보이는 순간입니다.

## ✅ 완료 체크리스트

- [ ] ConfigMap, Deployment, Pod, Service, HTTP 응답을 각각 따로 기록함
- [ ] 대시보드에 표시된 Pod 이름이 조회 결과와 일치함
- [ ] Pod가 user pool 노드에 배치된 것을 확인함
- [ ] 다른 namespace나 외부 노출 자원을 만들지 않음
- [ ] 실패 시 Events와 Pod 상태를 수집함

## 🚧 문제가 생겼다면

| 증상 | 원인일 가능성 | 해야 할 일 |
| --- | --- | --- |
| Pod가 `Pending` | 스케줄링 제약(nodeSelector) 또는 리소스 부족 | 노드 상태와 taint/toleration 확인 |
| Pod가 `ImagePullBackOff` | 이미지 태그/digest 오류 | manifest의 이미지 값 재확인 |
| Pod가 `ContainerCreating`에서 멈춤 | ConfigMap을 먼저 적용하지 않았을 수 있음 | `lab-web-content` ConfigMap 존재 여부 확인 |
| 화면은 뜼는데 POD가 `—` | Downward API 파일 경로 불일치 | manifest의 `path` 값과 HTML의 fetch 대상 비교 |
| port-forward 응답 없음 | 앱이 아직 `Ready` 아님 | 몇 초 대기 후 Pod 상태 재확인 |

## 다음 Lab

정상 상태라면 [Lab 07: 문제를 진단하고 복구하기](07-diagnose-and-recover.md)로, 시간이 부족하면 [Lab 08](08-document-and-cleanup.md)로 바로 이동합니다.
