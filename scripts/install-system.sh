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

# Passphrase for the hidden PWNBOX_ADMIN administration Access Point (WPA2-PSK)
# IMPORTANT: change this before running the script
ADMIN_AP_PASSPHRASE="Koutto!PwnB0x!"


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

# Run from the script's own directory so relative config/ paths resolve
# regardless of the caller's working directory
cd "$(dirname "$(readlink -f "$0")")" || { echo "${RED}[!] Cannot cd to script directory${RESET}"; exit 1; }

# Sanity check: the three USB WiFi adapter interface names must be distinct,
# otherwise /etc/network/interfaces gets duplicate iface stanzas (ifupdown error)
if [ "${WLAN_INTERFACE_BROSTREND_AC1L}" = "${WLAN_INTERFACE_ALFA_AWUS036NEH}" ] || \
   [ "${WLAN_INTERFACE_BROSTREND_AC1L}" = "${WLAN_INTERFACE_ALFA_AWUS036ACH}" ] || \
   [ "${WLAN_INTERFACE_ALFA_AWUS036NEH}" = "${WLAN_INTERFACE_ALFA_AWUS036ACH}" ]; then
    echo "${RED}[!] WLAN_INTERFACE_* values must be distinct. Edit the configuration at the top of this script.${RESET}"
    exit 1
fi

echo "${YELLOW}[!] Make sure to have correct configuration at the beginning of this script before continuing !!"
echo "${YELLOW}[~] Script will pause at the end of each step to allow for manual check of commands outputs (errors?)${RESET}"
echo
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Add Kali rolling repository in /etc/apt/sources.list${RESET}"
# https://www.kali.org/docs/general-use/kali-linux-sources-list-repositories/
if ! grep -q "deb http://http.kali.org/kali kali-rolling main non-free contrib" /etc/apt/sources.list; then
	echo "deb http://http.kali.org/kali kali-rolling main non-free contrib" | tee -a /etc/apt/sources.list
fi
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Upgrade system and apps...${RESET}"
apt-get update
apt-get -y upgrade
apt-get -y dist-upgrade
uname -a
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Install additional utils & dependencies ...${RESET}"
apt-get -y install htop iotop btop bmon git libcurl4-openssl-dev libssl-dev zlib1g-dev libpcap-dev
apt-get -y install isc-dhcp-server php-cgi iftop build-essential pkg-config libnl-genl-3-dev
apt-get -y install python3-pip python3-scapy netdiscover plocate
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Update datetime using systemd-timesyncd...${RESET}"
apt-get install -y systemd-timesyncd
systemctl enable systemd-timesyncd
systemctl start systemd-timesyncd
timedatectl status
read -n 1 -s -r -p "Press any key to continue"


# -------------------------------------------------------------------------------------------------
# WiFi Driver for Device not working out-of-box on Kali

echo "${YELLOW}[~] Install Wi-Fi drivers for Realtek RTL88x2bu (BrosTrend AC1200 Model AC1L Dongle)...${RESET}"
# https://fr.scribd.com/document/424931230/AC1L-AC3L-Linux-Manual-BrosTrend-WiFI-Adapter-v4
# Fallback: if vendor script fails, manual build instructions are in README
wget --timeout=30 -q deb.trendtechcn.com/installer.sh -O /tmp/installer.sh
if [ -s /tmp/installer.sh ]; then
	chmod +x /tmp/installer.sh
	sudo /tmp/installer.sh
else
	echo "${RED}[!] Vendor installer download failed. You may need to build the driver manually:${RESET}"
	echo "    git clone https://github.com/cilynx/rtl88x2bu.git && cd rtl88x2bu && ./dkms-install.sh"
fi
read -n 1 -s -r -p "Press any key to continue"

echo "${YELLOW}[~] Check Wi-Fi Dongle Realtek RTL88x2bu correct install${RESET}"
dmesg | grep -i rtl88 || true
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
systemctl status ssh || true
ss -tulpen | grep ':22'
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Install Guacamole (for Kali in Browser access)...${RESET}"
# https://www.kali.org/docs/general-use/guacamole-kali-in-browser/
git clone https://github.com/MysticRyuujin/guac-install.git /tmp/guac-install
chmod +x /tmp/guac-install/guac-install.sh
# sudo rm /etc/localtime && sudo ln -s /usr/share/zoneinfo/US/Central /etc/localtime
/tmp/guac-install/guac-install.sh --nomfa --installmysql --mysqlpwd ${GUACAMOLE_MYSQL_PASSWORD} --guacpwd ${GUACAMOLE_PASSWORD}
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Checking Guacamole status${RESET}"
TOMCAT_SVC=$(systemctl list-unit-files --type=service 2>/dev/null | grep -oE '^tomcat[0-9]*\.service' | head -n1 | sed 's/\.service//')
[ -z "$TOMCAT_SVC" ] && TOMCAT_SVC="tomcat9"
systemctl status ${TOMCAT_SVC} guacd mysql || true
ss -tulpen | grep -E "mysqld|guacd|java"
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Install and enable VNC service (autostart at boot)...${RESET}"
apt-get install -y tigervnc-common tigervnc-standalone-server
apt-get install -y autocutsel
rm -f /tmp/.X11-unix/X1
rm -f /tmp/.X1-lock
echo "${YELLOW}Enter VNC password to use:${RESET}"
vncpasswd # Will ask for VNC password
if [ ! -f /root/.vnc/passwd ]; then
    echo "${RED}[!] VNC password file not found. Did you set the password? Aborting.${RESET}"
    exit 1
fi
cp config/vncserver.service /etc/systemd/system/vncserver.service
chown root:root /etc/systemd/system/vncserver.service
chmod 644 /etc/systemd/system/vncserver.service
systemctl start vncserver
systemctl enable vncserver
systemctl status vncserver || true
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Check VNC server is running...${RESET}"
ss -tulpen | grep -i vnc
read -n 1 -s -r -p "Press any key to continue"


# -------------------------------------------------------------------------------------------------
# System settings

echo "${YELLOW}Configure auto-login at boot...${RESET}"
[ -f /etc/lightdm/lightdm.conf ] && cp /etc/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.backup.$(date +%Y%m%d%H%M%S)
cp config/lightdm.conf /etc/lightdm/lightdm.conf
[ -f /etc/pam.d/lightdm-autologin ] && cp /etc/pam.d/lightdm-autologin /etc/pam.d/lightdm-autologin.backup.$(date +%Y%m%d%H%M%S)
cp config/lightdm-autologin /etc/pam.d/lightdm-autologin
echo
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Disable Network-Manager to avoid undesirable side-effects...${RESET}"
systemctl stop NetworkManager || true
systemctl disable NetworkManager || true
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
cp /usr/lib/systemd/network/73-usb-net-by-mac.link /usr/lib/systemd/network/73-usb-net-by-mac.link.old || true
cp /usr/lib/systemd/network/99-default.link /usr/lib/systemd/network/99-default.link.old || true
if [ -f /etc/udev/rules.d/70-persistent-net.rules ]; then
	mv /etc/udev/rules.d/70-persistent-net.rules /etc/udev/rules.d/70-persistent-net.rules.old
fi
if [ -f /etc/udev/rules.d/73-usb-net-by-mac.rules ]; then
	mv /etc/udev/rules.d/73-usb-net-by-mac.rules /etc/udev/rules.d/73-usb-net-by-mac.rules.old
fi
cat > /etc/udev/rules.d/70-persistent-net.rules <<EOF
SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="${MAC_ETH0}", NAME="eth0"
SUBSYSTEM=="net", ACTION=="add", DRIVERS=="?*", ATTR{address}=="${MAC_WLAN0}", NAME="wlan0"
EOF

cp config/73-usb-net-by-mac.rules /etc/udev/rules.d/73-usb-net-by-mac.rules

systemctl restart systemd-udevd
udevadm control --reload-rules
udevadm trigger --subsystem-match=net
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Configure network interfaces${RESET}"
[ -f /etc/network/interfaces ] && cp /etc/network/interfaces /etc/network/interfaces.backup.$(date +%Y%m%d%H%M%S)
cat > /etc/network/interfaces <<EOF

auto lo
iface lo inet loopback

# Automatic connection to network via eth0 if Ethernet connected
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


# WiFi USB Adapter Alfa AWUS036NEH Ralink RT2870/RT3070
# Disabled by default at boot
iface ${WLAN_INTERFACE_ALFA_AWUS036NEH} inet manual

# WiFi USB Adapter Alfa AWUS036ACH Realtek RTL8812AU
# Disabled by default at boot
iface ${WLAN_INTERFACE_ALFA_AWUS036ACH} inet manual

EOF

# Only append the network block if this SSID is not already configured
# (avoids duplicate network={} entries when the script is run more than once)
if ! grep -q "ssid=\"${WIFI_SSID}\"" /etc/wpa_supplicant.conf 2>/dev/null; then
	wpa_passphrase "${WIFI_SSID}" "${WIFI_PASSPHRASE}" >> /etc/wpa_supplicant.conf
else
	echo "${YELLOW}[~] SSID ${WIFI_SSID} already present in /etc/wpa_supplicant.conf, skipping${RESET}"
fi
read -n 1 -s -r -p "Press any key to continue"


# -------------------------------------------------------------------------------------------------
# Setup AP at boot for pwnbox access via WiFi
# WiFi Interface used: WiFi USB Adapter BrosTrend AC1200 Realtek RTL88x2bu
# SSID: PWNBOX_ADMIN (Hidden)
# IP Range: 10.0.0.1/24 (DHCP enabled)
# IP PwnBox/AP: 10.0.0.1
echo "${YELLOW}[~] Setup AP at boot for pwnbox access via WiFi...${RESET}"

echo "${YELLOW}[~] Configure dnsmasq...${RESET}"
[ -f /etc/dnsmasq.conf ] && cp /etc/dnsmasq.conf /etc/dnsmasq.conf.backup.$(date +%Y%m%d%H%M%S)
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
mkdir -p /etc/hostapd
[ -f /etc/hostapd/hostapd.conf ] && cp /etc/hostapd/hostapd.conf /etc/hostapd/hostapd.conf.backup.$(date +%Y%m%d%H%M%S)
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
wpa_passphrase=${ADMIN_AP_PASSPHRASE}
wpa_key_mgmt=WPA-PSK
wpa_pairwise=CCMP
wpa_group_rekey=86400
ieee80211n=1
wme_enabled=1

EOF

echo "${YELLOW}[~] Configure hostapd & dnsmasq to start at boot as service...${RESET}"
# Tell hostapd where its config file is
if [ -f /etc/default/hostapd ]; then
    if grep -q '^DAEMON_CONF=' /etc/default/hostapd; then
        sed -i 's|^DAEMON_CONF=.*|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd
    else
        echo 'DAEMON_CONF="/etc/hostapd/hostapd.conf"' >> /etc/default/hostapd
    fi
fi
systemctl unmask hostapd || true # by default, service is masked on pi
systemctl enable hostapd
systemctl start hostapd

systemctl enable dnsmasq
systemctl start dnsmasq
# Disable isc-dhcp-server to avoid port 67/udp conflict with dnsmasq
systemctl disable isc-dhcp-server || true
systemctl stop isc-dhcp-server || true

read -n 1 -s -r -p "Press any key to continue"


# -------------------------------------------------------------------------------------------------
# Install Additional Tools (in /usr/share)

echo "${YELLOW}[~] Install wifite, reaver, bully, mdk4, kismet from repository (if not already)...${RESET}"
apt-get install -y wifite reaver bully mdk4 kismet
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Install hcxdumptool, hcxtools, cowpatty, dsniff from repository (if not already)...${RESET}"
apt-get install -y hcxdumptool hcxtools cowpatty dsniff
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Install dnsmasq, hostapd from repository (if not already)...${RESET}"
apt-get install -y dnsmasq hostapd
# hostapd-wpe and hostapd-mana both ship their own /usr/sbin/hostapd and conflict
# with hostapd and with each other, so they cannot be installed in one apt call.
# Install each separately and tolerate failure (they replace the base hostapd binary).
echo "${YELLOW}[~] Install hostapd-wpe (optional, conflicts with base hostapd)...${RESET}"
apt-get install -y hostapd-wpe || echo "${YELLOW}[~] hostapd-wpe unavailable, skipping${RESET}"
echo "${YELLOW}[~] Install hostapd-mana (optional, conflicts with base hostapd)...${RESET}"
apt-get install -y hostapd-mana || echo "${YELLOW}[~] hostapd-mana unavailable, skipping${RESET}"
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Install eapmd5pass, asleap from repository (if not already)...${RESET}"
apt-get install -y eapmd5pass asleap
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Install beef-xss from repository (if not already)...${RESET}"
apt-get install -y beef-xss || echo "${YELLOW}[~] beef-xss may not be available on this architecture, skipping${RESET}"
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Install Wifipumpkin3...${RESET}"
apt-get install -y libssl-dev libffi-dev build-essential python3-pyqt5
if [ -d /usr/share/wifipumpkin3 ]; then
	echo "${YELLOW}[~] Updating existing Wifipumpkin3...${RESET}"
	cd /usr/share/wifipumpkin3 && git pull
else
	cd /usr/share && git clone https://github.com/P0cL4bs/wifipumpkin3.git
fi
cd /usr/share/wifipumpkin3 || exit 1
python3 -m pip install . --break-system-packages 2>/dev/null || python3 -m pip install .
python3 -m pip install pyOpenSSL --break-system-packages 2>/dev/null || python3 -m pip install pyOpenSSL
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Install Wifiphisher...${RESET}"
if [ -d /usr/share/wifiphisher ]; then
	cd /usr/share/wifiphisher && git pull
else
	cd /usr/share && git clone https://github.com/wifiphisher/wifiphisher.git
fi
cd /usr/share/wifiphisher || exit 1
apt-get install -y libnl-3-dev libnl-genl-3-dev
python3 -m pip install . --break-system-packages 2>/dev/null || python3 -m pip install .
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Install Fluxion...${RESET}"
if [ -d /usr/share/fluxion ]; then
	cd /usr/share/fluxion && git pull
else
	cd /usr/share && git clone https://github.com/FluxionNetwork/fluxion.git
fi
# Fluxion requires X (graphical) session available
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Install/Update Bettercap2...${RESET}"
apt-get -y remove bettercap || true
command -v bettercap >/dev/null 2>&1 && rm -f "$(command -v bettercap)"
apt-get install -y bettercap
bettercap -version || true
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Install crEAP...${RESET}"
if [ -d /usr/share/creap ]; then
	cd /usr/share/creap && git pull
else
	cd /usr/share && git clone https://github.com/Shellntel/scripts.git creap
fi
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Install EAPHammer...${RESET}"
if [ -d /usr/share/eaphammer ]; then
	cd /usr/share/eaphammer && git pull
else
	cd /usr/share && git clone https://github.com/s0lst1c3/eaphammer.git
fi
cd /usr/share/eaphammer || exit 1
./kali-setup || true
python3 -m pip install flask_cors flask_socketio gevent --break-system-packages 2>/dev/null || python3 -m pip install flask_cors flask_socketio gevent
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Install Airgeddon...${RESET}"
if [ -d /usr/share/airgeddon ]; then
	cd /usr/share/airgeddon && git pull
else
	cd /usr/share && git clone https://github.com/v1s1t0r1sh3r3/airgeddon.git
fi
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Install Berate_ap...${RESET}"
if [ -d /usr/share/berate_ap ]; then
	cd /usr/share/berate_ap && git pull
else
	cd /usr/share && git clone https://github.com/sensepost/berate_ap.git
fi
read -n 1 -s -r -p "Press any key to continue"


echo "${YELLOW}[~] Install WPA_Sycophant...${RESET}"
if [ -d /usr/share/wpa_sycophant ]; then
	cd /usr/share/wpa_sycophant && git pull
else
	cd /usr/share && git clone https://github.com/sensepost/wpa_sycophant.git
fi
read -n 1 -s -r -p "Press any key to continue"


updatedb

echo "${YELLOW}[~] Cleaning up package cache...${RESET}"
apt-get autoremove -y
apt-get clean

echo "${GREEN}[+] Install script finished. Now Reboot !"
echo 
