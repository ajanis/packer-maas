#!/bin/bash
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

# shellcheck disable=SC2312

# Main Script Variable Exports
export webserverHost="172.22.31.150"
export webserverPort="8080"
export artifactoryURL="https://artifactory.charterlab.com"
export artifactoryPath="artifactory/upload/harmonic/apollo"
export apolloRelease="release-3.21.3.0-7+auto15"
export apolloISO="APOLLO_PLATFORM-${apolloRelease}.iso"
export ostreePackages="ostree-upgrade-bootstrap_2.0.41_all.deb ostree-upgrade_2.0.41_all.deb"
export proxyURI="http://proxy4.spoc.charterlab.com:8080"
export proxyIgnore="localhost,44.10.4.101,44.10.4.200,172.22.31.150,10.41.64.0/24,spoc.charterlab.com,nfv.charterlab.com,.svc,172.22.73.0/24,35.135.192.0/24,10.240.72.0/22,44.0.0.0/8,[2600:6ce6:4410:803/64],[2605:1c00:50f2:2800/64],[2605:1c00:50f3:70/64]"
export workingDir="${PWD}"
export isoDir="/data"
export physicalDisk="/dev/sda"
export harmonicPV="${physicalDisk}3"
export harmonicVG=${cos-slice-vg}
export proxy=0
export download=0
export install=0

runPrint() {
cat << EOF
===========================================================
  $@
===========================================================
EOF
}

# Remove existing partitions, logical volumes and volume groups
diskSetup() {
  runPrint "Disabling logical volumes ..."
  vgchange -an
  runPrint "Unmounting ${physicalDisk} ..."
  umount -lf "${physicalDisk}"
  runPrint "Removing VG ${harmonicVG} ..."
  vgremove -y cos-slice-vg
  runPrint "Removing PV ${physicalDisk}3 ..."
  pvremove -y "${physicalDisk}3"
  runPrint "Removing any filesystem data from ${physicalDisk} ..."
  wipefs -f -a "${physicalDisk}"
  runPrint "Forceably overwriting boot sector of ${physicalDisk} ..."
  dd if=/dev/zero of="${physicalDisk}" bs=1M count=100
  runPrint "Reloading ${physicalDisk} partition map ..."
  partprobe "${physicalDisk}"
}


# Script Help Function
showHelp() {
cat << EOH
Usage: $0 [-p -v] [-i] [-h]

Image a physical server with Harmonic cOS

-p|	  	(OPTIONAL) Enable the HTTP Proxy
        Note: HTTP Proxy is disabled by default

-v|	  	(OPTIONAL) Enable verbose and xtrace mode (set -xv)

-i|     (REQUIRED FOR INSTALL) Install Apollo (Harmonic cOS) .iso located in "${isoDir}" using ostree scripts

-h|     Display help

EOH
}

if ! (lsblk "${physicalDisk}" >/dev/null 2>&1); then
  runPrint "Physical disk ${physicalDisk} not found.  Can not proceed with Harmonic installation ..."
  exit 1
else
  runPrint "Physical disk ${physicalDisk} detected.  Performing pre-install disk preparation ..."
  diskSetup >(tee -a /var/log/harmonic >&2) > >(tee -a /var/log/harmonic)
  fi

runPrint "Unset any http(s) proxy configurations or environment variables by default ..."
unset http_proxy
unset https_proxy
unset no_proxy


# Proxy setup function
proxySetup() {
  if [[ ${proxy} == 1 ]]; then
    runPrint "Setting up HTTP(S) proxy environment ..."
    : "${http_proxy:=${proxyURI}}"  && export http_proxy="${http_proxy}"
    : "${https_proxy:=${proxyURI}}" && export https_proxy="${https_proxy}"
    : "${no_proxy:=${proxyIgnore}}" && export no_proxy="${no_proxy}"
 
    runPrint "

    Current HTTP(s) proxy environment:

    http_proxy: ${http_proxy}
    http_proxy: ${https_proxy}
    no_proxy: ${no_proxy}

    "
  fi
  return
}

# Install ostree-production script packages
ostreeSetup() {
  runPrint "Creating ${workingDir} ..."
  mkdir -p "${workingDir}"
  runPrint "Installing 'ostree-production' provider packages ..."
  for debPkg in ${ostreePackages}; do
    runPrint "Downloading ${debPkg} ..."
    wget "http://${webserverHost}:${webserverPort}/packages/${debPkg}" -O "${workingDir}/${debPkg}" > /dev/null 2>&1
    runPrint "Installing ${debPkg} ..."
    dpkg -i "${workingDir}/${debPkg}"
  done
  return
}

# Download Apollo ISO
harmonicSetup() {
  runPrint "Creating ${isoDir} ..."
  mkdir -p "${isoDir}"
  runPrint "Downloading ${apolloISO} to ${isoDir} ..."
  wget "${artifactoryURL}/${artifactoryPath}/${apolloISO}" -O "${isoDir}/${apolloISO}" > /dev/null 2>&1
  # wget "http://${webserverHost}:${webserverPort}/apollo/latest" -O "${isoDir}/${apolloISO}" > /dev/null 2>&1
  return
}

# Install "${apolloISO}" to "${physicalDisk}"
harmonicInstall() {
  runPrint "Listing .iso files located in ${isoDir} ..."
  ostree-production list-isos
  runPrint "Installing ${isoDir}/${apolloISO} to ${physicalDisk} ..."
  yes | ostree-production -D "${physicalDisk}" from "${isoDir}/${apolloISO}"
  return
}

# Main script options menu
while getopts "hvpi" o; do
    case "${o}" in
        h)
            showHelp
            exit 0
            ;;
        v)
            set -xv
            ;;
        p)
            proxy=1
            ;;
        i)
            download=1
            install=1
            ;;
        *)  showHelp
            exit 1
            ;;

    esac
done
shift $((OPTIND-1))

# Main Runners
if [[ ${proxy} == 1 ]]; then
  proxySetup  >(tee -a /var/log/harmonic >&2) > >(tee -a /var/log/harmonic)
fi

if [[ "${download}" == 1 ]]; then
  ostreeSetup >(tee -a /var/log/harmonic >&2) > >(tee -a /var/log/harmonic)
  harmonicSetup >(tee -a /var/log/harmonic >&2) > >(tee -a /var/log/harmonic)

fi

if [[ "${install}" == 1 ]]; then
  harmonicInstall >(tee -a /var/log/harmonic >&2) > >(tee -a /var/log/harmonic)
fi

exit 0
