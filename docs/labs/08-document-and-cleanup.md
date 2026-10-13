# Lab 08: 문서화 + 정리

**Lab 8 / 8** · 2부 · 실행과 마무리

🎯 실제 구성 인계·승인 후 삭제·잔여 확인

🧠 `azure-resource-lookup` · `azure-resource-visualizer`

> 🎬 기록을 인계 문서로 묶고 실습 비용을 정리합니다.

## 왜 필요한가요?

실제 결과를 인계하고 삭제 후 잔여 리소스·권한을 확인합니다.

## 시작 전에

- [Lab 06](06-run-sample-workload.md) 결과를 준비합니다. 중단했다면 미완료 상태로 정리만 요청합니다.

## Step 1. 인계·정리 맡기기

> 🧠 **Skill** `azure-resource-lookup`, `azure-resource-visualizer` &nbsp;·&nbsp; 💬 **Copilot 채팅에 붙여넣기**

```text
azure-resource-lookup과 azure-resource-visualizer Skill로 인계·정리를 진행해줘.

[읽을 값]
- .env, infra-report.md, templates/handoff-template.md
- Kubernetes 조회에는 .azure/workshop.kubeconfig 사용, 실제 AKS 대상 확인

[진행 순서]
- Workshop·Node Resource Group, Kubernetes 실제 구성과 실습 역할 조회
- 관측·설계·추정·미검증을 구분해 Mermaid와 인계 문서 작성
- assets/azure-icons/README.md 형식으로 .azure/architecture-spec.json 작성
- scripts/build-architecture-svg.sh로 .azure/my-architecture.svg 생성
- .azure/handoff.md에 그림·HTTP/SQL 증거·미검증·비용 책임 포함
- 실습 삭제 대상·의존성·데이터 손실을 표로 보여주고 명시적 승인 요청
- 승인 후 Gateway·ApplicationLoadBalancer부터 삭제, Azure AGC·Frontend·Association 정리 대기
- 실습 역할 할당·bootstrap Custom Role과 Resource Group 정리,
  AKS 소유 Node Resource Group 삭제 완료까지 대기
- 두 그룹·리소스·역할 재조회, Cleanup 장과 인계 문서를 최종 갱신

[제약]
- 실제 삭제 작업은 명시적 승인 전에는 수행하지 마
- 기존 리소스·공용 역할은 삭제 대상에서 제외
- Finalizer를 강제로 제거하거나 권한을 넓히지 마
- 미삭제 선택 시 잔여 항목·지속 비용을 기록하고 멈춰
- 실패하면 남은 항목을 기록하고 멈춰
- 양식 원본은 변경하지 마. 실제 값·Credentials·Token은 커밋하지 마
- 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘
```

**완료 기준:** 로컬 인계 문서 **및** 삭제·재조회 증거, 또는 미삭제 사유·비용 책임.

> [!WARNING]
> **미삭제 리소스는 계속 과금됩니다.** 중간에 멈췄어도 정리 결과를 확인하세요.

## ✅ 완료 체크리스트

- [ ] 실제 구성·E2E 증거·미검증 항목이 인계됐다
- [ ] 삭제를 명시적으로 승인했거나 미삭제 책임을 기록했다
- [ ] 두 그룹과 실습 역할의 최종 잔여 상태를 재조회했다

## 🚧 문제가 생겼다면

<details>
<summary>🔎 <b>정리 순서·인계 파일</b></summary>

| 문제 | 다음 조치 |
| --- | --- |
| ALB 삭제 대기 | Controller의 Azure 정리·Finalizer 완료 대기. 강제 제거 금지 |
| Custom Role 잔여 | 보고서의 실습 Role만 조회, 참조 할당 제거 후 정리 |
| 삭제 실패 | 남은 리소스·역할·비용과 실제 오류 기록. 삭제 성공으로 표시하지 않음 |
| 증거가 없음 | 예상·미검증으로 표기. E2E 통과를 가정하지 않음 |

Finalizer는 Controller의 외부 자원 정리가 끝날 때까지 삭제를 보류하는 표시입니다.
[`handoff-template.md`](../../templates/handoff-template.md) 원본은 유지합니다.
SVG는 [`build-architecture-svg.sh`](../../scripts/build-architecture-svg.sh)로 생성하며,
아이콘 이용 조건은 [`README.md`](../../assets/azure-icons/README.md)를 따릅니다.

<img src="../../img/example-architecture.svg" alt="Azure 공식 아이콘으로 구성한 인계 그림 예시" width="620">

</details>

## 다음 Lab

워크샵을 마쳤습니다. 최종 인계와 잔여 상태를 확인하고 [README](../../README.md)로 돌아갑니다.
