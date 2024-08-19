#!/bin/bash -ex
#
# networking.sh - Prepare image to boot with cloud-init
#
export DEBIAN_FRONTEND=noninteractive

apt-get -o Dpkg::Options::="--force-confold" install -qy netplan.io cloud-init

cat > /etc/sysctl.d/99-cloudimg-ipv6.conf <<EOF
net.ipv6.conf.all.use_tempaddr = 0
net.ipv6.conf.default.use_tempaddr = 0
EOF

rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg
rm -f /etc/cloud/cloud.cfg.d/99-installer.cfg
rm -f /etc/cloud/ds-identify.cfg
rm -f /etc/netplan/00-installer-config.yaml
