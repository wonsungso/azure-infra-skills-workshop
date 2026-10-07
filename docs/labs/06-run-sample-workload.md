# Lab 06: Gateway + Database 검증

**Lab 6 / 8** · 2부 · 실행과 마무리

🎯 Application Gateway for Containers → AKS → PostgreSQL 흐름 검증

🧠 Skill 없이 도구만 사용합니다

> 🎬 인프라가 준비됐습니다. 이제 Public 요청과 Private Database 연결을 증명합니다.

## 왜 필요한가요?

Azure 배포 성공만으로 전체 경로가 동작한다고 볼 수 없습니다.

- Gateway가 Public 요청을 Service로 전달해야 합니다
- Pod가 Private DNS로 PostgreSQL을 찾아야 합니다
- Workload Identity Token으로 SQL을 실행해야 합니다

## 시작 전에

- [Lab 05](05-deploy-and-connect.md)에서 `lab` Namespace 접근을 확인했나요?

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

Manifest는 네 조각으로 구성됩니다.

| 조각 | 역할 |
| --- | --- |
| `ConfigMap/lab-web-content` | 상품 페이지 `index.html` (외부 CDN 없이 CSS 내장) |
| `projected` Volume → Downward API | 실행 중인 Pod 이름과 Namespace를 파일로 주입 |
| `nginx-unprivileged` 이미지 | 위 두 조각을 합쳐 `/usr/share/nginx/html`로 서빙 |
| `Gateway` + `HTTPRoute` | AGC Public Frontend에서 Service로 전달 |
| `postgres-check` Job | Private DNS, TLS, Workload Identity, SQL 검증 |

그래서 페이지에 뜨는 Pod 이름은 **하드코딩된 값이 아니라 지금 응답하는 실제 Pod**입니다.

Placeholder는 [`render-workload.sh`](../../scripts/render-workload.sh)가 Azure 조회값으로 채웁니다. Secret은 저장하지 않습니다.

- 조회는 `.env`의 `SUBSCRIPTION_ID` Scope를 사용합니다
- 필수 값이나 조회 결과가 비면 Manifest를 출력하지 않고 오류로 멈춥니다
- Manifest와 Federated Credential이 `lab` 전용이므로 다른 `NAMESPACE`도 거부합니다

## Step 2. 렌더링하고 적용하기

> 💻 **터미널에서 실행**

```bash
set -o pipefail
bash scripts/render-workload.sh | kubectl apply -f -
kubectl -n lab rollout status deployment/lab-web --timeout=600s
kubectl -n lab wait --for=condition=complete job/postgres-check --timeout=600s
```

`pipefail`은 Renderer 실패를 파이프라인 실패로 전달합니다. 오류가 있으면 다음 검증 전에 먼저 해결합니다.

Renderer 출력에는 Azure Resource ID와 FQDN이 포함됩니다. 파일로 저장하거나 커밋하지 않습니다.

<details>
<summary>💡 <b>Skill을 안 썼다면?</b></summary>

| 방식 | 이 단계에서 벌어지는 일 |
| --- | --- |
| 🖐 수동 | `kubectl apply` 후 무엇을 확인해야 정상인지 스스로 정해야 한다. |
| 💬 일반 프롬프트 | `apply`가 성공하면 "배포 완료"라고 답하기 쉽다. Pod가 `Ready`인지, Service가 Pod와 **실제로 연결됐는지**는 확인하지 않는다. |
| ⚡ 이 랩은 Skill 없이 | 도구만 씁니다. 대신 **계층별 확인 순서**를 문서가 제공합니다. 무엇을 봐야 하는지 아는 것 자체가 이 랩의 학습 목표입니다. |

</details>

## Step 3. Public Ingress와 Database 확인하기

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

AGC의 최초 생성·Frontend 준비는 Web Pod와 SQL Job보다 늦을 수 있습니다.

- 준비 대기는 최대 15분입니다. Web·SQL이 먼저 성공해도 아직 Public 요청 성공은 아닙니다
- 시간 초과 시 재배포·삭제하지 말고 ALB 상태와 Controller Log를 수집합니다

[`verify-public-http.sh`](../../scripts/verify-public-http.sh)는 실제 HTTP와 SQL 상품 Row를 함께 확인합니다.

- 연결은 5초, 각 요청은 20초로 제한해 무기한 기다리지 않습니다
- Public endpoint가 준비 중이면 상태를 표시하며 최대 3분 대기합니다
- 시간 초과나 잘못된 내용은 오류로 종료합니다. HTTP 200만으로 성공 처리하지 않습니다

<img src="../../img/shop.png" alt="Contoso Shop 상품 페이지 - 상품 카드 4개와 하단에 실제 Pod 이름이 표시된 화면" width="760">

두 가지를 비교해 봅니다.

- 화면 아래의 Pod 이름과 터미널에서 조회한 이름이 **같은가** → 화면이 정말로 내 클러스터에서 오고 있다는 증거
- `-o wide`로 조회한 Node가 **User Pool인가** → Lab 02 설계 결정이 지켜졌다는 증거

Pod를 다시 만들면 Public URL은 유지되고 화면의 Pod 이름만 바뀝니다.

> 💻 **터미널에서 실행**

```bash
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
- [ ] 실패 시 Events와 Pod 상태를 수집함

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

[Lab 07: 진단과 복구](07-diagnose-and-recover.md) - 시간이 부족하면 [Lab 08: 문서화 + 정리](08-document-and-cleanup.md)로 바로 갑니다.
