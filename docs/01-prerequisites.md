# 사전 준비

이 워크샵은 혼자서 진행합니다. 아래 항목을 스스로 준비한 뒤 [Lab 01](labs/01-orientation-and-setup.md)을 시작하세요.

## 1. 도구 준비

- VS Code, GitHub Copilot, Azure MCP와 Azure Skills가 사용 가능한지 확인한다.
- Azure CLI, Bicep, `kubectl`, `kubelogin`을 설치하고 `az login`으로 로그인한다.

버전 확인은 아래 한 줄로 끝납니다. 하나라도 없으면 먼저 설치하세요.

```bash
az version && az bicep version && kubectl version --client && kubelogin --version
```

## 2. Azure 권한 확인

다음 두 가지를 **본인이 직접** 할 수 있어야 합니다. 하나라도 안 되면 이 워크샵을 끝까지 진행할 수 없습니다.

- 리소스 그룹을 만들고 그 안에 AKS를 배포할 수 있는 권한 (예: 해당 범위의 `Contributor`)
- 실습이 끝난 뒤 리소스를 **삭제**할 수 있는 권한

> [!WARNING]
> 회사 공용 구독이라면 반드시 **전용 리소스 그룹**을 새로 만들어 진행하세요. 기존 리소스가 있는 그룹에서 진행하면 Lab 08의 정리 단계에서 다른 사람의 자원까지 지울 위험이 있습니다.

## 3. 비용 인지

AKS 노드(기본 구성 기준 system 2대 + user 1대)는 **실행되는 동안 계속 과금**됩니다. 워크샵은 약 6시간 기준이며, 중간에 그만두더라도 반드시 [Lab 08](labs/08-document-and-cleanup.md)의 삭제 단계를 수행하세요.

## 4. 입력표 준비

[입력표](../templates/team-inputs.md)를 열어둡니다. 값은 Lab 01과 Lab 02에서 직접 조사해 채우며, **비밀값(토큰, kubeconfig 내용 등)은 기록하지 않습니다.**

준비가 끝났다면 [Lab 01](labs/01-orientation-and-setup.md)로 이동합니다.