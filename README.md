# GitHub Copilot과 Azure Skills로 진행하는 Azure 인프라 워크샵

**사람은 설계·승인하고, Agent는 실행·검증·기록합니다.**
AKS·Application Gateway for Containers·Private PostgreSQL을 만드는 자기주도형 워크샵입니다.
앱 코딩·이미지 빌드는 하지 않습니다.

## 시나리오

Contoso의 신입 플랫폼 엔지니어로서 일주일 안에 Shop 출시 환경을 준비합니다.
계획·코드·검증·배포를 Agent에게 맡기고 실제 HTTP·SQL 결과를 확인합니다.

<img src="img/contoso-scenario.png" alt="Contoso Shop 출시 환경을 설계하고 검증하는 워크샵 시나리오" width="1000">

## 시작하기

1. 전용 Azure Scope와 배포·제한된 역할 생성/할당·삭제 권한을 준비합니다.
2. [GitHub Codespaces](https://codespaces.new/wonsungso/azure-infra-skills-workshop)를 엽니다.
3. [Lab 01](docs/labs/01-orientation-and-setup.md)에서 로그인하고 순서대로 진행합니다.

터미널 복사는 **로그인 한 줄**입니다. 각 Lab의 프롬프트를 Copilot Agent에 붙여넣고
선택·승인에 응답합니다. 명령을 다시 터미널에 복사할 필요는 없습니다.

> [!WARNING]
> **AKS·PostgreSQL·AGC는 실제 비용이 발생합니다.** 중간에 멈춰도 [Lab 08](docs/labs/08-document-and-cleanup.md)에서 정리하세요.

## 진행 순서

**설계 → 계획 승인 → 코드 → 검증 → 배포 승인 → 실행 → 실제 검증 → 정리**

| Lab | 할 일 | 다음 단계에 넘길 것 |
| --- | --- | --- |
| [01. 시작하기](docs/labs/01-orientation-and-setup.md) | 로그인·Scope 준비 | `.env`, 준비 결과 |
| [02. 설계 결정](docs/labs/02-design-aks.md) | Quota·Network·SKU·권한 선택 | 결정값·근거 |
| [03. 계획 + Bicep](docs/labs/03-plan-and-bicep.md) | 계획 승인, IaC 생성 | 승인된 계획·코드 |
| [04. 검증 + 승인](docs/labs/04-validate-and-approve.md) | 실제 검사, 배포 승인 | 검증·승인 기록 |
| [05. 배포·접속](docs/labs/05-deploy-and-connect.md) | 인프라·제한된 접근 준비 | 서비스·Namespace |
| [06. E2E 검증](docs/labs/06-run-sample-workload.md) | HTTP·SQL·Pod 대조 | 관측 증거 |
| [07. 진단·복구 (선택)](docs/labs/07-diagnose-and-recover.md) | 장애·증거·복구 | 원인·복구 결과 |
| [08. 인계·정리](docs/labs/08-document-and-cleanup.md) | 문서화·승인 후 삭제 | 인계·잔여 확인 |

각 Lab의 체크리스트를 마친 뒤 다음으로 이동합니다. 실패·미승인 상태에서는 멈춥니다.

## 만들 환경

<img src="img/workload-architecture.png" alt="AGC에서 AKS로 요청을 전달하고 Workload Identity로 Private PostgreSQL을 조회하는 구성" width="740">

- **AGC**: Application Gateway for Containers, 외부 HTTP 진입점
- **AKS**: System/User Node Pool, Azure CNI Overlay + Cilium
- **PostgreSQL**: Private Network·Entra 인증, Password 없이 SQL 실행
- **Workload Identity**: Pod가 Entra Identity를 사용해 Database에 인증

<details>
<summary>🛍️ <b>확인할 상품 화면</b></summary>

<img src="img/shop.png" alt="상품과 실제 응답 Pod 이름을 보여주는 Contoso Shop" width="760">

공개 NGINX 이미지에 ConfigMap으로 화면을 넣습니다.
상품 Row는 PostgreSQL에서 읽고, Pod 이름은 실행 중인 실제 Pod에서 가져옵니다.

</details>

## 지켜야 할 경계

- 생성·권한 변경·장애 주입·삭제는 **대상·영향을 보고 각각 승인**합니다.
- 부족한 권한을 Owner·Cluster Admin 신규 부여로 해결하지 않습니다.
- API Server의 Egress `/32` 제한을 완화하지 않습니다.
- 실제 실행 결과만 통과로 기록합니다. 미실행은 `예상`·`미검증`입니다.
- 비밀값은 채팅·저장소에 넣지 않습니다. 결과는 로컬 `infra-report.md`에 쌓입니다.

<details>
<summary>🔄 <b>중간에 다시 시작한다면</b></summary>

> 💬 **Copilot 채팅에 붙여넣기**

```text
현재 진행 상태와 다음 미완료 단계를 확인해줘.

[읽을 값]
- .env와 infra-report.md

[할 일]
- 실제 Azure 상태와 기록 비교, 완료·미완료·선행 조건 요약

[제약]
- 리소스를 변경하거나 지난 승인을 새 변경에 재사용하지 마
```

</details>

<details>
<summary>🧰 <b>도구·자료·개발용 검사</b></summary>

설치는 [`.devcontainer/`](.devcontainer/)가 담당합니다.
로컬 VS Code도 가능하지만 누락 도구·Skill 준비는 먼저 해결해야 합니다.

| 자료 | 용도 |
| --- | --- |
| [`docs/labs/`](docs/labs/) | 본문 프롬프트·결정·승인 |
| [`reference/infra/`](reference/infra/) | 비교용 Bicep 기준본 |
| [`reference/kubernetes/`](reference/kubernetes/) | 워크로드 Manifest |
| [`handoff-template.md`](templates/handoff-template.md) | 로컬 인계 양식 |
| [`AGENTS.md`](AGENTS.md) | 실행·보고서·보안 규칙 |

[`workshop.sh`](scripts/workshop.sh)는 Agent용 실행 도구입니다.
`check`·`setup`·`connect`·`apply`·`verify`·`restart`로 반복 명령을 묶습니다.
변경 작업의 `--approved`는 실제 승인을 받은 뒤에만 사용합니다.
계획·배포·삭제 승인까지 자동으로 진행하는 스크립트가 아닙니다.

개발용 검사: [`test_workshop.py`](tests/test_workshop.py).
`python -m unittest discover -s tests -p test_workshop.py -v`로 실행합니다.
CLI·Kubernetes·HTTP를 Fixture로 대체하므로 실제 Azure E2E 증거는 아닙니다.

</details>
