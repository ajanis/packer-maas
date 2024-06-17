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
#
##############################################################################


webserverHost="172.22.31.150"
webserverPort="8080"
apolloRelease="release-3.21.3.0-7+auto15"
apolloISO="APOLLO_PLATFORM-${apolloRelease}.iso"
ostreePackages="ostree-upgrade-bootstrap_2.0.41_all.deb ostree-upgrade_2.0.41_all.deb"
localAssets="${WORKING_DIR}"
localData="/data"
physicalDisk="/dev/sda"

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

runPrint "Rebooting targetg system"
halt
