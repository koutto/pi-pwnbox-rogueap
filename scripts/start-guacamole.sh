#!/bin/bash

# -------------------------------------------------------------------------------------------------
# Pi-PwnBox-RogueAP 
# https://github.com/koutto/pi-pwnbox-rogueap
# -------------------------------------------------------------------------------------------------
# Start Guacamole service
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

systemctl start guacd
systemctl start tomcat9
systemctl start mysql

echo "${GREEN}[+] Guacamole started. Access via http://<ip>:8080/guacamole/${RESET}"
echo

#systemctl status guacd
#systemctl status tomcat9
#systemctl status mysql
