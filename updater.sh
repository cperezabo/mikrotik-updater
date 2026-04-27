#!/bin/bash

if [[ -t 1 ]]; then
    bold=$'\033[1m'
    boldoff=$'\033[22m'
    default=$'\033[39m'
    green=$'\033[32m'
    bgreen=$'\033[92m'
    yellow=$'\033[33m'
    red=$'\033[31m'
    cyan=$'\033[36m'
    dim=$'\033[2m'
    reset=$'\033[0m'
else
    bold='' boldoff='' default='' green='' bgreen='' yellow='' red='' cyan='' dim='' reset=''
fi

echo "${bold}MikroTik Updater v1.4.1${reset}"
echo "--------------------------"

updaterpath="$( cd "$(dirname "$0")" ; pwd -P )"
sourcefile="$updaterpath/sources/$1"

if [[ -f "$sourcefile" ]]; then
    source "$sourcefile"
else
    if [[ -f "$1" ]]; then
        source "$1"
    else
        echo "${red}Source file doesn't exists${reset}"
        exit 1
    fi
fi

if [[ -n "$private_key" && ! -f "$private_key" ]]; then
    echo "${red}Specified Private Key doesn't exists${reset}"
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
    local rendered=0
    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue
        case "$line" in
            *status:*) line="${cyan}  --> Updating system 🛠️:${line#*status:}${reset}" ;;
        esac
        printf '\r\033[K%s' "$line"
        rendered=1
    done < <(ros_command "/system package update $1")
    (( rendered )) && printf '\n'
}

for h in "${hosts[@]}"
do
    echo
    echo "Gathering information from ${bold}$h${reset} ..."
    device_name="$(ros_command ':put [/system identity get name]')"
    device_name="${device_name%?}" # the name comes with an extra character at the end so we remove it.

    if [ -z "$device_name" ]; then
        echo "${yellow}  --> Failed to gather information. Skipping update. ⚠️${reset}"
        continue
    fi

    echo "Checking for updates on ${bold}$device_name${reset} (${bold}$h${reset}) ..."
    ros_command '/system package update check-for-updates once' > /dev/null
    installed_version="$(ros_command ':put [/system package update get installed-version]')"
    installed_version="${installed_version%?}"
    latest_version="$(ros_command ':put [/system package update get latest-version]')"
    latest_version="${latest_version%?}"

    if [[ "$installed_version" == "$latest_version" ]];
    then
        echo "${green}  --> System up to date (${default}${bold}$installed_version${boldoff}${green}) 👍${reset}"

        firmware_cur="$(ros_command ':put [/system routerboard get current-firmware]')"
        firmware_cur="${firmware_cur%?}"
        firmware_upd="$(ros_command ':put [/system routerboard get upgrade-firmware]')"
        firmware_upd="${firmware_upd%?}"

        if [[ $firmware_cur == $firmware_upd ]];
        then
            echo "${green}  --> Firmware up to date (${default}${bold}$firmware_cur${boldoff}${green}) 👍${reset}"
        else
            echo "${cyan}  --> Updating firmware 🛠️ ... ${reset}"
            ros_command '/system routerboard upgrade'
            ros_command ':execute "/system reboot"' # I think it only works if auto-upgrade=yes
            echo "${bgreen}  --> Firmware updated from ${default}${bold}$firmware_cur${boldoff}${bgreen} to ${default}${bold}$firmware_upd${boldoff}${bgreen} 🎉${reset}"
            echo "${dim}  --> Rebooting ...${reset}"
        fi
    else
        system_update_command 'check-for-updates'
        system_update_command 'install'
        echo "${bgreen}  --> System updated from ${default}${bold}$installed_version${boldoff}${bgreen} to ${default}${bold}$latest_version${boldoff}${bgreen} 🎉${reset}"
        echo "${dim}  --> Rebooting ...${reset}"
    fi
done
