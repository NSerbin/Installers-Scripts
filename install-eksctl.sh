#!/bin/bash

set -euo pipefail

readonly EKSCTL_PATH="/usr/local/bin/eksctl"

function is_eksctl_installed() {
  if [[ -f "${EKSCTL_PATH}" ]]; then
    echo "Eksctl is already installed at $(command -v eksctl)"
    echo "Version: $(eksctl version)"
    return 0
  else
    return 1
  fi
}

function install_eksctl() {
  readonly LATEST_VERSION=$(curl -sL https://api.github.com/repos/weaveworks/eksctl/releases/latest | jq -r '.tag_name')
  
  if is_eksctl_installed; then
    local CURRENT_VERSION=$(eksctl version | awk 'NR==1{print $3}')
    if [[ "${CURRENT_VERSION}" < "${LATEST_VERSION}" ]]; then
      echo "Current version ${CURRENT_VERSION} is lower than the latest version ${LATEST_VERSION}"
      echo "Updating..."      
      sudo rm -f "${EKSCTL_PATH}"
    else
      echo "Eksctl is up to date."
      return 0
    fi
  fi

  readonly URL="https://github.com/weaveworks/eksctl/releases/download/${LATEST_VERSION}/eksctl_Linux_amd64.tar.gz"

  wget "${URL}"
  tar -xzf eksctl_Linux_amd64.tar.gz
  sudo mv eksctl "${EKSCTL_PATH}"
  rm eksctl_Linux_amd64.tar.gz
  
  echo "Installed: Eksctl Version: $(eksctl version)"
}

install_eksctl
