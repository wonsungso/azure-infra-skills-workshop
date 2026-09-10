# 조별 공통 입력표

| 항목 | 값 | 상태 |
| --- | --- | --- |
| 팀 식별자 | `<team-id>` | 미입력 |
| 구독 ID 또는 배정 scope | `<subscription-or-scope>` | 미입력 |
| 리전 | `<region>` | 리허설 확정 |
| 리소스 그룹 | `<resource-group>` | 미입력 |
| 클러스터 이름 | `<aks-name>` | 미입력 (base 이름, 실제 배포 이름에는 고유 접미사가 자동으로 붙는다) |
| node resource group | `<node-resource-group>` | 미입력 |
| VNet/subnet 또는 기존 subnet ID | `<subnet-id>` | 강사 확인 |
| Pod CIDR / Service CIDR / DNS IP | `<cidrs>` | 리허설 확정 |
| API 허용 IP 목록 | `<trusted-egress-ip-cidrs>` | 강사 확인 |
| system/user VM SKU와 노드 수 | `<approved-skus-and-counts>` | 리허설 확정 |
| namespace | `lab` | 강사 bootstrap |
| 샘플 이미지 태그 또는 digest | `<rehearsed-image>` | 리허설 확정 |

이 표는 2단계 계획 승인 후 변경을 기록한다. 비밀, 액세스 토큰, kubeconfig 내용은 기록하지 않는다.