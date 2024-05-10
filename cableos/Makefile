#!/usr/bin/make -f

include ../scripts/check.mk

PACKER ?= packer
PACKER_LOG ?= 0
export PACKER_LOG
BOOT ?= uefi
ARCH ?= amd64
TIMEOUT ?= 1h
ISO= ?= boot-images/debirf-live_bullseye_amd64.iso


.PHONY: all clean

all: cableos-installer.tar.gz
$(eval $(call check_packages_deps,cloud-image-utils ovmf libnbd0 nbdfuse nbdkit fuse2fs debirf,cloud-image-utils ovmf libnbd0 nbdfuse nbdkit fuse2fs debirf))

lint:
	packer validate .
	packer fmt -check -diff .

format:
	packer fmt .

cableos-installer.tar.gz: check-deps clean
	${PACKER} init cableos-installer.pkr.hcl && ${PACKER} build \
		-var architecture=${ARCH} \
		-var boot_mode=${BOOT} \
		-var timeout=${TIMEOUT} cableos-installer.pkr.hcl

clean:
	${RM} -rf output-cableos-installer/* cableos-installer-*.gz