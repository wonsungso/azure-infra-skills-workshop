# 워크샵 프롬프트 카드

모든 프롬프트에서 대괄호 값을 [공통 입력표](../templates/team-inputs.md)의 값으로 바꾼다. Skill 이름을 포함했다고 실제 사용된 것은 아니다. 응답의 Skill 지침 참조와 실행 결과를 [증거 양식](../templates/evidence-log.md)에 기록한다.

## 계획

```text
azure-enterprise-infra-planner를 사용해 [resource-group]에 [aks-name] AKS를 위한 인프라 계획을 작성해줘. azure-kubernetes의 Day-0 검토와 azure-rbac의 최소 권한 검토를 반영해줘. public API의 authorized IP ranges는 [trusted-egress-ip-cidrs]만 사용하고, Entra와 Azure RBAC for Kubernetes를 사용하며 local accounts는 비활성화해줘. system/user pool 분리, Azure CNI Overlay + Cilium, load balancer egress, 비중첩 CIDR을 포함해줘. 대안, 위험, 비용 요인을 보여주고 계획 승인 전에는 멈춰.
```

## IaC 검증

```text
승인된 infrastructure plan과 기존 입력표를 읽어 Bicep을 생성 또는 갱신해줘. azure-enterprise-infra-planner의 검증 단계를 따라 Bicep build, 보안 검사, ARM validation 또는 what-if를 수행하고 실제 명령 결과와 실패 항목을 정리해줘. 배포는 하지 마. 검증되지 않은 결과는 예상으로 표시해줘.
```

## 배포 승인 요청

```text
승인된 계획과 검증 증거를 읽어줘. 배포 대상, 생성 또는 변경될 자원, 권한 요구, 비용 및 삭제 책임을 요약한 뒤 명시적 배포 승인을 요청해줘. 승인을 받기 전에는 Azure 리소스를 생성하거나 변경하지 마.
```

## 재개

```text
이 저장소의 공통 입력표, 증거 로그, checkpoint를 읽고 현재 완료된 단계를 판별해줘. Azure에서 실제 상태를 조회해 문서와 비교하되 리소스를 변경하지 마. 다음 미완료 단계의 프롬프트와 선행 조건만 제시해줘.
```

## 문서화

```text
azure-resource-lookup과 azure-resource-visualizer를 사용해 [resource-group]과 [node-resource-group]의 실제 Azure 리소스와 관계를 조사하고 Mermaid 문서를 작성해줘. Kubernetes Deployment, Pod, Service 관계는 kubectl 증거를 별도 섹션으로 작성해줘. 관측 사실, 설계값, 추정, 미검증 항목을 구분해줘. 리소스를 변경하지 마.
```