# 3계층 워크로드 인계 문서

## 범위와 상태

- 팀 / Scope / Region:
- 실행 일시:
- 최종 상태: 관측됨 / 부분 관측 / 미검증

## 결정과 승인

| 결정 | 근거 | 승인자 | 상태 |
| --- | --- | --- | --- |

## 실제 Azure 구성

- Application Gateway for Containers·AKS·PostgreSQL·VNet·Identity 구성과 관계:

## 실제 Kubernetes 구성

- Gateway·HTTPRoute·Deployment·Service 상태와 PostgreSQL Job 결과:

## E2E 증거

- Gateway Public URL의 HTTP 응답:
- PostgreSQL `successful_checks` 결과:

## 검증과 문제 해결

- `infra-report.md`의 근거 섹션:
- 실패 증상·원인:
- 복구 조치·재검증 결과:

## 미검증 및 정리

- 미검증 항목·비용 관찰의 한계:
- 잔여 리소스·권한·Scope:
- 삭제 승인·실행·재조회 또는 미삭제 사유:
- 리소스 유지 시 비용 책임자: