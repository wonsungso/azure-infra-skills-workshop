# 워크샵 설계 결정

> 이 문서는 "왜 이렇게 설계했는가"를 담고 있습니다. 처음 참가한다면 가볍게 훑어보고, [Lab 01](labs/01-orientation-and-setup.md)에서 실습을 시작하면서 다시 참고해도 좋습니다.

## 확정 사항

- Azure Skills로 설계, 검증, 배포, 문서화하는 경험이 핵심이며 AKS는 시나리오다.
- 참가자 조마다 단일 리전의 전용 AKS 클러스터를 사용한다.
- Bicep 단일 트랙이며 VM 단독 실습, 앱 개발, 이미지 빌드는 제외한다.
- AKS는 Standard 운영 모드로 system pool과 user pool을 분리한다.
- 관리 API는 공개 엔드포인트와 허용 IP 목록을 사용하고 Entra 인증 및 Azure RBAC for Kubernetes를 적용한다.
- 샘플 서비스는 `lab` namespace의 ClusterIP Service이며 외부 공개하지 않는다.
- 인프라의 주 흐름은 `azure-enterprise-infra-planner`의 계획 승인, IaC 검증, 위험 인지 배포다.

## 리허설에서 확정할 항목

- 구독, 리전, 정책, 지원 VM SKU, 실제 용량, 쿼터, 비용 한도
- 행사장 및 자동화 실행 지점의 공인 출구 IP
- provider 등록, 이미지 레지스트리 egress, 도구와 Skill 버전
- 시스템/사용자 풀의 SKU와 노드 수, API 버전, Bicep 검사 도구
- 강사 bootstrap 주체와 Azure/Kubernetes RBAC 범위

## 경계

Azure Resource Manager의 실제 자원 관계와 Kubernetes API의 Deployment, Pod, Service 관계는 별도 증거로 문서화한다. `port-forward` 성공은 외부 ingress나 클러스터 내부 DNS 통신 성공의 증거가 아니다.

## 이름 충돌 방지

`reference/infra/main.bicep`은 참가자가 입력한 `aksName`, `dnsPrefix`를 그대로 쓰지 않고 `uniqueString(resourceGroup().id, aksName)` 기반 접미사를 자동으로 붙인다. 실제 배포된 이름은 출력값 `aksResourceName`, `aksDnsPrefix`로 확인하고 증거 로그에 그 값을 기록한다(입력표의 값은 base 이름일 뿐이다).

## 제한된 구독에서의 테스트

`Microsoft.Authorization`(역할 할당 생성/조회) 자체가 막힌 구독에서는 Azure RBAC for Kubernetes에 필요한 역할 할당을 만들 수 없어 Kubernetes 계층을 검증할 수 없다. 이 경우에만 `testingMode=true` 매개변수를 사용해 `disableLocalAccounts`와 `enableAzureRBAC`를 임시로 끄고 `az aks get-credentials --admin`으로 접속을 검증한다. `testingMode`는 기본값이 `false`이며, 실제 워크샵 운영에서는 절대 `true`로 설정하지 않는다.