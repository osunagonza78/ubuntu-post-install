# Ubuntu Post-Install Tool

A comprehensive post-installation configuration tool for Ubuntu Linux that automates system setup, package installation, driver configuration, and development environment provisioning through an interactive terminal menu.

## Features

- Interactive arrow-key menu with a split tmux pane for live output streaming
- Modular scripts — run only what you need
- Idempotent where possible — safe to re-run

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

If `tmux` is available the tool launches automatically in a split-pane session — menu on the left, live output on the right. Without `tmux` scripts run inline.

## Menu Options

| # | Option | Description |
|---|--------|-------------|
| 0 | **System Configuration** | Full system upgrade, boot optimisation |
| 1 | **Packages Installation** | Codecs, fonts, browsers, Wine, Steam, Oh My Posh |
| 2 | **Development Environment** | JetBrains IDEs, VS Code, Docker, OpenJDK 21, Gradle |
| 3 | **Virtualization Stack** | KVM/QEMU, libvirt, virt-manager |
| 4 | **Nvidia Drivers** | Hardware acceleration, ubuntu-drivers autoinstall, CUDA |
| 5 | **Exit** | |

## Script Details

### System Configuration (`scripts/system_configuration.sh`)
- Runs `apt full-upgrade` and cleans up orphaned packages
- Disables `NetworkManager-wait-online.service` to reduce boot time
- Reboots the system on completion

### Packages Installation (`scripts/packages_installation.sh`)
- Firmware updates via `fwupdmgr`
- Flatpak + Flathub setup
- `ubuntu-restricted-extras` and GStreamer plugins for full codec support
- Essential packages: p7zip, unrar, btop, vim, git, VLC, GIMP, GParted, and more
- Steam (with i386 multiarch)
- fastfetch (via PPA)
- Microsoft TrueType fonts
- Oh My Posh prompt with FiraCode Nerd Font
- Brave Browser
- Google Chrome
- Wine (WineHQ stable)
- Shell environment configured in `~/.bashrc`

### Development Environment (`scripts/development_installation.sh`)
- IntelliJ IDEA Ultimate and PyCharm Professional (extracted to `/opt/jetbrains`)
- Visual Studio Code (extracted to `/opt/vscode`)
- Docker CE with Compose plugin (official Docker repository)
- OpenJDK 21 (extracted to `/opt/java`)
- Gradle 8.14.4 (extracted to `/opt/gradle`)
- `JAVA_HOME` and `GRADLE_HOME` added to `/etc/environment` and `~/.bashrc`

### Virtualization Stack (`scripts/virtualization_installation.sh`)
- Installs `qemu-kvm`, `libvirt-daemon-system`, `libvirt-clients`, `bridge-utils`, `virt-manager`, `virtinst`, `cpu-checker`
- Starts and enables `libvirtd`
- Adds the current user to the `kvm` and `libvirt` groups

> **Note:** Log out and back in after this step for group membership to take effect.

### Nvidia Drivers (`scripts/nvidia_drivers.sh`)
- Installs VA-API/VDPAU utilities and multimedia codec packages
- Runs `ubuntu-drivers autoinstall` to detect and install the recommended driver
- Installs `nvidia-cuda-toolkit`
- Displays post-installation verification commands

> **Note:** A reboot is required for the NVIDIA kernel module to load.

## Project Structure

```
ubuntu-post-install/
├── run.sh                              # Interactive menu launcher
├── lib/
│   ├── logging.sh                      # Colour-coded log helpers
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
