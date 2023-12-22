#!/bin/bash

set -euo pipefail

readonly TERRAFORM_DOCS_PATH="/usr/local/bin/terraform-docs"
readonly TERRAFORM_PATH="/usr/local/bin/terraform"
readonly TERRAGRUNT_PATH="/usr/local/bin/terragrunt"


function is_tf_docs_installed() {
  if [[ -f "${TERRAFORM_DOCS_PATH}" ]]; then
    echo "=======================================" 
    echo "Terraform-Docs is already installed at $(command -v terraform-docs)"
    echo "Version: $(terraform-docs version)"
    return 0
  else
    return 1
  fi
}

function check_system(){
  local OS_SYSTEM
  OS_SYSTEM=$(uname -s)
}

function tf-docs-install() {
  local LATEST_VERSION
  LATEST_VERSION=$(curl -sL https://api.github.com/repos/terraform-docs/terraform-docs/releases/latest | jq -r '.tag_name')
  if is_tf_docs_installed; then
    local CURRENT_VERSION
    CURRENT_VERSION=$(${TERRAFORM_DOCS_PATH} version | grep -oP 'v\d+\.\d+\.\d+')
    if [[ "${CURRENT_VERSION}" < "${LATEST_VERSION}" ]]; then
      echo "Current version ${CURRENT_VERSION} is lower than the latest version ${LATEST_VERSION}"
      echo "Updating..."      
      sudo rm -f "${TERRAFORM_DOCS_PATH}"
      check_system

        case $OS_SYSTEM in
          *"Linux"*) TERRAFORM_DOCS_TYPE="terraform-docs-${LATEST_VERSION}-linux-amd64.tar.gz";;
          *"Darwin"*) TERRAFORM_DOCS_TYPE="terraform-docs-${LATEST_VERSION}-darwin-amd64.tar.gz";;
          *)
            echo "OS not supported"
            exit 1
            ;;
        esac

        local URL
        URL="https://terraform-docs.io/dl/${LATEST_VERSION}/${TERRAFORM_DOCS_TYPE}"
        wget "${URL}"
        tar -xzf "${TERRAFORM_DOCS_TYPE}"
        chmod +x terraform-docs
        sudo mv terraform-docs "${TERRAFORM_DOCS_PATH}"
        rm "${TERRAFORM_DOCS_TYPE}"

        echo "Installed: $(terraform-docs version)"      
    else
      echo "Terraform-Docs is up to date."
      return 0
    fi
  fi
  
}

function is_tf_installed(){
  if [[ -f "${TERRAFORM_PATH}" ]]; then
    echo "======================================="
    echo "Terraform already installed at ${TERRAFORM_PATH}"
    echo "Version: $(terraform version)"
    return 0
  else
    return 1
  fi
}

function tf-install() {
  if is_tf_installed; then
    local CURRENT_VERSION
    CURRENT_VERSION=$(terraform version | awk 'NR==1{print $2}')
    local LATEST_VERSION
    LATEST_VERSION=$(curl -sL https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
    if [[ "${CURRENT_VERSION}" < "${LATEST_VERSION}" ]]; then
      echo "Current version ${CURRENT_VERSION} is lower than the latest version ${LATEST_VERSION}"
      echo "Updating..."      
      sudo rm -f "${TERRAFORM_PATH}"
      check_system

      case $OS_SYSTEM in
        *"Linux"*) TERRAFORM_TYPE="terraform_${VERSION}_linux_amd64.zip";;
        *"Darwin"*) TERRAFORM_TYPE="terraform_${VERSION}_darwin_amd64.zip";;
        *)
          echo "OS not supported"
          exit 1
          ;;
      esac

      local URL="https://releases.hashicorp.com/terraform/${VERSION}/${TERRAFORM_TYPE}"
      wget "${URL}"
      unzip "${TERRAFORM_TYPE}"
      sudo mv terraform "${TERRAFORM_PATH}"
      rm "${TERRAFORM_TYPE}"
      if ! grep -qF "export PATH=${TERRAFORM_PATH}:\${PATH}" ~/.zshrc ; then
        echo "export PATH=${TERRAFORM_PATH}:\${PATH}" >> ~/.zshrc
      fi
      
      echo "Installed: $(terraform version)"
      echo "Run the following to reload your PATH with Terraform:"
      echo "source ~/.zshrc"
    else
      echo "Terraform is up to date."
      return 0
    fi
  fi  
  
}

function is_tg_installed(){
  if [[ -f "${TERRAGRUNT_PATH}" ]]; then
    echo "======================================="
    echo "Terragrunt already installed at ${TERRAGRUNT_PATH}"
    echo "Version: $(terragrunt --version)"
    return 0
  else
    return 1
  fi
}

function tg-install(){
  if is_tg_installed; then
    local CURRENT_VERSION
    CURRENT_VERSION=$(terragrunt --version | awk 'NR==1{print $2}')
    local LATEST_VERSION
    LATEST_VERSION=$(curl -sL https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4)
    if [[ "${CURRENT_VERSION}" < "${LATEST_VERSION}" ]]; then
      echo "Current version ${CURRENT_VERSION} is lower than the latest version ${LATEST_VERSION}"
      echo "Updating..."      
      sudo rm -f "${TERRAGRUNT_PATH}"
      check_system

      case $OS_SYSTEM in
        *"Linux"*) TERRAGRUNT_TYPE="terragrunt_linux_amd64";;
        *"Darwin"*) TERRAGRUNT_TYPE="terragrunt_darwin_amd64";;
        *)
          echo "OS not supported"
          exit 1
          ;;
      esac
      local URL="https://github.com/gruntwork-io/terragrunt/releases/download/${VERSION}/${TERRAGRUNT_TYPE}"
      wget "${URL}"
      chmod +x "${TERRAGRUNT_TYPE}"
      sudo mv "${TERRAGRUNT_TYPE}" "${TERRAGRUNT_PATH}"
      rm "$TERRAGRUNT_TYPE"

      echo "Installed: $(terragrunt --version)"
    else
      echo "Terragrunt is up to date."
      return 0
    fi
  fi
}

tf-docs-install

tf-install

tg-install



