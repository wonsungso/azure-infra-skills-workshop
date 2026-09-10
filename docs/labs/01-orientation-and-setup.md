# Lab 01: 워크샵 시작하기

**Lab 1 / 8** · 1부 · 설계와 검증 · ⏱ 30분

🎯 Skill·도구·사람의 역할 구분 / 입력값 확정 / 내 Azure 범위를 읽기 전용으로 확인

> 🎬 팀장의 요청을 방금 받았습니다. 서두르기 전에 **내가 무엇을 건드릴 수 있는 사람인지**부터 확인합니다.

## 왜 필요한가요?

Skill에게 작업을 요청하면 Skill은 절차와 판단 기준을, MCP 도구와 CLI는 실행을 담당합니다. 하지만 **무엇을 승인할지, 결과가 진짜인지 확인하는 것은 사람의 몫**입니다. 이 랩에서 그 역할을 이해하고, 이후 모든 프롬프트가 공유할 입력값을 확정합니다.

## 시작 전에

- [README](../../README.md)의 시작하기를 마치고 `my-inputs.md`에 **workshop ID가 채워져 있는지** 확인했나요?
- Codespace 터미널에서 `az login`으로 로그인했나요?

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

> [!TIP]
> 헷갈리면 "지금 이 작업이 Azure를 바꾸나요, 읽기만 하나요?"를 먼저 물어보세요.

## Step 2. 입력값 확인하고 채우기 (10분)

이후 모든 프롬프트가 이 값을 공유합니다. **`my-inputs.md`는 이미 만들어져 있습니다.** Codespace가 생성될 때 workshop ID와 리소스 이름이 자동으로 채워졌습니다.

```bash
cat my-inputs.md
```

> [!NOTE]
> 파일이 없다면 `bash scripts/init-workshop.sh`로 만듭니다. 이 파일은 `.gitignore`에 등록돼 있어 커밋되지 않습니다.

빈 칸을 채워 나갑니다. **이번 Lab에서 채울 것**은 두 가지입니다.

| 항목 | 어떻게 |
| --- | --- |
| subscription ID 또는 scope | Step 3에서 조회 |
| egress IP | 아래에서 지금 조회 |

region, CIDR, VM SKU는 Lab 02에서 quota를 확인한 뒤 채우고, node resource group은 Lab 05 배포 후 output으로 채웁니다.

**egress IP를 지금 조회합니다.** AKS API server에 접근할 수 있는 유일한 주소가 됩니다.

```bash
curl -s https://api.ipify.org
```

조회된 값을 `<IP>/32` 형식으로 기록하세요.

> [!IMPORTANT]
> Codespace에서 실행하면 내 PC의 IP가 아니라 **Codespace의 egress IP**가 나옵니다. authorized IP ranges에는 이 값을 넣어야 하므로, 반드시 **Codespace 터미널에서** 조회하세요.
>
> Codespace를 중지했다가 다시 시작하면 이 IP가 바뀔 수 있습니다. Lab 05 이후 API server 접속이 갑자기 안 되면 이 값부터 다시 확인합니다.

> [!WARNING]
> 확실하지 않은 값을 추측해서 채우지 마세요. 이후 모든 프롬프트가 잘못된 전제를 쓰게 됩니다. 비밀번호, token, kubeconfig 내용은 절대 적지 않습니다.

## Step 3. 내 Azure 범위 확인하기 (15분)

**사용 Skill:** `azure-resource-lookup`

```text
azure-resource-lookup을 사용해 내 subscription과 [resource-group]을 읽기 전용으로 확인해줘. 리소스를 생성·변경·삭제하지 말고, 접근 불가 항목은 권한 부족으로 구분해줘.
```

**확인할 것**

- 조회된 subscription·region이 `my-inputs.md`와 같은가?
- resource group이 없다면 **지금 만들지 않고** 이름만 확정합니다. 생성은 Lab 05에서 배포와 함께 합니다.
- 그룹에 다른 리소스가 이미 있다면, Lab 08에서 실수로 지우지 않도록 목록을 기록해 둡니다.

<details>
<summary>💡 <b>Skill을 안 썼다면?</b></summary>

| 방식 | 이 단계에서 벌어지는 일 |
| --- | --- |
| 🖐 수동 | `az account show`, `az group show`를 직접 조합한다. **무엇을 확인해야 하는지** 스스로 알아야 한다. |
| 💬 일반 프롬프트 | 실제 조회 없이 그럴듯한 결과를 지어낼 수 있다. 읽기 전용이라는 보장도 없다. |
| ⚡ Skill | 조회 도구를 실제로 호출하고, 접근 불가 항목을 **권한 부족으로 구분**해 알려준다. |

</details>

## ✅ 완료 체크리스트

- [ ] `my-inputs.md`에 workshop ID와 리소스 이름이 채워진 것을 확인했다
- [ ] Codespace 터미널에서 egress IP를 조회해 기록했다
- [ ] 조회 결과가 `my-inputs.md`와 일치함을 확인했다
- [ ] [증거 로그](../../templates/evidence-log.md)에 기록했다

## 🚧 문제가 생겼다면

| 증상 | 해야 할 일 |
| --- | --- |
| 조회 결과가 입력표와 다름 | `az account show`로 현재 subscription 확인 후 정정 |
| subscription이 여러 개라 헷갈림 | `az account list -o table` → `az account set --subscription <id>` |
| "권한이 없습니다" | 권한을 스스로 올리지 말고, 권한이 있는 다른 subscription·그룹으로 진행 |
| Skill이 리소스를 만들려 함 | "읽기 전용"을 다시 강조해 재요청 |

## 다음 Lab

[Lab 02: AKS 설계 결정하기](02-design-aks.md)
