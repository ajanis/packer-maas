#!/bin/bash -ex
#
# curtin.sh - Move curtin scripts to final destination
#

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y jq
mkdir -p /curtin

# install scripts
for s in curtin-hooks setup-bootloader; do
  if [[ -f "/tmp/${s}" ]]; then
    mv "/tmp/${s}" /curtin/
    chmod 750 "/curtin/${s}"
  fi
done
