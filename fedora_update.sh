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
if ! fwupdmgr get-updates 2>&1 | grep -qi "no updates available"; then
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
if ! flatpak update | grep -qi "nothing to do"; then
    is_update_available="true"

    echo -e "${MAGENTA}FLATPAK:${RESET_CLR}"

    sudo flatpak update
fi

if [ "$is_update_available" == "false" ]; then
    echo "No updates available."
    exit 0
fi

if [[ -n "$pkg_need_reboot" ]]; then
    echo -ne "${YELLOW}Restart required: ${CYAN}$pkg_need_reboot ${YELLOW}has been updated, restart now? [Y/n] : ${RESET_CLR}"
    read response
    
    if [ "$response" == "n" ]; then
        exit 0
    else
        sudo reboot
    fi
fi
### END OF SCRIPT ###