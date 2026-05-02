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

readonly DOWNLOAD_DIR=~/Downloads
readonly JETBRAINS_DIR="/opt/jetbrains"
readonly VSCODE_DIR="/opt/vscode"

# URLs for downloading software — keep these updated
readonly IDEA_URL=https://download.jetbrains.com/idea/ideaIU-2025.3.3.tar.gz
readonly PYCHARM_URL=https://download.jetbrains.com/python/pycharm-2025.3.3.tar.gz
readonly VSCODE_URL="https://code.visualstudio.com/sha/download?build=stable&os=linux-x64"

readonly OPENJDK_URL=https://download.java.net/openjdk/jdk21/ri/openjdk-21+35_linux-x64_bin.tar.gz
readonly GRADLE_URL=https://services.gradle.org/distributions/gradle-8.14.4-bin.zip

readonly GRADLE_DIR="/opt/gradle"
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

# Download and extract VS Code to /opt/vscode.
install_vscode_ide() {
  log_info "Installing Visual Studio Code..."

  if ! wget --content-disposition -P "$DOWNLOAD_DIR" "$VSCODE_URL"; then
    log_error "Failed to download VS Code"
    return 1
  fi

  local downloaded_file
  downloaded_file=$(find "$DOWNLOAD_DIR" -name "code*.tar.gz" -type f -printf "%f\n" | head -1)
  if [ -z "$downloaded_file" ]; then
    log_error "Could not find downloaded VS Code file"
    return 1
  fi

  log_info "Downloaded file: $downloaded_file"
  sudo mkdir -p "$VSCODE_DIR"

  if ! sudo tar -xzf "$DOWNLOAD_DIR/$downloaded_file" -C "$VSCODE_DIR"; then
    log_error "Failed to extract VS Code"
    return 1
  fi

  find "$DOWNLOAD_DIR" -name "code*.tar.gz" -type f -exec rm -f {} +

  log_success "VS Code installed successfully"
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
  log_info "Installing OpenJDK 21..."

  if ! wget -P "$DOWNLOAD_DIR" "$OPENJDK_URL"; then
    log_error "Failed to download OpenJDK"
    return 1
  fi

  sudo mkdir -p /opt/java

  if ! sudo tar -xzf "$DOWNLOAD_DIR"/openjdk-21*.tar.gz -C /opt/java; then
    log_error "Failed to extract OpenJDK"
    return 1
  fi

  rm -f "$DOWNLOAD_DIR"/openjdk-21*.tar.gz

  echo "JAVA_HOME=/opt/java/jdk-21" | sudo tee -a /etc/environment > /dev/null
  echo 'export PATH=$JAVA_HOME/bin:$PATH' | sudo tee /etc/profile.d/java.sh > /dev/null

  log_success "OpenJDK 21 installed successfully"
}

# Download and install Gradle 8.14.4 to /opt/gradle.
install_gradle() {
  log_info "Installing Gradle..."

  if ! wget -P "$DOWNLOAD_DIR" "$GRADLE_URL"; then
    log_error "Failed to download Gradle"
    return 1
  fi

  if ! command -v unzip &> /dev/null; then
    sudo apt-get install -y unzip || { log_error "Failed to install unzip"; return 1; }
  fi

  sudo mkdir -p "$GRADLE_DIR"

  if ! sudo unzip -q "$DOWNLOAD_DIR"/gradle-8*.zip -d "$GRADLE_DIR"; then
    log_error "Failed to extract Gradle"
    return 1
  fi

  rm -f "$DOWNLOAD_DIR"/gradle-8*.zip

  echo "GRADLE_HOME=/opt/gradle/gradle-8.14.4" | sudo tee -a /etc/environment > /dev/null
  echo 'export PATH=$GRADLE_HOME/bin:$PATH' | sudo tee /etc/profile.d/gradle.sh > /dev/null

  log_success "Gradle installed successfully"
}

# Append Java and Gradle PATH entries to ~/.bashrc.
configure_shell_environment() {
  local config_block="\n# Java and Gradle\n"
  local java_home="export JAVA_HOME=/opt/java/jdk-21"
  local gradle_home="export GRADLE_HOME=/opt/gradle/gradle-8.14.4"
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
