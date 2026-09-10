# 워크샵 설계 결정

> 이 문서는 "왜 이렇게 설계했는가"를 담고 있습니다. 처음 참가한다면 가볍게 훑어보고, [Lab 01](labs/01-orientation-and-setup.md)에서 실습을 시작하면서 다시 참고해도 좋습니다.

## 확정 사항

- Azure Skills로 설계, 검증, 배포, 문서화하는 경험이 핵심이며 AKS는 시나리오다.
- 참가자는 자신의 리소스 그룹에 전용 AKS 클러스터 하나를 단일 리전으로 만든다.
- Bicep 단일 트랙이며 VM 단독 실습, 앱 개발, 이미지 빌드는 제외한다.
- AKS는 Standard 운영 모드로 system pool과 user pool을 분리한다.
- 관리 API는 공개 엔드포인트와 허용 IP 목록을 사용하고 Entra 인증 및 Azure RBAC for Kubernetes를 적용한다.
- 샘플 서비스는 `lab` namespace의 ClusterIP Service이며 외부 공개하지 않는다.
- 샘플 서비스(Contoso Mission Control 대시보드)는 **컨테이너 이미지를 빌드하지 않는다.** 공개 nginx-unprivileged 이미지에 ConfigMap으로 `index.html`을 주입하고, projected volume의 Downward API로 Pod 이름과 namespace를 파일로 전달한다. 이로써 "앱 코딩·컨테이너 빌드 제외" 경계를 유지하면서도 시각적 결과물을 얻는다.
- 대시보드 HTML은 **외부 CDN을 참조하지 않는다.** 클러스터 아웃바운드가 제한된 환경에서도 화면이 깨지지 않도록 CSS를 모두 내장한다.
- 인프라의 주 흐름은 `azure-enterprise-infra-planner`의 계획 승인, IaC 검증, 위험 인지 배포다.
- **별도의 사전 세팅 담당자를 전제하지 않는다.** 환경 확인, 권한 검증, namespace 생성, 정리까지 참가자가 직접 수행한다.

## 내가 직접 결정하고 확인할 항목

아래 값은 문서에 고정해 두지 않았습니다. 환경마다 다르고, **직접 조사하는 과정 자체가 실습의 일부**이기 때문입니다.

| 항목 | 어디서 정하나 | 확인 방법 |
| --- | --- | --- |
| 구독, 리소스 그룹, 리전 | Lab 01 | 내가 쓸 scope를 읽기 전용으로 조회해 확인 |
| 내 공인 출구 IP | Lab 01 | API 허용 IP 목록에 넣을 값을 직접 조회 |
| vCPU 쿼터와 리전 용량 | Lab 02 | `azure-quotas`로 확인 후 SKU 결정 |
| system/user 풀 SKU와 노드 수 | Lab 02 | 쿼터 여유 범위 안에서 결정 |
| Pod/Service CIDR, DNS IP | Lab 02 | 기존 네트워크와 겹치지 않게 결정 |
| 샘플 이미지 태그 | Lab 06 | 제공된 매니페스트 값을 그대로 사용 |

> [!TIP]
> 값이 확실하지 않을 때 **추측해서 채우지 마세요.** Skill에게 "이 값을 어떻게 확인하는지" 먼저 물어보고, 조회 결과로 채우는 것이 이 워크샵이 가르치려는 습관입니다.


## 경계

Azure Resource Manager의 실제 자원 관계와 Kubernetes API의 Deployment, Pod, Service 관계는 별도 증거로 문서화한다. `port-forward` 성공은 외부 ingress나 클러스터 내부 DNS 통신 성공의 증거가 아니다.

## 이름 충돌 방지

`reference/infra/main.bicep`은 참가자가 입력한 `aksName`, `dnsPrefix`를 그대로 쓰지 않고 `uniqueString(resourceGroup().id, aksName)` 기반 접미사를 자동으로 붙인다. 실제 배포된 이름은 출력값 `aksResourceName`, `aksDnsPrefix`로 확인하고 증거 로그에 그 값을 기록한다(입력표의 값은 base 이름일 뿐이다).

## 제한된 구독에서의 테스트

`Microsoft.Authorization`(역할 할당 생성/조회) 자체가 막힌 구독에서는 Azure RBAC for Kubernetes에 필요한 역할 할당을 만들 수 없어 Kubernetes 계층을 검증할 수 없다. 이 경우에만 `testingMode=true` 매개변수를 사용해 `disableLocalAccounts`와 `enableAzureRBAC`를 임시로 끄고 `az aks get-credentials --admin`으로 접속을 검증한다. `testingMode`는 기본값이 `false`이며, 실제 워크샵 운영에서는 절대 `true`로 설정하지 않는다.