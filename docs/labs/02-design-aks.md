# Lab 02: 3계층 설계 결정하기

**Lab 2 / 8** · 1부 · 설계와 검증

🎯 Quota·Network·SKU·권한 결정

🧠 `azure-quotas` · `azure-kubernetes` · `azure-enterprise-infra-planner`

> 🎬 Agent의 대안을 보고 배포할 구성을 선택합니다.

## 왜 필요한가요?

배포 후 바꾸기 어려운 Network·인증·SKU를 먼저 결정합니다.

## 시작 전에

- [Lab 01](01-orientation-and-setup.md)의 준비 검사와 Scope 확인을 마칩니다.

## Step 1. 설계 검토·선택하기

Day-0는 배포 전 결정입니다. 아래 후보를 **그대로 자동 적용하지 않고**, 검토 후 선택합니다.

| 항목 | 교육용 후보 |
| --- | --- |
| Region / Node | `koreacentral` / System D4s_v5 2대 + User D2s_v5 1대, 합계 10 vCPU |
| Network | VNet `10.60.0.0/16`, Azure CNI Overlay + Cilium |
| Pod / Service CIDR | `10.245.0.0/16` / `10.1.48.0/20` |
| DNS Service IP | `10.1.48.10` |
| ALB / PostgreSQL Subnet | `10.60.1.0/24` / `10.60.2.0/28` |
| Database | PostgreSQL `Standard_B1ms`, Private Access + Entra 인증 |

> 🧠 **Skill** `azure-quotas`, `azure-kubernetes`, `azure-enterprise-infra-planner` &nbsp;·&nbsp; 💬 **Copilot 채팅에 붙여넣기**

```text
azure-quotas, azure-kubernetes, azure-enterprise-infra-planner Skill로 3계층 설계를 검토해줘.

[읽을 값]
- 저장소 루트 .env와 Lab 02 본문의 교육용 후보

[검토·결정]
- Quota: DSv5 Family·Total Regional vCPU 한도와 사용량, SKU·AGC Region 지원
- AKS: System/User Pool, CNI Overlay·Cilium, AGC Add-on·Gateway API
- Network: CIDR 겹침, Subnet 크기, DNS Service IP 범위
- 인증: Egress /32 제한, Entra·Workload Identity, Private passwordless PostgreSQL
- 권한: 배포자·역할 할당자·각 Identity·lab 사용자의 Least Privilege 매트릭스
- 대안·위험·비용을 보여주고 Region·SKU·Node 수·CIDR은 내가 선택하게 해줘
- 결정된 값만 scripts/set-env.sh로 .env에 반영
- 근거와 결정·권한 매트릭스를 infra-report.md에 기록

[제약]
- Quota는 한도만 보지 말고 한도에서 사용량을 빼서 판단해줘
- 사람의 설계값을 자동 선택하지 마
- Azure 리소스·권한을 만들거나 바꾸지 마
- 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘
```

**완료 기준:** 선택값이 `.env`에 반영되고 설계 근거·권한 매트릭스가 기록됩니다.

## ✅ 완료 체크리스트

- [ ] Quota 여유로 Region·SKU·Node 수를 결정했다
- [ ] CIDR·인증·권한 경계를 확인했다
- [ ] 선택값과 근거가 `.env`·`infra-report.md`에 남았다

## 🚧 문제가 생겼다면

<details>
<summary>🔎 <b>Quota·CIDR·권한 확인 기준</b></summary>

| 문제 | 다음 조치 |
| --- | --- |
| Quota·Region 용량 부족 | 대안 Region·SKU·Node 수를 검토하고 사람이 다시 선택 |
| CIDR 겹침 | Pod·Service·VNet 간 겹침 제거, DNS는 Service CIDR 안에 배치 |
| Subnet 크기 부족 | ALB 최소 `/24`, PostgreSQL 최소 `/28` 확보 |
| 역할 생성·할당 권한 부족 | 필요한 작업과 Scope만 승인 요청. Owner·Cluster Admin 신규 부여 금지 |

CIDR은 IP 주소 범위입니다. Agent는 [`set-env.sh`](../../scripts/set-env.sh)로 결정값을 한 번에 반영합니다.
교육용 단일 User Node·Burstable Database는 운영용 고가용성 구성이 아닙니다.

</details>

## 다음 Lab

결정과 기록을 마친 뒤 [Lab 03: 계획 승인 + Bicep 생성](03-plan-and-bicep.md)으로 이동합니다.
