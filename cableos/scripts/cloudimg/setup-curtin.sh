#!/bin/bash -ex
#
# cloud-img-setup-curtin.sh - Set up curtin curthooks, if needed.
#

if  [[ ! -f  "/curtin/CUSTOM_KERNEL" ]]; then
  echo "Skipping curtin setup, since no custom kernel is used."
  exit 0
fi

echo "Configuring curtin to install custom kernel"

mkdir -p /curtin

FILENAME=curtin-hooks
mv "/tmp/${FILENAME}" /curtin/
chmod 750 "/curtin/${FILENAME}"
