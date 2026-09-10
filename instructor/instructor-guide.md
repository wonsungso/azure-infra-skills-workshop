# 강사 운영 가이드

참가자는 [Lab 01](../docs/labs/01-orientation-and-setup.md)부터 [Lab 08](../docs/labs/08-document-and-cleanup.md)까지 8개 Lab을 순서대로 진행합니다. Lab 07(진단과 복구)만 선택 항목이며, 나머지는 모두 순서대로 완료해야 합니다. 이 가이드는 강사가 사전에 준비하고, 실습 중 참가자를 지원하고, 마지막에 정리하는 책임을 정리합니다.

## 사전 bootstrap

- 조별 scope, 비용 한도, 이름 규칙, 리전, trusted egress IP를 확정한다.
- `azure-quotas`로 quota와 용량을 확인하고 provider 등록, 도구/Skill commit과 버전을 기록한다.
- 배포자와 역할 할당자를 분리한다. 참가자에게 구독 Owner 또는 cluster-admin 자격증명을 주지 않는다.
- AKS control-plane identity에 custom subnet 등 필요한 최소 권한을 부여한다.
- AKS 생성 후 `lab` namespace와 참가자 Kubernetes 권한을 bootstrap한다. 다른 namespace 쓰기 거부를 리허설한다.
- 기준 Bicep과 manifest의 API, SKU, 이미지 digest를 해당 환경에서 검증한다.
- 기준 Bicep은 `aksName`/`dnsPrefix`에 자동으로 고유 접미사를 붙인다. 실제 배포 이름은 `aksResourceName`/`aksDnsPrefix` 출력값으로 확인한다.
- 구독이 `Microsoft.Authorization` 역할 할당 생성/조회를 막고 있으면(Kubernetes 접속을 위한 역할 할당이 불가능하면) `testingMode=true`로 한정된 검증만 수행하고, 실제 워크샵 배포에는 절대 사용하지 않는다.

## 시간 운영과 fallback

- 배포 대기 중 manifest 읽기와 node resource group 설명을 진행하되 성공 판정은 클러스터 ready 후에 한다.
- 예비 클러스터는 뒷부분 데모용일 뿐 참가자 배포 성공으로 기록하지 않는다.
- IP 변경, 권한 전파, quota, 정책, 용량, 이미지 pull 문제를 구분해 지원한다. API 허용 범위를 전체 공개로 완화하지 않는다.
- 지연 시 Lab 07(장애 주입/진단)을 생략하고 Lab 08의 문서화와 정리 시간을 확보한다.

## 정리

삭제 전에 팀, scope, 대상 리소스, node resource group 영향과 비용을 검토한다. 승인 뒤 삭제하고 `azure-resource-lookup`으로 잔여 자원을 확인한다. 삭제하지 못한 자원은 소유자와 만료 시각을 인계 문서에 남긴다.