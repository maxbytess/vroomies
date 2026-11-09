#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "======================================================================"
echo "  >> PHANTOM: vroomies 3.0 : yuni <3"
echo "======================================================================"
echo "  [!] WARNING: This script will root-install vroomies to your system."
echo "  [!] It will proceed without asking for confirmation."
echo "  [!] Installation will begin in 10 seconds..."
echo "======================================================================"
sleep 10

echo "[*] Enabling Void nonfree repo and updating database..."
sudo xbps-install -Sy void-repo-nonfree
sudo xbps-install -Sy

echo "[*] Analyzing hardware..."
if lspci | grep -i "nvidia" &> /dev/null; then
    if ! xbps-query -l | grep -i "nvidia" &> /dev/null; then
        echo "[*] NVIDIA GPU detected. Installing driver..."
        sudo xbps-install -Sy nvidia nvidia-gtklibs
    fi
fi

echo "[*] Installing core system packages..."
sudo xbps-install -Sy \
    hyprland hyprland-devel xdg-desktop-portal-hyprland rofi-wayland bluez libnotify jq curl gawk flatpak \
    pipewire wireplumber dbus hyprlock

echo "[*] Linking Runit services..."
sudo ln -s /etc/sv/bluetoothd /var/service/ 2>/dev/null || true
sudo ln -s /etc/sv/dbus /var/service/ 2>/dev/null || true

echo "[*] Copying configuration files to ~/.config..."
mkdir -p ~/.config

if [ -d "$SCRIPT_DIR/settings" ]; then
    cp -rL "$SCRIPT_DIR/settings/"* ~/.config/
    echo "  [+] All files from settings/ copied successfully."
else
    echo "  [!] ERROR: settings/ directory not found!"
fi

echo "[*] Installing Flatpak applications..."
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub \
    com.obsproject.Studio \
    org.kde.krita \
    com.spotify.Client \
    md.obsidian.Obsidian \
    org.videolan.VLC

echo ">> PHANTOM completed! You can now restart the computer <3"
