#!/bin/bash

echo "MikroTik Updater"
echo "Version: 1.3.0"
echo "Created by: Cristián Pérez"
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

if [[ ! -f "$private_key" ]]; then
    echo "Specified Private Key doesn't exists"
    exit 1
fi

ros_command () {
    ssh -o ConnectTimeout=5 -i $private_key -l $username $h $1
}

for h in "${hosts[@]}"
do
    echo
    echo "Gathering information from $h ..."
    device_name="$(ros_command ':put [/system identity get name]')"
    device_name="${device_name%?}" # the name comes with an extra character at the end so we remove it.

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
        ros_command '/system package update install' | xargs -I % bash -c "tput el && echo -ne '%\r' | sed -e 's/^[ \\t]*status:/  --> Updating system 🛠:/g'";
        echo "  --> System updated 👍"
        echo "  --> Rebooting ..."
    fi
done
