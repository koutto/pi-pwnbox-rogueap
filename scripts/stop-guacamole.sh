#!/bin/bash

# -------------------------------------------------------------------------------------------------
# Pi-PwnBox-RogueAP 
# https://github.com/koutto/pi-pwnbox-rogueap
# -------------------------------------------------------------------------------------------------
# Stop Guacamole service
# -------------------------------------------------------------------------------------------------

RED=`tput setaf 1`
GREEN=`tput setaf 2`
BLUE=`tput setaf 4`
YELLOW=`tput setaf 3`
RESET=`tput sgr0`


if [[ $EUID -ne 0 ]]; then
   echo "${RED}[!] This script must be run as root ${RESET}"
   exit 1
fi

systemctl stop guacd
systemctl stop tomcat9
systemctl stop mysql

echo "${GREEN}[+] Guacamole stopped${RESET}"
echo

#systemctl status guacd
#systemctl status tomcat9
#systemctl status mysql
