#!/usr/bin/make -f

include ../scripts/check.mk

PACKER ?= packer
PACKER_LOG ?= 0
export PACKER_LOG

SERIES ?= bullseye
BOOT ?= uefi
ARCH ?= amd64
TIMEOUT ?= 1h

ifeq ($(strip $(SERIES)),buster)
	VERSION = 10
else ifeq ($(strip $(SERIES)),bullseye)
	VERSION = 11
else ifeq ($(strip $(SERIES)),bookworm)
	VERSION = 12
else
	VERSION = 11
endif

# Safeguard
ifeq ($(strip $(ARCH)),arm64)
	boot = uefi
endif

.PHONY: all clean

all: cableos

$(eval $(call check_packages_deps,cloud-image-utils ovmf,cloud-image-utils ovmf))

lint:
	packer validate .
	packer fmt -check -diff .

format:
	packer fmt .

OVMF_VARS.fd: /usr/share/OVMF/OVMF_VARS.fd
	cp -v $< $@

debian: check-deps clean
	${PACKER} init . && ${PACKER} build \
		-var debian_series=${SERIES} \
		-var debian_version=${VERSION} \
		-var architecture=${ARCH} \
		-var boot_mode=${BOOT} \
		-var timeout=${TIMEOUT} .

clean:
	${RM} -rf output-* debian-custom-*.gz \
		seeds-cloudimg.iso \
		OVMF_VARS.fd \
		AAVMF_VARS.fd

CUSTOM_PKGS:=${wildcard packages/*.deb}

packages/custom-packages.tar.gz: ${CUSTOM_PKGS}
ifeq ($(strip $(CUSTOM_PKGS)),)
	tar czf $@ -C packages -T /dev/null
else
	tar czf $@ -C packages ${notdir $^}
endif

.INTERMEDIATE: OVMF_VARS.fd packages/custom-packages.tar.gz \
	seeds-cloudimg.iso

include ../scripts/check.mk

PACKER ?= packer
PACKER_LOG ?= 0
TIMEOUT ?= 1h
RM ?= RM
SERIES ?= jammy
ARCH ?= amd64
URL ?= http://releases.ubuntu.com
SUMS ?= SHA256SUMS
TIMEOUT ?= 1h
export PACKER_LOG

.PHONY: all clean

all: cableos.tar.gz
$(eval $(call check_packages_deps))

deps: check-deps clean
	${PACKER} init . deps.pkr.hcl && ${PACKER} build -var timeout=${TIMEOUT} deps.pkr.hcl

debirf.tar.gz: check-deps clean
  # ${PACKER} build template.json
	${PACKER} init . cableos.pkr.hcl && ${PACKER} build -var timeout=${TIMEOUT} cableos.pkr.hcl



cableos.tar.gz: check-deps clean
  # ${PACKER} build template.json
	${PACKER} init . debirf.pkr.hcl && ${PACKER} build -var timeout=${TIMEOUT} debirf.pkr.hcl


clean:
	${RM} -rf output-cableos cableos.tar.gz output-debirf debirf.tar.gz
