 <div align="center">

# • installation · Arch Linux •

[← back to README](../README.md)

Everything needed to build and run **yunies** on Arch Linux.

</div>

> [!WARNING]
> This setup does **not** install GPU drivers automatically. If you're using a minimal Arch Linux installation, make sure your GPU drivers are installed before proceeding. Hyprland requires working graphics drivers to start.

## • 0. GPU drivers (minimal Arch only) •

Choose the packages matching your GPU:

```bash
# AMD
sudo pacman -S --needed mesa vulkan-radeon libva-mesa-driver mesa-vdpau

# Intel
sudo pacman -S --needed mesa vulkan-intel intel-media-driver

# NVIDIA (proprietary, DKMS)
sudo pacman -S --needed nvidia-dkms nvidia-utils nvidia-settings

# NVIDIA (open kernel modules, RTX 20xx+)
sudo pacman -S --needed nvidia-open-dkms nvidia-utils nvidia-settings
```

> Already running a working desktop environment (GNOME, KDE, etc.)? Your GPU drivers are most likely installed. You can skip this step.

## • 1. Build dependencies •

Install the tools required to build and install the setup:

```bash
sudo pacman -S --needed base-devel git curl
```

| Package | Purpose |
| --- | --- |
| **base-devel** | Compiler toolchain for building AUR packages |
| **git** | Cloning the repository and AUR packages |
| **curl** | Fetching remote assets and installer resources |

## • 2. Runtime dependencies •

These packages are required for the desktop environment and its components:

| Package | Purpose |
| --- | --- |
| **hyprland** | Wayland compositor |
| **quickshell-git** | Widget system, bar, launcher and wallpaper selector |
| **hyprlock** | Lock screen |
| **rofi-wayland** | Application launcher and power menu |
| **xdg-desktop-portal-hyprland** | Hyprland screen sharing and portals |
| **xdg-desktop-portal-gtk** | GTK application portals |
| **xdg-desktop-portal-kde** | KDE and Qt application portals |
| **pipewire** | Audio server |
| **wireplumber** | PipeWire session manager |
| **bluez / bluez-utils** | Bluetooth support |
| **libnotify** | Desktop notifications |
| **jq / gawk** | JSON and text processing |
| **matugen-bin** | Wallpaper-based color generation |
| **awww-git** | Wallpaper daemon |

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

chmod +x AETHER.sh
./AETHER.sh
```

The installer starts automatically after a **10-second countdown**.

It will:

1. Install `paru` if it is not already available.
2. Detect NVIDIA hardware and install the required NVIDIA packages if needed.
3. Install runtime dependencies through `paru`.
4. Copy the `settings/` directory into `~/.config/`.
5. Install the optional Flatpak applications.

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

**`paru: command not found`**

Install `paru` manually from the AUR or run the installer again.

**AUR package fails to build**

Make sure `base-devel` is installed and update your system:

```bash
sudo pacman -Syu
```

**Flatpak applications are not appearing**

Try launching the application manually:

```bash
flatpak run <app-id>
```

Alternatively, log out and back in.

---

<div align="center">

**yunies · Arch Linux**

</div>
