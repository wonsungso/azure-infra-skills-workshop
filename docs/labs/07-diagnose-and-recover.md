# Lab 07: 진단과 복구 (선택)

**Lab 7 / 8** · 2부 · 실행과 마무리

🎯 장애 증거·서비스 영향·승인 후 복구

🧠 `azure-diagnostics`

> 🎬 잘못된 이미지로 만든 장애를 실제 증거로 진단합니다.

## 왜 필요한가요?

- Agent가 승인된 이미지 오류를 주입하고 Events·Pod 상태·HTTP 응답으로 원인과 영향을 조사합니다.
- 별도 복구 승인 후 원래 이미지를 되돌리고, 정상 상태의 HTTP·SQL 증거와 다시 비교합니다.
- 원인을 추측으로 단정하지 않고, 장애 관측부터 복구 확인까지 근거로 이어지는지 연습하는 단계입니다.

## 시작 전에

- [Lab 06](06-run-sample-workload.md)의 정상 HTTP·SQL 증거를 준비합니다.

## Step 1. 승인 → 장애 → 진단 → 복구

이 프롬프트는 장애 주입·진단·복구를 이어서 진행하되, 주입과 복구 변경은 각각 승인을 받습니다.

> 🧠 **Skill** `azure-diagnostics` &nbsp;·&nbsp; 💬 **Copilot 채팅에 붙여넣기**

```text
azure-diagnostics Skill로 내 실습 환경의 이미지 장애를 진단·복구해줘.

[진행 순서]
- .env의 AKS Scope와 .azure/workshop.kubeconfig 대상 일치 확인
- scripts/workshop.sh verify로 정상 상태 확인, 이미지·응답 Pod 보존
- lab-web의 web 이미지 변경 대상·영향을 설명하고 주입 승인 요청
- 승인 후 nginxinc/nginx-unprivileged:does-not-exist로 web 이미지만 변경
- 실제 Events·Pod 상태로 원인 진단, 기존 Pod·Public HTTP 영향도 확인
- 진단 결과와 원래 이미지 복원을 설명하고 별도 복구 승인 요청
- 승인 후 원래 이미지 복원, rollout Ready와 정확한 이미지 확인
- bash scripts/workshop.sh verify로 읽기 전용 재검증
- 증상·원인·서비스 영향·승인·복구 결과를 infra-report.md의 Incident 장에 기록

[제약]
- 주입·복구 승인을 각각 받기 전에는 해당 변경을 실행하지 마
- 예상한 ImagePullBackOff에서 실패 rollout 완료를 기다리지 마
- 정상 이미지가 없거나 다른 변경이 섞였으면 추측하지 말고 멈춰
- Manifest 적용이나 Pod 삭제·재생성은 반복하지 마
- 권한·IP 제한을 완화하지 마
- 이 Skill을 쓸 수 없으면 다른 방법으로 대신하지 말고 먼저 알려줘
```

**완료 기준:** 실제 오류 원인 확인, 기존 서비스 영향 관측, 정상 이미지·HTTP·SQL 복구.

## ✅ 완료 체크리스트

- [ ] 진단이 실제 Events·Pod 상태에 근거한다
- [ ] 장애 중 기존 Pod·Public HTTP 결과를 기록했다
- [ ] 별도 승인 후 복구·재검증을 마쳤다

## 🚧 문제가 생겼다면

<details>
<summary>🔎 <b>예상 장애와 복구 확인</b></summary>

`ImagePullBackOff`는 이미지를 가져오지 못한 상태입니다. 이 Lab에서는 의도한 증상입니다.
기존 Pod가 살아 있다면 복구 후에도 이름이 같습니다. 응답과 Pod 상태를 함께 확인합니다.

| 문제 | 다음 조치 |
| --- | --- |
| 원인이 불명확 | 실제 Events·이미지 참조·Pod 상태 추가 수집 |
| 복구 후 실패 | 주입 전 기록과 달라진 항목 확인. 원인 해결 전 정리 외 다음 단계 중단 |
| 원래 이미지가 없음 | 추측·무조건 rollout undo 금지. 변경 이력과 [Manifest](../../reference/kubernetes/lab-web.yaml) 대조 |

<img src="../../img/lab07-diagnose.png" alt="ImagePullBackOff와 기존 Running Pod, Events와 복구 예시" width="760">

</details>

## 다음 Lab

복구·재검증을 마친 뒤 [Lab 08: 문서화 + 정리](08-document-and-cleanup.md)로 이동합니다.
