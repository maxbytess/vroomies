#!/usr/bin/env bash

# Nerd Font icons (as UTF-8 byte sequences, locale-independent)
ICON_CONNECTED=$'\xf3\xb0\xa4\xa8'   # U+F0928
ICON_DISCONNECTED=$'\xf3\xb0\xa4\xaf' # U+F092F
ICON_OFF=$'\xf3\xb0\xa4\xae'         # U+F092E
ICON_ENABLE=$'\xf3\xb0\x96\xa9'      # U+F05A9
ICON_DISABLE=$'\xf3\xb0\x96\xaa'     # U+F05AA
LOCK=$'\xef\x80\xa3'                 # U+F023
UNLOCK=$'\xef\x82\x9c'               # U+F09C

THEME="$HOME/.config/rofi/network.rasi"

active_ssid() {
    nmcli -t -e no -f active,ssid dev wifi | grep '^yes' | cut -d: -f2- | head -n1
}

case "$1" in
    icon)
        if [ "$(nmcli radio wifi)" = "enabled" ]; then
            if [ -n "$(active_ssid)" ]; then
                echo "$ICON_CONNECTED"
            else
                echo "$ICON_DISCONNECTED"
            fi
        else
            echo "$ICON_OFF"
        fi
        ;;
    ssid)
        if [ "$(nmcli radio wifi)" = "enabled" ]; then
            ssid=$(active_ssid)
            if [ -n "$ssid" ]; then
                echo "$ssid"
            else
                echo "Not connected"
            fi
        else
            echo "Off"
        fi
        ;;
    menu)
        if [ "$(nmcli radio wifi)" = "disabled" ]; then
            toggle="$ICON_ENABLE  Enable Wi-Fi"
            wifi_list=""
        else
            toggle="$ICON_DISABLE  Disable Wi-Fi"
            wifi_list=$(nmcli -t -e no -f SECURITY,SSID device wifi list | while IFS= read -r line; do
                sec=${line%%:*}
                ssid=${line#*:}
                [ -z "$ssid" ] && continue
                if [ -n "$sec" ] && [ "$sec" != "--" ]; then
                    printf '%s  %s\n' "$LOCK" "$ssid"
                else
                    printf '%s  %s\n' "$UNLOCK" "$ssid"
                fi
            done | sort -u)
        fi

        chosen_entry=$(printf '%s\n%s\n' "$toggle" "$wifi_list" | rofi -dmenu -i -theme "$THEME" -selected-row 1 -p "Wi-Fi: ")

        [ -z "$chosen_entry" ] && exit 0

        case "$chosen_entry" in
            *"Enable Wi-Fi")  nmcli radio wifi on;  exit 0 ;;
            *"Disable Wi-Fi") nmcli radio wifi off; exit 0 ;;
        esac

        chosen_id=$(printf '%s' "$chosen_entry" | sed 's/^[^ ]* *//')

        if nmcli -t -e no -f NAME connection | grep -qFx -- "$chosen_id"; then
            notify-send "Network" "Connecting to: $chosen_id..."
            if nmcli connection up id "$chosen_id"; then
                notify-send "Network" "Connected to: \"$chosen_id\""
            else
                notify-send "Network" "Could not connect to: \"$chosen_id\". If the password changed, delete the saved profile and try again."
            fi
        elif [[ "$chosen_entry" == "$LOCK"* ]]; then
            wifi_password=$(printf '' | rofi -dmenu -password -theme "$THEME" -theme-str 'listview { lines: 0; }' -p "Password: ")
            [ -z "$wifi_password" ] && exit 0

            notify-send "Network" "Connecting to: $chosen_id..."
            if nmcli device wifi connect "$chosen_id" password "$wifi_password"; then
                notify-send "Network" "Connected to: \"$chosen_id\""
            else
                notify-send "Network" "Connection failed! Check the password."
            fi
        else
            notify-send "Network" "Connecting to: $chosen_id..."
            if nmcli device wifi connect "$chosen_id"; then
                notify-send "Network" "Connected to: \"$chosen_id\""
            else
                notify-send "Network" "Connection failed!"
            fi
        fi
        ;;
    *)
        echo "Usage: $0 {icon|ssid|menu}"
        ;;
esac