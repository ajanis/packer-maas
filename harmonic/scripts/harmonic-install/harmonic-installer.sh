#!/bin/bash
##############################################################################
#
#   /usr/local/bin/harmonic-installer.sh
#
#   This script is executed by 'harmonic-install.service' that fetches the
#   Apollo (Harmonic cOS) .iso file and executes the 'ostree-production'
#   commands that will to write the .iso to the system '/dev/sda' disk.
#
##############################################################################


WS_HOST="172.22.31.150"
WS_PORT="8080"
APOLLO_RELEASE="release-3.21.3.0-7+auto15"
APOLLO_ISO="APOLLO_PLATFORM-${APOLLO_RELEASE}.iso"
OSTREE_PKGS="ostree-upgrade-bootstrap_2.0.41_all.deb ostree-upgrade_2.0.41_all.deb"
# MAAS_RESOURCE_URL=http://maas.spoc.charterlab.com:5248/images
PROXY_URL='http://proxy4.spoc.charterlab.com:8080'
PROXY_IGNORE='localhost,127.0.0.1,127.0.0.53,spoc.charterlab.com,nfv.charterlab.com,proxy4.spoc.charterlab.com,44.10.4.101/32,44.10.4.200/32,172.22.0.0/16'


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

-i|     (REQUIRED FOR INSTALL) Install Apollo (Harmonic cOS) .iso located in /data using ostree scripts

-h|     Display help

EOT
}

proxySetup() {
  if [[ ${proxy} == 1 ]]; then

    runPrint "Configuring Proxies"

    : "${http_proxy:=${PROXY_URL}}"  && export http_proxy="${http_proxy}"
    : "${https_proxy:=${PROXY_URL}}" && export https_proxy="${https_proxy}"
    : "${no_proxy:=${PROXY_IGNORE}}" && export no_proxy="${no_proxy}"
    echo "HTTP Proxy:: ${http_proxy}"
    echo "HTTPS Proxy:: ${https_proxy}"
  fi
  return
}

ostreeSetup() {
  runPrint "Downloadig Dependencies.."

  runPrint "Checking for OSTree Helper Scripts"

  if [[ ! -n $(command -v ostree-production) ]]; then
    for PACKAGE in ${OSTREE_PKGS}; do

      runPrint "Fetching ${PACKAGE}"

      curl "http://${WS_HOST}:${WS_PORT}/packages/${PACKAGE}" \
      --output "/tmp/${PACKAGE}"

      runPrint "Installing ${PACKAGE}"

      dpkg -i "/tmp/${PACKAGE}"

    done
  fi

  if [[ ! -d /data ]]; then

    runPrint "Creating install directory at /data"

    mkdir /data

    runPrint "Fetching ${APOLLO_ISO}"

    curl "http://${WS_HOST}:${WS_PORT}/apollo/latest" \
    --output "/data/${APOLLO_ISO}"

  fi

  return
}

ostreeInstall() {

  ${runPrint} "Verifyiing ${APOLLO_ISO} ostree"

  ostree-production list-isos

  ${runPrint} "Imaging /dev/sda from ${APOLLO_ISO} ostree"

  ostree-production -D /dev/sda from "/data/${APOLLO_ISO}"

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

[[ ${proxy} == 1 ]] && ( (proxySetup && runPrint "Proxy Configuration Complete") || (runPrint "Proxy Configuration Failed" && exit 1) )
[[ "${download}" == 1 ]] && ( (ostreeSetup &&  runPrint "Resources Downloaded") || (runPrint "Resource Download Failed" && exit 1) )
[[ "${install}" == 1 ]] && ( (ostreeInstall && runPrint "Harmonic cOS Install COMPLETE") || (runPrint "Harmonic Install FAILED" && exit 1) )

exit 0
