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


export webserverHost="172.22.31.150"
export webserverPort="8080"
export apolloRelease="release-3.21.3.0-7+auto15"
export apolloISO="APOLLO_PLATFORM-${apolloRelease}.iso"
export ostreePackages="ostree-upgrade-bootstrap_2.0.41_all.deb ostree-upgrade_2.0.41_all.deb"
export proxyURI="http://proxy4.spoc.charterlab.com:8080"
export proxyIgnore="localhost,127.0.0.1,127.0.0.53,spoc.charterlab.com,nfv.charterlab.com,proxy4.spoc.charterlab.com,44.10.4.101/32,44.10.4.200/32,172.22.0.0/16"
export workingDir="/media/root-rw"
export isoDir="/data"
export physicalDisk="/dev/sda"
export proxy=0
export download=0
export install=0

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

if ! lsblk "${physicalDisk}" >/dev/null 2>&1; then
runPrint "Physical disk ${physicalDisk} not found.  Harmonic cOS installation can not run on this host."
exit 0
else
runPrint "Physical disk ${physicalDisk} found.  Proceeding with Harmonic cOS installation..."
fi


showHelp() {
cat << EOT
Usage: $0 [-p -v] [-i] [-h]

Image a physical server with Harmonic cOS

-p|	  	(OPTIONAL) Enable the HTTP Proxy
        Note: HTTP Proxy is disabled by default

-v|	  	(OPTIONAL) Enable verbose and xtrace mode (set -xv)

-i|     (REQUIRED FOR INSTALL) Install Apollo (Harmonic cOS) .iso located in "${isoDir}" using ostree scripts

-h|     Display help

EOT
}

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

ostreeSetup() {

  runPrint "Installing 'ostree-production' provider packages"
    for debPkg in ${ostreePackages}; do

      runPrint "Downloading ${debPkg}"
      wget "http://${webserverHost}:${webserverPort}/packages/${debPkg}" -O "${workingDir}/${debPkg}" 2>&1

      runPrint "Installing ${debPkg}"
      dpkg -i "${workingDir}/${debPkg}" 2>&1

    done

  return
}

harmonicSetup() {
  runPrint "Creating ${isoDir}"
  mkdir -p "${isoDir}"

  runPrint "Downloading ${apolloISO} to ${isoDir}"
  wget "http://${webserverHost}:${webserverPort}/apollo/latest" -O "${isoDir}/${apolloISO}" 2>&1

  return
}

harmonicInstall() {
  runPrint "Listing .iso files located in ${isoDir}"
  ostree-production list-isos 2>&1

  runPrint "Installing ${isoDir}/${apolloISO} tdo ${physicalDisk}"
  ostree-production -D "${physicalDisk}" from "${isoDir}"/"${apolloISO}" 2>&1
  
  return
}

while getopts "h?vpi" o; do
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
        ?|*)
            showHelp
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))


if [[ ${proxy} == 1 ]]; then
proxySetup
fi

if [[ "${download}" == 1 ]]; then
ostreeSetup
fi

if [[ "${install}" == 1 ]]; then
harmonicSetup
harmonicInstall
fi

exit 0