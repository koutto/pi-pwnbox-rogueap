#!/bin/bash

# -------------------------------------------------------------------------------------------------
# Pi-PwnBox-RogueAP 
# https://github.com/koutto/pi-pwnbox-rogueap
# -------------------------------------------------------------------------------------------------
# Stop Access Point used for Dedicated Administration Network
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

systemctl stop dnsmasq
systemctl stop hostapd

echo "${GREEN}[+] AP Stopped${RESET}"
echo

