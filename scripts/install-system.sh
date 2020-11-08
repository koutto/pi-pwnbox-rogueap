#!/bin/bash

# -------------------------------------------------------------------------------------------------
# Pi-PwnBox-RogueAP 
# https://github.com/koutto/pi-pwnbox-rogueap
# -------------------------------------------------------------------------------------------------
# Install Script - IMPORTANT: EDIT CONFIGURATION BEFORE RUNNING IT !
# -------------------------------------------------------------------------------------------------



# -------------------------------------------------------------------------------------------------
# Configuration: Make sure to have correct values here before running install script
# -------------------------------------------------------------------------------------------------

# Guacamole credentials
GUACAMOLE_PASSWORD="MyGuacamolePassword"
GUACAMOLE_MYSQL_PASSWORD="MyGuacamoleMySQLPassword"


# Wifi interface names:
# This script will turn on persistent/predictable naming for WiFI USB Adapters (modern naming)
# i.e. name will be like: wlx + MAC address (without colons)
# Example: if MAC is AA:BB:CC:DD:EE:FF => interface name = wlxaabbccddeeff

# Goal is to have a static networking configuration, and to make sure the integrated WiFi
# (named wlan0) will always be used as default interface to connect to Internet at boot
# (when eth0 is not used).

# WiFi USB Adapter Dongle BrosTrend AC1200 Model No AC1L: Realtek RTL88x2bu
WLAN_INTERFACE_BROSTREND_AC1L="wlxaabbccddeeff"

# WiFi USB Adapter Dongle Alfa AWUS036NEH: Ralink RT2870/RT3070
WLAN_INTERFACE_ALFA_AWUS036NEH="wlxaabbccddeeff"

# WiFi USB Adapter Alfa AWUS036ACH: Realtek RTL8812AU
WLAN_INTERFACE_ALFA_AWUS036ACH="wlxaabbccddeeff"

# MAC Address of built-in Ethernet interface
MAC_ETH0="aa:bb:cc:dd:ee:ff"

# MAC Address of built-in WiFi interface
MAC_WLAN0="aa:bb:cc:dd:ee:ff"

# First WiFi connection (to configure wpa_supplicant)
# This will be the first default SSID wlan0 will try to connect to automatically at boot
# Note: Additional SSID+Passphrase can later be added using the command:
# wpa_passphrase <SSID> <Passphrase> >> /etc/wpa_supplicant.conf
WIFI_SSID="WifiSsid"
WIFI_PASSPHRASE="MyPassphrase"


# -------------------------------------------------------------------------------------------------

RED=`tput setaf 1`
GREEN=`tput setaf 2`
BLUE=`tput setaf 4`
YELLOW=`tput setaf 3`
RESET=`tput sgr0`

if [[ $EUID -ne 0 ]]; then
   echo "${RED}[!] This script must be run as root ${RESET}" 
   exit 1
fi

echo "${YELLOW}[!] Make sure to have correct configuration at the beginning of this script before continuing !!"
echo "${YELLOW}[~] Script will pause at the end of each step to allow for manual check of commands outputs (errors?)${RESET}"
echo
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Add Kali rolling repository in /etc/apt/sources.list${RESET}"
# https://www.kali.org/docs/general-use/kali-linux-sources-list-repositories/
if cat /etc/apt/sources.list | grep -q "deb http://http.kali.org/kali kali-rolling main non-free contrib"; then
	echo "deb http://http.kali.org/kali kali-rolling main non-free contrib" | tee /etc/apt/sources.list
fi
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Upgrade system and apps...${RESET}"
apt-get update
apt-get -y upgrade
apt-get -y dist-upgrade
uname -a
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Install additional utils & dependencies ...${RESET}"
apt-get -y install htop iotop bashtop bmon git libcurl4-openssl-dev libssl-dev zlib1g-dev libpcap-dev
apt-get -y install dhcpd php-cgi iftop build-essential pkg-config libnl-genl-3-dev
apt-get -y install python3-pip python3-scapy
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Update datetime...${RESET}"
apt-get install -y ntp ntpdate
ntpdate fr.pool.ntp.org
date
cp config/ntpdate.service /etc/systemd/system/ntpdate.service
chown root:root /etc/systemd/system/ntpdate.service
chmod 644 /etc/systemd/system/ntpdate.service
systemctl enable ntpdate
systemctl start ntpdate


# -------------------------------------------------------------------------------------------------
# WiFi Driver for Device not working out-ot-box on Kali

echo "${YELLOW}[~] Install Wi-Fi drivers for Realtek RTL88x2bu (BrosTrend AC1200 Model AC1L Dongle)...${RESET}"
# https://fr.scribd.com/document/424931230/AC1L-AC3L-Linux-Manual-BrosTrend-WiFI-Adapter-v4
wget deb.trendtechcn.com/installer.sh -O /tmp/installer.sh
chmod +x /tmp/installer.sh
sudo /tmp/installer.sh
read -n 1 -s -r -p "Press any key to continue"

echo "${YELLOW}[~] Check Wi-Fi Dongle Realtek RTL88x2bu correct install${RESET}"
dmesg | grep -i rtl88
lsusb
iw dev
ip a
read -n 1 -s -r -p "Press any key to continue"


# -------------------------------------------------------------------------------------------------
# Services

echo "${YELLOW}[~] Enable SSH server...${RESET}"
apt-get install -y ssh openssh-server
systemctl enable ssh
service ssh start
systemctl status ssh
netstat -latupen | grep ':22'
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Install Guacamole (for Kali in Browser access)...${RESET}"
# https://www.kali.org/docs/general-use/guacamole-kali-in-browser/
git clone https://github.com/MysticRyuujin/guac-install.git /tmp/guac-install
chmod +x /tmp/guac-install/guac-install.sh
# sudo rm /etc/localtime && sudo ln -s /usr/share/zoneinfo/US/Central /etc/localtime
/tmp/guac-install/guac-install.sh --nomfa --installmysql --mysqlpwd ${GUACAMOLE_MYSQL_PASSWORD} --guacpwd ${GUACAMOLE_PASSWORD}
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Checking Guacamole status${RESET}"
systemctl status tomcat9 guacd mysql
netstat -latupen | grep "mysqld\|guacd\|java"
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Install and enable VNC service (autostart at boot)...${RESET}"
apt-get install -y tigervnc-common tigervnc-standalone-server
apt-get install -y autocutsel
#mkdir ~/.vnc/ && wget https://gitlab.com/kalilinux/nethunter/build-scripts/kali-nethunter-project/-/raw/master/nethunter-fs/profiles/xstartup -O ~/.vnc/xstartup
#apt-get install x11vnc
rm -f /tmp/.X11-unix/X0
rm -f /tmp/.X0-lock
#vncserver -kill :1
#vncserver :1
#x11vnc -display :0 -autoport -localhost -nopw -bg -xkb -ncache -ncache_cr -quiet -forever
#cp x11vnc.service /lib/systemd/system/x11vnc.service
#systemctl enable x11vnc.service
echo "${YELLOW}Enter VNC password to use:${RESET}"
vncpasswd # Will ask for VNC password
cp config/vncserver.service /etc/systemd/system/vncserver.service
chown root:root /etc/systemd/system/vncserver.service
chmod 644 /etc/systemd/system/vncserver.service
systemctl start vncserver
systemctl enable vncserver
systemctl status vncserver
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Check VNC server is running...${RESET}"
netstat -latupen | grep -i vnc
read -n 1 -s -r -p "Press any key to continue"


# -------------------------------------------------------------------------------------------------
# System settings

echo "${YELLOW}Configure auto-login at boot...${RESET}"
mv /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.old
cp config/lightdm.conf /etc/lightdm/lightdm.conf
mv /etc/pam.d/lightdm-autologin /etc/pam.d/lightdm-autologin.old
cp config/lightdm-autologin /etc/pam.d/lightdm-autologin
echo
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Disable Network-Manager to avoid undesirable side-effects...${RESET}"
systemctl stop NetworkManager
systemctl disable NetworkManager
read -n 1 -s -r -p "Press any key to continue"


# -------------------------------------------------------------------------------------------------
# Networking configuration (with persistent interfaces naming)

echo "${YELLOW}[~] Ensure Network Interface names are persistent and predictable... ${RESET}"
echo "${YELLOW}eth0 => Ethernet${RESET}"
echo "${YELLOW}wlan0 => Built-in Wi-Fi interface${RESET}"
echo "${YELLOW}${WLAN_INTERFACE_BROSTREND_AC1L} => USB Adapter BrosTrend AC1L - Chipset Realtek RTL88x2bu${RESET}"
echo "${YELLOW}${WLAN_INTERFACE_ALFA_AWUS036NEH} => USB Adapter Alfa AWUS036NEH - Chipset Ralink RT2870/RT3070${RESET}"
echo "${YELLOW}${WLAN_INTERFACE_ALFA_AWUS036ACH} => USB Adapter Alfa AWUS036ACH - Chipset Realtek RTL8812AU${RESET}"
# Note: We do not use wlan1, wlan2... naming for USB dongles devices because Udev feature appeared bugged
# during tests (https://wiki.debian.org/NetworkInterfaceNames) and we need consistent naming to avoid confusion
echo
cp /usr/lib/systemd/network/73-usb-net-by-mac.link /usr/lib/systemd/network/73-usb-net-by-mac.link.old
cp /usr/lib/systemd/network/99-default.link /usr/lib/systemd/network/99-default.link.old
if [ -f /etc/udev/rules.d/70-persistent-net.rules ]; then
	mv /etc/udev/rules.d/70-persistent-net.rules /etc/udev/rules.d/70-persistent-net.rules.old
fi
if [ -f /etc/udev/rules.d/73-usb-net-by-mac.rules ]; then
	mv /etc/udev/rules.d/73-usb-net-by-mac.rules /etc/udev/rules.d/73-usb-net-by-mac.rules.old
fi
# cp config/70-persistent-net.rules /etc/udev/rules.d/70-persistent-net.rules
cat > /etc/udev/rules.d/70-persistent-net.rules <<EOF
SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="${MAC_ETH0}", NAME="eth0"
SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="${MAC_WLAN0}", NAME="wlan0"
EOF

cp config/73-usb-net-by-mac.rules /etc/udev/rules.d/73-usb-net-by-mac.rules

systemctl restart systemd-udevd
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Configure network interfaces${RESET}"
mv /etc/network/interfaces /etc/network/interfaces.old
cat > /etc/network/interfaces <<EOF

auto lo
iface lo inet loopback

# Automatic connection to network via eth0 if Ethenet connected
auto eth0
allow-hotplug eth0
iface eth0 inet dhcp

# wlan0: Built-in WiFi interface (Broadcom 43430)
# Used to connect to Internet (when eth0 not used)
auto wlan0
allow-hotplug wlan0
iface wlan0 inet dhcp
wpa-conf /etc/wpa_supplicant.conf
iface default inet dhcp


# WiFi USB Adapter BrosTrend AC1200 Realtek RTL88x2bu
# Used to set up AP at boot for pwnbox access via WiFi
allow-hotplug ${WLAN_INTERFACE_BROSTREND_AC1L}
iface ${WLAN_INTERFACE_BROSTREND_AC1L} inet static
  address 10.0.0.1
  netmask 255.255.255.0
  up route add -net 10.0.0.0 netmask 255.255.255.0 gw 10.0.0.1
# iface ${WLAN_INTERFACE_BROSTREND_AC1L} inet manual
# ifdown ${WLAN_INTERFACE_BROSTREND_AC1L}


# WiFi USB Adapter Alfa AWUS036NEH Ralink RT2870/RT3070
# Disabled by default at boot
iface ${WLAN_INTERFACE_ALFA_AWUS036NEH} inet manual
ifdown ${WLAN_INTERFACE_ALFA_AWUS036NEH}

# WiFi USB Adapter Alfa AWUS036ACH Realtek RTL8812AU
# Disabled by default at boot
iface ${WLAN_INTERFACE_ALFA_AWUS036ACH} inet manual
ifdown ${WLAN_INTERFACE_ALFA_AWUS036ACH}

EOF

wpa_passphrase ${WIFI_SSID} ${WIFI_PASSPHRASE} >> /etc/wpa_supplicant.conf
read -n 1 -s -r -p "Press any key to continue"


# -------------------------------------------------------------------------------------------------
# Setup AP at boot for pwnbox access via WiFi
# WiFi Interface used: WiFi USB Adapter BrosTrend AC1200 Realtek RTL88x2bu
# SSID: PWNBOX_ADMIN (Hidden)
# IP Range: 10.0.0.1/24 (DHCP enabled)
# IP PwnBox/AP: 10.0.0.1
echo "${YELLOW}[~] Setup AP at boot for pwnbox access via WiFi...${RESET}"

echo "${YELLOW}[~] Configure dnsmasq...${RESET}"
mv /etc/dnsmasq.conf /etc/dnsmasq.conf.old
cat > /etc/dnsmasq.conf <<EOF

interface=${WLAN_INTERFACE_BROSTREND_AC1L}
dhcp-authoritative
dhcp-range=10.0.0.2,10.0.0.30,255.255.255.0,12h
dhcp-option=3,10.0.0.1
dhcp-option=6,10.0.0.1
server=8.8.8.8
log-queries
log-dhcp
listen-address=10.0.0.1
bind-interfaces # to listen only on interface used by AP (avoid conflict when spawning rogue AP)

EOF


echo "${YELLOW}[~] Configure hostapd...${RESET}"
mv /etc/hostapd/hostapd.conf /etc/hostapd.conf.old
cat > /etc/hostapd/hostapd.conf <<EOF

interface=${WLAN_INTERFACE_BROSTREND_AC1L}
driver=nl80211
ssid=PWNBOX_ADMIN
hw_mode=g
channel=11
macaddr_acl=0
ignore_broadcast_ssid=1 # hidden SSID
auth_algs=1
wpa=2
wpa_passphrase=Koutto!PwnB0x!
wpa_key_mgmt=WPA-PSK
wpa_pairwise=CCMP
wpa_group_rekey=86400
ieee80211n=1
wme_enabled=1

EOF

echo "${YELLOW}[~] Configure hostapd & dnsmasq to start at boot as service...${RESET}"
systemctl unmask hostapd # by default, service is masked on pi
systemctl enable hostapd
systemctl start hostapd

systemctl enable dnsmasq
systemctl start dnsmasq

read -n 1 -s -r -p "Press any key to continue"


# -------------------------------------------------------------------------------------------------
# Install Additional Tools (in /usr/share)

echo "${YELLOW}[~] Install wifite, reaver, bully, mdk4, mdk3, kismet from repository (if not already)...${RESET}"
apt-get install -y wifite reaver bully mdk4 mdk3 kismet
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Install hcxdumptool, hcxtools, cowpatty, dsniff from repository (if not already)...${RESET}"
apt-get install -y hcxdumptool hcxtools cowpatty dsniff
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Install dnsmasq, hostapd, hostapd-wpe, hostapd-mana from repository (if not already)...${RESET}"
apt-get install -y dnsmasq hostapd hostapd-wpe hostapd-mana
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Install eapmd5pass, asleap from repository (if not already)...${RESET}"
apt-get install -y eapmd5pass asleap
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Install beef-xss from repository (if not already)...${RESET}"
apt-get install -y beef-xss
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Install pip2 for old python2.7 scripts dependencies install...${RESET}"
cd /tmp
curl -k https://bootstrap.pypa.io/get-pip.py --output get-pip.py
python2 get-pip.py
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Install Scapy & Scapy-com for Python2...${RESET}"
python2 -m pip install scapy
cd /usr/share
git clone https://github.com/Tylous/Scapy-com.git
cd Scapy-com
python2 setup.py install
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Install Wifipumpkin3...${RESET}"
apt-get install -y libssl-dev libffi-dev build-essential
cd /usr/share
git clone https://github.com/P0cL4bs/wifipumpkin3.git
cd wifipumpkin3
apt-get install -y python3-pyqt5
python3 setup.py install
python3 -m pip install pyOpenSSL==19.0.0
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Install Wifiphisher...${RESET}"
cd /usr/share
git clone https://github.com/wifiphisher/wifiphisher.git
cd wifiphisher
apt-get install -y libnl-3-dev libnl-genl-3-dev
python3 setup.py install
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Install Fluxion...${RESET}"
cd /usr/share
git clone https://github.com/FluxionNetwork/fluxion.git
# Fluxion requires X (graphical) session available
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Install Bettercap2...${RESET}"
apt-get -y remove bettercap
rm `which bettercap`
apt-get install -y bettercap
`which bettercap` -version


echo "${YELLOW}[~] Install crEAP...${RESET}"
cd /usr/share
git clone https://github.com/Shellntel/scripts.git creap
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Install EAPHammer...${RESET}"
cd /usr/share
git clone https://github.com/s0lst1c3/eaphammer.git
cd eaphammer
./kali-setup
python3 -m pip install flask_cors
python3 -m pip install flask_socketio
python3 -m pip install --upgrade gevent
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Install Airgeddon...${RESET}"
cd /usr/share
git clone https://github.com/v1s1t0r1sh3r3/airgeddon.git
read -n 1 -s -r -p "Press any key to continue"


#echo "${YELLOW}[~] Install Hostapd-mana...${RESET}"
#cd /usr/share
#git clone https://github.com/sensepost/hostapd-mana
#cd hostapd-mana
#make -C hostapd


echo "${YELLOW}[~] Install Berate_ap...${RESET}"
cd /usr/share
git clone https://github.com/sensepost/berate_ap.git
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Install WPA_Sycophant...${RESET}"
cd /usr/share
git clone https://github.com/sensepost/wpa_sycophant.git
read -n 1 -s -r -p "Press any key to continue"


updatedb

echo "${GREEN}[+] Install script finished. Now Reboot !"
echo 

