#!/bin/bash

set -euo pipefail

readonly EKSCTL_PATH="/usr/local/bin/eksctl"

function is_installed() {
  local tool_path="$1"
  local tool_name="$2"
  
  if [[ -f "$tool_path" ]]; then
    echo "======================================="
    echo "$tool_name is already installed at $(command -v "$tool_name")"
    echo "Version: $($tool_name version)"
    return 0
  else
    return 1
  fi
}

function install_eksctl() {
  local tool_name="$1"
  local latest_version_url="$2"
  
  if is_installed "${EKSCTL_PATH}" "eksctl"; then
    local current_version
    current_version=$(eksctl version)
    local latest_version
    latest_version=$(curl -sL "${latest_version_url}" | jq -r '.tag_name' | sed 's/v//')
    
    if [[ "${current_version}" < "${latest_version}" ]]; then
      echo "Current version ${current_version} is lower than the latest version ${latest_version}"
      echo "Updating..."
      sudo rm -f "${EKSCTL_PATH}"
      download_and_install "${tool_name}" "${latest_version_url}"
    else
      echo "${tool_name} is up to date."
      return 0
    fi
  else
    echo "eksctl is not installed. Installing..."
    download_and_install "${tool_name}" "${latest_version_url}"
  fi
}

function download_and_install() {
  local tool_name="$1"
  local latest_version_url="$2"
  
  local latest_version
  latest_version=$(curl -sL "${latest_version_url}" | jq -r '.tag_name' | sed 's/v//')

  local url="https://github.com/weaveworks/eksctl/releases/download/v${latest_version}/eksctl_Linux_amd64.tar.gz"
  wget "${url}"
  tar -xzf eksctl_Linux_amd64.tar.gz
  chmod +x "${tool_name}"
  sudo mv "${tool_name}" "${EKSCTL_PATH}"
  rm eksctl_Linux_amd64.tar.gz

  echo "Installed: $(${tool_name} version)"
}


install_eksctl "eksctl" "https://api.github.com/repos/weaveworks/eksctl/releases/latest"
