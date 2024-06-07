#!/usr/bin/make -f

include ../scripts/check.mk

PACKER ?= packer
PACKER_LOG ?= 1
export PACKER_LOG
SERIES ?= jammy
ARCH ?= amd64
URL ?= http://releases.ubuntu.com
SUMS ?= SHA256SUMS
TIMEOUT ?= 1h
CUSTOMIZE_SCRIPT ?= /dev/null


ISO=$(shell wget -O- -q ${URL}/${SERIES}/${SUMS} | grep live-server | cut -d'*' -f2)

.PHONY: all clean

all: cableos-installer
$(eval $(call check_packages_deps,cloud-image-utils ovmf libnbd0 nbdfuse nbdkit fuse2fs,cloud-image-utils ovmf libnbd0 nbdfuse nbdkit fuse2fs ))

lint:
	packer validate .
	packer fmt -check -diff .

format:
	packer fmt .

cableos-installer: check-deps clean
	${PACKER} init . && ${PACKER} build \
		-var architecture=${ARCH} \
		-var ubuntu_series=${SERIES} \
		-var timeout=${TIMEOUT} -var customize_script=${CUSTOMIZE_SCRIPT} .

clean:
	${RM} -rf output-* cableos-*.gz seeds-cableos.iso OVMF_VARS.fd
