#!/bin/bash -ex
#
# curtin.sh - Move curtin scripts to final destination
#

export DEBIAN_FRONTEND=noninteractive

apt-get install -y jq
mkdir -p /curtin

# install scripts
for s in curtin-hooks install-custom-packages setup-bootloader; do
  if [[ -f "/tmp/${s}" ]]; then
    mv "/tmp/${s}" /curtin/
    chmod 750 "/curtin/${s}"
  fi
done

# copy custom packages
if [[ -f /tmp/custom-packages.tar.gz ]]; then
  mv /tmp/custom-packages.tar.gz /curtin/
fi
