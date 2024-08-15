#!/usr/bin/bash

### COLORS VARS ###
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
RESET_CLR="\e[0m"

### FUNCTIONS ###
check_cmd() {
    if [[ $? -eq 0 ]]; then
        echo -e "[$GREEN OK $RESET_CLR]"
    else
        echo -e "[$RED ERROR $RESET_CLR]"
        exit 1
    fi
}

### START OF SCRIPT ###
is_update_available="false"
pkg_need_reboot=""

### FIRMWARES ###
if ! fwupdmgr get-updates 2>&1 | grep -q "No updates available"; then
    is_update_available="true"

    echo -e "${MAGENTA}FIRMWARES : $RESET_CLR"

    sudo fwupdmgr update
fi

### RPM ###
dnf check-update >/dev/null 2>&1

if [[ $? -eq 100 ]]; then
    is_update_available="true"

    echo -e "${MAGENTA}RPM : $RESET_CLR"

    sudo dnf update

    if  [[ $? -eq 0 ]]; then
        pkg_need_reboot=$(dnf history info last | grep -Eo '(dbus-broker|glibc|kernel|linux-firmware|systemd)' | sort | uniq | xargs)
    fi
fi

### FLATPAK ###
if ! flatpak update | grep -q "Nothing to do"; then
    is_update_available="true"

    echo -e "${MAGENTA}FLATPAK : $RESET_CLR"

    flatpak update
fi

### XAMPP ###
xampp_device_version=$(grep -Po '(?<=base_stack_version=).*(?=-)' /opt/lampp/properties.ini | sed 's/\.//g')
xampp_web_version=$(curl -s 'https://www.apachefriends.org/fr/index.html' | grep -Po '(?<=xampp-linux-x64-).*(?=-.*-installer.run)' | sed 's/\.//g')

if [[ $xampp_device_version -lt $xampp_web_version ]]; then
    is_update_available="true"

    echo -e "${MAGENTA}XAMPP : $RESET_CLR"
    
    echo -ne "${YELLOW}New version available! Do you want to update? [y/N] : $RESET_CLR"
    read response

    if [ "$response" == "y" ]; then
        xampp_installer_link=$(curl -s 'https://www.apachefriends.org/fr/index.html' | grep 'xampp-linux' | grep -Po '(?<=download_success.html" href=")[^"]+')
        
        echo -n "Downloading the XAMPP installer: "
        wget -q "$xampp_installer_link" -O xampp-installer.run >/dev/null 2>&1
        check_cmd

        echo -n "Configuring installer execution rights: "
        sudo chmod u+x xampp-installer.run
        check_cmd

        echo -n "Installing XAMPP: "
        sudo ./xampp-installer.run
        check_cmd

        echo -n "Removing the installer: "
        rm xampp-installer.run
        check_cmd

        echo "XAMPP has been updated."
    else
        echo "XAMPP has not been updated."
    fi
fi

if [ "$is_update_available" == "false" ]; then
    echo "No updates available."
    exit 0
fi

if [[ -n "$pkg_need_reboot" ]]; then
    echo -ne "${YELLOW}Restart required: ${CYAN}$pkg_need_reboot ${YELLOW}has been updated, restart now? [y/N] : $RESET_CLR"
    read response
    
    if [ "$response" == "y" ]; then
        reboot
    else
        exit 0
    fi
fi
### END OF SCRIPT ###