#!/usr/bin/env bash
case "$1" in
    icon)
        BLUETOOTH_STATUS=$(bluetoothctl show | grep "Powered" | awk '{print $2}')
        if [[ "$BLUETOOTH_STATUS" == "yes" ]]; then
            DEVICE_STATUS=$(bluetoothctl devices | grep "Device" | wc -l)
            if (( DEVICE_STATUS > 0 )); then
                echo "󰂯"
            else
                echo "󰂯"
            fi
        else
            echo "󰂲"
        fi
        ;;
    name)
        BLUETOOTH_STATUS=$(bluetoothctl show | grep "Powered" | awk '{print $2}')
        if [[ "$BLUETOOTH_STATUS" == "yes" ]]; then
            DEVICE_NAME=$(bluetoothctl devices | grep "Device" | awk '{print substr($0, index($0,$3))}')
            if [[ -n "$DEVICE_NAME" ]]; then
                echo "$DEVICE_NAME"
            else
                echo "None"
            fi
        else
            echo ""
        fi
        ;;
    menu)
        notify-send "Search Bluetooth devices"
        bluetoothctl power on
        bt_list=$(bluetoothctl devices | sed 's/Device //')
        device_names=$(echo "$bt_list" | awk '{$1=""; print substr($0,2)}')

        powered=$(bluetoothctl show | grep "Powered: yes")
        if [ -n "$powered" ]; then
            toggle="󰂯  Disable Bluetooth"
        else
            toggle="󰂯  Enable Bluetooth"
        fi

        chosen_device_name=$(echo -e "$toggle\n$device_names" | rofi -dmenu -i -theme ~/.config/rofi/network.rasi -selected-row 1 -p "Bluetooth: ")

        if [ -z "$chosen_device_name" ]; then
            exit
        fi

        if [ "$chosen_device_name" = "󰂯  Enable Bluetooth" ]; then
            bluetoothctl power on
        elif [ "$chosen_device_name" = "󰂯  Disable Bluetooth" ]; then
            bluetoothctl power off
        else
            chosen_mac=$(echo "$bt_list" | grep "$chosen_device_name" | awk '{print $1}')
            pairing_output=$(bluetoothctl pair "$chosen_mac")

            if echo "$pairing_output" | grep -q "Request.*PIN code"; then
                pin_code=$(rofi -dmenu -theme ~/.config/rofi/network.rasi -p "PIN Kodu: " -lines 0)
                echo "$pin_code" | bluetoothctl pair "$chosen_mac"
            elif echo "$pairing_output" | grep -q "Request.*confirmation"; then
                confirmation=$(echo -e "yes\nno" | rofi -dmenu -theme ~/.config/rofi/network.rasi -p "Onayla? " -selected-row 0)
                if [ "$confirmation" = "yes" ]; then
                    echo "yes" | bluetoothctl pair "$chosen_mac"
                else
                    echo "no" | bluetoothctl pair "$chosen_mac"
                    exit
                fi
            fi

            bluetoothctl trust "$chosen_mac"
            bluetoothctl connect "$chosen_mac"

            if bluetoothctl info "$chosen_mac" | grep -q "Connected: yes"; then
                notify-send "Bluetooth" "Bağlandı: \"$chosen_device_name\"."
            else
                notify-send "Bluetooth" "Bağlantı başarısız: \"$chosen_device_name\"."
            fi
        fi
        ;;
    *)
        echo "Kullanım: $0 {icon|name|menu}"
        ;;
esac

