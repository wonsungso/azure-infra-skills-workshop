# 사전 준비

## 참가자

- VS Code, GitHub Copilot, Azure MCP와 Azure Skills가 사용 가능한지 확인한다.
- Azure CLI, Bicep, `kubectl`, `kubelogin`으로 로그인 가능한 상태를 준비한다.
- 강사에게 조별 구독 또는 리소스 그룹 범위, 클러스터 이름 규칙, 허용 IP 목록 반영 여부를 확인한다.
- [공통 입력표](../templates/team-inputs.md)를 작성하되 비밀값은 저장소에 기록하지 않는다.

## 강사 리허설

- `azure-quotas`로 조 수를 고려한 regional/family vCPU, AKS, Public IP 한도와 용량을 확인한다.
- 배포자, 역할 할당자, AKS control-plane identity, Kubernetes 참가자의 권한을 분리한다.
- 참가자의 실제 네트워크에서 API 접근, Entra 로그인, namespace 쓰기, 다른 namespace 쓰기 거부를 확인한다.
- 기준 Bicep과 manifest를 실제 지원 API, 이미지 digest, 정책에 맞춰 고정한다.

사전 준비가 완료되지 않으면 [Lab 01](labs/01-orientation-and-setup.md)을 시작하지 않는다.