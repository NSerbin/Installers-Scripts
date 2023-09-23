#!/bin/bash

set -euo pipefail

readonly HELM_PATH="/usr/local/bin/helm"

function is_helm_installed() {
  if [[ -f "${HELM_PATH}" ]]; then
    echo "Helm already installed at ${HELM_PATH}"
    echo "Version: $(helm version --short | awk '{print $1}' | sed 's/+.*//')"
    return 0
  else
    return 1
  fi
}

function install_helm() {
  readonly LATEST_VERSION=$(curl -sL https://api.github.com/repos/helm/helm/releases/latest | jq -r '.tag_name')

  if is_helm_installed; then
    local CURRENT_VERSION=$(helm version --short | awk '{print $1}' | sed 's/+.*//')
    if [[ "${CURRENT_VERSION}" < "${LATEST_VERSION}" ]]; then
      echo "Current version ${CURRENT_VERSION} is lower than the latest version ${LATEST_VERSION}."
      echo "Updating..."
      sudo rm -f "${HELM_PATH}"
    else
      echo "Helm is up to date."
      return 0
    fi
  fi
  readonly URL="https://get.helm.sh/helm-${LATEST_VERSION}-linux-amd64.tar.gz"

  wget "${URL}"
  tar -xzf helm-"${LATEST_VERSION}"-linux-amd64.tar.gz
  sudo mv linux-amd64/helm "${HELM_PATH}"
  rm helm-"${LATEST_VERSION}"-linux-amd64.tar.gz
  
  echo "Installed Helm Version: $(helm version --short | awk '{print $1}' | sed 's/+.*//')"
}

install_helm
