#!/bin/bash -ex
#
# setup-boot.sh - Set up the image after initial boot
#

export DEBIAN_FRONTEND=noninteractive

# Configure apt proxy if needed.
packer_apt_proxy_config="/etc/apt/apt.conf.d/packer-proxy.conf"
if  [[ -n  "${http_proxy}" ]]; then
  echo "Acquire::http::Proxy \"${http_proxy}\";" >> "${packer_apt_proxy_config}"
fi
if  [[ -n  "${https_proxy}" ]]; then
  echo "Acquire::https::Proxy \"${https_proxy}\";" >> "${packer_apt_proxy_config}"
fi

# Reset cloud-init, so that it can run again when MAAS deploy the image.
cloud-init clean --logs

# Update apt listins first as they might be stale
apt-get update -q

# The cloud image for qemu has a kernel already. Remove it, since the user
# should either install a kernel in the customize script, or let MAAS install
# the right kernel when deploying.
apt-get remove --purge -y linux-virtual 'linux-image-*'
