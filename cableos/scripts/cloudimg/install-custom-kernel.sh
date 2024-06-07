#!/bin/bash -ex
#
# install-custom-kernel.sh - Install custom kernel, if specified
#

if  [[ -z  "${CLOUDIMG_CUSTOM_KERNEL}" ]]; then
  echo "Not installing custom kernel, since none was specified."
  exit 0
fi

echo "Installing custom kernel ${CLOUDIMG_CUSTOM_KERNEL}"
apt-get install -y "${CLOUDIMG_CUSTOM_KERNEL}"

# Record the installed kernel version, so that the curtin hook knows about it.
mkdir -p /curtin
echo -n "${CLOUDIMG_CUSTOM_KERNEL}" > /curtin/CUSTOM_KERNEL
