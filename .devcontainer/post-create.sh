#!/usr/bin/env bash
# Codespace 또는 devcontainer가 처음 만들어질 때 한 번 실행된다.
# Azure CLI와 Bicep은 devcontainer feature가 설치하므로, 여기서는 kubectl과 kubelogin만 설치한다.
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

BIN_DIR=/usr/local/bin
if [ ! -w "$BIN_DIR" ]; then
  BIN_DIR="$HOME/.local/bin"
  mkdir -p "$BIN_DIR"
  grep -qxF "export PATH=\"$BIN_DIR:\$PATH\"" "$HOME/.bashrc" 2>/dev/null \
    || echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$HOME/.bashrc"
  export PATH="$BIN_DIR:$PATH"
fi

az aks install-cli \
  --install-location "$BIN_DIR/kubectl" \
  --kubelogin-install-location "$BIN_DIR/kubelogin"

bash "$REPO_ROOT/scripts/init-workshop.sh"

echo ""
echo "설치된 도구 버전:"
az version --output tsv --query '"azure-cli"' 2>/dev/null || true
az bicep version 2>/dev/null || true
kubectl version --client --output=yaml 2>/dev/null | head -3 || true
kubelogin --version 2>/dev/null | head -1 || true

echo ""
echo "다음 단계: az login 으로 로그인한 뒤 my-inputs.md와 docs/labs/01-orientation-and-setup.md 를 여세요."
