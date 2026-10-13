# Lab 01: 워크샵 시작하기

**Lab 1 / 8** · 1부 · 설계와 검증

🎯 로그인·도구·Scope 준비

🧠 `azure-resource-lookup`

> 🎬 로그인은 직접, 나머지 준비는 Agent에게 맡깁니다.

## 왜 필요한가요?

배포 전에 도구와 사용할 Azure Scope를 확인합니다.

## 시작 전에

- [README](../../README.md)에서 Codespace를 열고 Copilot Agent를 준비합니다.

## Step 1. 직접 로그인하기

이 워크샵에서 기본적으로 직접 실행하는 터미널 명령은 이 한 줄입니다.

> 💻 **터미널에서 실행**

```bash
az login --use-device-code
```

브라우저에서 로그인합니다. Credentials·Token은 채팅에 전달하지 않습니다.

## Step 2. Agent에게 준비 맡기기

> 🧠 **Skill** `azure-resource-lookup` &nbsp;·&nbsp; 💬 **Copilot 채팅에 붙여넣기**

```text
azure-resource-lookup Skill을 사용해 워크샵을 준비해줘.

[진행 순서]
- 사용할 Subscription을 보여주고 내 선택을 확인
- 아래 6개 Skill의 파일·실제 사용 가능 여부와 MCP 연결을 확인
  azure-quotas, azure-kubernetes, azure-enterprise-infra-planner,
  azure-resource-lookup, azure-diagnostics, azure-resource-visualizer
- bash scripts/workshop.sh check로 도구·로그인·.env 준비 확인
- Provider·Feature의 현재 등록 상태를 조회
- Provider·Feature 등록이 필요하면 대상·영향을 설명하고 승인 요청
- 승인 후 bash scripts/workshop.sh setup --approved 실행
- .env의 Scope·Egress IP 준비 상태와 기존 리소스를 조회
- 실제 결과를 infra-report.md의 Env 장에 기록

[제약]
- CLI와 .env의 Subscription이 다르면 덮어쓰지 말고 멈춰
- 비밀값·.env 전체를 출력하지 마
- 등록 승인 전에는 Subscription 설정을 바꾸지 마
- Azure 리소스를 배포하지 마
- 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘
```

**완료 기준:** 도구·Skill 6개 준비, Provider·Feature `Registered`, Scope 일치.
Resource Group이 아직 없어도 정상입니다.

## ✅ 완료 체크리스트

- [ ] 직접 로그인하고 사용할 Subscription을 확인했다
- [ ] 준비 검사와 등록이 완료됐다
- [ ] 실제 결과가 `infra-report.md`에 기록됐다

## 🚧 문제가 생겼다면

<details>
<summary>🔎 <b>준비 실패·Scope·Egress IP</b></summary>

| 증상 | 다음 조치 |
| --- | --- |
| 도구·Skill 누락 | Codespace 준비 실패부터 해결. 다른 Skill로 대체하지 않음 |
| 로그인·Scope 불일치 | 사용할 Scope를 다시 확인. 로그인은 직접 수행 |
| 등록 시간 초과 | 실제 등록 상태를 재조회. 완료 전 다음 Lab으로 가지 않음 |
| Egress 조회 실패 | 연결을 확인한 뒤 Agent에게 `check` 재실행 요청 |
| 권한 부족 | 권한을 확대하지 말고 허용된 전용 Scope 선택 |

도구 설치는 [`.devcontainer/`](../../.devcontainer/), MCP 설정은 [`mcp.json`](../../.vscode/mcp.json)이 담당합니다.
[`workshop.sh`](../../scripts/workshop.sh)는 매번 환경을 준비하므로 Shell 설정을 복사하지 않습니다.
이미 AKS가 있는 상태의 Egress 변경은 [Lab 05](05-deploy-and-connect.md)에서 별도로 승인합니다.

</details>

## 다음 Lab

체크리스트를 마친 뒤 [Lab 02: 3계층 설계 결정하기](02-design-aks.md)로 이동합니다.
