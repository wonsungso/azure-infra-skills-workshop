# Lab 06: Gateway + Database 검증

**Lab 6 / 8** · 2부 · 실행과 마무리

🎯 Application Gateway for Containers → AKS → PostgreSQL 흐름 검증

🧠 Skill 없이 도구만 사용합니다

> 🎬 Public HTTP와 Private SQL로 전체 요청 경로를 확인합니다.

## 왜 필요한가요?

배포 성공만으로 요청 경로를 확인할 수는 없습니다.

- Gateway가 Public 요청을 Service로 전달해야 합니다
- Pod가 Private DNS로 PostgreSQL을 찾아야 합니다
- Workload Identity Token으로 SQL을 실행해야 합니다

## 시작 전에

- [Lab 05](05-deploy-and-connect.md)에서 `lab` Namespace 접근을 확인했나요?
- 같은 Bash 터미널의 `KUBECONFIG`를 유지합니다. 새 터미널이면 Lab 05의 환경 설정만 다시 실행합니다

## Step 1. Manifest 검토하기

> 💬 **Copilot 채팅에 붙여넣기**

```text
reference/kubernetes/lab-web.yaml과 scripts/render-workload.sh를 검토해줘.

[설명할 것]
- ConfigMap, Deployment, ClusterIP Service
- ApplicationLoadBalancer, Gateway, HTTPRoute
- PostgreSQL ServiceAccount와 Workload Identity
- postgres-check Job의 TLS·SQL 검증

[그다음]
- 적용 대상과 검증 순서를 제시해줘

[제약]
- 검토만 하고 클러스터에 적용하지 마
```

Manifest의 주요 구성입니다.

| 조각 | 역할 |
| --- | --- |
| `ConfigMap/lab-web-content` | 상품 페이지 `index.html` (외부 CDN 없이 CSS 내장) |
| `projected` Volume → Downward API | 실행 중인 Pod 이름과 Namespace를 파일로 주입 |
| `nginx-unprivileged` 이미지 | 화면·Pod 정보·SQL 조회 파일을 HTTP로 제공 |
| `Gateway` + `HTTPRoute` | AGC Public Frontend에서 Service로 전달 |
| `postgres-check` Job | Private DNS, TLS, Workload Identity, SQL 검증 |

페이지의 Pod 이름은 **응답하는 실제 Pod**에서 읽습니다.

[`render-workload.sh`](../../scripts/render-workload.sh)가 Azure 조회값으로 Placeholder를 채웁니다.

- 조회는 `.env`의 `SUBSCRIPTION_ID` Scope를 사용합니다
- 값이 비면 출력 없이 오류로 멈춥니다. Secret은 저장하지 않습니다
- Manifest·Federated Credential은 `lab` 전용입니다. 다른 Namespace는 거부합니다

## Step 2. 승인 후 렌더링·적용하기

Step 1에서 확인한 적용 대상·영향을 승인한 뒤 실행합니다.
Manifest 적용은 워크로드를 만들고 **비용이 발생하는 AGC도 생성**합니다.
이 블록은 최초 적용용입니다. 복구 후 점검에는 다시 적용하지 않습니다.

> 💻 **터미널에서 실행**

```bash
set -o pipefail
bash scripts/render-workload.sh | kubectl apply -f -
kubectl -n lab rollout status deployment/lab-web --timeout=600s
kubectl -n lab wait --for=condition=complete job/postgres-check --timeout=600s
```

`pipefail`은 Renderer 오류를 파이프라인 실패로 전달합니다. 실패하면 다음 단계 전에 해결합니다.

Renderer 출력에는 Azure Resource ID와 FQDN이 포함됩니다. 파일로 저장하거나 커밋하지 않습니다.

Deployment rollout과 Job Complete가 모두 성공한 뒤 Step 3으로 이동합니다.
실패하면 Pod·Events·Log를 확인하고, 다음 단계로 넘어가지 않습니다.

<details>
<summary>💡 <b>Skill을 안 썼다면?</b></summary>

| 방식 | 이 단계에서 벌어지는 일 |
| --- | --- |
| 🖐 수동 | 적용 후 준비 상태·연결을 직접 검증한다. |
| 💬 일반 프롬프트 | `apply` 결과와 서비스 동작을 구분하도록 지시해야 한다. |
| ⚡ 이 Lab은 도구만 사용 | 문서의 계층별 순서로 준비 상태·HTTP·SQL을 확인한다. |

</details>

## Step 3. Public Ingress와 Database 확인하기

아래는 **읽기 전용 재검증 블록**입니다. 최초 적용 후와 Lab 07 복구 후에 사용합니다.

> 💻 **터미널에서 실행**

```bash
echo "Waiting for Gateway Accepted / Programmed"
kubectl -n lab wait --for=condition=Accepted gateway/lab-gateway --timeout=900s
kubectl -n lab wait --for=condition=Programmed gateway/lab-gateway --timeout=900s
echo "Waiting for HTTPRoute Accepted / ResolvedRefs"
kubectl -n lab wait \
  --for=jsonpath='{.status.parents[0].conditions[?(@.type=="Accepted")].status}'=True \
  httproute/lab-web --timeout=180s
kubectl -n lab wait \
  --for=jsonpath='{.status.parents[0].conditions[?(@.type=="ResolvedRefs")].status}'=True \
  httproute/lab-web --timeout=180s
kubectl -n lab get applicationloadbalancer,gateways,httproutes
APP_URL="http://$(kubectl -n lab get gateway lab-gateway -o jsonpath='{.status.addresses[0].value}')"
echo "Checking public HTTP and SQL-derived product"
bash scripts/verify-public-http.sh
kubectl -n lab logs job/postgres-check -c psql
```

- Gateway는 `Accepted`·`Programmed`, HTTPRoute는 `Accepted`·`ResolvedRefs`가 `True`여야 합니다
- `curl`은 Application Gateway for Containers를 통해 AKS에 도달합니다
- `/data/products.txt`는 Web Pod가 PostgreSQL에서 읽은 Row입니다
- Job Log의 `successful_checks`가 PostgreSQL SQL 실행 증거입니다

**Web·SQL 성공과 Public HTTP 준비는 별개입니다.**
Gateway의 각 준비 조건은 최대 15분 기다립니다.
시간 초과 시 재배포·삭제하지 말고 ALB 상태·Controller Log를 수집합니다.

[`verify-public-http.sh`](../../scripts/verify-public-http.sh)는 HTTP와 SQL 상품 Row를 확인합니다.

- 연결 5초·요청 20초, 준비 대기 최대 3분으로 제한합니다
- 시간 초과·내용 불일치는 오류입니다. HTTP 200만으로 성공 처리하지 않습니다

<img src="../../img/shop.png" alt="Contoso Shop 상품 페이지 - 상품 카드 4개와 하단에 실제 Pod 이름이 표시된 화면" width="760">

실제 Pod 이름·배치 Node·User Pool을 조회하고 화면과 비교합니다.

> 💻 **터미널에서 실행**

```bash
kubectl -n lab get pods -l app=lab-web -o wide
kubectl get nodes -L kubernetes.azure.com/mode
curl -4 -fsS --connect-timeout 5 --max-time 20 "$APP_URL/pod-name.txt"
```

확인할 것:

- 화면의 Pod 이름과 실제 조회한 이름이 같은가?
- `-o wide`로 확인한 배치 Node가 User Pool인가?

### 최초 실습에서만: Pod 재생성

**위 읽기 전용 검증이 통과한 뒤**, Pod 삭제의 대상·영향을 승인하고 실행합니다.
단일 Web Pod이므로 재생성 중 응답이 일시 중단될 수 있습니다.
복구 후 점검에서는 이 블록을 반복하지 않습니다.

재생성 후 **같은 URL·새 Pod 이름·SQL 상품**을 확인합니다.

> 💻 **터미널에서 실행**

```bash
APP_URL="http://$(kubectl -n lab get gateway lab-gateway -o jsonpath='{.status.addresses[0].value}')"
kubectl delete pod -n lab -l app=lab-web
kubectl -n lab rollout status deployment/lab-web --timeout=600s
kubectl -n lab wait --for=condition=Ready pod -l app=lab-web --timeout=600s
bash scripts/verify-public-http.sh
curl -4 -fsS --connect-timeout 5 --max-time 20 "$APP_URL/pod-name.txt"
```

<img src="../../img/shop-after-restart.png" alt="Pod 재생성 후 같은 상품 페이지 - 하단의 Pod 이름만 다른 값으로 바뀐 화면" width="760">

## ✅ 완료 체크리스트

- [ ] Gateway Public URL에서 HTTP 응답 확인
- [ ] PostgreSQL Job에서 SQL 결과 확인
- [ ] 페이지에 표시된 Pod 이름이 조회 결과와 일치함
- [ ] Pod가 User Pool Node에 배치된 것을 확인함
- [ ] PostgreSQL Public Access와 Password를 사용하지 않음
- [ ] 최초 실습의 Pod 재생성 후 같은 URL·새 Pod 이름·SQL 상품 확인
- [ ] 실패가 있었다면 Events와 Pod 상태를 기록함

## 🚧 문제가 생겼다면

<details>
<summary>🔎 <b>증상별 원인과 해결 방법</b></summary>

| 증상 | 원인일 가능성 | 해야 할 일 |
| --- | --- | --- |
| Pod가 `Pending` | 스케줄링 제약(nodeSelector) 또는 리소스 부족 | Node 상태와 Taint/Toleration 확인 |
| Pod가 `ImagePullBackOff` | 이미지 태그/digest 오류 | Manifest의 이미지 값 재확인 |
| Pod가 `ContainerCreating`에서 멈춤 | ConfigMap을 먼저 적용하지 않았을 수 있음 | `lab-web-content` ConfigMap 존재 여부 확인 |
| 화면은 뜨는데 Pod 이름이 `-` | Downward API 파일 경로 불일치 | Manifest의 `path` 값과 HTML의 Fetch 대상 비교 |
| Gateway 주소가 비어 있음 | ALB Controller 또는 Subnet 역할 전파 중 | Gateway와 ApplicationLoadBalancer Events 확인 |
| PostgreSQL Job 실패 | Private DNS, Workload Identity, Entra Admin 문제 | Init Container와 Job Log를 분리해 확인 |

</details>

## 다음 Lab

완료 체크리스트를 확인한 뒤 [Lab 07: 진단과 복구](07-diagnose-and-recover.md)를 선택하거나
바로 [Lab 08](08-document-and-cleanup.md)로 진행합니다. 오류가 남아 있으면 먼저 해결합니다.
