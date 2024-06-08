#!/usr/bin/make -f

include ../scripts/check.mk

PACKER ?= packer
PACKER_LOG ?= 1
export PACKER_LOG
SERIES ?= jammy
TIMEOUT ?= 1h
CUSTOMIZE_SCRIPT ?= /dev/null
URL ?= http://releases.ubuntu.com
ISO=$(shell wget -O- -q ${URL}/${SERIES}/${SUMS} | grep live-server | cut -d'*' -f2)

.PHONY: all clean

all: harmonic-installer
$(eval $(call check_packages_deps,cloud-image-utils ovmf libnbd0 nbdfuse nbdkit fuse2fs,cloud-image-utils ovmf libnbd0 nbdfuse nbdkit fuse2fs ))

harmonic-seeds.iso: user-data meta-data
	cloud-localds $@ $^

harmonic-seeds-live.iso: user-data-live meta-data
	cloud-localds $@ $^

OVMF_VARS.fd: /usr/share/OVMF/OVMF_VARS.fd
	cp -v $< $@

lint:
	packer validate .
	packer fmt -check -diff .

format:
	packer fmt .

harmonic-installer: check-deps clean harmonic-seeds.iso OVMF_VARS.fd
	${PACKER} init . \
	&& ${PACKER} build -except=*harmonic-live* \
		-var ubuntu_series=${SERIES} \
		-var timeout=${TIMEOUT} \
		.

harmonic-installer-live: check-deps clean harmonic-seeds-live.iso OVMF_VARS.fd
	${PACKER} init . \
	&& ${PACKER} build -only=*harmonic-live* \
		-var ubuntu_series=${SERIES} \
		-var timeout=${TIMEOUT} \
	  -var ubuntu_iso=${ISO} \
		.

clean:
	${RM} -rf output-* harmonic-*.gz harmonic-seeds.iso harmonic-seeds-live.iso OVMF_VARS.fd manifest.json

.INTERMEDIATE: OVMF_VARS.fd \
	harmonic-seeds-live.iso harmonic-seeds.iso
