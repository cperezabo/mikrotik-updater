#!/bin/bash

echo "MikroTik Updater"
echo "Version: 1.4.0"
echo "Created by Cristián Pérez"
echo "--------------------------"

updaterpath="$( cd "$(dirname "$0")" ; pwd -P )"
sourcefile="$updaterpath/sources/$1"

if [[ -f "$sourcefile" ]]; then
    source "$sourcefile"
else
    if [[ -f "$1" ]]; then
        source "$1"
    else
        echo "Source file doesn't exists"
        exit 1
    fi
fi

if [[ -n "$private_key" && ! -f "$private_key" ]]; then
    echo "Specified Private Key doesn't exists"
    exit 1
fi

ros_command () {
    local ssh_command="ssh -o ConnectTimeout=5"

    if [[ -n "$private_key" ]]; then
        ssh_command+=" -i $private_key"
    fi

    $ssh_command -l "$username" "$h" "$1" 2>/dev/null
}

system_update_command() {
    ros_command "/system package update $1" | xargs -I % bash -c "tput el && echo -ne '%\r' | sed -e 's/^[ \\t]*status:/  --> Updating system 🛠:/g'";
}

for h in "${hosts[@]}"
do
    echo
    echo "Gathering information from $h ..."
    device_name="$(ros_command ':put [/system identity get name]')"
    device_name="${device_name%?}" # the name comes with an extra character at the end so we remove it.

    if [ -z "$device_name" ]; then
        echo "  --> Failed to gather information. Skipping update. ⚠️"
        continue
    fi

    echo "Checking for updates on $device_name ($h) ..."
    ros_command '/system package update check-for-updates once' > /dev/null
    status="$(ros_command ':put [/system package update get status]')"

    if [[ $status == *"System is already up to date"* ]];
    then
        echo "  --> System up to date 👍"

        firmware_cur="$(ros_command ':put [/system routerboard get current-firmware]')"
        firmware_upd="$(ros_command ':put [/system routerboard get upgrade-firmware]')"

        if [[ $firmware_cur == $firmware_upd ]];
        then
            echo "  --> Firmware up to date 👍"
        else
            echo "  --> Updating firmware 🛠 ... "
            ros_command '/system routerboard upgrade'
            ros_command ':execute "/system reboot"' # I think it only works if auto-upgrade=yes
            echo "  --> Firmware updated 👍"
            echo "  --> Rebooting ..."
        fi
    else
        system_update_command 'check-for-updates'
        system_update_command 'install'
        echo "  --> System updated 👍"
        echo "  --> Rebooting ..."
    fi
done
