# Lab 01: 워크샵 시작하기

**Lab 1 / 8** · 1부 · 설계와 검증

🎯 역할 구분 / Azure 로그인·입력값 확인 / Scope 조회

🧠 `azure-resource-lookup`

> 🎬 배포 전에 도구·권한·Scope를 확인합니다.

## 왜 필요한가요?

도구·권한·입력값이 준비돼야 다음 Lab을 진행할 수 있습니다.

## 시작 전에

- [README](../../README.md)의 시작하기를 읽고 Codespace를 열었나요?
- 터미널에서 `az version`이 동작하나요?

> 📖 **💻 실행**은 터미널, **💬 붙여넣기**는 Copilot 채팅입니다.

## Step 1. 역할 이해하기

| 역할 | 하는 일 |
| --- | --- |
| Azure Skill | 절차·모범 사례·위험 판단 기준 제공 |
| MCP 도구 / CLI | 실제 조회·생성·배포 실행 |
| 사람 | 범위 확인, 승인, 결과 검증 |

- 실제 도구 호출과 결과를 확인합니다
- 생성·변경·삭제 전에 사람이 승인합니다
- `예상`과 `관측`을 구분해 기록합니다

작업 전 **조회인지 변경인지** 구분합니다.

## Step 2. Azure Skills 확인하기

Codespace가 만들어질 때 Skill 6개를 `.github/skills/`에 내려받았습니다.

설치된 파일을 확인합니다.

> 💻 **터미널에서 실행**

```bash
ls .github/skills
```

Copilot이 Skill을 인식하는지도 확인합니다.

> 💬 **Copilot 채팅에 붙여넣기**

```text
아래 6개 Skill을 지금 쓸 수 있는지 표로 알려줘.

[확인 대상]
- azure-quotas
- azure-kubernetes
- azure-enterprise-infra-planner
- azure-resource-lookup
- azure-diagnostics
- azure-resource-visualizer

[제약]
- 확인만 하고 각 Skill의 실제 작업까지 진행하지마
- 없는 것이 있으면 대체 방법을 찾지 말고 그대로 알려줘
- Azure 리소스를 만들거나 바꾸지 마

```

**6개 모두 필요합니다.** 누락되면 설치를 완료한 뒤 진행합니다.

`azure-enterprise-infra-planner`는 MCP 서버에서 Azure 모범 사례와 Microsoft Learn 문서를 조회합니다.
MCP 연결이 없으면 내장 참조 문서만 사용할 수 있으므로 연결 상태를 확인합니다.

VS Code의 **MCP 서버** 목록에서 `azure`와 `microsoft-learn`을 확인합니다.

- 설정은 [`mcp.json`](../../.vscode/mcp.json)에 있습니다
- 중지 상태면 시작합니다. 첫 실행에는 패키지 다운로드 시간이 필요합니다

<details>
<summary>🖐 <b>비어 있거나 로컬 VS Code로 진행한다면</b></summary>

자동 설치는 Codespace 생성 시 실행됩니다. 수동 설치는 저장소 루트에서 진행합니다.

> 💻 **터미널에서 실행**

```bash
tmp=$(mktemp -d)
git clone -q --depth 1 https://github.com/microsoft/azure-skills.git "$tmp" || {
  echo "Could not download Azure Skills" >&2
  exit 1
}
for s in azure-quotas azure-kubernetes azure-enterprise-infra-planner \
         azure-resource-lookup azure-diagnostics azure-resource-visualizer; do
  [ -f "$tmp/skills/$s/SKILL.md" ] || {
    echo "Missing required Skill: $s" >&2
    exit 1
  }
done
mkdir -p .github/skills
for s in azure-quotas azure-kubernetes azure-enterprise-infra-planner \
         azure-resource-lookup azure-diagnostics azure-resource-visualizer; do
  cp -r "$tmp/skills/$s" .github/skills/
done
rm -rf "$tmp"
```

</details>

## Step 3. Azure에 로그인하기

**직접 로그인합니다.** Credentials를 다루므로 Skill이나 스크립트에 맡기지 않습니다.

> 💻 **터미널에서 실행**

```bash
az login --use-device-code
```

Quota와 Application Gateway for Containers Add-on을 **아래 블록 한 번으로** 준비합니다.

- Feature 등록은 비동기이므로 요청 후 `Registered`까지 기다립니다
- Feature 등록 완료 후 `Microsoft.ContainerService` Provider를 다시 등록합니다
- 이미 등록됐다면 대기는 바로 끝납니다
- **Subscription 설정을 변경합니다.** 비용이나 리소스 생성은 없지만, 공용 Subscription에서는 먼저 승인을 확인합니다

> 💻 **터미널에서 실행**

```bash
az provider register --namespace Microsoft.Quota --wait || exit 1
az provider register --namespace Microsoft.NetworkFunction --wait || exit 1
for FEATURE in ManagedGatewayAPIPreview ApplicationLoadBalancerPreview; do
  az feature register --namespace Microsoft.ContainerService --name "$FEATURE" || exit 1
done
for FEATURE in ManagedGatewayAPIPreview ApplicationLoadBalancerPreview; do
  DEADLINE=$((SECONDS + 1800))
  while true; do
    STATE=$(az feature show --namespace Microsoft.ContainerService --name "$FEATURE" --query properties.state -o tsv) || exit 1
    [ "$STATE" = Registered ] && break
    [ "$SECONDS" -lt "$DEADLINE" ] || {
      echo "Feature registration timeout: $FEATURE" >&2
      exit 1
    }
    echo "Waiting for Feature: $FEATURE (state: $STATE)"
    sleep 15
  done
done
az provider register --namespace Microsoft.ContainerService --wait || exit 1
az provider register --namespace Microsoft.Network --wait || exit 1
az provider register --namespace Microsoft.ServiceNetworking --wait || exit 1
az provider register --namespace Microsoft.DBforPostgreSQL --wait || exit 1
az provider register --namespace Microsoft.ManagedIdentity --wait || exit 1
az extension add --name alb --upgrade --yes || exit 1
```

등록이 완료되면 Step 4의 입력값 확인과 Step 5의 Scope 확인을 진행합니다.
**완료 체크리스트를 모두 확인한 뒤 Lab 02로 넘어갑니다.**

## Step 4. 입력값 확인하기

모든 프롬프트는 저장소 루트의 `.env`를 읽습니다.

- Codespace 생성 시 리소스 이름과 Egress IP를 자동으로 채웁니다
- 로그인 후 다시 실행하면 Subscription도 채웁니다

> 💻 **터미널에서 실행**

```bash
bash scripts/init-workshop.sh
cat .env
```

| 항목 | 채우는 방식 |
| --- | --- |
| `WORKSHOP_ID`와 리소스 이름 | Codespace 생성 시 자동 |
| `EGRESS_IP_CIDR` | 자동 (ipify 조회) |
| `SUBSCRIPTION_ID` | 자동 (Step 3 로그인 후 재실행) |
| `REGION` | 기본값 `koreacentral` - **Lab 02에서 Quota를 보고 확인** |
| Subnet CIDR, Node·Database SKU | **Lab 02에서 내가 결정** |
| `NODE_RESOURCE_GROUP` | Lab 05 배포 후 Output |

`EGRESS_IP_CIDR`은 **AKS에 접속할 환경의 Egress IP**입니다. Codespace에서는 PC IP를 쓰지 않습니다.

- AKS API Server에 접근할 수 있는 유일한 주소가 됩니다
- Codespace 안에서 조회해야 합니다
- 재시작으로 IP가 바뀌면 [`init-workshop.sh`](../../scripts/init-workshop.sh)로 갱신합니다

## Step 5. 내 Azure 범위 확인하기

CLI로 현재 Subscription을 확인합니다.

> 💻 **터미널에서 실행**

```bash
az account show --query "{subscription:name, state:state, tenant:tenantDefaultDomain}" -o table
```

명령 출력은 화면에만 표시됩니다.
Skill 프롬프트의 답변은 [`AGENTS.md`](../../AGENTS.md)에 따라 `infra-report.md`에 기록됩니다.
Lab 08은 이 보고서로 인계 문서를 작성합니다.

Resource Group은 [Lab 04](04-validate-and-approve.md)에서 만듭니다. **지금 없어도 정상입니다.**

> 💻 **터미널에서 실행**

```bash
set -a; . ./.env; set +a
EXISTS=$(az group exists -n "$RESOURCE_GROUP" --subscription "$SUBSCRIPTION_ID")
if [ "$EXISTS" = true ]; then
  az group show -n "$RESOURCE_GROUP" --subscription "$SUBSCRIPTION_ID" -o table
else
  echo "Not created yet - expected"
fi
```

**확인할 것**

- 표시된 Subscription이 `.env`의 `SUBSCRIPTION_ID`와 같은가?
- 기존 리소스가 있다면 목록을 기록합니다. Lab 08의 삭제 대상과 구분해야 합니다

### Skill은 언제 쓰나

존재 여부와 권한 부족을 구분하는 등 조회 결과 해석이 필요할 때 Skill을 사용합니다.

> 🧠 **Skill** `azure-resource-lookup` &nbsp;·&nbsp; 💬 **Copilot 채팅에 붙여넣기**

```text
azure-resource-lookup Skill을 사용해 Resource Group의 존재 여부를 확인해줘.

[읽을 값]
- 저장소 루트 .env의 SUBSCRIPTION_ID, RESOURCE_GROUP

[답할 것]
- 존재 여부만 한 줄로
- 없으면 "없음", 접근이 막혀 있으면 "권한 부족"으로 구분

[제약]
- Azure 리소스를 만들거나 바꾸지 마
- 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려주세요

```

**단순 조회는 CLI, 판단·절차·위험 검토는 Skill을 사용합니다.**

<details>
<summary>💡 <b>Skill을 안 썼다면?</b></summary>

| 방식 | 이 단계에서 벌어지는 일 |
| --- | --- |
| 🖐 수동 | 직접 조회하고 결과를 해석한다. |
| 💬 일반 프롬프트 | 실제 조회와 읽기 전용 조건을 명시해야 한다. |
| ⚡ Skill | 조회 결과와 권한 문제를 절차에 따라 해석한다. |

</details>

## ✅ 완료 체크리스트

- [ ] `.github/skills/`에 Skill 6개가 있고 Copilot이 인식함을 확인했다
- [ ] `az login --use-device-code`로 로그인하고 쓸 Subscription을 선택했다
- [ ] `Microsoft.Quota` Provider가 `Registered` 상태임을 확인했다
- [ ] 두 Feature와 필요한 Provider 등록 완료를 확인했다
- [ ] `.env`의 `SUBSCRIPTION_ID`와 `EGRESS_IP_CIDR`이 채워진 것을 확인했다
- [ ] 조회한 Subscription이 `.env`와 일치함을 확인했다
- [ ] `infra-report.md`가 생성되고 조회 결과가 들어갔다
- [ ] Skill 프롬프트를 실행한 뒤 그 답변이 보고서에 섹션으로 추가되는지 확인했다
- [ ] 단순 조회와 판단을 각각 어떤 도구로 하는지 설명할 수 있다

## 🚧 문제가 생겼다면

<details>
<summary>🔎 <b>증상별 원인과 해결 방법</b></summary>

| 증상 | 해야 할 일 |
| --- | --- |
| "~ 도구가 제공되지 않아" 라며 다른 방법으로 답함 | Skill이 로드되지 않은 것입니다. Step 2를 다시 확인하고, 그 답변은 증거로 쓰지 마세요 |
| `.github/skills`가 비어 있거나 없음 | Step 2의 "비어 있거나 로컬 VS Code로 진행한다면"을 펼쳐 수동으로 내려받으세요 |
| 파일은 있는데 Copilot이 못 찾음 | Azure MCP Server가 npm 패키지입니다. `node --version`으로 Node.js 설치 상태를 봅니다 |
| `az login`이 브라우저를 못 열고 멈춤 | `--use-device-code`를 붙였는지 확인 |
| 로그인은 됐는데 Subscription이 안 보임 | 게스트 계정일 수 있음. `az login --use-device-code --tenant <tenant-id>` |
| `SUBSCRIPTION_ID`가 비어 있음 | 로그인 후 [`init-workshop.sh`](../../scripts/init-workshop.sh)를 다시 실행 |
| 조회 결과가 `.env`와 다름 | `az account set --subscription <id>` 후 [`init-workshop.sh`](../../scripts/init-workshop.sh) 재실행 |
| "권한이 없습니다" | 권한을 스스로 올리지 말고, 권한이 있는 다른 Subscription·그룹으로 진행 |
| Skill이 리소스를 만들려 함 | "읽기 전용"을 다시 강조해 다시 요청 |

</details>

## 다음 Lab

[Lab 02: 3계층 설계 결정하기](02-design-aks.md)
