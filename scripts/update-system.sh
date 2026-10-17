#!/bin/bash


# -------------------------------------------------------------------------------------------------
# Pi-PwnBox-RogueAP 
# https://github.com/koutto/pi-pwnbox-rogueap
# -------------------------------------------------------------------------------------------------
# Update System/Tools Script
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


echo "${YELLOW}[~] Current Kernel version:${RESET}"
uname -a


echo "${YELLOW}[~] Upgrade system and kali apps...${RESET}"
apt-get update
apt-get -y upgrade
apt-get -y dist-upgrade
uname -a
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Update Wifipumpkin3...${RESET}"
if [ -d /usr/share/wifipumpkin3 ]; then
	cd /usr/share/wifipumpkin3 || exit 1
	git pull
	python3 -m pip install . --break-system-packages 2>/dev/null || python3 -m pip install .
	wifipumpkin3 --version || true
else
	echo "${RED}[!] Wifipumpkin3 not found in /usr/share/wifipumpkin3${RESET}"
fi
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Update Wifiphisher...${RESET}"
if [ -d /usr/share/wifiphisher ]; then
	cd /usr/share/wifiphisher || exit 1
	git pull
	python3 -m pip install . --break-system-packages 2>/dev/null || python3 -m pip install .
else
	echo "${RED}[!] Wifiphisher not found in /usr/share/wifiphisher${RESET}"
fi
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Update Fluxion...${RESET}"
if [ -d /usr/share/fluxion ]; then
	cd /usr/share/fluxion || exit 1
	git pull
else
	echo "${RED}[!] Fluxion not found in /usr/share/fluxion${RESET}"
fi
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Update EAPHammer...${RESET}"
if [ -d /usr/share/eaphammer ]; then
	cd /usr/share/eaphammer || exit 1
	git pull
	# Setup takes lots of time, do it manually
	#./kali-setup
	echo "${YELLOW}[~] Setup of updated files should be run manually (/usr/share/eaphammer/kali-setup). Takes lots of time !${RESET}"
else
	echo "${RED}[!] EAPHammer not found in /usr/share/eaphammer${RESET}"
fi
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Update Airgeddon...${RESET}"
if [ -d /usr/share/airgeddon ]; then
	cd /usr/share/airgeddon || exit 1
	git pull
else
	echo "${RED}[!] Airgeddon not found in /usr/share/airgeddon${RESET}"
fi
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Update Berate_ap...${RESET}"
if [ -d /usr/share/berate_ap ]; then
	cd /usr/share/berate_ap || exit 1
	git pull
else
	echo "${RED}[!] Berate_ap not found in /usr/share/berate_ap${RESET}"
fi
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Update WPA_Sycophant...${RESET}"
if [ -d /usr/share/wpa_sycophant ]; then
	cd /usr/share/wpa_sycophant || exit 1
	git pull
else
	echo "${RED}[!] WPA_Sycophant not found in /usr/share/wpa_sycophant${RESET}"
fi
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Update locate database...${RESET}"
updatedb

echo "${YELLOW}[~] Cleaning up package cache...${RESET}"
apt-get autoremove -y
apt-get clean

echo "${GREEN}[+] Update finished.${RESET}"
