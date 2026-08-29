# Ubuntu Post-Install Tool

A comprehensive post-installation configuration tool for Ubuntu Linux that automates system setup, package installation, driver configuration, and development environment provisioning through an interactive terminal menu.

## Features

- **Modern Interactive Interface**: Arrow-key menu with a split `tmux` pane for live output streaming.
- **Customizable Setup**: External configuration files (`config.env`, `versions.env`) allow users to customize package lists and versions without modifying scripts.
- **Persistent Logging**: All execution output is captured in `~/ubuntu-post-install.log` for auditing and debugging.
- **Safe Operations**:
    - Pre-flight `sudo` access verification.
    - User-prompted reboots to prevent accidental data loss.
    - Idempotent operations — safe to re-run.
- **Modular Scripts**: Run only the specific components you need.

## Requirements

- Ubuntu 22.04 LTS or later
- `bash`, `tmux`, `sudo` access
- Internet connection

## Usage

```bash
git clone https://github.com/osunagonza78/ubuntu-post-install.git
cd ubuntu-post-install
chmod +x run.sh
./run.sh
```

If `tmux` is available, the tool launches automatically in a split-pane session — menu on the left, live output on the right. Without `tmux`, scripts run inline.

## Customization

You can tailor the installation to your needs by editing the configuration files:

- **`config.env`**: Define which APT packages to install, installation directories, and shell themes.
- **`versions.env`**: Update version strings and download URLs for development tools (Java, Gradle, JetBrains IDEs) as new releases become available.

## Menu Options

| # | Option | Description |
|---|--------|-------------|
| 0 | **System Configuration** | Full system upgrade, boot optimisation, and optional reboot. |
| 1 | **Packages Installation** | Codecs, fonts, browsers, Wine, Steam, Oh My Posh. |
| 2 | **Development Environment** | JetBrains IDEs, VS Code (via APT), Docker, OpenJDK, Gradle. |
| 3 | **Virtualization Stack** | KVM/QEMU, libvirt, virt-manager. |
| 4 | **Nvidia Drivers** | Hardware acceleration, automatic driver detection and installation, CUDA. |
| 5 | **Exit** | |

## Script Details

### System Configuration (`scripts/system_configuration.sh`)
- Runs `apt full-upgrade` and cleans up orphaned packages.
- Disables `NetworkManager-wait-online.service` to reduce boot time.
- Prompts the user before rebooting.

### Packages Installation (`scripts/packages_installation.sh`)
- Uses `config.env` to install a curated list of essential packages.
- Firmware updates via `fwupdmgr`.
- Flatpak + Flathub setup.
- `ubuntu-restricted-extras` and GStreamer plugins for full codec support.
- Steam (with i386 multiarch), Brave Browser, Google Chrome, and Wine (WineHQ stable).
- Oh My Posh prompt with FiraCode Nerd Font.
- Shell environment configured in `~/.bashrc`.

### Development Environment (`scripts/development_installation.sh`)
- IntelliJ IDEA Ultimate and PyCharm Professional (extracted to `/opt/jetbrains`).
- Visual Studio Code installed via the official Microsoft APT repository.
- Docker CE with Compose plugin (official Docker repository).
- OpenJDK and Gradle (extracted to `/opt`).
- `JAVA_HOME` and `GRADLE_HOME` added to `/etc/environment` and `~/.bashrc`.

### Virtualization Stack (`scripts/virtualization_installation.sh`)
- Installs `qemu-kvm`, `libvirt-daemon-system`, `libvirt-clients`, `bridge-utils`, `virt-manager`, `virtinst`, `cpu-checker`.
- Starts and enables `libvirtd`.
- Adds the current user to the `kvm` and `libvirt` groups.

### Nvidia Drivers (`scripts/nvidia_drivers.sh`)
- Installs VA-API/VDPAU utilities and multimedia codec packages.
- Uses `ubuntu-drivers` for automatic detection and installation with a robust fallback to manual package installation.
- Installs `nvidia-cuda-toolkit`.
- Displays post-installation verification commands.

## Project Structure

```
ubuntu-post-install/
├── run.sh                              # Interactive menu launcher
├── config.env                          # User-editable general configuration
├── versions.env                        # Version-specific strings and URLs
├── README.md                           # Documentation
├── lib/
│   ├── logging.sh                      # Colour-coded log helpers & persistent logging
│   ├── output_pane.sh                  # tmux output pane driver
│   └── package_utils.sh                # apt install / dpkg-query helpers
└── scripts/
    ├── system_configuration.sh
    ├── packages_installation.sh
    ├── development_installation.sh
    ├── virtualization_installation.sh
    └── nvidia_drivers.sh
```

## License

GPL v3.0 — see [LICENSE](LICENSE) for details.

## Author

Gilberto Osuna Gonzalez
