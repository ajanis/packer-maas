#!/bin/bash -ex
export APOLLO_PKG=APOLLO_PLATFORM-release-3.21.3.0-7+auto15.iso
ostree-production -D /dev/sda from /opt/${APOLLO_PKG}
