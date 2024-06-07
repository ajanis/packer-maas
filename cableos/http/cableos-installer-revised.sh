#!/bin/bash -ex
# /root/cableos.sh

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
cat << EOF
Usage: $0 [-p|--proxy] [-v|--verbose] [-i|--install] [-h|--help]

Image a physical server with Harmony CableOS

-p|--proxy 	  	Enable the HTTP Proxy
			Note: HTTP Proxy is disabled by default

-v|--verbose 	  	Enable verbose and xtrace mode (set -xv)

-i|--install            Install Apollo iso located in /data using ostree scripts

-h|--help               Display help

EOF
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

  # Fetch and install ostree script dpkgs
  for PACKAGE in ${OSTREE_PKGS}; do
    curl "http://${WS_HOST}:${WS_PORT}/packages/${PACKAGE}" --output "/opt/${PACKAGE}" && dpkg -i "/opt/${PACKAGE}"
  done

  # Fetch VCMTS iso
  mkdir /data
  curl "http://${WS_HOST}:${WS_PORT}/apollo/latest" --output "/data/${APOLLO_ISO}"

  ## Original command fetches apollo iso to root-rw and moves it to /data
  #curl "http://172.22.31.150:8080/apollo/${APOLLO_ISO}" --output "/media/root-rw/${APOLLO_ISO}"
  #mv "/media/root-rw/${APOLLO_ISO}" /data/

  ## Original commands fetch tar.gz to root-rw, extract, install .deb packagers
  #curl "http://172.22.31.150:8080/packages/${OSTREE_PKG}" --output "/media/root-rw/${OSTREE_PKG}"
  #tar -zxvf "${OSTREE_PKG}"
  #dpkg -i nsg-upgrade/ostree-upgrade-bootstrap_2.0.41_all.deb
  #dpkg -i nsg-upgrade/ostree-upgrade_2.0.41_all.deb

  ## Alternate commands fetch .deb packages to /opt and install them
  #curl http://172.22.31.150:8080/packages/ostree-upgrade-bootstrap_2.0.41_all.deb --output /opt/ostree-upgrade-bootstrap_2.0.41_all.deb
  #curl http://172.22.31.150:8080/packages/ostree-upgrade_2.0.41_all.deb --output /opt/ostree-upgrade_2.0.41_all.deb
  #dpkg -i /opt/ostree-upgrade-bootstrap_2.0.41_all.deb
  #dpkg -i /opt/ostree-upgrade_2.0.41_all.deb

}

ostreeInstall() {
  ostree-production list-isos
  ostree-production -D /dev/sda from "/data/${APOLLO_ISO}"
}

options=$(getopt -l "help,proxy,verbose,install" -o "hpvi")
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


# For MAAS version <= 4.2 you can deploy ubuntu images “ephemerally” (i.e. loaded in memory) using the CLI with
# maas $USER machine deploy $MACHINE_ID ephemeral_deploy=true
# maas admin machine deploy bfxr33 ephemeral_deploy=true user_data='I2Nsb3VkLWNvbmZpZwp1c2VyczoKICAtIG5hbWU6IHJvb3QKICAgIGxvY2tfcGFzc3dkOiBGYWxzZQogICAgcGxhaW5fdGV4dF9wYXNzd2Q6ICJpbnN0YWxsIgogICAgcGFzc3dvcmQ6IGluc3RhbGwKICAgIHNzaF9yZWRpcmVjdF91c2VyOiBGYWxzZQogICAgc3NoX3B3YXV0aDogVHJ1ZQogICAgZGlzYWJsZV9yb290OiBGYWxzZQogICAgcHJlc2VydmVfaG9zdG5hbWU6IFRydWUKcnVuY21kOgogIC0gc2VkIC1pIC1lICcvXlsjXSpQZXJtaXRSb290TG9naW4vcy9eLiokL1Blcm1pdFJvb3RMb2dpbiB5ZXMvJyAvZXRjL3NzaC9zc2hkX2NvbmZpZwogIC0gc3lzdGVtY3RsIHJlc3RhcnQgc3NoCmJvb3RjbWQ6CiAgIy0gY3VybCBodHRwOi8vMTcyLjIyLjMxLjE1MDo4MDgwL2Fwb2xsby9BUE9MTE9fUExBVEZPUk0tcmVsZWFzZS0zLjIxLjMuMC03K2F1dG8xNS5pc28gLS1vdXRwdXQgL21lZGlhL3Jvb3QtcncvQVBPTExPX1BMQVRGT1JNLXJlbGVhc2UtMy4yMS4zLjAtNythdXRvMTUuaXNvCiAgIy0gY3VybCAgaHR0cDovLzE3Mi4yMi4zMS4xNTA6ODA4MC9wYWNrYWdlcy9vc3RyZWUtdXBncmFkZS50YXIuZ3ogLS1vdXRwdXQgL21lZGlhL3Jvb3Qtcncvb3N0cmVlLXVwZ3JhZGUudGFyLmd6CiAgLSBjdXJsIGh0dHA6Ly8xNzIuMjIuMzEuMTUwOjgwODAvc2NyaXB0cy9jYWJsZW9zLWluc3RhbGxlci5zaCAtLW91dHB1dCAvb3B0L2NhYmxlb3MtaW5zdGFsbGVyLnNoCiAgLSBjaG1vZCAreCAvb3B0L2NhYmxlb3MtaW5zdGFsbGVyLnNoCiAgLSAvb3B0L2NhYmxlb3MtaW5zdGFsbGVyLnNoIC12IC1pCg=='
