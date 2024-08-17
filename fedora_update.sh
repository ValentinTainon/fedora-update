#!/usr/bin/bash

### COLORS VARS ###
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
RESET_CLR="\e[0m"


### START OF SCRIPT ###
is_update_available="false"
pkg_need_reboot=""

### TEST ROOT ###
if [ "$(whoami)" != "root" ]; then
    echo -e "[${RED} ERROR ${RESET_CLR}] Unauthorized user. Please restart the script as root."
    exit 1
fi

### BIOS & FIRMWARES ###
bios_device_version=$(sudo dmidecode -t bios | grep -Po '(?<=Version: )\d+')
bios_latest_version=1663

if [[ $bios_device_version -lt $bios_latest_version ]]; then
    is_update_available="true"
    bios_website_url="https://rog.asus.com/fr/motherboards/rog-strix/rog-strix-b760-i-gaming-wifi-model/helpdesk_bios/"

    echo -e "${MAGENTA}BIOS:${RESET_CLR}"

    echo -e "New BIOS version available! Download it from:
    ${CYAN}${bios_website_url}${RESET_CLR}
    " | sed 's/^[ \t]*//'

    echo -e "${YELLOW}Press enter to continue executing the script...${RESET_CLR}"
    read response
fi

if ! fwupdmgr get-updates 2>&1 | grep -q "No updates available"; then
    is_update_available="true"

    echo -e "${MAGENTA}FIRMWARES:${RESET_CLR}"

    sudo fwupdmgr update
fi

### RPM ###
dnf check-update >/dev/null 2>&1

if [[ $? -eq 100 ]]; then
    is_update_available="true"

    echo -e "${MAGENTA}RPM:${RESET_CLR}"

    sudo dnf update

    if [[ $? -eq 0 ]]; then
        pkg_need_reboot=$(dnf history info last | grep -Eo '(dbus-broker|glibc|kernel|linux-firmware|systemd)' | sort | uniq | xargs)
    fi
fi

### FLATPAK ###
if ! flatpak update | grep -q "Nothing to do"; then
    is_update_available="true"

    echo -e "${MAGENTA}FLATPAK:${RESET_CLR}"

    flatpak update
fi

if [ "$is_update_available" == "false" ]; then
    echo "No updates available."
    exit 0
fi

if [[ -n "$pkg_need_reboot" ]]; then
    echo -ne "${YELLOW}Restart required: ${CYAN}$pkg_need_reboot ${YELLOW}has been updated, restart now? [y/N] : ${RESET_CLR}"
    read response
    
    if [ "$response" == "y" ]; then
        reboot
    else
        exit 0
    fi
fi
### END OF SCRIPT ###