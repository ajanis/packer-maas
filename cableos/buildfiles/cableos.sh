#!/bin/bash -ex
# /root/cableos.sh
export APOLLO_ISONAME=APOLLO_PLATFORM-release-3.21.3.0-7+auto15.iso
export MAAS_RESOURCE_URL=http://maas.spoc.charterlab.com:5248/images
export PROXY_URL='http://proxy4.spoc.charterlab.com:8080'
export PROXY_IGNORE='spoc.charterlab.com,nfv.charterlab.com,.svc,172.22.73.0/24,35.135.192.0/24,44.10.4.100/32,44.10.4.101/32,10.240.72.0/22,44.0.0.0/8,[2600:6ce6:4410:803/64],[2605:1c00:50f2:2800/64],[2605:1c00:50f3:70/64],proxy4.spoc.charterlab.com,44.10.4.101,44.10.4.100,localhost,127.0.0.1'

function proxySetup() {
: "${http_proxy:=${PROXY_URL}}"
: "${https_proxy:=${PROXY_URL}}"
: "${no_proxy:=${PROXY_IGNORE}}"
echo -n "
http_proxy: ${http_proxy}
https_proxy: ${https_proxy}
no_proxy: ${no_proxy}
"
}

function proxyTeardown() {

if [[ ! -z $http_proxy ]]; then
  unset http_proxy
  echo "http_proxy unset"
fi

if [[ ! -z $https_proxy ]]; then
  unset https_proxy
  echo "https_proxy unset"
fi

}

function ostreeSetup() {
mkdir -p /data
curl --output "${APOLLO_ISONAME}" "${MAAS_RESOURCE_URL}/${APOLLO_ISONAME}"
}

function ostreeInstall() {
ostree-production list-isos
ostree-production -D /dev/sda from "/data/${APOLLO_ISONAME}"
}



proxyTeardown
ostreeSetup
ostreeInstall
f

# For MAAS version <= 3.4 you can deploy ubuntu images “ephemerally” (i.e. loaded in memory) using the CLI with

# maas $USER machine deploy $MACHINE_ID ephemeral_deploy=true
# In order to view all the possible parameters (os version to be deployed and other…), you can run
