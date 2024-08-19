#!/usr/bin/make -f

include ../scripts/check.mk

PACKER ?= packer
PACKER_LOG ?= 1
export PACKER_LOG
SERIES ?= jammy
TIMEOUT ?= 1h
CUSTOMIZE_SCRIPT ?= /dev/null
URL ?= http://releases.ubuntu.com

.PHONY: all clean

all: harmonic-installer
$(eval $(call check_packages_deps,cloud-image-utils ovmf libnbd0 nbdfuse nbdkit fuse2fs,cloud-image-utils ovmf libnbd0 nbdfuse nbdkit fuse2fs ))

seeds.iso: user-data meta-data
	cloud-localds $@ $^

OVMF_VARS.fd: /usr/share/OVMF/OVMF_VARS.fd
	cp -v $< $@

lint:
	packer validate .
	packer fmt -check -diff .

format:
	packer fmt .


harmonic-installer: check-deps clean seeds.iso OVMF_VARS.fd
	${PACKER} init . \
	&& ${PACKER} build \
		-var ubuntu_series=${SERIES} \
		-var timeout=${TIMEOUT} \
		-var packer_log=${PACKER_LOG} \
		.

clean:
	${RM} -rf output-* harmonic-installer*.gz packer-cache/* seeds.iso OVMF_VARS.fd manifest.json

.INTERMEDIATE: OVMF_VARS.fd seeds.iso
