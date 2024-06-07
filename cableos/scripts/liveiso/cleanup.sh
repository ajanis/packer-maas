#!/bin/bash -ex
#
# cleanup.sh - Remove cache and install artifacts
#
export DEBIAN_FRONTEND=noninteractive

apt-get autoremove --purge -yq
apt-get clean -yq
