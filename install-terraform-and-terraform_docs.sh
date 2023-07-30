#!/bin/bash

set -euo pipefail

readonly TERRAFORM_DOCS_PATH="/usr/local/bin/terraform-docs"
readonly TERRAFORM_PATH="/usr/local/bin/terraform"

function terraform-docs-install() {
  if [[ -f "${TERRAFORM_DOCS_PATH}" ]]; then
    echo "Terraform-Docs already installed at ${TERRAFORM_DOCS_PATH}"
    echo "Version: $(/usr/local/bin/terraform-docs version)"
    return 0
  fi

  local VERSION=$(curl -sL https://api.github.com/repos/terraform-docs/terraform-docs/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\, | awk '{$1=$1};1')
  local URL="https://terraform-docs.io/dl/${VERSION}/terraform-docs-${VERSION}-linux-amd64.tar.gz"
  wget "${URL}"
  tar -xzf terraform-docs-"${VERSION}"-linux-amd64.tar.gz
  chmod +x terraform-docs
  sudo mv terraform-docs "${TERRAFORM_DOCS_PATH}"
  rm terraform-docs-"${VERSION}"-linux-amd64.tar.gz

  echo "Installed: $(terraform-docs version)"
}

function terraform-install() {
  if [[ -f "${TERRAFORM_PATH}" ]]; then
    echo "Terraform already installed at ${TERRAFORM_PATH}"
    echo "Version: $(terraform version)"
    return 0
  fi
  
  local VERSION=$(curl -sL https://api.github.com/repos/hashicorp/terraform/releases/latest | grep tag_name | cut -d: -f2 | tr -d \"\,\v | awk '{$1=$1};1')
  local URL="https://releases.hashicorp.com/terraform/${VERSION}/terraform_${VERSION}_linux_amd64.zip"
  wget "${URL}"
  unzip terraform_"${VERSION}"_linux_amd64.zip
  sudo mv terraform "${TERRAFORM_PATH}"
  rm terraform_"${VERSION}"_linux_amd64.zip
  if ! grep -qF "export PATH=${TERRAFORM_PATH}:\${PATH}" ~/.zshrc ; then
  	echo "export PATH=${TERRAFORM_PATH}:\${PATH}" >> ~/.zshrc
  fi
  
  echo "Installed: $(terraform version)"
  
  cat << EOF
Run the following to reload your PATH with Terraform:
  source ~/.bashrc
EOF
}

terraform-docs-install

terraform-install
