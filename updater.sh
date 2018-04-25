#!/bin/bash

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

ros_command () {
    ssh -i $private_key -l $username $h $1
}

echo "MikroTik Updater"
echo "Version: 1.0.0"
echo "Created by: Cristián Pérez"
echo "--------------------------"

for h in "${hosts[@]}"
do
    echo
    echo "Gathering information from $h ..."
    ros_command '/system package update check-for-updates once' > /dev/null
    status="$(ros_command ':put [/system package update get status]')"

    if [[ $status == *"System is already up to date"* ]];
    then
        echo "  --> System up to date 👍🏻"
    else
        echo "  --> Updating system 🛠 ... "
        ros_command '/system package update install' > /dev/null
        echo "  --> Device rebooted 👍🏻"
    fi
done
