#!/bin/bash

NS2.SEDOPARKING.COM"}],"rdapConformance":["rdap_level_0","icann_rdap_technical_implementation_guide_0","icann_rdap_response_profile_0"],"notices":[{"title":"Terms of Use","description":["Service subject to Terms of Use."],"links":[{"href":"https:\/\/www.verisign.com\/domain-names\/registration-data-access-protocol\/terms-service\/index.xhtml","type":"text\/html"}]},{"title":"Status Codes","description":["For more information on domain status codes, please visit https:\/\/icann.org\/epp"],"links":[{"href":"https:\/\/icann.org\/epp","type":"text\/html"}]},{"title":"RDDS Inaccuracy Complaint Form","description":["URL of the ICANN RDDS Inaccuracy Complaint Form: https:\/\/icann.org\/wicf"],"links":[{"href":"https:\/\/icann.org\/wicf","type":"text\/html"}]}]}
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
cd /usr/share/wifipumpkin3
git pull
python3 setup.py install
wifipumpkin3 --version
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Update Wifiphisher...${RESET}"
cd /usr/share/wifiphisher
git pull
python3 setup.py install
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Update Fluxion...${RESET}"
cd /usr/share/fluxion
git pull
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Update EAPHammer...${RESET}"
cd /usr/share/eaphammer
git pull
# Setup takes lots of time, do it manually
#./kali-setup
echo "${YELLOW}[~] Setup of updated files should be run manually (/usr/share/kali-setup.sh). Takes lots of time !${RESET}"
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Update Airgeddon...${RESET}"
cd /usr/share/airgeddon
git pull
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Update Berate_ap...${RESET}"
cd /usr/share/berate_ap
git pull
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Install WPA_Sycophant...${RESET}"
cd /usr/share/wpa_sycophant
git pull
read -n 1 -s -r -p "Press any key to continue"

