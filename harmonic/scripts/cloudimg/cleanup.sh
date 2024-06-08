#!/bin/bash -ex
#
# cleanup.sh - Clean up what we did to be able to build the image.
#

# cloud-init put networking in place on initial boot. Let's remove that, to
# allow MAAS to configure the networking on deploy.
rm /etc/netplan/50-cloud-init.yaml

# Everything in /run/packer_backup should be restored.
find /run/packer_backup
cp --preserve -r /run/packer_backup/ /
rm -rf /run/packer_backup

# We had to allow root to ssh for the image setup. Let's try to revert that.
sed -i s/^root:[^:]*/root:*/ /etc/shadow
rm -r /root/.ssh
rm -r /root/.cache
rm -r /etc/ssh/ssh_host_*

# Final Clean-up
apt-get autoremove --purge -yq
apt-get clean -yq
