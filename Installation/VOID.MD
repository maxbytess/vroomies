 <div align="center">

# • installation · Void Linux •

[← back to README](../README.md)

Everything needed to build and run **yunies** on Void Linux.

</div>

> [!WARNING]
> This setup does **not** install GPU drivers automatically. If you're using a minimal Void Linux installation, make sure your GPU drivers are installed before proceeding. Hyprland requires working graphics drivers to start.

## • 0. GPU drivers (minimal Void only) •

Choose the packages matching your GPU:

```bash
# AMD
sudo xbps-install -S mesa-dri mesa-vulkan-radeon mesa-vaapi mesa-vdpau

# Intel
sudo xbps-install -S mesa-dri mesa-vulkan-intel intel-media-driver

# NVIDIA (requires nonfree repository)
sudo xbps-install -S void-repo-nonfree
sudo xbps-install -Su nvidia
```

### NVIDIA users

Void provides versioned NVIDIA packages for different GPU generations. Identify your GPU family first:

```bash
lspci -k -d ::03xx
```

Install the matching package:

| Package | GPU generation |
| --- | --- |
| **nvidia** | Current supported GPUs |
| **nvidia580** | Older supported GPUs |
| **nvidia470** | Legacy GPUs |
| **nvidia390** | Older legacy GPUs |

> Already running a working desktop environment? Your GPU drivers are most likely installed. You can skip this step.

## • 1. Build dependencies •

Install the tools required to build and install the setup:

```bash
sudo xbps-install -S base-devel git curl
```

| Package | Purpose |
| --- | --- |
| **base-devel** | Compiler toolchain for building packages |
| **git** | Cloning the repository |
| **curl** | Fetching remote assets and installer resources |

## • 2. Runtime dependencies •

These packages are required for the desktop environment and its components:

| Package | Purpose | Source |
| --- | --- | --- |
| **hyprland** | Wayland compositor | Hyprland-Void |
| **quickshell** | Widget system, bar, launcher and wallpaper selector | Official Void repository |
| **hyprlock** | Lock screen | Hyprland-Void |
| **rofi** | Application launcher and power menu | Official Void repository |
| **xdg-desktop-portal-hyprland** | Hyprland screen sharing and portals | Hyprland-Void |
| **xdg-desktop-portal-gtk** | GTK application portals | Official Void repository |
| **xdg-desktop-portal-kde** | KDE and Qt application portals | Official Void repository |
| **pipewire** | Audio server | Official Void repository |
| **wireplumber** | PipeWire session manager | Official Void repository |
| **bluez** | Bluetooth daemon | Official Void repository |
| **bluez-utils** | Bluetooth command-line tools | Official Void repository |
| **libnotify** | Desktop notifications | Official Void repository |
| **jq** | JSON processing | Official Void repository |
| **gawk** | Text processing | Official Void repository |
| **matugen** | Wallpaper-based color generation | Official Void repository |
| **awww** | Wallpaper daemon | Official Void repository |

### Package notes

- `quickshell`, `matugen`, and `awww` are available through Void repositories according to the setup's package assumptions.
- `rofi-wayland` is not included in the package list. The setup uses standard `rofi` as a fallback.
- Depending on repository synchronization, `awww` may appear under a different package name or have a transitional `swww` package available.
- You can search for available packages using `xbps-query -Rs`.

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

chmod +x PHANTOM.sh
./PHANTOM.sh
```

The installer starts automatically after a **10-second countdown**.

It will:

1. Add the Hyprland-Void repository to `/etc/xbps.d/`.
2. Synchronize repositories and accept the repository fingerprint.
3. Install `hyprland`, `hyprlock`, and `xdg-desktop-portal-hyprland`.
4. Install the remaining runtime dependencies through XBPS.
5. Copy the `settings/` directory into `~/.config/`.
6. Install the optional Flatpak applications.

> [!NOTE]
> Void does not ship the required Hyprland packages through its official repositories. The setup uses the community-maintained **Hyprland-Void** repository, which provides prebuilt binaries for supported architectures, including `x86_64-glibc`, `x86_64-musl`, and ARM variants. These are not official Void packages.

### Adding the repository manually

If the installer fails to configure the repository, you can add it manually.

For **x86_64 glibc** (most common):

```bash
echo 'repository=https://raw.githubusercontent.com/Makrennel/hyprland-void/repository-x86_64-glibc' | sudo tee /etc/xbps.d/hyprland-void.conf

# Synchronize repositories
sudo xbps-install -S

# Install Hyprland packages
sudo xbps-install -S hyprland hyprlock xdg-desktop-portal-hyprland
```

> If you're using **musl**, replace `repository-x86_64-glibc` with `repository-x86_64-musl` in the repository URL.

## • 5. Post-installation •

Once the installation is complete:

1. Log out and select **Hyprland** from your display manager.
2. Alternatively, launch Hyprland directly from a TTY:

```bash
Hyprland
```

### Seat management

Hyprland may require your user to belong to the `_seatd` group:

```bash
sudo usermod -aG _seatd $USER
```

Log out and back in for the group change to take effect.

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

**Hyprland package not found**

The Hyprland-Void repository may not have been added or synchronized correctly. Check whether the repository configuration exists:

```bash
cat /etc/xbps.d/hyprland-void.conf
sudo xbps-install -S
```

**NVIDIA black screen**

Make sure the correct NVIDIA package is installed for your GPU generation. Older GPUs may require a versioned package such as `nvidia470` or `nvidia390`, rather than the default `nvidia` package.

**`rofi-wayland` not found**

The setup uses the standard `rofi` package as a fallback. Check whether a Wayland-specific package is available in your enabled repositories.

**`awww` not found**

Search for both package names:

```bash
xbps-query -Rs awww
xbps-query -Rs swww
```

**Flatpak applications are not appearing**

Try launching the application manually:

```bash
flatpak run <app-id>
```

Alternatively, log out and back in.

---

<div align="center">

**yunies · Void Linux**

</div>
