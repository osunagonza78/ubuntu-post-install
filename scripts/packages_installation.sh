#!/bin/bash

###############################################################################
# Packages Installation Script for Ubuntu
###############################################################################
# This script installs essential packages, multimedia codecs, fonts, browsers,
# and shell customizations for Ubuntu Linux.
#
# Author: Gilberto Osuna Gonzalez
# Version: 1.0
###############################################################################

SCRIPT_DIR="$(dirname "$0")"
source "${SCRIPT_DIR}/../lib/logging.sh"
source "${SCRIPT_DIR}/../lib/package_utils.sh"
source "${SCRIPT_DIR}/../config.env"

# Core packages available in the standard Ubuntu repos are now managed in config.env

###############################################################################
# Functions
###############################################################################

# Update firmware using LVFS.
update_system_firmware() {
  log_info "Performing firmware updates..."

  check_program_installed fwupdmgr

  if ! sudo fwupdmgr refresh --force; then
    log_error "Failed to refresh firmware database"
    return 1
  fi

  sudo fwupdmgr get-devices || log_warning "Could not get device list"
  sudo fwupdmgr get-updates || log_warning "No firmware updates available"

  if ! sudo fwupdmgr update -y; then
    log_warning "Firmware update returned non-zero (may mean no updates available)"
  fi

  log_success "Firmware updates completed"
}

# Add the Flathub remote and configure filesystem theme access.
setup_flatpak_environment() {
  log_info "Performing Flatpak setup..."

  check_program_installed flatpak

  if ! flatpak remote-list | grep -q "flathub"; then
    log_info "Adding Flathub repository..."
    if ! flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo; then
      log_error "Failed to add Flathub repository"
      return 1
    fi
  else
    log_info "Flathub repository is already added."
  fi

  sudo flatpak override --filesystem=~/.themes || log_warning "Failed to set flatpak theme override"
  flatpak update --appstream || log_warning "Failed to update flatpak appstream"

  log_success "Flatpak setup completed"
}

# Install ubuntu-restricted-extras and GStreamer plugins for full codec support.
install_multimedia_codecs() {
  log_info "Performing multimedia codecs setup..."

  # ubuntu-restricted-extras includes ffmpeg, MP3/MP4 codecs, and more.
  # It presents a debconf licence prompt; pre-accept it non-interactively.
  echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula \
    select true | sudo debconf-set-selections

  if ! sudo apt-get install -y ubuntu-restricted-extras; then
    log_error "Failed to install ubuntu-restricted-extras"
    return 1
  fi

  local gst_packages=(
    gstreamer1.0-plugins-good
    gstreamer1.0-plugins-bad
    gstreamer1.0-plugins-ugly
    gstreamer1.0-libav
    gstreamer1.0-vaapi
  )

  if ! sudo apt-get install -y "${gst_packages[@]}"; then
    log_warning "Some GStreamer plugins failed to install"
  fi

  log_success "Multimedia codecs installation completed"
}

# Enable H.264 support for Firefox (snap version uses a different mechanism).
configure_firefox_codecs() {
  log_info "Configuring Firefox video codec support..."

  # The gstreamer1.0-libav package provides H.264 for the .deb Firefox.
  # For the snap version of Firefox the codec bundle is handled automatically.
  if ! sudo apt-get install -y gstreamer1.0-libav; then
    log_warning "Failed to install gstreamer1.0-libav"
  fi

  log_success "Firefox codec support configured"
}

# Install Microsoft TrueType core fonts via the Ubuntu package.
install_microsoft_fonts() {
  log_info "Installing Microsoft TrueType fonts..."

  # Pre-accept the EULA so the install is fully non-interactive.
  echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula \
    select true | sudo debconf-set-selections

  if ! sudo apt-get install -y ttf-mscorefonts-installer; then
    log_error "Failed to install Microsoft fonts"
    return 1
  fi

  sudo fc-cache -fv || log_warning "Failed to update font cache"

  log_success "Microsoft fonts installed"
}

# Install Steam with 32-bit multiarch support.
install_steam() {
  log_info "Installing Steam..."

  # Steam requires i386 (32-bit) packages.
  if ! sudo dpkg --add-architecture i386; then
    log_warning "Failed to add i386 architecture (may already be enabled)"
  fi

  sudo apt-get update

  if ! sudo apt-get install -y steam-installer; then
    log_error "Failed to install Steam"
    return 1
  fi

  log_success "Steam installed"
}

# Add the fastfetch PPA and install fastfetch.
install_fastfetch() {
  log_info "Installing fastfetch..."

  if ! sudo add-apt-repository -y ppa:zhangsongcui3371/fastfetch; then
    log_error "Failed to add fastfetch PPA"
    return 1
  fi

  sudo apt-get update

  if ! sudo apt-get install -y fastfetch; then
    log_error "Failed to install fastfetch"
    return 1
  fi

  log_success "fastfetch installed"
}

# Add the Brave Browser apt repository and install.
install_brave_browser() {
  log_info "Installing Brave Browser..."

  sudo install -m 0755 -d /usr/share/keyrings

  if ! sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg \
      https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg; then
    log_error "Failed to download Brave GPG key"
    return 1
  fi

  echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] \
https://brave-browser-apt-release.s3.brave.com/ stable main" | \
    sudo tee /etc/apt/sources.list.d/brave-browser.list > /dev/null

  sudo apt-get update

  if ! sudo apt-get install -y brave-browser; then
    log_error "Failed to install Brave Browser"
    return 1
  fi

  log_success "Brave Browser installed"
}

# Add the WineHQ Ubuntu repository and install Wine stable.
install_wine() {
  log_info "Installing Wine..."

  # Ensure 32-bit support is enabled.
  sudo dpkg --add-architecture i386 || true
  sudo mkdir -pm755 /etc/apt/keyrings

  if ! sudo wget -O /etc/apt/keyrings/winehq-archive.key \
      https://dl.winehq.org/wine-builds/winehq.key; then
    log_error "Failed to download WineHQ GPG key"
    return 1
  fi

  local codename
  codename=$(lsb_release -cs)
  if ! sudo wget -NP /etc/apt/sources.list.d/ \
      "https://dl.winehq.org/wine-builds/ubuntu/dists/${codename}/winehq-${codename}.sources"; then
    log_error "Failed to add WineHQ repository for ${codename}"
    return 1
  fi

  sudo apt-get update

  if ! sudo apt-get install -y --install-recommends winehq-stable; then
    log_error "Failed to install Wine"
    return 1
  fi

  log_success "Wine installed"
}

# Download the official Google Chrome .deb and install it.
install_google_chrome() {
  log_info "Installing Google Chrome..."

  local deb_path="/tmp/google-chrome-stable.deb"

  if ! wget -O "$deb_path" \
      https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb; then
    log_error "Failed to download Google Chrome"
    return 1
  fi

  if ! sudo apt-get install -y "$deb_path"; then
    log_error "Failed to install Google Chrome"
    rm -f "$deb_path"
    return 1
  fi

  rm -f "$deb_path"
  log_success "Google Chrome installed"
}

# Download and install Oh My Posh with FiraCode Nerd Font and themes.
setup_oh_my_posh_shell() {
  log_info "Installing Oh My Posh..."
  local posh_bin="/usr/local/bin/oh-my-posh"
  local fonts_dir="$HOME/.local/share/fonts"
  local themes_dir="$HOME/.poshthemes"
  local downloads_dir="$HOME/Downloads"

  if ! sudo wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/posh-linux-amd64 \
      -O "$posh_bin"; then
    log_error "Failed to download Oh My Posh"
    return 1
  fi

  sudo chmod +x "$posh_bin"

  mkdir -p "$fonts_dir"

  if ! wget https://github.com/ryanoasis/nerd-fonts/releases/download/v3.2.1/FiraCode.zip \
      -O "$downloads_dir/firacode.zip"; then
    log_error "Failed to download FiraCode font"
    return 1
  fi

  unzip -o "$downloads_dir/firacode.zip" -d "$fonts_dir"
  rm -f "$downloads_dir/firacode.zip"
  fc-cache -f -v || log_warning "Failed to update font cache"

  mkdir -p "$themes_dir"

  if ! wget https://github.com/JanDeDobbeleer/oh-my-posh/releases/latest/download/themes.zip \
      -O "$themes_dir/themes.zip"; then
    log_error "Failed to download Oh My Posh themes"
    return 1
  fi

  unzip -o "$themes_dir/themes.zip" -d "$themes_dir"
  rm -f "$themes_dir/themes.zip"
  chmod u+rw "$themes_dir"/*.json || log_warning "Failed to set permissions on theme files"

  log_success "Oh My Posh installation completed"
}

# Append fastfetch and Oh My Posh initialisation to ~/.bashrc.
configure_shell_environment() {
  local bashrc_path="$HOME/.bashrc"

  if grep -q "fastfetch and poshtheme" "$bashrc_path" 2>/dev/null; then
    log_info "Shell configuration already exists in .bashrc"
    return 0
  fi

  cp "$bashrc_path" "${bashrc_path}.backup.$(date +%Y%m%d_%H%M%S)" || \
    log_warning "Failed to backup .bashrc"

  {
    echo -e "\n# fastfetch and poshtheme"
    echo "fastfetch"
    echo "eval \"\$(oh-my-posh init bash --config ${POSH_THEME})\""
  } >> "$bashrc_path"

  log_success "Shell environment configured successfully"
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    log_info "Starting comprehensive package installation..."

    update_system_firmware
    setup_flatpak_environment
    install_multimedia_codecs
    configure_firefox_codecs
    install_packages "${APT_PACKAGES[@]}"
    install_steam
    install_fastfetch
    install_microsoft_fonts
    setup_oh_my_posh_shell
    install_brave_browser
    install_google_chrome
    install_wine
    configure_shell_environment

    log_success "Package installation completed successfully!"
    log_info "Please restart your terminal or run 'source ~/.bashrc' to apply shell changes."
}

main "$@"
