# AI 에이전트 가이드라인

이 파일에는 이 저장소에서 작업하는 AI 에이전트를 위한 지침과 가이드라인이 들어 있습니다.

## 🔒 보안 모범 사례

**민감한 정보를 이 저장소에 절대 커밋하지 마세요.**

- API 키, 토큰, credentials
- 개인용 액세스 토큰(PAT)
- 암호가 포함된 데이터베이스 연결 문자열
- 환경별 구성 값

### 이 저장소에서 특히 위험한 값

이 워크샵은 실제 Azure 리소스를 다루므로, 명령 출력과 스크린샷에 아래 값이 섞여 들어가기 쉽습니다. **모두 커밋 금지 대상입니다.**

| 값 | 어디서 새어 나오나 | 대신 쓸 것 |
| --- | --- | --- |
| subscription ID, tenant ID, 사용자/객체 ID | `az account show`, `az deployment` 출력 | `<subscription-id>`, `<tenant-id>` |
| 개인 egress IP | Lab 01의 IP 조회, `authorizedIpRanges` | `<your-ip>/32` |
| kubeconfig 내용, 클러스터 인증서, 토큰 | `az aks get-credentials`, `kubectl config view` | 절대 붙여넣지 않음 |
| AKS FQDN, node resource group 실명 | `az aks show` 출력 | `<aks-fqdn>`, `MC_<rg>_<aks>_<region>` |
| 로그인 계정 이메일(UPN) | `az account show`, 오류 메시지 | `<user>@<tenant>` |

`kubectl config view`는 기본적으로 credentials를 출력합니다. 문서나 이슈에 붙여넣어야 한다면 반드시 `kubectl config view --raw=false --minify` 수준으로 줄이고, 그래도 남는 인증 필드는 직접 지우세요. 더 안전한 방법은 붙여넣지 않는 것입니다.

### 문서와 템플릿에 값을 기록할 때

- [인계 문서](templates/handoff-template.md)는 **참가자가 자기 환경에서 로컬로 채우는 양식**입니다. 실제 값을 채운 상태로 커밋하지 마세요.
- 워크샵 공용 값은 저장소 루트의 `.env`에, Lab 결과는 `infra-report.md`에 들어 있으며 둘 다 `.gitignore` 대상입니다. 이 파일을 커밋하거나 내용을 문서·이슈에 붙여넣지 마세요.
- 저장소에 커밋되는 것은 **자리 표시자가 들어간 빈 양식**뿐이어야 합니다.
- 실제 값이 필요한 예시는 `<subscription-id>` 처럼 꺾쇠 자리 표시자를 쓰거나, 형태만 알 수 있게 마스킹합니다(예: `10.245.x.x`).

### 스크린샷과 터미널 출력

- 스크린샷을 추가하기 전에 **subscription ID, 계정 이메일, IP, 토큰이 화면에 없는지** 확인하고 필요하면 가립니다.
- 터미널 캡처는 프롬프트 줄(사용자명·호스트명)이 포함되기 쉽습니다. 잘라내거나 마스킹하세요.
- 브라우저 캡처는 주소 표시줄과 확장 프로그램 배지에 정보가 노출될 수 있으므로 콘텐츠 영역만 캡처합니다.

### MCP 구성 파일(`mcp.json`)의 경우

- `"YOUR_API_KEY_HERE"` 또는 `"${API_KEY}"` 같은 자리 표시자 값을 사용하세요
- 민감한 데이터는 환경 변수를 참조하세요
- 필요한 환경 변수에 대한 문서를 포함하세요

### 커밋 전 점검

에이전트는 커밋 또는 푸시 직전에 **추적 대상 파일만** 대상으로 아래를 실행하고, 결과가 비어 있는지 확인합니다. 이 파일 자체는 아래 패턴 문자열을 담고 있어 스스로 매칭되므로 제외합니다.

```bash
hits=$(git ls-files -z -- . ':!AGENTS.md' | xargs -0 grep -nEI \
  "[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}|onmicrosoft\.com|BEGIN [A-Z ]*PRIVATE KEY|client_secret|Bearer [A-Za-z0-9._-]{20,}|ghp_[A-Za-z0-9]{20,}|github_pat_")
if [ -n "$hits" ]; then printf '%s\n' "$hits"; echo "확인 필요: 커밋하지 마세요"; else echo "클린: 민감정보 없음"; fi
```

종료 코드로 판정하지 마세요. `xargs`는 `grep`이 "일치 없음(1)"을 반환해도 `123`을 돌려주기 때문에, 종료 코드만 보면 잘못 판단합니다. **출력이 비어 있는지**로 판정해야 합니다.

`assets/azure-icons/*.svg`와 `img/*.svg`는 `linearGradient id`가 GUID 형식이라 위 패턴에 걸립니다. 이것만으로 유출이라고 단정하지 말고, 실제 값과 대조해 확인하세요.

```bash
grep -rqF "$(az account show --query id -o tsv)" . && echo "실제 유출" || echo "오탐"
```

무언가 걸리면 **커밋하지 말고 사용자에게 먼저 알립니다.** 이미 커밋된 뒤라면 파일 수정만으로는 히스토리에서 지워지지 않으므로, 해당 credentials를 **폐기(rotate)** 하는 것이 우선입니다.

에이전트는 사용자의 비밀값을 대화로 요청하지 않습니다. 비밀번호, 토큰, 연결 문자열이 필요하면 사용자가 터미널이나 환경 변수에 직접 입력하도록 안내하고, 그 값을 다시 출력하거나 파일에 쓰지 않습니다.

## 🧾 Lab 프롬프트를 수행할 때

이 절은 **참가자가 `docs/labs/`의 프롬프트를 실행했을 때**만 적용됩니다. 저장소를 수정하는 작업에는 해당하지 않습니다.

조사·검토·판단을 마쳤으면 **사용자가 시키지 않아도** 그 결과를 보고서에 남깁니다. 참가자가 매번 기록 명령을 치게 하지 않습니다.

채팅에 보여준 **표·목록·설명을 그대로** 넣습니다. 한 줄 요약으로 줄이지 않습니다.

```bash
bash scripts/add-report.sh <장> "<한 줄 제목>" "<쓴 Skill 또는 도구>" <<'EOF'
<답변에 쓴 markdown 본문 그대로>
EOF
```

Azure를 조회하는 단계는 명령과 출력을 그대로 남기는 쪽이 정확합니다.

```bash
bash scripts/add-report.sh --run <장> "<제목>" "<도구>" -- <명령...>
```

장은 작업 성격에 맞춰 고릅니다. Lab 번호가 아니라 **보고서에서 그 내용이 있어야 할 자리**로 봅니다.

| 장 | 들어갈 내용 |
| --- | --- |
| `env` | subscription·scope 확인, 접근 경로 |
| `capacity` | quota와 용량 판정 |
| `design` | Day-0 선택과 CIDR·SKU 결정 |
| `access` | 역할과 scope, least privilege |
| `plan` | 인프라 계획, 승인, 생성된 IaC |
| `validate` | build, 보안 검사, what-if 결과 |
| `deploy` | 배포 결과와 생성된 자원 |
| `workload` | 샘플 워크로드와 계층별 검증 |
| `incident` | 장애 증상, 원인, 복구 |
| `cleanup` | 삭제 대상, 승인, 잔여 자원 |

- 결론은 **판단과 근거가 드러나게** 씁니다. "확인했습니다" 같은 내용 없는 문장은 남기지 않습니다.
- 조회 결과가 **검증되지 않은 추정**이면 본문에 그렇게 적습니다.
- 사람이 정해야 하는 값(region, SKU, 승인 여부)을 **대신 결정해 기록하지 않습니다.** 결정을 물어본 뒤 그 답을 기록합니다.

## ☁️ Azure 작업 규칙

- **읽기와 쓰기를 구분합니다.** 조회는 자유롭게, 생성·변경·삭제는 대상과 영향을 확인한 뒤 사용자 승인을 받고 수행합니다.
- **비용이 발생하는 리소스**(AKS node 등)를 만들었다면 반드시 사용자에게 알리고, 정리 방법을 함께 안내합니다.
- 접속 오류를 해결하려고 `authorizedIpRanges`에 `0.0.0.0/0`을 넣거나 허용 목록을 비우지 않습니다.
- 권한 문제를 우회하려고 사용자에게 Owner나 cluster-admin을 부여하도록 제안하지 않습니다.
- [`reference/infra/main.bicep`](reference/infra/main.bicep)의 `testingMode`는 기본값 `false`를 유지합니다. 역할 할당이 차단된 제한 subscription에서 테스트할 때만 예외적으로 사용합니다.

## 📋 저장소 가이드라인

### 커밋 메시지

커밋 메시지는 **영어로** 씀니다. 제목은 명령형 현재시제 한 줄이고, 본문이 필요하면 무엇을 왜 바꿨는지 적습니다. 문서 본문은 한국어를 유지합니다.

```text
Auto-fill .env and evidence log from the environment

Participants had to type values the tooling already knows.
```

### 목적

이 저장소는 **Azure Skills를 사용해 AKS 인프라를 설계·검증·배포·문서화하는 6시간 자기주도형 워크샵**입니다.

- 참가자가 **강사 없이 혼자서** Lab 01부터 Lab 08까지 순서대로 완주할 수 있어야 합니다
- 각 Lab은 앞 Lab의 산출물을 입력으로 사용하는 하나의 연속된 흐름입니다
- AKS는 소재일 뿐이고, 핵심은 "계획 승인 → 코드 → 검증 → 배포 승인 → 배포"라는 안전한 절차입니다
- 실행 환경은 **GitHub Codespaces**가 기본입니다. 도구 설치는 `.devcontainer/`가 담당하므로, Lab 문서에 설치 절차를 다시 쓰지 않습니다
- 프롬프트와 입력값은 **해당 Lab 본문 안에** 둡니다. 별도의 프롬프트 모음 파일이나 입력표 파일을 다시 만들지 않습니다
- **기계가 알 수 있는 값은 사람이 타이핑하게 하지 않습니다.** 조회로 얻는 값은 [`scripts/init-workshop.sh`](scripts/init-workshop.sh)가 채우고, 사람이 결정한 값은 [`scripts/set-env.sh`](scripts/set-env.sh)로 반영하며, Lab 결과는 [`scripts/add-report.sh`](scripts/add-report.sh)가 보고서로 쌓습니다. 문서에 "손으로 적으세요"라고 쓰지 않습니다
- **프롬프트에 값을 직접 적지 않습니다.** `[resource-group]` 같은 자리 표시자를 두고 사람이 치환하게 하는 대신, "저장소 루트의 .env에서 RESOURCE_GROUP을 읽어"처럼 **Skill이 직접 읽도록** 씁니다. 비어 있는 값은 추측하지 말고 멈추라고 붙입니다
- 반대로 **판단이 필요한 값**(CIDR, SKU, node 개수, 승인 여부)은 자동으로 정하지 않습니다. 사람이 결정하고 도구는 기록만 돕습니다. `REGION`만은 바로 시작할 수 있도록 `koreacentral` 기본값을 두되, Lab 02에서 quota를 보고 확인하게 합니다
- **프롬프트에는 Skill 이름 뒤에 `Skill`을 붙입니다.** `azure-kubernetes를 사용해`라고만 쓰면 에이전트가 같은 이름의 **도구**를 찾다 실패하고 다른 방법으로 조용히 대체합니다. 모든 Skill 프롬프트는 "이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘."로 끝납니다
- **Skill은 이 저장소에 커밋하지 않습니다.** Codespace가 만들어질 때 [`post-create.sh`](.devcontainer/post-create.sh)가 `microsoft/azure-skills`에서 필요한 것만 `.github/skills/`로 복사하며, 이 경로는 `.gitignore` 대상입니다. 워크샵이 쓰는 Skill을 바꿀 때는 `WORKSHOP_SKILLS` 목록과 Lab 01 Step 2의 확인 프롬프트를 함께 고칩니다
- 참조하려는 Skill이 `microsoft/azure-skills`의 `skills/`에 **실제로 있는지 확인하고 씁니다.** 그 목록은 바뀝니다(예: `azure-rbac`은 2026-07에 제거됨)
- Step 제목에 **소요시간을 적지 않습니다.** 진도가 사람마다 달라 지키기 어렵고, 뒤처진다는 느낌만 줍니다. 전체 분량은 Lab 머리말의 ⏱ 표기로만 안내합니다

### 용어 표기

Azure·Kubernetes 기술 용어는 **영어를 그대로** 씁니다. 번역하지 않습니다.

| 쓰기 | 쓰지 않기 |
| --- | --- |
| egress IP | 출구 IP, 공인 출구 IP |
| authorized IP ranges | 허용 IP 목록 |
| subscription, tenant, region | 구독, 테넌트, 리전 |
| resource group, node, node pool | 리소스 그룹, 노드, 노드풀 |
| quota, credentials, manifest | 쿼터, 자격 증명, 매니페스트 |

### 콘텐츠 규칙

- 저장소에 대용량 바이너리 파일(PowerPoint 덱, 동영상, 녹화본)을 두지 않음
- 앱 소스 코드와 Dockerfile을 추가하지 않음. 이 워크샵은 **앱 코딩과 컨테이너 이미지 빌드를 범위에서 제외**함
- 샘플 워크로드는 `lab` namespace의 ClusterIP만 사용하고 외부 LoadBalancer나 Ingress를 만들지 않음
- 모든 README와 Lab 문서의 상대 링크는 항상 유효해야 함
- **저장소에 있는 파일을 본문에서 언급할 때는 링크를 겁니다.** 파일명은 백틱으로 감싸고, 링크 대상은 그 문서 위치 기준 상대 경로로 씁니다. 예를 들어 [`set-env.sh`](scripts/set-env.sh)를 Lab 문서에서 가리키려면 경로가 `../../scripts/set-env.sh`가 됩니다. 단, `.env`나 `infra-report.md`처럼 **실행 중에 생성되는 파일**은 저장소에 없으므로 링크하지 않습니다. 연결할 양식이나 생성 스크립트가 있다면 그쪽을 링크합니다
- 강사 전용 자료를 다시 만들지 않음. 모든 작업은 참가자가 직접 수행하는 형태로 서술함

### 검증되지 않은 것을 검증된 것처럼 쓰지 않기

- 실제로 실행하지 않은 결과는 `예상` 또는 `미검증`으로 표기합니다
- "동작합니다"라고 쓰려면 실행 증거가 있어야 합니다
- `port-forward` 성공은 외부 공개나 클러스터 내부 DNS 통신의 증거가 아닙니다

### 문서 스타일

- 초심자가 읽는 문서이므로, 용어를 처음 쓸 때는 한 줄로 풀어 설명합니다
- 각 Lab의 머리말은 다음 순서를 지킵니다: `# 제목` → `**Lab N / 8** · 부 · ⏱ 시간` → `🎯 목표` → `🧠 사용 Skill` → `> 🎬 도입부`
- 각 Lab 본문은 다음 순서를 따릅니다: 왜 필요한가 → 시작 전에 → Step → 완료 체크리스트 → 문제가 생겼다면 → 다음 Lab
- 복사해서 바로 쓸 수 있는 프롬프트는 ` ```text ` 블록에 넣습니다
- **모든 프롬프트 블록 바로 위에는 배지 한 줄**을 둡니다. 이 워크샵의 핵심이 Skill과 프롬프트이므로 눈에 띄어야 합니다

  ```text
  > 🧠 **Skill** `skill-name` &nbsp;·&nbsp; 📋 **아래 프롬프트를 복사해 실행**
  ```

  Skill을 쓰지 않는 프롬프트는 `> 📋 **아래 프롬프트를 복사해 실행**`만 붙입니다.
- 강조는 기본적으로 **본문 문장과 굵게**로 합니다. GitHub Alert(`> [!WARNING]`)는 Codespace 내부 에디터에서 깨져 보이고 많아지면 오히려 안 읽힐니다. **문서 하나에 최대 1개**만 쓰고, 무시했을 때 돈이 나가거나 되돌릴 수 없는 일에만 한정합니다
