# Lab 01: 워크샵 시작하기

**Lab 1 / 8** · 1부 · 설계와 검증 · ⏱ 30분

🎯 Skill·도구·사람의 역할 구분 / Azure 로그인과 입력값 확인 / 내 범위를 읽기 전용으로 확인

🧠 `azure-resource-lookup`

> 🎬 팀장의 요청을 방금 받았습니다. 서두르기 전에 **내가 무엇을 건드릴 수 있는 사람인지**부터 확인합니다.

## 왜 필요한가요?

Skill에게 작업을 요청하면 Skill은 절차와 판단 기준을, MCP 도구와 CLI는 실행을 담당합니다. 하지만 **무엇을 승인할지, 결과가 진짜인지 확인하는 것은 사람의 몫**입니다. 이 랩에서 그 역할을 이해하고, 이후 모든 프롬프트가 공유할 입력값을 확정합니다.

## 시작 전에

- [README](../../README.md)의 시작하기를 읽고 Codespace를 열었나요?
- 터미널에서 `az version`이 동작하나요?

## Step 1. 역할 이해하기

| 역할 | 하는 일 |
| --- | --- |
| Azure Skill | 절차·모범 사례·위험 판단 기준 제공 |
| MCP 도구 / CLI | 실제 조회·생성·배포 실행 |
| 사람 | 범위 확인, 승인, 결과 검증 |

지킬 규칙은 세 가지입니다.

- Skill 이름을 프롬프트에 썼다고 실행된 것이 아닙니다. **어떤 도구가 실제로 호출됐는지** 확인하세요.
- 만들거나 바꾸거나 지우기 전에 항상 사람이 승인합니다.
- `예상`과 `관측`을 구분해서 기록합니다.

헷갈리면 "지금 이 작업이 Azure를 바꾸나요, 읽기만 하나요?"를 먼저 물어보세요.

## Step 2. Azure Skills 확인하기

Codespace가 만들어질 때 이 워크샵이 쓰는 Skill 6개를 `.github/skills/`에 내려받았습니다. 저장소에는 커밋되지 않고, 내 Codespace 안에만 있습니다.

먼저 파일이 있는지 봅니다.

```bash
ls .github/skills
```

그다음 Copilot이 실제로 인식하는지 확인합니다. 파일이 있어도 로드되지 않으면 소용이 없습니다.

> 📋 **아래 프롬프트를 복사해 실행**

```text
azure-quotas, azure-kubernetes, azure-enterprise-infra-planner, azure-resource-lookup, azure-diagnostics, azure-resource-visualizer Skill을 지금 쓸 수 있는지 하나씩 확인해서 표로 알려줘. 없는 것이 있으면 그대로 알려줘. 아무것도 실행하지 마.
```

여섯 개가 모두 있어야 합니다.

<details>
<summary>🖐 <b>비어 있거나 로컬 VS Code로 진행한다면</b></summary>

자동 설치는 Codespace를 만들 때만 실행됩니다. 직접 내려받으려면 저장소 루트에서 아래를 실행하세요.

```bash
tmp=$(mktemp -d)
git clone -q --depth 1 https://github.com/microsoft/azure-skills.git "$tmp"
mkdir -p .github/skills
for s in azure-quotas azure-kubernetes azure-enterprise-infra-planner \
         azure-resource-lookup azure-diagnostics azure-resource-visualizer; do
  cp -r "$tmp/skills/$s" .github/skills/
done
rm -rf "$tmp"
```

</details>

## Step 3. Azure에 로그인하기

**이 단계는 사람이 직접 수행해야 합니다.** 로그인은 본인 계정의 credentials를 다루므로 Skill이나 스크립트에 맡기지 않습니다.

```bash
az login --use-device-code
```

마지막으로 quota 조회 API를 쓰려면 `Microsoft.Quota` provider가 subscription에 등록돼 있어야 합니다. Lab 02가 이걸 씁니다.

```bash
az provider register --namespace Microsoft.Quota --wait
az provider show --namespace Microsoft.Quota --query registrationState -o tsv
```

`Registered`가 나와야 합니다. 이미 등록돼 있으면 그대로 끝나므로 여러 번 실행해도 안전합니다.

**이것이 이 워크샵의 첫 번째 쓰기 작업입니다.** provider 등록은 비용이 없고 리소스를 만들지 않으며, 해당 API를 쓸 수 있게 만들 뿐입니다. 그래도 subscription 설정을 바꾸는 일이니, 공용 subscription이라면 먼저 확인하세요.

## Step 4. 입력값 확인하기

이후 모든 프롬프트가 저장소 루트의 `.env`를 공유합니다. **직접 타이핑할 값은 없습니다.** Codespace가 만들어질 때 리소스 이름과 egress IP가 채워졌고, 로그인을 마친 지금 아래를 한 번 더 실행하면 subscription까지 채워집니다.

```bash
bash scripts/init-workshop.sh
cat .env
```

| 항목 | 채우는 방식 |
| --- | --- |
| `WORKSHOP_ID`와 리소스 이름 | Codespace 생성 시 자동 |
| `EGRESS_IP_CIDR` | 자동 (ipify 조회) |
| `SUBSCRIPTION_ID` | 자동 (Step 3 로그인 후 재실행) |
| `REGION` | 기본값 `koreacentral` — **Lab 02에서 quota를 보고 확인** |
| CIDR, VM SKU | **Lab 02에서 내가 결정** |
| `NODE_RESOURCE_GROUP` | Lab 05 배포 후 output |

이후 Lab의 프롬프트는 이 값들을 **Skill이 `.env`에서 직접 읽어 씁니다.**

`EGRESS_IP_CIDR`은 내 PC가 아니라 **Codespace의 egress IP**입니다. AKS API server에 접근할 수 있는 유일한 주소가 되므로 반드시 Codespace 안에서 조회된 값이어야 합니다. Codespace를 중지했다가 다시 시작하면 이 IP가 바뀔 수 있으므로, Lab 05 이후 접속이 갑자기 안 되면 [`init-workshop.sh`](../../scripts/init-workshop.sh)를 다시 실행해 갱신하세요.

## Step 5. 내 Azure 범위 확인하기

먼저 **빠른 방법**으로 확인합니다. 단순 조회는 CLI가 몇 초면 끝납니다.

```bash
bash scripts/add-report.sh --run env "구독과 범위 확인" "az CLI" -- az account show --query "{subscription:name, state:state, tenant:tenantDefaultDomain}" -o table
```

결과를 출력하면서 동시에 저장소 루트의 `infra-report.md`에 명령과 출력을 그대로 남깁니다.

앞으로 Skill 프롬프트를 실행하면 **답변의 표와 설명이 그대로 같은 문서에 섹션으로 추가됩니다.** 저장소 루트의 [`AGENTS.md`](../../AGENTS.md)에 그렇게 지시돼 있어서입니다. Lab 08의 인계 문서가 이 보고서를 근거로 씁니다.

그다음 resource group을 봅니다. Lab 05에서 배포와 함께 만들 것이므로 **지금 없어도 정상입니다.**

```bash
set -a; . ./.env; set +a
az group show -n "$RESOURCE_GROUP" -o table 2>/dev/null || echo "아직 없음 - 정상입니다"
```

**확인할 것**

- 표시된 subscription이 `.env`의 `SUBSCRIPTION_ID`와 같은가?
- 그룹에 다른 리소스가 이미 있다면, Lab 08에서 실수로 지우지 않도록 목록을 기록해 둡니다.

### Skill은 언제 쓰나

위 두 명령으로 "무엇이 있는가"는 알 수 있습니다. 하지만 **"접근이 안 되는 게 권한 때문인지, 없어서인지"** 같은 구분은 CLI가 대신해주지 않습니다. 그럴 때 Skill을 씁니다.

> 🧠 **Skill** `azure-resource-lookup` &nbsp;·&nbsp; 📋 **아래 프롬프트를 복사해 실행**

```text
azure-resource-lookup Skill로 저장소 루트의 .env를 읽어 SUBSCRIPTION_ID와 RESOURCE_GROUP을 확인하고, 그 resource group의 존재 여부만 확인해줘. 없으면 "없음", 접근이 막혀 있으면 권한 부족으로 구분해서 한 줄로 답해줘. 리소스를 만들거나 바꾸지 마. 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘.
```

**Skill 응답은 CLI보다 느립니다.** 도구를 여러 번 호출하고 결과를 해석하기 때문입니다. 그만큼 더 복잡한 작업 혹은 질문에 써야 합니다.

**단순 조회는 CLI, 판단·절차·위험 검토는 Skill.** 이 구분이 이번 Lab의 진짜 교훈입니다. Lab 02부터는 quota 판정과 Day-0 설계 검토처럼 CLI 한 줄로 대체할 수 없는 작업이 이어집니다.

<details>
<summary>💡 <b>Skill을 안 썼다면?</b></summary>

| 방식 | 이 단계에서 벌어지는 일 |
| --- | --- |
| 🖐 수동 | `az account show`, `az group show`를 직접 조합한다. **가장 빠르지만** 무엇을 확인해야 하는지 스스로 알아야 한다. |
| 💬 일반 프롬프트 | 실제 조회 없이 그럴듯한 결과를 지어낼 수 있다. 읽기 전용이라는 보장도 없다. |
| ⚡ Skill | 조회 도구를 실제로 호출하고, 접근 불가 항목을 **권한 부족으로 구분**해 알려준다. 대신 느리다. |

이번 Lab처럼 **답이 분명한 조회**는 수동이 유리합니다. Skill의 값어치는 Lab 02 이후처럼 **판단과 절차가 필요할 때** 드러납니다.

</details>

## ✅ 완료 체크리스트

- [ ] `.github/skills/`에 Skill 6개가 있고 Copilot이 인식함을 확인했다
- [ ] `az login --use-device-code`로 로그인하고 쓸 subscription을 선택했다
- [ ] `Microsoft.Quota` provider가 `Registered` 상태임을 확인했다
- [ ] `.env`의 `SUBSCRIPTION_ID`와 `EGRESS_IP_CIDR`이 채워진 것을 확인했다
- [ ] 조회한 subscription이 `.env`와 일치함을 확인했다
- [ ] `infra-report.md`가 생성되고 조회 결과가 들어갔다
- [ ] Skill 프롬프트를 실행한 뒤 그 답변이 보고서에 섹션으로 추가되는지 확인했다
- [ ] 단순 조회와 판단을 각각 어떤 도구로 하는지 설명할 수 있다

## 🚧 문제가 생겼다면

| 증상 | 해야 할 일 |
| --- | --- |
| "~ 도구가 제공되지 않아" 라며 다른 방법으로 답함 | Skill이 로드되지 않은 것입니다. Step 2를 다시 확인하고, 그 답변은 증거로 쓰지 마세요 |
| `.github/skills`가 비어 있거나 없음 | Step 2의 "비어 있거나 로컬 VS Code로 진행한다면"을 펼서 수동으로 내려받으세요 |
| 파일은 있는데 Copilot이 못 찾음 | Azure MCP server가 npm 패키지입니다. `node --version`으로 Node.js를 확인하세요 |
| `az login`이 브라우저를 못 열고 멈춤 | `--use-device-code`를 붙였는지 확인 |
| 로그인은 됐는데 subscription이 안 보임 | 게스트 계정일 수 있음. `az login --use-device-code --tenant <tenant-id>` |
| `SUBSCRIPTION_ID`가 비어 있음 | 로그인 후 [`init-workshop.sh`](../../scripts/init-workshop.sh)를 다시 실행 |
| 조회 결과가 `.env`와 다름 | `az account set --subscription <id>` 후 [`init-workshop.sh`](../../scripts/init-workshop.sh) 재실행 |
| "권한이 없습니다" | 권한을 스스로 올리지 말고, 권한이 있는 다른 subscription·그룹으로 진행 |
| Skill이 리소스를 만들려 함 | "읽기 전용"을 다시 강조해 재요청 |

## 다음 Lab

[Lab 02: AKS 설계 결정하기](02-design-aks.md)
