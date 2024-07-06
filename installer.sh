#!/bin/bash

set -euo pipefail

readonly EKSCTL_PATH="/usr/local/bin/eksctl"
readonly HELM_PATH="/usr/local/bin/helm"
readonly TERRAFORM_DOCS_PATH="/usr/local/bin/terraform-docs"
readonly TERRAFORM_PATH="/usr/local/bin/terraform"
readonly TERRAGRUNT_PATH="/usr/local/bin/terragrunt"
readonly OS_SYSTEM="$(uname -s)"

function is_installed() {
  local tool_path="$1"
  local tool_name="$2"
  
  if [[ -f "$tool_path" ]]; then
    echo "======================================="
    echo "$tool_name is already installed at $(command -v "$tool_name")"
    if [[ "$tool_name" == "terragrunt" ]]; then
      echo "Version: $($tool_name -version 2>/dev/null | grep -Eo 'v[0-9]+\.[0-9]+\.[0-9]+')"
    elif [[ "$tool_name" == "helm" ]]; then
      echo "Version: $($tool_name version --short | awk '{print $1}' | sed 's/+.*//')"
    else
      echo "Version: $($tool_name version | grep -Eo 'v?[0-9]+\.[0-9]+\.[0-9]+')"
    fi
    return 0
  else
    return 1
  fi
}

function download_and_install() {
  local tool_name="$1"
  local latest_version_url="$2"
  local tool_path="$3"
  local os_type="$4"
  local file_extension="$5"
  
  local version
  version=$(curl -sL "${latest_version_url}" | jq -r '.tag_name')

  local url
  if [[ "$tool_name" == "terraform-docs" ]]; then
    url="https://github.com/terraform-docs/terraform-docs/releases/download/${version}/terraform-docs-${version}-${os_type}.${file_extension}"
  elif [[ "$tool_name" == "terraform" ]]; then
    url="https://releases.hashicorp.com/terraform/${version}/terraform_${version#v}_${os_type}.${file_extension}"
  elif [[ "$tool_name" == "terragrunt" ]]; then
    url="https://github.com/gruntwork-io/terragrunt/releases/download/${version}/terragrunt_${os_type}"
  elif [[ "$tool_name" == "helm" ]]; then
    url="https://get.helm.sh/helm-${version}-${os_type}.${file_extension}"
  elif [[ "$tool_name" == "eksctl" ]]; then
    url="https://github.com/weaveworks/eksctl/releases/download/${version}/eksctl_${os_type}.${file_extension}"
  fi

  wget "${url}"
  if [[ "${file_extension}" == "tar.gz" ]]; then
    if [[ "$tool_name" == "terraform-docs" ]]; then
      tar -xzf "terraform-docs-${version}-${os_type}.${file_extension}"
      sudo mv "terraform-docs" "${tool_path}"
    elif [[ "$tool_name" == "helm" ]]; then
      tar -xzf "${tool_name}-${version}-${os_type}.${file_extension}"
      sudo mv "${os_type}/helm" "${tool_path}"
    elif [[ "$tool_name" == "eksctl" ]]; then
      tar -xzf "${tool_name}_${os_type}.${file_extension}"
      sudo mv "eksctl" "${tool_path}"
    fi
  elif [[ "${file_extension}" == "zip" ]]; then
    unzip "${tool_name}-${version}-${os_type}.${file_extension}"
    sudo mv "${tool_name}-${version}-${os_type}/${tool_name}" "${tool_path}"
  else
    mv "terragrunt_${os_type}" "${tool_path}"
  fi
  
  chmod +x "${tool_path}"

  if [[ "$tool_name" == "terragrunt" ]]; then
    echo "Installed: $(${tool_name} -version)"
  else
    echo "Installed: $(${tool_name} version)"
  fi
}

function install_tool() {
  local tool_name="$1"
  local latest_version_url="$2"
  local tool_path="$3"
  local os_type="$4"
  local file_extension="$5"
  
  if is_installed "${tool_path}" "${tool_name}"; then
    local current_version
    local latest_version

    if [[ "$tool_name" == "terragrunt" ]]; then
      current_version=$("${tool_name}" -version | grep -Eo 'v?[0-9]+\.[0-9]+\.[0-9]+' | sed 's/v//')
    elif [[ "$tool_name" == "helm" ]]; then
      current_version=$("${tool_name}" version --short | awk '{print $1}' | sed 's/+.*//' | sed 's/v//')
    else
      current_version=$("${tool_name}" version | grep -Eo 'v?[0-9]+\.[0-9]+\.[0-9]+' | sed 's/v//')
    fi

    latest_version=$(curl -sL "${latest_version_url}" | jq -r '.tag_name' | sed 's/v//')

    if [[ $(printf '%s\n' "$latest_version" "$current_version" | sort -V | head -n1) != "$latest_version" ]]; then
      echo "Current version ${current_version} is lower than the latest version ${latest_version}"
      echo "Updating..."
      sudo rm -f "${tool_path}"
      download_and_install "${tool_name}" "${latest_version_url}" "${tool_path}" "${os_type}" "${file_extension}"
    else
      echo "${tool_name} is up to date."
      return 0
    fi
  else
    echo "${tool_name} is not installed. Installing..."
    download_and_install "${tool_name}" "${latest_version_url}" "${tool_path}" "${os_type}" "${file_extension}"
  fi
}

case $OS_SYSTEM in
  "Linux")
    TERRAFORM_DOCS_OS_TYPE="linux-amd64"
    TERRAFORM_OS_TYPE="linux_amd64"
    TERRAGRUNT_OS_TYPE="linux_amd64"
    HELM_OS_TYPE="linux-amd64"
    EKSCTL_OS_TYPE="linux_amd64"
    ;;
  "Darwin")
    TERRAFORM_DOCS_OS_TYPE="darwin-amd64"
    TERRAFORM_OS_TYPE="darwin_amd64"
    TERRAGRUNT_OS_TYPE="darwin_amd64"
    HELM_OS_TYPE="darwin-amd64"
    EKSCTL_OS_TYPE="darwin_amd64"    
    ;;
  *)
    echo "OS not supported"
    exit 1
    ;;
esac

install_tool "terraform-docs" "https://api.github.com/repos/terraform-docs/terraform-docs/releases/latest" "${TERRAFORM_DOCS_PATH}" "${TERRAFORM_DOCS_OS_TYPE}" "tar.gz"
install_tool "terraform" "https://api.github.com/repos/hashicorp/terraform/releases/latest" "${TERRAFORM_PATH}" "${TERRAFORM_OS_TYPE}" "zip"
install_tool "terragrunt" "https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest" "${TERRAGRUNT_PATH}" "${TERRAGRUNT_OS_TYPE}" ""
install_tool "helm" "https://api.github.com/repos/helm/helm/releases/latest" "${HELM_PATH}" "${HELM_OS_TYPE}" "tar.gz"
install_tool "eksctl" "https://api.github.com/repos/weaveworks/eksctl/releases/latest" "${EKSCTL_PATH}" "${EKSCTL_OS_TYPE}" "tar.gz"
