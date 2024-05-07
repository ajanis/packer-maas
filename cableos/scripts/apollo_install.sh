#!/bin/bash -ex
export DEBIAN_FRONTEND=noninteractive
export APOLLO_PKG=APOLLO_PLATFORM-release-3.21.3.0-7+auto15.iso
mkdir /data
wget -O /data/${APOLLO_PKG} http://${PACKER_HTTP_IP}:${PACKER_HTTP_PORT}:/${APOLLO_PKG}

# run ostree-production command

ostree-production -D /dev/sda from /data/${APOLLO_PKG}
