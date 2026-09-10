# 실습 체크포인트

각 체크포인트는 해당 Lab을 마쳤을 때 체크합니다. 체크가 안 되면 다음 Lab으로 넘어가지 말고 해당 Lab의 "🚧 문제가 생겼다면" 표를 먼저 확인하세요.

| 체크포인트 | 대응 Lab | 완료 기준 | 증거 위치 | 상태 |
| --- | --- | --- | --- | --- |
| C1 준비 완료 | [Lab 01](../docs/labs/01-orientation-and-setup.md) | 역할 이해, 입력표 완료, scope 확인 | evidence-log | 미완료 |
| C2 설계 결정 | [Lab 02](../docs/labs/02-design-aks.md) | Day-0 결정표와 최소 권한 매트릭스 정리 | evidence-log | 미완료 |
| C3 계획/Bicep | [Lab 03](../docs/labs/03-plan-and-bicep.md) | 계획 승인, Bicep 생성 | `.azure/infrastructure-plan.json`, `infra/` | 미완료 |
| C4 검증/배포승인 | [Lab 04](../docs/labs/04-validate-and-approve.md) | build/검사 결과 기록, 명시적 배포 승인 | evidence-log | 미완료 |
| C5 배포/접속 | [Lab 05](../docs/labs/05-deploy-and-connect.md) | nodes Ready, Entra 접속과 최소 권한 확인 | evidence-log | 미완료 |
| C6 워크로드 | [Lab 06](../docs/labs/06-run-sample-workload.md) | Deployment, Pod, EndpointSlice, HTTP 응답 확인 | evidence-log | 미완료 |
| C7 진단/복구 (선택) | [Lab 07](../docs/labs/07-diagnose-and-recover.md) | 오류 원인과 정상 복구를 기록 | evidence-log | 미완료 |
| C8 문서화/정리 | [Lab 08](../docs/labs/08-document-and-cleanup.md) | Azure/Kubernetes 계층 분리 인계 문서, 승인된 삭제와 잔여 리소스 재조회 | handoff-template, evidence-log | 미완료 |