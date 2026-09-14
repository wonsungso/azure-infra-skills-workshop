# 워크샵 설계 결정

> 이 문서는 "왜 이렇게 설계했는가"를 담고 있습니다. 처음 참가한다면 가볍게 훑어보고, [Lab 01](labs/01-orientation-and-setup.md)에서 실습을 시작하면서 다시 참고해도 좋습니다.

## 확정 사항

| 구분 | 결정 |
| --- | --- |
| 목적 | Azure Skills로 설계·검증·배포·문서화하는 경험이 핵심이고, AKS는 그 소재다 |
| 실행 환경 | GitHub Codespaces를 기본으로 한다. 도구 설치 차이로 인한 실패를 없애기 위해서다 |
| 범위 | Bicep 단일 트랙. VM 단독 실습, 앱 개발, 이미지 빌드는 제외 |
| 클러스터 | 자신의 resource group에 단일 region 전용 AKS 하나. Standard 운영 모드, system/user pool 분리 |
| 관리 API | 공개 엔드포인트 + authorized IP ranges, Entra 인증, Azure RBAC for Kubernetes |
| 샘플 서비스 | `lab` namespace의 ClusterIP Service. 외부로 공개하지 않는다 |
| 진행 방식 | `azure-enterprise-infra-planner`의 계획 승인 → IaC 검증 → 위험 인지 배포 |
| 담당자 | 사전 세팅 담당자를 두지 않는다. 환경 확인·권한 검증·namespace 생성·정리까지 참가자가 직접 |
| 문서 구조 | 프롬프트와 입력값을 별도 파일로 두지 않고 **해당 Lab 본문에 직접** 둔다. 문서 사이를 오가는 횟수를 줄이기 위해서다 |

**샘플 서비스를 이미지 빌드 없이 만드는 이유**

Contoso Shop 상품 페이지는 공개 `nginx-unprivileged` 이미지에 ConfigMap으로 `index.html`을 주입하고, projected volume의 Downward API로 Pod 이름과 namespace를 파일로 전달한다. "앱 코딩·컨테이너 빌드 제외" 경계를 지키면서도 눈에 보이는 결과물을 얻기 위해서다. HTML은 외부 CDN을 참조하지 않고 CSS를 모두 내장해, 클러스터 아웃바운드가 제한된 환경에서도 화면이 깨지지 않는다.

## 내가 직접 결정하고 확인할 항목

아래 값은 문서에 고정해 두지 않았습니다. 환경마다 다르고, **직접 조사하는 과정 자체가 실습의 일부**이기 때문입니다.

| 항목 | 어디서 정하나 | 확인 방법 |
| --- | --- | --- |
| subscription, resource group, region | Lab 01 | 내가 쓸 scope를 읽기 전용으로 조회해 확인 |
| 내 egress IP | Lab 01 | API authorized IP ranges에 넣을 값을 직접 조회 |
| vCPU quota와 region 용량 | Lab 02 | `azure-quotas`로 확인 후 SKU 결정 |
| system/user 풀 SKU와 node 개수 | Lab 02 | quota 여유 범위 안에서 결정 |
| Pod/Service CIDR, DNS IP | Lab 02 | 기존 네트워크와 겹치지 않게 결정 |
| 샘플 이미지 태그 | Lab 06 | 제공된 manifest 값을 그대로 사용 |

값이 확실하지 않을 때 **추측해서 채우지 마세요.** Skill에게 "이 값을 어떻게 확인하는지" 먼저 물어보고, 조회 결과로 채우는 것이 이 워크샵이 가르치려는 습관입니다.

Codespace에서 조회한 egress IP는 내 PC가 아니라 **Codespace의 주소**이다. 그리고 Codespace를 재시작하면 바뀔 수 있다. 따라서 authorized IP ranges는 워크샵 도중에 한 번 갱신해야 할 수 있는 값으로 다룬다.

## 경계

Azure Resource Manager의 실제 자원 관계와 Kubernetes API의 Deployment, Pod, Service 관계는 별도 증거로 문서화한다. `port-forward` 성공은 외부 ingress나 클러스터 내부 DNS 통신 성공의 증거가 아니다.

## 이름 충돌 방지

모든 리소스 이름에 6글자 `workshopId`를 공통으로 넣는다. [`main.bicep`](../reference/infra/main.bicep)은 이 값 하나로 VNet과 AKS 이름, DNS 접두사를 모두 생성한다.

| 리소스 | 이름 규칙 |
| --- | --- |
| resource group | `rg-aks-lab-<ID>` (직접 지정) |
| VNet | `vnet-aks-lab-<ID>` (Bicep이 생성) |
| AKS | `aks-lab-<ID>` (Bicep이 생성) |

이름이 입력값으로부터 결정되므로 배포 전에 예측할 수 있다. 배포 후에는 출력값 `aksResourceName`, `vnetName`, `nodeResourceGroup`으로 실제 생성된 이름을 확인해 증거 로그에 기록한다.

## 제한된 subscription에서의 테스트

`Microsoft.Authorization`(역할 할당 생성/조회) 자체가 막힌 subscription에서는 Azure RBAC for Kubernetes에 필요한 역할 할당을 만들 수 없어 Kubernetes 계층을 검증할 수 없다. 이 경우에만 `testingMode=true` 매개변수를 사용해 `disableLocalAccounts`와 `enableAzureRBAC`를 임시로 끄고 `az aks get-credentials --admin`으로 접속을 검증한다. `testingMode`는 기본값이 `false`이며, 실제 워크샵 운영에서는 절대 `true`로 설정하지 않는다.