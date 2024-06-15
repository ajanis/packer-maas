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
cat << 'EOI' > /local/usr/local/bin/harmonic-installer.sh
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


webserverHost="172.22.31.150"
webserverPort="8080"
apolloRelease="release-3.21.3.0-7+auto15"
apolloISO="APOLLO_PLATFORM-${apolloRelease}.iso"
ostreePackages="ostree-upgrade-bootstrap_2.0.41_all.deb ostree-upgrade_2.0.41_all.deb"
# maasURI="http://maas.spoc.charterlab.com:5248/images"
proxyURI="http://proxy4.spoc.charterlab.com:8080"
proxyIgnore="localhost,127.0.0.1,127.0.0.53,spoc.charterlab.com,nfv.charterlab.com,proxy4.spoc.charterlab.com,44.10.4.101/32,44.10.4.200/32,172.22.0.0/16"
localAssets="/media/root-rw"
localData="/data"
physicalDisk="/dev/sda"

proxy=0
download=0
install=0
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

showHelp() {
cat << EOT
Usage: $0 [-p -v] [-i] [-h]

Image a physical server with Harmonic cOS

-p|	  	(OPTIONAL) Enable the HTTP Proxy
        Note: HTTP Proxy is disabled by default

-v|	  	(OPTIONAL) Enable verbose and xtrace mode (set -xv)

-i|     (REQUIRED FOR INSTALL) Install Apollo (Harmonic cOS) .iso located in "${localData}" using ostree scripts

-h|     Display help

EOT
}

proxySetup() {
  if [[ ${proxy} == 1 ]]; then


    : "${http_proxy:=${proxyURI}}"  && export http_proxy="${http_proxy}"
    : "${https_proxy:=${proxyURI}}" && export https_proxy="${https_proxy}"
    : "${no_proxy:=${proxyIgnore}}" && export no_proxy="${no_proxy}"

    echo "Using http_proxy:: ${http_proxy}"
    echo "Using https_proxy:: ${https_proxy}"
  fi
  return
}

ostreeSetup() {

  runPrint "Checking  to see if ostree-helper scripts are already present..."

  if [[ -z $(command -v ostree-production) ]]; then
    for thisPackage in ${ostreePackages}; do
      curl "http://${webserverHost}:${webserverPort}/packages/${thisPackage}" --output "${localAssets}/${thisPackage}" 2>&1
      dpkg -i "${localAssets}/${thisPackage}" 2>&1

    done
  fi

    mkdir "${localData}" \
    && curl "http://${webserverHost}:${webserverPort}/apollo/latest" --output "${localData}/${apolloISO}" 2>&1

  return
}

ostreeInstall() {

  ostree-production list-isos 2>&1
  ostree-production -D "${physicalDisk}" from "${localData}"/"${apolloISO}" 2>&1

  return
}

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
        *)
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
ostreeInstall
fi

EOI

## Fix script ownership
chmod +x /usr/local/bin/harmonic-installer.sh
