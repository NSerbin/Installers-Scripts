#!/bin/bash

set -euo pipefail

readonly TERRAFORM_DOCS_PATH="/usr/local/bin/terraform-docs"
readonly TERRAFORM_PATH="/usr/local/bin/terraform"
readonly TERRAGRUNT_PATH="/usr/local/bin/terragrunt"

function terraform-docs-install() {
  if [[ -f "${TERRAFORM_DOCS_PATH}" ]]; then
    echo "============================="  
    echo "Terraform-Docs already installed at ${TERRAFORM_DOCS_PATH}"
    echo "Version: $(${TERRAFORM_DOCS_PATH} version)"
    echo ""
    return 0
  fi

  local VERSION
  VERSION=$(curl -sL https://api.github.com/repos/terraform-docs/terraform-docs/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\, | awk '{$1=$1};1')

  local OS_SYSTEM
  OS_SYSTEM=$(uname -s)

  case $OS_SYSTEM in
    *"Linux"*) TERRAFORM_DOCS_TYPE="terraform-docs-${VERSION}-linux-amd64.tar.gz";;
    *"Darwin"*) TERRAFORM_DOCS_TYPE="terraform-docs-${VERSION}-darwin-amd64.tar.gz";;
    *)
      echo "OS not supported"
      exit 1
      ;;
  esac

  local URL
  URL="https://terraform-docs.io/dl/${VERSION}/${TERRAFORM_DOCS_TYPE}"
  wget "${URL}"
  tar -xzf "${TERRAFORM_DOCS_TYPE}"
  chmod +x terraform-docs
  sudo mv terraform-docs "${TERRAFORM_DOCS_PATH}"
  rm "${TERRAFORM_DOCS_TYPE}"

  echo "Installed: $(terraform-docs version)"
}

function terraform-install() {
  if [[ -f "${TERRAFORM_PATH}" ]]; then
    echo "============================="  
    echo "Terraform already installed at ${TERRAFORM_PATH}"
    echo "Version: $(terraform version)"
    echo ""    
    return 0
  fi
  
  local VERSION
  VERSION=$(curl -sL https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')

  local OS_SYSTEM
  OS_SYSTEM=$(uname -s)

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
  
  cat << EOF
Run the following to reload your PATH with Terraform:
  source ~/.zshrc
EOF
}

function terragrunt-install(){
  if [[ -f "$TERRAGRUNT_PATH" ]]; then
    echo "============================="  
    echo "Terragrunt already installed at ${TERRAGRUNT_PATH}"
    echo "Version: $(terragrunt --version)"
    echo ""    
    return 0
  fi

  local VERSION
  VERSION=$(curl -sL https://api.github.com/repos/gruntwork-io/terragrunt/releases/latest | grep -o '"tag_name": *"[^"]*"' | cut -d'"' -f4)
  local OS_SYSTEM
  OS_SYSTEM=$(uname -s)

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

  echo "Installed: $(terragrunt --version)"
}

terraform-docs-install

terraform-install

terragrunt-install



