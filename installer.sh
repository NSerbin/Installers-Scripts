#!/bin/bash

set -euo pipefail

readonly AWSCLI_PATH="/usr/local/bin/aws"
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
    
    local version_cmd
    case "$tool_name" in
      aws) version_cmd="$tool_name --version | awk '{print \$1}' | cut -d'/' -f2" ;;
      terragrunt) version_cmd="$tool_name -version | grep -Eo 'v?[0-9]+\.[0-9]+\.[0-9]+' | sed 's/v//'" ;;
      helm) version_cmd="$tool_name version --short | awk '{print \$1}' | sed 's/+.*//' | sed 's/v//'" ;;
      *) version_cmd="$tool_name version | grep -Eo 'v?[0-9]+\.[0-9]+\.[0-9]+' | sed 's/v//'" ;;
    esac
    
    echo "Version: $(eval $version_cmd)"
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
  if [[ "$tool_name" == "terraform" ]]; then
    version=$(curl -sL "${latest_version_url}" | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
  else
    version=$(curl -sL "${latest_version_url}" | jq -r '.tag_name')
  fi

  local url_template
  case "$tool_name" in
    terraform-docs) url_template="https://github.com/terraform-docs/terraform-docs/releases/download/${version}/terraform-docs-${version}-${os_type}.${file_extension}" ;;
    terraform) url_template="https://releases.hashicorp.com/terraform/${version}/terraform_${version}_${os_type}.${file_extension}" ;;
    terragrunt) url_template="https://github.com/gruntwork-io/terragrunt/releases/download/${version}/terragrunt_${os_type}" ;;
    helm) url_template="https://get.helm.sh/helm-${version}-${os_type}.${file_extension}" ;;
    eksctl) url_template="https://github.com/weaveworks/eksctl/releases/download/${version}/eksctl_${os_type}.${file_extension}" ;;
    aws) url_template="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" ;;
  esac
  
  wget "${url_template}" -O "${tool_name}.${file_extension}"
  
  case "${file_extension}" in
    tar.gz) tar -xzf "${tool_name}.${file_extension}" ;;
    zip) unzip "${tool_name}.${file_extension}" ;;
    "") mv "${tool_name}.${file_extension}" "${tool_name}" ;;
  esac

  if [[ "$file_extension" == "" ]]; then
    sudo mv "${tool_name}" "${tool_path}"
  else
    sudo mv $(find . -name "${tool_name}") "${tool_path}"
  fi

  chmod +x "${tool_path}"
  
  case "$tool_name" in
    terragrunt) echo "Installed: $(${tool_name} -version)" ;;
    *) echo "Installed: $(${tool_name} version)" ;;
  esac

  rm -f "${tool_name}.${file_extension}"
}

function install_tool() {
  local tool_name="$1"
  local latest_version_url="$2"
  local tool_path="$3"
  local os_type="$4"
  local file_extension="$5"
  
  if is_installed "${tool_path}" "${tool_name}"; then
    local current_version latest_version
    
    case "$tool_name" in
      terragrunt) current_version=$("${tool_name}" -version | grep -Eo 'v?[0-9]+\.[0-9]+\.[0-9]+' | sed 's/v//') ;;
      helm) current_version=$("${tool_name}" version --short | awk '{print $1}' | sed 's/+.*//' | sed 's/v//') ;;
      *) current_version=$("${tool_name}" version | grep -Eo 'v?[0-9]+\.[0-9]+\.[0-9]+' | sed 's/v//') ;;
    esac
    
    latest_version=$(curl -sL "${latest_version_url}" | jq -r '.tag_name' | sed 's/v//')

    if [[ $(printf '%s\n' "$latest_version" "$current_version" | sort -V | head -n1) != "$latest_version" ]]; then
      echo "Current version ${current_version} is lower than the latest version ${latest_version}"
      echo "Updating..."
      sudo rm -f "${tool_path}"
      download_and_install "${tool_name}" "${latest_version_url}" "${tool_path}" "${os_type}" "${file_extension}"
    else
      echo "${tool_name} is up to date."
    fi
  else
    echo "${tool_name} is not installed. Installing..."
    download_and_install "${tool_name}" "${latest_version_url}" "${tool_path}" "${os_type}" "${file_extension}"
  fi
}

case $OS_SYSTEM in
  "Linux")
    os_type="linux-amd64"
    terraform_os_type="linux_amd64"
    terragrunt_os_type="linux_amd64"
    eksctl_os_type="linux_amd64"
    ;;
  "Darwin")
    os_type="darwin-amd64"
    terraform_os_type="darwin_amd64"
    terragrunt_os_type="darwin_amd64"
    eksctl_os_type="darwin_amd64"
    ;;
  *)
    echo "OS not supported"
    exit 1
    ;;
esac

install_tool "terraform-docs" "https://api.github.com/repos/terraform-docs/terraform-docs/releases/latest" "${TERRAFORM_DOCS_PATH}" "${os_type}" "tar.gz"
install_tool "terraform" "https://api.github.com/repos/hashicorp/terraform/releases/latest" "${TERRAFORM_PATH}" "${terraform_os_type}" "zip"
install_tool "terragrunt" "https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest" "${TERRAGRUNT_PATH}" "${terragrunt_os_type}" ""
install_tool "helm" "https://api.github.com/repos/helm/helm/releases/latest" "${HELM_PATH}" "${os_type}" "tar.gz"
install_tool "eksctl" "https://api.github.com/repos/weaveworks/eksctl/releases/latest" "${EKSCTL_PATH}" "${eksctl_os_type}" "tar.gz"
