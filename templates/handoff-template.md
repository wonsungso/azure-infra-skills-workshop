# 3계층 워크로드 인계 문서

## 범위와 상태

- 팀 / Scope / Region:
- 실행 일시:
- 최종 상태: 관측됨 / 부분 관측 / 미검증

## 결정과 승인

| 결정 | 근거 | 승인자 | 상태 |
| --- | --- | --- | --- |

## 실제 Azure 구성

Application Gateway for Containers, AKS, PostgreSQL, VNet, Identity 관계를 기록한다.

## 실제 Kubernetes 구성

Gateway, HTTPRoute, Deployment, Service, PostgreSQL Job 결과를 기록한다.

## E2E 증거

- Gateway Public URL의 HTTP 응답:
- PostgreSQL `successful_checks` 결과:

## 검증과 문제 해결

`infra-report.md`의 해당 섹션, 실패 증상, 원인, 복구 조치, 재검증 결과를 기록한다.

## 미검증 및 정리

미검증 항목, 비용 관찰의 한계, 남은 리소스와 삭제 승인 상태를 기록한다.