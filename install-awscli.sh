#!/bin/bash

set -euo pipefail

readonly AWSCLI_PATH="/usr/local/bin/aws"

readonly LATEST_VERSION_URL="https://api.github.com/repos/aws/aws-cli/tags"

# Check if the tool is already installed
function is_installed() {
  if [[ -f "$AWSCLI_PATH" ]]; then
    echo "======================================="
    echo "AWS CLI is already installed at $AWSCLI_PATH"
    echo "Version: $(get_current_version)"
  fi
}

# Function to get the current version of AWS CLI
function get_current_version() {
  aws --version | awk '{print $1}' | cut -d'/' -f2
}

# Function to get the latest version of AWS CLI
function get_latest_version() {
  curl -sL "${LATEST_VERSION_URL}" | grep -o -E "\"name\": \"[0-9]+\.[0-9]+\.[0-9]+\"" | head -n 1 | awk -F'"' '{print $4}'
}

# Install or update AWS CLI
function install_awscli() {
  
  if is_installed; then

    local current_version=$(get_current_version)
    local latest_version=$(get_latest_version)

    if [[ "${current_version}" < "${latest_version}" ]]; then
      echo "Current version ${current_version} is lower than the latest version ${latest_version}"
      echo "Updating..."
      download_and_install
    else
      echo "AWS CLI is up to date."
    fi
  else
    echo "awscli is not installed. Installing..."
    download_and_install
  fi
}

# Download and install the latest version of AWS CLI
function download_and_install() {
  local url

  url="https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip"

  curl -o "awscliv2.zip" "${url}"
  unzip awscliv2.zip
  if is_installed; then
    sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
    echo "AWS CLI updated successfully."
  else
    sudo ./aws/install
    echo "AWS CLI installed successfully."
  fi
  rm -rf aws*
}

install_awscli
