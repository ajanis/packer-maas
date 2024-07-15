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
export apolloRelease="release-3.21.3.0-7+auto15"
export apolloISO="APOLLO_PLATFORM-${apolloRelease}.iso"
export ostreePackages="ostree-upgrade-bootstrap_2.0.41_all.deb ostree-upgrade_2.0.41_all.deb"
export proxyURI="http://proxy4.spoc.charterlab.com:8080"
export proxyIgnore="localhost,127.0.0.1,127.0.0.53,spoc.charterlab.com,nfv.charterlab.com,proxy4.spoc.charterlab.com,44.10.4.101/32,44.10.4.200/32,172.22.0.0/16"
export workingDir="$(PWD)"
export isoDir="/data"
export physicalDisk="/dev/sda"
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

# Set up script logging
: > /var/log/harmonic
exec 2> >(tee -a /var/log/harmonic >&2) > >(tee -a /var/log/harmonic)

# Check for "${physicalDisk}
# Remove any existing LVMs and zero boot partition if found
# Otherwise exit
if ! lsblk "${physicalDisk}" >/dev/null 2>&1; then
  runPrint "Physical disk ${physicalDisk} not found.  Harmonic cOS installation can not run on this host."
  exit 1
else
  runPrint "Physical disk ${physicalDisk} found.  Proceeding with Harmonic cOS installation..."
  vgchange -an
  umount -lf /dev/sda
  dd if=/dev/zero of="${physicalDisk}" bs=1M count=100
fi

# Unset HTTP Proxies by default
unset http_proxy
unset https_proxy
unset no_proxy

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

# Proxy setup function
proxySetup() {
  if [[ ${proxy} == 1 ]]; then
    runPrint "Configuring HTTP(S) proxies"
    : "${http_proxy:=${proxyURI}}"  && export http_proxy="${http_proxy}"
    : "${https_proxy:=${proxyURI}}" && export https_proxy="${https_proxy}"
    : "${no_proxy:=${proxyIgnore}}" && export no_proxy="${no_proxy}"
    runprint "Proxy Information:
    http_proxy: ${http_proxy}
    http_proxy: ${https_proxy}
    no_proxy: ${no_proxy}
    "
  fi
  return
}

# Install ostree-production script packages
ostreeSetup() {
  runPrint "Creating ${workingDir}"
  mkdir -p "${workingDir}"
  runPrint "Installing 'ostree-production' provider packages"
  for debPkg in ${ostreePackages}; do
    runPrint "Downloading ${debPkg}"
    wget "http://${webserverHost}:${webserverPort}/packages/${debPkg}" -O "${workingDir}/${debPkg}"
    runPrint "Installing ${debPkg}"
    dpkg -i "${workingDir}/${debPkg}"
  done
  return
}

# Download Apollo ISO
harmonicSetup() {
  runPrint "Creating ${isoDir}"
  mkdir -p "${isoDir}"
  runPrint "Downloading ${apolloISO} to ${isoDir}"
  wget "http://${webserverHost}:${webserverPort}/apollo/latest" -O "${isoDir}/${apolloISO}"
  # runPrint "Direct-Installing ${apolloISO} via HTTP"
  return
}

# Install "${apolloISO}" to "${physicalDisk}"
harmonicInstall() {
  runPrint "Listing .iso files located in ${isoDir}"
  ostree-production list-isos
  runPrint "Installing ${isoDir}/${apolloISO} to ${physicalDisk}"
  # runPrint "Installing http://${webserverHost}:${webserverPort}/apollo/latest} to ${physicalDisk}"
  # ostree-production -D "${physicalDisk}" from "http://${webserverHost}:${webserverPort}/apollo/latest}"
  ostree-production -D "${physicalDisk}" from "${isoDir}/${apolloISO}" <<EOS
  y
  y
  y
  y
EOS
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
  proxySetup
fi

if [[ "${download}" == 1 ]]; then
  ostreeSetup
  harmonicSetup

fi

if [[ "${install}" == 1 ]]; then
  harmonicInstall
fi

exit 0
