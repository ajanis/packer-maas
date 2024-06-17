#!/bin/bash -x
##############################################################################
#
#   setup-harmonic-installer.sh
#
# - Install debian packages containing Harmonic wrapper-scripts for OSTree
#
# - Create 'harmonic-install.service' :
#   A single-use (oneshot) SystemD service file that will run on 1st boot.
#
# - Create 'harmonic-installer.sh' :
#   The script executed by 'harmonic-install.service' that fetches the
#   Apollo (Harmonic cOS) .iso file and executes the 'ostree-production'
#   commands that will to write the .iso to the system '/dev/sda' disk.
#
##############################################################################


## Install OSTree wrapper-scripts packages
curl  http://172.22.31.150:8080/packages/ostree-upgrade-bootstrap_2.0.41_all.deb --output /tmp/ostree-upgrade-bootstrap_2.0.41_all.deb
dpkg -i /tmp/ostree-upgrade-bootstrap_2.0.41_all.deb
curl  http://172.22.31.150:8080/packages/ostree-upgrade_2.0.41_all.deb --output /tmp/ostree-upgrade_2.0.41_all.deb
dpkg -i /tmp/ostree-upgrade_2.0.41_all.deb


## Create systemd service to run on boot
touch /etc/systemd/system/harmonic-install.service
cat << 'EOS' > /etc/systemd/system/harmonic-install.service
[Unit]
Description=Harmonic cOS Installation Single-Use Startup Script
ConditionFirstBoot=yes

[Service]
Type=forking
PIDFile=/run/harmonic.pid
ExecStart=/usr/local/bin/harmonic-installer.sh -v -i
RemainAfterExit=true
StandardOutput=journal

[Install]
WantedBy=multi-user.target
EOS

## Create script called by systemd service
touch /usr/local/bin/harmonic-installer.sh
cat << 'EOI' > /usr/local/bin/harmonic-installer.sh
#!/bin/bash -x
##############################################################################
#
#   harmonic-installer.sh
#
#   This script is executed either by 'harmonic-install.service' or by a
#   user-provided 'cloud-init' configuration.
#
#   The harmonic-installer.sh script will then perform the following steps:
#
#   1. Download and install the ostree-production .deb packages from the
#   MAAS webserver.
#   2. Download the latest Apollo (Harmony cOS) .iso from the MAAS webserver.
#   3. Create a /data directory and move the Apollo .iso into it.
#   4. Run the 'ostree-production' commands to display and write the .iso
#   to the system's physical disk (/dev/sda)
#   5. Reboot the system to /dev/sda
#
#   The system will reboot into Harmony cOS
# shellcheck disable=SC2155
##############################################################################

export DEBIAN_FRONTEND=noninteractive
export webserverHost="172.22.31.150"
export webserverPort="8080"
export apolloRelease="release-3.21.3.0-7+auto15"
export apolloISO="APOLLO_PLATFORM-${apolloRelease}.iso"
export ostreePackages="ostree-upgrade-bootstrap_2.0.41_all.deb ostree-upgrade_2.0.41_all.deb"
export localAssets="$(mktemp -d)"
export localData="/data"
export physicalDisk="/dev/sda"

unset http_proxy
unset https_proxy
unset no_proxy

runPrint() {
cat <<EOF
===========================================================
  $@
===========================================================
EOF
}

for thisPackage in ${ostreePackages}; do
  runPrint "Downloading ${thisPackage}"
  wget "http://${webserverHost}:${webserverPort}/packages/${thisPackage}" -O "${localAssets}/${thisPackage}"

  runPrint "Installing ${thisPackage}"
  dpkg -i "${localAssets}/${thisPackage}"

done

runPrint "Creating /data directory"
mkdir "${localData}"

runPrint "Downloading ${apolloISO}"
wget "http://${webserverHost}:${webserverPort}/apollo/latest" -O "${localData}/${apolloISO}"

runPrint "Listing ISOs found in ${localData}"
ostree-production list-isos

runPrint "Writing contents of ${localData}"/"${apolloISO} to ${physicalDisk}"
ostree-production -D "${physicalDisk}" from "${localData}"/"${apolloISO}"

EOI

## Fix script ownership
chmod +x /usr/local/bin/harmonic-installer.sh
