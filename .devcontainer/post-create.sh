#!/usr/bin/env bash
# Codespace 또는 devcontainer가 처음 만들어질 때 한 번 실행된다.
# Azure CLI와 Bicep은 devcontainer feature가 설치하므로, 여기서는 kubectl과 kubelogin만 설치한다.
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

BIN_DIR=/usr/local/bin
SUDO=""
if [ ! -w "$BIN_DIR" ]; then
  if sudo -n true 2>/dev/null; then
    # 모든 셸에서 보이도록 PATH에 이미 있는 /usr/local/bin에 설치한다
    SUDO=sudo
  else
    BIN_DIR="$HOME/.local/bin"
    mkdir -p "$BIN_DIR"
    grep -qxF "export PATH=\"$BIN_DIR:\$PATH\"" "$HOME/.bashrc" 2>/dev/null \
      || echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$HOME/.bashrc"
    export PATH="$BIN_DIR:$PATH"
  fi
fi

$SUDO az aks install-cli \
  --install-location "$BIN_DIR/kubectl" \
  --kubelogin-install-location "$BIN_DIR/kubelogin"

# azure-quotas는 quota, 나머지 조회 Skill은 resource-graph extension을 요구한다
for ext in quota resource-graph alb aks-preview; do
  az extension add --name "$ext" --upgrade --yes --only-show-errors || {
    echo "필수 Extension '$ext' 설치 실패 - 준비를 중단합니다." >&2
    exit 1
  }
done
command -v jq >/dev/null || {
  echo "필수 도구 jq가 없습니다. 컨테이너 준비 상태를 확인하세요." >&2
  exit 1
}

bash "$REPO_ROOT/scripts/init-workshop.sh"

# VS Code는 작업 영역의 .github/skills 에서도 Skill을 읽는다. 저장소에는 커밋하지 않는다.
SKILL_DIR="$REPO_ROOT/.github/skills"
WORKSHOP_SKILLS="azure-quotas azure-kubernetes azure-enterprise-infra-planner azure-resource-lookup azure-diagnostics azure-resource-visualizer"
TMP=$(mktemp -d)
SKILL_ERROR=0
if git clone -q --depth 1 https://github.com/microsoft/azure-skills.git "$TMP"; then
  for s in $WORKSHOP_SKILLS; do
    if [ ! -f "$TMP/skills/$s/SKILL.md" ]; then
      echo "필수 Azure Skill 누락: $s - 설치를 중단합니다." >&2
      SKILL_ERROR=1
    fi
  done
  if [ "$SKILL_ERROR" -eq 0 ]; then
    mkdir -p "$SKILL_DIR"
    INSTALLED=0
    for s in $WORKSHOP_SKILLS; do
      cp -r "$TMP/skills/$s" "$SKILL_DIR/"
      INSTALLED=$((INSTALLED+1))
    done
    echo ""
    echo "Azure Skills 설치 완료: $INSTALLED / 6"
  fi
else
  echo "Azure Skills 자동 설치 실패 - Lab 01 Step 2의 수동 설치 방법을 따르세요" >&2
  SKILL_ERROR=1
fi
rm -rf "$TMP"
[ "$SKILL_ERROR" -eq 0 ] || exit 1

echo ""
echo "설치된 도구 버전:"
az version --output tsv --query '"azure-cli"'
az bicep version
kubectl version --client --output=yaml
kubelogin --version
# Azure MCP server가 npm 패키지라 Skill 사용에 필요하다
node --version
az extension list --query "[].name" -o tsv | tr '\n' ' '
echo ""

echo ""
echo "다음 단계: docs/labs/01-orientation-and-setup.md 를 열어 Azure 로그인부터 진행하세요."
