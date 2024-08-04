#!/usr/bin/bash

### COLORS VARS ###
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
RESET_CLR="\e[0m"

### GLOBAL VARS ###
IS_UPDATE_AVAILABLE="false"

### FUNCTIONS ###
check_cmd() {
    if [ $? -eq 0 ]; then
        echo -e "[$GREEN OK $RESET_CLR]"
    else
        echo -e "[$RED ERREUR $RESET_CLR]"
    fi
}

### START OF SCRIPT ###

### FIRMWARES ###
if ! fwupdmgr get-updates 2>&1 | grep -q "No updates available"; then
    IS_UPDATE_AVAILABLE="true"

    echo -e "${MAGENTA}FIRMWARES : $RESET_CLR"

    sudo fwupdmgr update
fi

### DNF ###
dnf check-update >/dev/null 2>&1

if [[ $? -eq 100 ]]; then
    IS_UPDATE_AVAILABLE="true"
    PKG_NEED_REBOOT=$(dnf check-update | grep -Eo '^(dbus-broker|glibc|kernel|linux-firmware|systemd)' | sort | uniq | xargs)

    echo -e "${MAGENTA}DNF : $RESET_CLR"

    sudo dnf update
fi

### FLATPAK ###
if ! flatpak update | grep -q "Nothing to do"; then
    IS_UPDATE_AVAILABLE="true"

    echo -e "${MAGENTA}FLATPAK : $RESET_CLR"

    flatpak update
fi

### XAMPP ###
XAMPP_DEVICE_VERSION=$(grep -Po '(?<=base_stack_version=).*(?=-)' /opt/lampp/properties.ini | sed 's/\.//g')
XAMPP_WEB_VERSION=$(curl -s 'https://www.apachefriends.org/fr/index.html' | grep -Po '(?<=xampp-linux-x64-).*(?=-.*-installer.run)' | sed 's/\.//g')

if [[ $XAMPP_DEVICE_VERSION -lt $XAMPP_WEB_VERSION ]]; then
    IS_UPDATE_AVAILABLE="true"

    echo -e "${MAGENTA}XAMPP : $RESET_CLR"
    
    echo -ne "${YELLOW}Nouvelle version disponible ! Voulez-vous faire la mise à jour ? [y/N] : $RESET_CLR"
    read RESPONSE

    if [ "$RESPONSE" == "y" ]; then
        XAMPP_INSTALLER_LINK=$(curl -s 'https://www.apachefriends.org/fr/index.html' | grep 'xampp-linux' | grep -Po '(?<=download_success.html" href=")[^"]+')
        
        echo -n "Téléchargement du programme d'installation de XAMPP : "
        wget -q "$XAMPP_INSTALLER_LINK" -O xampp-installer.run >/dev/null
        check_cmd

        echo -n "Configuration des droits du programme d'installation : "
        sudo chmod u+x xampp-installer.run
        check_cmd

        echo -n "Installation de XAMPP : "
        sudo ./xampp-installer.run
        check_cmd

        echo -n "Suppression du programme d'installation : "
        rm xampp-installer.run
        check_cmd

        echo "XAMPP a été mis à jour."
    else
        echo "XAMPP n'a pas été mis à jour."
    fi
fi

if [ "$IS_UPDATE_AVAILABLE" == "false" ]; then
    echo "Aucune mise à jour disponible."
    exit 0
fi

if [[ -n "$PKG_NEED_REBOOT" ]]; then
    echo -ne "${YELLOW}Redémarrage nécéssaire: ${CYAN}$PKG_NEED_REBOOT ${YELLOW}a été mis à jour, redémarrer maintenant ? [y/N] : $RESET_CLR"
    read RESPONSE
    
    if [ "$RESPONSE" == "y" ]; then
        reboot
    else
        exit 0
    fi
fi
### END OF SCRIPT ###