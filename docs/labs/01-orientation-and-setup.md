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

## Step 1. 역할 이해하기 (5분)

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

## Step 2. Azure에 로그인하기 (5분)

**이 단계는 사람이 직접 해야 합니다.** 로그인은 본인 계정의 credentials를 다루는 일이라 Skill이나 스크립트에 맡기지 않습니다.

Codespace는 원격 컨테이너라 브라우저가 자동으로 열리지 않습니다. **device code 방식**을 씁니다.

```bash
az login --use-device-code
```

터미널에 나온 코드를 복사해, 함께 표시된 주소를 브라우저에서 열고 붙여넣습니다. 브라우저에서 인증이 끝나면 터미널이 알아서 다음으로 넘어갑니다.

subscription이 여러 개라면 이 워크샵에서 쓸 것을 직접 고릅니다.

```bash
az account list --query "[].{name:name, id:id, default:isDefault}" -o table
az account set --subscription "<사용할 subscription 이름 또는 id>"
```

## Step 3. 입력값 확인하기 (5분)

이후 모든 프롬프트가 저장소 루트의 `.env`를 공유합니다. **직접 타이핑할 값은 없습니다.** Codespace가 만들어질 때 리소스 이름과 egress IP가 채워졌고, 로그인을 마친 지금 아래를 한 번 더 실행하면 subscription까지 채워집니다.

```bash
bash scripts/init-workshop.sh
cat .env
```

| 항목 | 채우는 방식 |
| --- | --- |
| `WORKSHOP_ID`와 리소스 이름 | Codespace 생성 시 자동 |
| `EGRESS_IP_CIDR` | 자동 (ipify 조회) |
| `SUBSCRIPTION_ID` | 자동 (Step 2 로그인 후 재실행) |
| `REGION`, CIDR, VM SKU | **Lab 02에서 내가 결정** |
| `NODE_RESOURCE_GROUP` | Lab 05 배포 후 output |

자동으로 알 수 있는 값과 **사람이 결정해야 하는 값**을 구분하세요. 뒤의 네 가지는 quota와 기존 네트워크를 보고 판단해야 해서 자동화할 수 없습니다.

`EGRESS_IP_CIDR`은 내 PC가 아니라 **Codespace의 egress IP**입니다. AKS API server에 접근할 수 있는 유일한 주소가 되므로 반드시 Codespace 안에서 조회된 값이어야 합니다. Codespace를 중지했다가 다시 시작하면 이 IP가 바날 수 있으므로, Lab 05 이후 접속이 갑자기 안 되면 [`init-workshop.sh`](../../scripts/init-workshop.sh)를 다시 실행해 갱신하세요.

비밀번호, token, kubeconfig 내용은 `.env`에 적지 않습니다. 이 파일은 `.gitignore` 대상이므로 커밋되지 않습니다.

## Step 4. 내 Azure 범위 확인하기 (10분)

먼저 **빠른 방법**으로 확인합니다. 단순 조회는 CLI가 몇 초면 끝납니다.

```bash
bash scripts/log-evidence.sh "Lab 01 Step 4" "az CLI" -- az account show -o table
```

결과를 보여주면서 동시에 저장소 루트의 `evidence-log.md`에 한 줄을 기록합니다. 따로 적을 필요가 없습니다. 어떤 칸을 사람이 채워야 하는지는 [증거 로그 양식](../../templates/evidence-log.md)에 설명되어 있습니다.

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
azure-resource-lookup으로 내 subscription에서 [resource-group]의 존재 여부만 확인해줘. 없으면 "없음", 접근이 막혀 있으면 권한 부족으로 구분해서 한 줄로 답해줘. 리소스를 만들거나 바꾸지 마.
```

**Skill 응답은 CLI보다 느립니다.** 도구를 여러 번 호출하고 결과를 해석하기 때문입니다. 그만큼 값어치가 있는 질문에 써야 합니다.

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

- [ ] `az login --use-device-code`로 로그인하고 쓸 subscription을 선택했다
- [ ] `.env`의 `SUBSCRIPTION_ID`와 `EGRESS_IP_CIDR`이 채워진 것을 확인했다
- [ ] 조회한 subscription이 `.env`와 일치함을 확인했다
- [ ] [증거 로그](../../templates/evidence-log.md) 형식의 `evidence-log.md`에 실행 기록이 남았다
- [ ] 단순 조회와 판단을 각각 어떤 도구로 하는지 설명할 수 있다

## 🚧 문제가 생겼다면

| 증상 | 해야 할 일 |
| --- | --- |
| `az login`이 브라우저를 못 열고 멈춤 | `--use-device-code`를 붙였는지 확인 |
| 로그인은 됐는데 subscription이 안 보임 | 게스트 계정일 수 있음. `az login --use-device-code --tenant <tenant-id>` |
| `SUBSCRIPTION_ID`가 비어 있음 | 로그인 후 [`init-workshop.sh`](../../scripts/init-workshop.sh)를 다시 실행 |
| 조회 결과가 `.env`와 다름 | `az account set --subscription <id>` 후 [`init-workshop.sh`](../../scripts/init-workshop.sh) 재실행 |
| "권한이 없습니다" | 권한을 스스로 올리지 말고, 권한이 있는 다른 subscription·그룹으로 진행 |
| Skill이 리소스를 만들려 함 | "읽기 전용"을 다시 강조해 재요청 |

## 다음 Lab

[Lab 02: AKS 설계 결정하기](02-design-aks.md)
