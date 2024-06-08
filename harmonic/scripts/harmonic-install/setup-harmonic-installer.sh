#!/bin/bash -ex
##############################################################################
#
#   /opt/setup-harmonic-installer.sh
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
dpkg -i /opt/ostree-upgrade-bootstrap_2.0.41_all.deb
dpkg -i /opt/ostree-upgrade_2.0.41_all.deb
rm -f /opt/*.deb

## Create systemd service to run on boot
touch /etc/systemd/system/harmonic-install.service
cat > /etc/systemd/system/harmonic-install.service <<EOF
[Unit]
Description=Harmonic cOS Installation Single-Use Startup Script
ConditionFirstBoot=yes

[Service]
Type=oneshot
ExecStart=/usr/local/bin/harmonic-installer.sh -v -i
RemainAfterExit=true
StandardOutput=journal

[Install]
WantedBy=multi-user.target
EOF

## Create script called by systemd service
touch /usr/local/bin/harmonic-installer.sh
cat > /usr/local/bin/harmonic-installer.sh <<EOF
#!/bin/bash -ex
##############################################################################
#
#   /usr/local/bin/harmonic-installer.sh
#
#   This script is executed by 'harmonic-install.service' that fetches the
#   Apollo (Harmonic cOS) .iso file and executes the 'ostree-production'
#   commands that will to write the .iso to the system '/dev/sda' disk.
#
##############################################################################


export WS_HOST="172.22.31.150"
export WS_PORT="8080"
export APOLLO_RELEASE="release-3.21.3.0-7+auto15"
export APOLLO_ISO="APOLLO_PLATFORM-${APOLLO_RELEASE}.iso"
export OSTREE_PKG=ostree-upgrade.tar.gz
export OSTREE_PKGS="ostree-upgrade-bootstrap_2.0.41_all.deb ostree-upgrade_2.0.41_all.deb"
export MAAS_RESOURCE_URL=http://maas.spoc.charterlab.com:5248/images
export PROXY_URL='http://proxy4.spoc.charterlab.com:8080'
export PROXY_IGNORE='spoc.charterlab.com,nfv.charterlab.com,.svc,172.22.73.0/24,35.135.192.0/24,10.240.72.0/22,44.0.0.0/8,[2600:6ce6:4410:803/64],[2605:1c00:50f2:2800/64],[2605:1c00:50f3:70/64],proxy4.spoc.charterlab.com,localhost,127.0.0.1,44.10.4.0/24,44.10.4.101:5240/MAAS,44.10.4.200:5240/MAAS'

export proxy=0
export verbose=0
unset http_proxy
unset https_proxy

showHelp() {
cat << EOT
Usage: $0 [-p|--proxy] [-v|--verbose] [-i|--install] [-h|--help]

Image a physical server with Harmonic cOS

-p|--proxy 	  	Enable the HTTP Proxy
			Note: HTTP Proxy is disabled by default

-v|--verbose 	  	Enable verbose and xtrace mode (set -xv)

-i|--install            Install Apollo (Harmonic cOS) .iso located in /data using ostree scripts

-h|--help               Display help

EOT
}

proxySetup() {
  : "${http_proxy:=${PROXY_URL}}"
  : "${https_proxy:=${PROXY_URL}}"
  : "${no_proxy:=${PROXY_IGNORE}}"

  echo -n "
  http_proxy is set: ${http_proxy}
  https_proxy is set: ${https_proxy}

  no_proxy value is set: ${no_proxy}

  "
}

proxyTeardown() {

  if [[ -n ${http_proxy} ]]; then
    unset http_proxy
    echo "http_proxy unset"
  fi

  if [[ -n ${https_proxy} ]]; then
    unset https_proxy
    echo "https_proxy unset"
  fi

}

ostreeSetup() {

  command -v ostree-production ||
  # # Fetch and install OSTree wrapper-script dpkgs
  for PACKAGE in ${OSTREE_PKGS}; do
    curl "http://${WS_HOST}:${WS_PORT}/packages/${PACKAGE}" --output "/opt/${PACKAGE}" && dpkg -i "/opt/${PACKAGE}"
  done

  # Fetch Harmonic cOS iso
  mkdir /data
  curl "http://${WS_HOST}:${WS_PORT}/apollo/latest" --output "/data/${APOLLO_ISO}"
}

ostreeInstall() {
  ostree-production list-isos
  ostree-production -D /dev/sda from "/data/${APOLLO_ISO}"
}

options=$(getopt -l "help,proxy,verbose,install" -o "hpvi" -- "$@")
eval set -- "${options}"
while true
do
case "$1" in
-h|--help)
    showHelp
    exit 0
    ;;
-p|--proxy)
    export proxy=1
    ;;
-v|--verbose)
    set -xv  # Set xtrace and verbose mode.
    ;;
-i|--install)
    if [[ ${proxy} == 1 ]]; then
      proxySetup
      else
      proxyTeardown
      fi
    ostreeSetup
    ostreeInstall
    #shutdown -r now
    ;;
*)
    showHelp
    exit 1
    ;;
esac
shift
done
EOF

## Fix script ownership
chmod +x /usr/local/bin/harmonic-installer.sh
