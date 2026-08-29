#!/bin/bash

###############################################################################
# Development Tools Installation Script for Ubuntu
###############################################################################
# This script installs essential development tools and configures various
# development environments on Ubuntu Linux.
#
# Author: Gilberto Osuna Gonzalez
# Version: 1.0
###############################################################################

SCRIPT_DIR="$(dirname "$0")"
source "${SCRIPT_DIR}/../lib/logging.sh"
source "${SCRIPT_DIR}/../config.env"

readonly DOWNLOAD_DIR=~/Downloads
readonly bashrc_path="$HOME/.bashrc"

# Download and extract IntelliJ IDEA Ultimate and PyCharm Professional to /opt/jetbrains.
install_jetbrains_ide() {
  log_info "Performing JetBrains IDEs installation..."

  log_info "Downloading IntelliJ IDEA Ultimate..."
  if ! wget -P "$DOWNLOAD_DIR" "$IDEA_URL"; then
    log_error "Failed to download IntelliJ IDEA"
    return 1
  fi

  log_info "Downloading PyCharm Professional..."
  if ! wget -P "$DOWNLOAD_DIR" "$PYCHARM_URL"; then
    log_error "Failed to download PyCharm"
    return 1
  fi

  sudo mkdir -p "$JETBRAINS_DIR"

  log_info "Extracting IntelliJ IDEA..."
  if ! sudo tar -xzf "$DOWNLOAD_DIR"/ideaIU-*.tar.gz -C "$JETBRAINS_DIR"; then
    log_error "Failed to extract IntelliJ IDEA"
    return 1
  fi

  log_info "Extracting PyCharm..."
  if ! sudo tar -xzf "$DOWNLOAD_DIR"/pycharm-*.tar.gz -C "$JETBRAINS_DIR"; then
    log_error "Failed to extract PyCharm"
    return 1
  fi

  find "$DOWNLOAD_DIR" -name "ideaIU-*.tar.gz" -type f -exec rm -f {} +
  find "$DOWNLOAD_DIR" -name "pycharm-*.tar.gz" -type f -exec rm -f {} +

  log_success "JetBrains IDEs installed successfully"
}

# Install Visual Studio Code via the official APT repository.
install_vscode_ide() {
  log_info "Installing Visual Studio Code via APT..."

  # Ensure prerequisites are installed
  if ! sudo apt-get install -y wget gpg apt-transport-https; then
    log_error "Failed to install VS Code prerequisites"
    return 1
  fi

  # Add the Microsoft GPG key
  log_info "Adding Microsoft GPG key..."
  sudo mkdir -pm755 /etc/apt/keyrings
  if ! wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /etc/apt/keyrings/packages.microsoft.gpg > /dev/null; then
    log_error "Failed to add Microsoft GPG key"
    return 1
  fi

  # Add the VS Code repository
  log_info "Adding Visual Studio Code repository..."
  echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | \
    sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

  # Update and install
  sudo apt-get update
  if ! sudo apt-get install -y code; then
    log_error "Failed to install Visual Studio Code"
    return 1
  fi

  log_success "Visual Studio Code installed successfully via APT"
}

# Install Docker CE from the official Docker Ubuntu repository.
setup_docker_engine() {
  log_info "Performing Docker installation..."

  log_info "Removing previous Docker installation..."
  sudo apt-get remove -y \
    docker docker-doc docker-compose docker-compose-v2 \
	podman-docker docker-engine docker.io containerd runc \
    docker-ce docker-ce-cli 2>/dev/null || true

  log_info "Installing Docker prerequisites..."
  if ! sudo apt-get install -y ca-certificates curl gnupg lsb-release; then
    log_error "Failed to install Docker prerequisites"
    return 1
  fi

  log_info "Adding Docker GPG key..."
  sudo install -m 0755 -d /etc/apt/keyrings
  if ! curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
      sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg; then
    log_error "Failed to add Docker GPG key"
    return 1
  fi
  sudo chmod a+r /etc/apt/keyrings/docker.gpg

  log_info "Adding Docker repository..."
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
https://download.docker.com/linux/ubuntu \
$(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

  sudo apt-get update

  log_info "Installing Docker packages..."
  if ! sudo apt-get install -y \
      docker-ce docker-ce-cli containerd.io \
      docker-buildx-plugin docker-compose-plugin; then
    log_error "Failed to install Docker packages"
    return 1
  fi

  if ! sudo systemctl enable --now docker; then
    log_error "Failed to enable Docker service"
    return 1
  fi

  sudo usermod -aG docker "$USER"

  log_success "Docker engine setup completed"
}

# Download and install Oracle OpenJDK 21 to /opt/java.
install_openjdk() {
  log_info "Installing OpenJDK ${JAVA_VERSION}..."

  if ! wget -P "$DOWNLOAD_DIR" "$OPENJDK_URL"; then
    log_error "Failed to download OpenJDK"
    return 1
  fi

  sudo mkdir -p "$JAVA_DIR"

  if ! sudo tar -xzf "$DOWNLOAD_DIR"/openjdk-*.tar.gz -C "$JAVA_DIR"; then
    log_error "Failed to extract OpenJDK"
    return 1
  fi

  rm -f "$DOWNLOAD_DIR"/openjdk-*.tar.gz

  echo "JAVA_HOME=${JAVA_DIR}/${JAVA_VERSION}" | sudo tee -a /etc/environment > /dev/null
  echo 'export PATH=$JAVA_HOME/bin:$PATH' | sudo tee /etc/profile.d/java.sh > /dev/null

  log_success "OpenJDK ${JAVA_VERSION} installed successfully"
}

# Download and install Gradle 8.14.4 to /opt/gradle.
install_gradle() {
  log_info "Installing Gradle ${GRADLE_VERSION}..."

  if ! wget -P "$DOWNLOAD_DIR" "$GRADLE_URL"; then
    log_error "Failed to download Gradle"
    return 1
  fi

  if ! command -v unzip &> /dev/null; then
    sudo apt-get install -y unzip || { log_error "Failed to install unzip"; return 1; }
  fi

  sudo mkdir -p "$GRADLE_DIR"

  if ! sudo unzip -q "$DOWNLOAD_DIR"/gradle-*.zip -d "$GRADLE_DIR"; then
    log_error "Failed to extract Gradle"
    return 1
  fi

  rm -f "$DOWNLOAD_DIR"/gradle-*.zip

  echo "GRADLE_HOME=${GRADLE_DIR}/${GRADLE_VERSION}" | sudo tee -a /etc/environment > /dev/null
  echo 'export PATH=$GRADLE_HOME/bin:$PATH' | sudo tee /etc/profile.d/gradle.sh > /dev/null

  log_success "Gradle ${GRADLE_VERSION} installed successfully"
}

# Append Java and Gradle PATH entries to ~/.bashrc.
configure_shell_environment() {
  local config_block="\n# Java and Gradle\n"
  local java_home="export JAVA_HOME=${JAVA_DIR}/${JAVA_VERSION}"
  local gradle_home="export GRADLE_HOME=${GRADLE_DIR}/${GRADLE_VERSION}"
  local path_config='export PATH=$PATH:$JAVA_HOME/bin:$GRADLE_HOME/bin'

  cp "$bashrc_path" "${bashrc_path}.backup.$(date +%Y%m%d_%H%M%S)" || \
    log_warning "Failed to backup .bashrc"

  {
    echo -e "$config_block"
    echo "$java_home"
    echo "$gradle_home"
    echo "$path_config"
  } >> "$bashrc_path"

  log_success "Shell environment configured successfully"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    log_info "Starting development environment installation..."

    install_jetbrains_ide
    install_vscode_ide
    setup_docker_engine
    install_openjdk
    install_gradle
    configure_shell_environment

    log_success "Development environment installation completed successfully!"
    log_info "Please restart your terminal or run 'source ~/.bashrc' to apply shell changes."
}

main "$@"
