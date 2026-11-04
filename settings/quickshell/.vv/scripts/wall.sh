#!/usr/bin/env bash

# Sadece dogrudan bir dosya yolu ile cagrilir (Settings > Duvar Kagidi > Kaydet
# ve bar'daki duvar kagidi ikonu, zenity ile secilen dosyayi buraya yollar).
# Eski "argumansiz cagrilirsa secici ac" davranisi kaldirildi - artik secim
# tamamen zenity (xdg-desktop-portal-gtk) uzerinden yapiliyor.

SYMLINK_PATH="$HOME/.config/hypr/current_wallpaper"
SELECTED_PATH="${1:-}"

if [[ -z "$SELECTED_PATH" ]]; then
    echo "Kullanim: wall.sh <resim-dosyasi>" >&2
    exit 1
fi

[[ ! -f "$SELECTED_PATH" ]] && exit 1

ln -sf "$SELECTED_PATH" "$SYMLINK_PATH"

awww img "$SELECTED_PATH" \
    -o eDP-1 \
    --transition-type grow \
    --transition-pos bottom-left \
    --transition-duration 1.2 \
    --transition-fps 144 \
    --transition-bezier 0.16,1,0.3,1 \
    --resize crop &

matugen image "$SELECTED_PATH" --source-color-index 0
wallust run "$SELECTED_PATH"

pkill -9 quickshell || true
sleep 0.3
setsid nohup env QML_XHR_ALLOW_FILE_READ=1 quickshell --path "$HOME/.config/quickshell/vv/shell.qml" \
    > /tmp/quickshell.log 2>&1 &
disown


