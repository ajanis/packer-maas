#!/usr/bin/make -f

include ../scripts/check.mk

PACKER ?= packer
PACKER_LOG ?= 0
export PACKER_LOG
SERIES ?= jammy
TIMEOUT ?= 1h
CUSTOMIZE_SCRIPT ?= /dev/null

.PHONY: all clean

all: harmonic-installer
$(eval $(call check_packages_deps,cloud-image-utils ovmf libnbd0 nbdfuse nbdkit fuse2fs,cloud-image-utils ovmf libnbd0 nbdfuse nbdkit fuse2fs ))

lint:
	packer validate .
	packer fmt -check -diff .

format:
	packer fmt .

harmonic-installer: check-deps clean
	${PACKER} init . && ${PACKER} build \
	  -only='harmonic.*'
		-var ubuntu_series=${SERIES} \
		-var timeout=${TIMEOUT} -var customize_script=${CUSTOMIZE_SCRIPT} .

clean:
	${RM} -rf output-* harmonic-*.gz harmonic-seeds.iso OVMF_VARS.fd manifest.json
