#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "======================================================================"
echo "  >> IGNITE: vroomies 3.0 : yuni <3"
echo "======================================================================"
echo "  [!] WARNING: This script will root-install vroomies to your system."
echo "  [!] It will proceed without asking for confirmation."
echo "  [!] Installation will begin in 10 seconds..."
echo "======================================================================"
sleep 10

echo "[*] Enabling RPM Fusion repositories..."
sudo dnf install -y \
    https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
    https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

echo "[*] Analyzing hardware..."
if lspci | grep -i "nvidia" &> /dev/null; then
    if ! rpm -q akmod-nvidia &> /dev/null; then
        echo "[*] NVIDIA GPU detected. Installing AKMOD driver..."
        sudo dnf install -y akmod-nvidia xorg-x11-drv-nvidia-cuda
    fi
fi

echo "[*] Installing core system packages from official repos..."
sudo dnf install -y niri rofi-wayland bluez bluez-tools libnotify jq curl gawk flatpak hyprlock

echo "[*] Enabling COPR repos and installing customization tools..."
sudo dnf copr enable -y keyitdev/quickshell || true
sudo dnf copr enable -y varlad/niri-tools || true
sudo dnf install -y quickshell matugen awww || echo "[!] Warning: Some COPR packages failed to install, continuing..."

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

echo ">> IGNITE completed! You can now restart the computer <3 "
