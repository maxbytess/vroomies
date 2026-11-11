 <div align="center">

# • installation · Fedora •

[← back to README](../README.md)

Everything needed to build and run **yunies** on Fedora Linux.

</div>

> [!WARNING]
> This setup does **not** install GPU drivers automatically. If you're using a minimal Fedora installation, make sure your GPU drivers are installed before proceeding. Hyprland requires working graphics drivers to start.

## • 0. GPU drivers (minimal Fedora only) •

Choose the packages matching your GPU:

```bash
# AMD
sudo dnf install mesa-dri-drivers mesa-vulkan-drivers mesa-va-drivers

# Intel
sudo dnf install mesa-dri-drivers mesa-vulkan-drivers intel-media-driver

# NVIDIA (proprietary, RPM Fusion)
sudo dnf install akmod-nvidia xorg-x11-drv-nvidia-cuda
```

### NVIDIA users

NVIDIA proprietary drivers require RPM Fusion to be enabled first:

```bash
sudo dnf install \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
```

> Already running a working desktop environment (GNOME, KDE, etc.)? Your GPU drivers are most likely installed. You can skip this step.

## • 1. Build dependencies •

Install the tools required to build and install the setup:

```bash
sudo dnf install git curl @development-tools
```

| Package | Purpose |
| --- | --- |
| **@development-tools** | Compiler toolchain for building packages |
| **git** | Cloning the repository and accessing COPR packages |
| **curl** | Fetching remote assets and installer resources |

## • 2. Runtime dependencies •

These packages are required for the desktop environment and its components:

| Package | Purpose |
| --- | --- |
| **hyprland** | Wayland compositor (via COPR) |
| **quickshell-git** | Widget system, bar, launcher and wallpaper selector (via COPR) |
| **hyprlock** | Lock screen |
| **rofi-wayland** | Application launcher and power menu |
| **xdg-desktop-portal-hyprland** | Hyprland screen sharing and portals (via COPR) |
| **xdg-desktop-portal-gtk** | GTK application portals |
| **xdg-desktop-portal-kde** | KDE and Qt application portals |
| **pipewire** | Audio server |
| **wireplumber** | PipeWire session manager |
| **bluez / bluez-tools** | Bluetooth support |
| **libnotify** | Desktop notifications |
| **jq / gawk** | JSON and text processing |
| **matugen** | Wallpaper-based color generation (via COPR) |
| **awww** | Wallpaper daemon |

## • 3. Optional applications (Flatpak) •

The installer can also install the following applications through Flatpak:

| Application | Purpose |
| --- | --- |
| **com.obsproject.Studio** | OBS Studio |
| **org.kde.krita** | Krita |
| **com.spotify.Client** | Spotify |
| **md.obsidian.Obsidian** | Obsidian |
| **org.videolan.VLC** | VLC media player |

## • 4. Install yunies •

Clone the repository and run the installer:

```bash
git clone https://github.com/maxbytess/vroomies.git
cd vroomies

chmod +x IGNITE.sh
./IGNITE.sh
```

The installer starts automatically after a **10-second countdown**.

It will:

1. Enable the required COPR repositories.
2. Install `quickshell-git` and `matugen` through COPR.
3. Install Hyprland and `xdg-desktop-portal-hyprland` through COPR.
4. Install the remaining runtime dependencies through `dnf`.
5. Copy the `settings/` directory into `~/.config/`.
6. Install the optional Flatpak applications.

> [!NOTE]
> Fedora does not ship the required Hyprland packages through its standard repositories. The setup uses the `ashbuk/Hyprland-Fedora` COPR for Hyprland and `errornointernet/quickshell` for Quickshell. These repositories are community-maintained and are not officially supported by Fedora.

## • 5. Post-installation •

Once the installation is complete:

1. Log out and select **Hyprland** from your display manager.
2. Alternatively, launch Hyprland directly from a TTY:

```bash
Hyprland
```

### Default keybindings

| Shortcut | Action |
| --- | --- |
| `Super + /` | Show keybinding list |
| `Super + Enter` | Open terminal |
| `Super + Q` | Close active window |

## • 6. Troubleshooting •

**Hyprland won't start**

Check the system logs:

```bash
journalctl --user -u hyprland
```

A missing or incorrectly configured GPU driver is a common cause. See step 0.

**COPR repository fails to enable**

Make sure `dnf-plugins-core` is installed:

```bash
sudo dnf install dnf-plugins-core
```

**Quickshell or Hyprland package not found**

The COPR repositories may not yet support your Fedora version. Check their availability or update your system:

```bash
sudo dnf upgrade --refresh
```

**Package installation fails**

Fedora does not use the AUR. Check that the required COPR repositories are enabled and that your Fedora version is supported.

**Flatpak applications are not appearing**

Try launching the application manually:

```bash
flatpak run <app-id>
```

Alternatively, log out and back in.

---

<div align="center">

**yunies · Fedora Linux**

</div>
