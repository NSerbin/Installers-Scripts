#!/bin/bash

set -euo pipefail

readonly EKSCTL_PATH="/usr/local/bin/eksctl"

function install_eksctl() {
  if [[ -f "${EKSCTL_PATH}" ]]; then
    echo "Eksctl already installed at ${EKSCTL_PATH}"
    echo "Version: $(eksctl version)"
    return 0
  fi

  readonly VERSION=$(curl -sL https://api.github.com/repos/weaveworks/eksctl/releases/latest | jq -r '.tag_name')
  readonly URL="https://github.com/weaveworks/eksctl/releases/download/${VERSION}/eksctl_Linux_amd64.tar.gz"

  wget "${URL}"
  tar -xzf eksctl_Linux_amd64.tar.gz
  sudo mv eksctl "${EKSCTL_PATH}"
  rm eksctl_Linux_amd64.tar.gz
  
  echo "Installed: eksctl Version: $(eksctl version)"
}

install_eksctl
