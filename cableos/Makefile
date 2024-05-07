#!/usr/bin/make -f

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

debirf.tar.gz: check-deps clean
  # ${PACKER} build template.json
	${PACKER} init . cableos.pkr.hcl && ${PACKER} build -var timeout=${TIMEOUT} cableos.pkr.hcl



cableos.tar.gz: check-deps clean
  # ${PACKER} build template.json
	${PACKER} init . debirf.pkr.hcl && ${PACKER} build -var timeout=${TIMEOUT} debirf.pkr.hcl


clean:
	${RM} -rf output-cableos cableos.tar.gz output-debirf debirf.tar.gz
