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

	if [[ -n ${http_proxy} ]]; then
		  unset http_proxy
		    echo "http_proxy unset"
	fi

	if [[ -n ${https_proxy} ]]; then
		  unset https_proxy
		    echo "https_proxy unset"
	fi

}

function ostreeSetup() {

	# Fetch and install ostree script dpkgs
	for PACKAGE in ${OSTREE_PKGS}; do
		curl "http://${WS_HOST}:${WS_PORT}/packages/${PACKAGE}" --output "/opt/${PACKAGE}" && dpkg -i "/opt/${PACKAGE}"
	done

	# Fetch VCMTS iso
	mkdir /data
        curl "http://${WS_HOST}:${WS_PORT}/apollo/latest" --output "/data/${APOLLO_ISO}"

	#curl "http://172.22.31.150:8080/packages/${OSTREE_PKG}" --output "/media/root-rw/${OSTREE_PKG}"
	#tar -zxvf "${OSTREE_PKG}"
	#dpkg -i nsg-upgrade/ostree-upgrade-bootstrap_2.0.41_all.deb
	#dpkg -i nsg-upgrade/ostree-upgrade_2.0.41_all.deb

	#curl http://172.22.31.150:8080/packages/ostree-upgrade-bootstrap_2.0.41_all.deb --output /opt/ostree-upgrade-bootstrap_2.0.41_all.deb
	#curl http://172.22.31.150:8080/packages/ostree-upgrade_2.0.41_all.deb --output /opt/ostree-upgrade_2.0.41_all.deb
	#dpkg -i /opt/ostree-upgrade-bootstrap_2.0.41_all.deb
	#dpkg -i /opt/ostree-upgrade_2.0.41_all.deb

}

function ostreeInstall() {
#	mkdir /data
#	mv /media/root-rw/* /data/
	ostree-production list-isos
	ostree-production -D /dev/sda from "/data/${APOLLO_ISO}"
}

ostreeInstall
#shutdown -r now

# For MAAS version <= 4.2 you can deploy ubuntu images “ephemerally” (i.e. loaded in memory) using the CLI with
# maas $USER machine deploy $MACHINE_ID ephemeral_deploy=true
# maas admin machine deploy bfxr33 ephemeral_deploy=true user_data='I2Nsb3VkLWNvbmZpZwp1c2VyczoKICAtIG5hbWU6IHJvb3QKICAgIGxvY2tfcGFzc3dkOiBmYWxzZQogICAgcGxhaW5fdGV4dF9wYXNzd2Q6ICJpbnN0YWxsIgogICAgc3NoX3JlZGlyZWN0X3VzZXI6IGZhbHNlCnNzaF9wd2F1dGg6IFRydWUKZGlzYWJsZV9yb290OiBmYWxzZQpwcmVzZXJ2ZV9ob3N0bmFtZTogdHJ1ZQpydW5jbWQ6CiAgLSBzZWQgLWkgLWUgJy9eWyNdKlBlcm1pdFJvb3RMb2dpbi9zL14uKiQvUGVybWl0Um9vdExvZ2luIHllcy8nIC9ldGMvc3NoL3NzaGRfY29uZmlnCiAgLSBzeXN0ZW1jdGwgcmVzdGFydCBzc2gKYm9vdGNtZDoKICAjLSBjdXJsIGh0dHA6Ly8xNzIuMjIuMzEuMTUwOjgwODAvQVBPTExPX1BMQVRGT1JNLXJlbGVhc2UtMy4yMS4zLjAtNythdXRvMTUuaXNvIC0tb3V0cHV0IC9tZWRpYS9yb290LXJ3L0FQT0xMT19QTEFURk9STS1yZWxlYXNlLTMuMjEuMy4wLTcrYXV0bzE1LmlzbwogICMtIGN1cmwgIGh0dHA6Ly8xNzIuMjIuMzEuMTUwOjgwODAvb3N0cmVlLXVwZ3JhZGUudGFyLmd6IC0tb3V0cHV0IC9tZWRpYS9yb290LXJ3L29zdHJlZS11cGdyYWRlLnRhci5negogIC0gY3VybCBodHRwOi8vMTcyLjIyLjMxLjE1MDo4MDgwL2NhYmxlb3MtaW5zdGFsbGVyLnNoIC0tb3V0cHV0IC9tZWRpYS9yb290LXJ3L2NhYmxlb3MtaW5zdGFsbGVyLnNoCiAgLSBjaG1vZCAreCAvbWVkaWEvcm9vdC1ydy9jYWJsZW9zLWluc3RhbGxlci5zaAogIC0gL2Jpbi9iYXNoIC9tZWRpYS9yb290LXJ3L2NhYmxlb3MtaW5zdGFsbGVyLnNoCg=='
