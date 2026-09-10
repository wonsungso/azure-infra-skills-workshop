# 공통 입력표

이후 모든 프롬프트가 이 값을 공유합니다. **추측해서 채우지 말고**, "확인 방법" 열의 방식으로 직접 조회한 값만 적으세요.

| 항목 | 값 | 확인 방법 |
| --- | --- | --- |
| 구독 ID 또는 사용할 scope | `<subscription-or-scope>` | Lab 01에서 읽기 전용 조회 |
| 리전 | `<region>` | Lab 02에서 쿼터·용량 확인 후 결정 |
| 리소스 그룹 | `<resource-group>` | 내가 직접 만들 이름 (전용 그룹 권장) |
| 클러스터 이름 | `<aks-name>` | 내가 정하는 base 이름 (실제 배포 이름에는 고유 접미사가 자동으로 붙는다) |
| node resource group | `<node-resource-group>` | 배포 후 실제 값 확인 |
| VNet/subnet 또는 기존 subnet ID | `<subnet-id>` | Lab 02~03에서 결정 (새로 만들지, 기존 것을 참조할지) |
| Pod CIDR / Service CIDR / DNS IP | `<cidrs>` | Lab 02에서 기존 네트워크와 겹치지 않게 결정 |
| API 허용 IP 목록 | `<trusted-egress-ip-cidrs>` | Lab 01에서 내 공인 출구 IP 직접 조회 |
| system/user VM SKU와 노드 수 | `<approved-skus-and-counts>` | Lab 02에서 `azure-quotas` 확인 후 결정 |
| namespace | `lab` | 고정값 (Lab 05에서 내가 직접 생성) |
| 샘플 이미지 태그 | `nginxinc/nginx-unprivileged:1.27-alpine` | 제공된 매니페스트 값 그대로 사용 |

이 표는 2단계 계획 승인 후 변경을 기록한다. 비밀, 액세스 토큰, kubeconfig 내용은 기록하지 않는다.