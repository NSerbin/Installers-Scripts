#!/bin/bash

set -euo pipefail

readonly TERRAFORM_DOCS_PATH="/usr/local/bin/terraform-docs"
readonly TERRAFORM_PATH="/usr/local/bin/terraform"
readonly TERRAGRUNT_PATH="/usr/local/bin/terragrunt"

function is_installed() {
  local tool_path="$1"
  local tool_name="$2"
  
  if [[ -f "$tool_path" ]]; then
    echo "======================================="
    echo "$tool_name is already installed at $(command -v "$tool_name")"
    echo "Version: $($tool_name --version)"
    return 0
  else
    return 1
  fi
}

function install_tool() {
  local tool_name="$1"
  local latest_version_url="$2"
  
  if is_installed "${TERRAFORM_DOCS_PATH}" "terraform-docs"; then
    local current_version
    current_version=$("${TERRAFORM_DOCS_PATH}" version | grep -oP 'v\d+\.\d+\.\d+')
    local latest_version
    latest_version=$(curl -sL "${latest_version_url}" | jq -r '.tag_name')
    
    if [[ "${current_version}" < "${latest_version}" ]]; then
      echo "Current version ${current_version} is lower than the latest version ${latest_version}"
      echo "Updating..."
      sudo rm -f "${TERRAFORM_DOCS_PATH}"
      check_system

      case $OS_SYSTEM in
        *"Linux"*) local tool_type="terraform-docs-${latest_version}-linux-amd64.tar.gz";;
        *"Darwin"*) local tool_type="terraform-docs-${latest_version}-darwin-amd64.tar.gz";;
        *)
          echo "OS not supported"
          exit 1
          ;;
      esac

      local url="https://terraform-docs.io/dl/${latest_version}/${tool_type}"
      wget "${url}"
      tar -xzf "${tool_type}"
      chmod +x "${tool_name}"
      sudo mv "${tool_name}" "${TERRAFORM_DOCS_PATH}"
      rm "${tool_type}"

      echo "Installed: $(${tool_name} version)"
    else
      echo "${tool_name} is up to date."
      return 0
    fi
  fi
}

function check_system(){
  local OS_SYSTEM
  OS_SYSTEM=$(uname -s)
}

function install_terraform() {
  local tool_name="$1"
  local latest_version_url="$2"
  
  if is_installed "${TERRAFORM_PATH}" "terraform"; then
    local current_version
    current_version=$("${TERRAFORM_PATH}" version | awk 'NR==1{print $2}')
    local latest_version
    latest_version=$(curl -sL "${latest_version_url}" | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
    
    if [[ "${current_version}" < "${latest_version}" ]]; then
      echo "Current version ${current_version} is lower than the latest version ${latest_version}"
      echo "Updating..."
      sudo rm -f "${TERRAFORM_PATH}"
      check_system

      case $OS_SYSTEM in
        *"Linux"*) local tool_type="terraform_${latest_version}_linux_amd64.zip";;
        *"Darwin"*) local tool_type="terraform_${latest_version}_darwin_amd64.zip";;
        *)
          echo "OS not supported"
          exit 1
          ;;
      esac

      local url="https://releases.hashicorp.com/terraform/${latest_version}/${tool_type}"
      wget "${url}"
      unzip "${tool_type}"
      sudo mv "${tool_name}" "${TERRAFORM_PATH}"
      rm "${tool_type}"
      
      if ! grep -qF "export PATH=${TERRAFORM_PATH}:\${PATH}" ~/.zshrc ; then
        echo "export PATH=${TERRAFORM_PATH}:\${PATH}" >> ~/.zshrc
      fi
      
      echo "Installed: $(${tool_name} version)"
      echo "Run the following to reload your PATH with Terraform:"
      echo "source ~/.zshrc"
    else
      echo "${tool_name} is up to date."
      return 0
    fi
  fi  
}

function install_terragrunt() {
  local tool_name="$1"
  local latest_version_url="$2"
  
  if is_installed "${TERRAGRUNT_PATH}" "terragrunt"; then
    local current_version
    current_version=$("${TERRAGRUNT_PATH}" --version | awk 'NR==1{print $2}')
    local latest_version
    latest_version=$(curl -sL "${latest_version_url}" | grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4)
    
    if [[ "${current_version}" < "${latest_version}" ]]; then
      echo "Current version ${current_version} is lower than the latest version ${latest_version}"
      echo "Updating..."
      sudo rm -f "${TERRAGRUNT_PATH}"
      check_system

      case $OS_SYSTEM in
        *"Linux"*) local tool_type="terragrunt_linux_amd64";;
        *"Darwin"*) local tool_type="terragrunt_darwin_amd64";;
        *)
          echo "OS not supported"
          exit 1
          ;;
      esac

      local url="https://github.com/gruntwork-io/terragrunt/releases/download/${latest_version}/${tool_type}"
      wget "${url}"
      chmod +x "${tool_type}"
      sudo mv "${tool_type}" "${TERRAGRUNT_PATH}"
      rm "${tool_type}"

      echo "Installed: $(${tool_name} --version)"
    else
      echo "${tool_name} is up to date."
      return 0
    fi
  fi
}

install_tool "terraform-docs" "https://api.github.com/repos/terraform-docs/terraform-docs/releases/latest"

install_terraform "terraform" "https://api.github.com/repos/hashicorp/terraform/releases/latest"

install_terragrunt "terragrunt" "https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest"
