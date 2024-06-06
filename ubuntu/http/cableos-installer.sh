#!/bin/bash -ex
# /root/cableos.sh
if [[ -n $1 ]]; then
export COMMAND=build
else
export COMMAND=$1
fi

export APOLLO_ISONAME=APOLLO_PLATFORM-release-3.21.3.0-7+auto15.iso
export OSTREE_PKG=ostree-upgrade.tar.gz
export MAAS_RESOURCE_URL=http://maas.spoc.charterlab.com:5248/images
export PROXY_URL='http://proxy4.spoc.charterlab.com:8080'
export PROXY_IGNORE='spoc.charterlab.com,nfv.charterlab.com,.svc,172.22.73.0/24,35.135.192.0/24,44.10.4.100/32,44.10.4.200/32,10.240.72.0/22,44.0.0.0/8,[2600:6ce6:4410:803/64],[2605:1c00:50f2:2800/64],[2605:1c00:50f3:70/64],proxy4.spoc.charterlab.com,44.10.4.200,44.10.4.100,localhost,127.0.0.1'

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

if [[ ! -z ${http_proxy} ]]; then
  unset http_proxy
  echo "http_proxy unset"
fi

if [[ ! -z ${https_proxy} ]]; then
  unset https_proxy
  echo "https_proxy unset"
fi

}

function ostreeSetup() {
# cd /media/root-rw
# tar -zxvf "${OSTREE_PKG}"
# dpkg -i nsg-upgrade/ostree-upgrade-bootstrap_2.0.41_all.deb
# dpkg -i nsg-upgrade/ostree-upgrade_2.0.41_all.deb
mkdir /data
curl "http://${PACKER_HTTP_IP}:${PACKER_HTTP_PORT}:/ostree-upgrade_2.0.41_all.deb" --output /opt/ostree-upgrade_2.0.41_all.deb
curl "http://${PACKER_HTTP_IP}:${PACKER_HTTP_PORT}:/ostree-upgrade-bootstrap_2.0.41_all.deb" --output /opt/ostree-upgrade-bootstrap_2.0.41_all.deb
dpkg -i /opt/ostree-upgrade-bootstrap_2.0.41_all.deb
dpkg -i /opt/ostree-upgrade_2.0.41_all.deb
}

function ostreeInstall() {
ostree-production list-isos
ostree-production -D /dev/sda from "/data/${APOLLO_ISONAME}"
}

case $1 in
  build)
    proxyTeardown
    ostreeSetup
    ;;
  install)
    proxyTeardown
    ostreeInstall
    shutdown -r now
    ;;
  *)
    exit
esac
# For MAAS version <= 3.4 you can deploy ubuntu images “ephemerally” (i.e. loaded in memory) using the CLI with
# maas $USER machine deploy $MACHINE_ID ephemeral_deploy=true
# maas admin machine deploy bfxr33 ephemeral_deploy=true user_data='I2Nsb3VkLWNvbmZpZwp1c2VyczoKICAtIG5hbWU6IHJvb3QKICAgIGxvY2tfcGFzc3dkOiBmYWxzZQogICAgcGxhaW5fdGV4dF9wYXNzd2Q6ICJpbnN0YWxsIgogICAgc3NoX3JlZGlyZWN0X3VzZXI6IGZhbHNlCnNzaF9wd2F1dGg6IFRydWUKZGlzYWJsZV9yb290OiBmYWxzZQpwcmVzZXJ2ZV9ob3N0bmFtZTogdHJ1ZQpydW5jbWQ6CiAgLSBzZWQgLWkgLWUgJy9eWyNdKlBlcm1pdFJvb3RMb2dpbi9zL14uKiQvUGVybWl0Um9vdExvZ2luIHllcy8nIC9ldGMvc3NoL3NzaGRfY29uZmlnCiAgLSBzeXN0ZW1jdGwgcmVzdGFydCBzc2gKYm9vdGNtZDoKICAtIGN1cmwgaHR0cDovLzE3Mi4yMi4zMS4xNTA6ODA4MC9BUE9MTE9fUExBVEZPUk0tcmVsZWFzZS0zLjIxLjMuMC03K2F1dG8xNS5pc28gLS1vdXRwdXQgL21lZGlhL3Jvb3QtcncvQVBPTExPX1BMQVRGT1JNLXJlbGVhc2UtMy4yMS4zLjAtNythdXRvMTUuaXNvCiAgLSBjdXJsICBodHRwOi8vMTcyLjIyLjMxLjE1MDo4MDgwL29zdHJlZS11cGdyYWRlLnRhci5neiAtLW91dHB1dCAvbWVkaWEvcm9vdC1ydy9vc3RyZWUtdXBncmFkZS50YXIuZ3oKICAtIGN1cmwgaHR0cDovLzE3Mi4yMi4zMS4xNTA6ODA4MC9jYWJsZW9zLWluc3RhbGxlci5zaCAtLW91dHB1dCAvbWVkaWEvcm9vdC1ydy9jYWJsZW9zLWluc3RhbGxlci5zaAogIC0gY2htb2QgK3ggL21lZGlhL3Jvb3QtcncvY2FibGVvcy1pbnN0YWxsZXIuc2gKICAtIC9iaW4vYmFzaCAvbWVkaWEvcm9vdC1ydy9jYWJsZW9zLWluc3RhbGxlci5zaAo='
