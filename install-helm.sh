#!/bin/bash

set -euo pipefail

readonly HELM_PATH="/usr/local/bin/helm"

function install_helm() {
  if [[ -f "${HELM_PATH}" ]]; then
    echo "Helm already installed at ${HELM_PATH}"
    echo "Version: $(helm version)"
    return 0
  fi

  readonly VERSION=$(curl -sL https://api.github.com/repos/helm/helm/releases/latest | jq -r '.tag_name')
  readonly URL="https://get.helm.sh/helm-${VERSION}-linux-amd64.tar.gz"

  wget "${URL}"
  tar -xzf helm-"${VERSION}"-linux-amd64.tar.gz
  sudo mv linux-amd64/helm "${HELM_PATH}"
  rm helm-"${VERSION}"-linux-amd64.tar.gz
  
  echo "Installed: helm Version: $(helm version)"
}

install_helm
