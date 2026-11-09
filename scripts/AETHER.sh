#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "======================================================================"
echo "  >> AETHER: vroomies 3.0 : yuni <3"
echo "======================================================================"
echo "  [!] WARNING: This script will root-install vroomies to your system."
echo "  [!] It will proceed without asking for confirmation."
echo "  [!] Installation will begin in 10 seconds..."
echo "======================================================================"
sleep 10

if ! command -v paru &> /dev/null; then
    echo "[*] Installing Paru (AUR Helper)..."
    sudo pacman -S --needed --noconfirm base-devel git
    rm -rf /tmp/paru
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    chown -R $(whoami):$(whoami) /tmp/paru
    (cd /tmp/paru && makepkg -si --noconfirm)
    rm -rf /tmp/paru
fi

echo "[*] Analyzing hardware..."
if lspci | grep -i "nvidia" &> /dev/null; then
    if ! pacman -Qs nvidia &> /dev/null && ! pacman -Qs nvidia-dkms &> /dev/null; then
        echo "[*] NVIDIA GPU detected. Installing DKMS driver..."
        paru -S --needed --noconfirm nvidia-dkms nvidia-utils nvidia-settings
    fi
fi

echo "[*] Installing core system packages and dependencies..."
paru -S --needed --noconfirm \
    quickshell-git hyprland xdg-desktop-portal-hyprland xdg-desktop-portal-gtk xdg-desktop-portal-kde awww-git matugen-bin rofi-wayland \
    bluez bluez-utils libnotify jq curl gawk flatpak \
    pipewire wireplumber hyprlock 

echo "[*] Copying configuration files to ~/.config..."
mkdir -p ~/.config

if [ -d "$SCRIPT_DIR/settings" ]; then
    cp -rL "$SCRIPT_DIR/settings/"* ~/.config/
    echo "  [+] All files from settings/ copied successfully."
else
    echo "  [!] ERROR: settings/ directory not found!"
fi

echo "[*] Installing Flatpak applications..."
flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub \
    com.obsproject.Studio \
    org.kde.krita \
    com.spotify.Client \
    md.obsidian.Obsidian \
    org.videolan.VLC

echo ">> AETHER completed! You can now restart the computer <3."
