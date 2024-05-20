#!/usr/bin/make -f

include ../scripts/check.mk

PACKER ?= packer
PACKER_LOG ?= 1
export PACKER_LOG
BOOT ?= uefi
ARCH ?= amd64
TIMEOUT ?= 1h
ISO= ?= boot-images/debirf-live_bullseye_amd64.qcow2


.PHONY: all clean

all: cableos-installer
$(eval $(call check_packages_deps,cloud-image-utils ovmf libnbd0 nbdfuse nbdkit fuse2fs debirf,cloud-image-utils ovmf libnbd0 nbdfuse nbdkit fuse2fs debirf))

lint:
	packer validate .
	packer fmt -check .

format:
	packer fmt .

# OVMF_VARS.fd: /usr/share/OVMF/OVMF_VARS.fd
# 	cp -v $< $@

cableos-installer: check-deps clean
	${PACKER} init cableos-installer.pkr.hcl && ${PACKER} build \
		-var architecture=${ARCH} \
		-var boot_mode=${BOOT} \
		-var timeout=${TIMEOUT} cableos-installer.pkr.hcl



clean:
	${RM} -rf output-cableos-builder output-cableos-installer cableos-installer-*.gz
# OVMF_VARS.fd
# AAVMF_VARS.fd

# .INTERMEDIATE: OVMF_VARS.fd
