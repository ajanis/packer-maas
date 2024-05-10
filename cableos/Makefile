
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

all: cableos-installer.qcow2
$(eval $(call check_packages_deps))

cableos-installer.qcow2: check-deps clean
  # ${PACKER} build template.json
	${PACKER} init . build.pkr.hcl && ${PACKER} build -var timeout=${TIMEOUT} build.pkr.hcl

# cableos-installer.tar.gz: check-deps clean
#   # ${PACKER} build template.json
# 	${PACKER} init . build.pkr.hcl && ${PACKER} build -var timeout=${TIMEOUT} build.pkr.hcl

clean:
	${RM} -rf output-images/cableos-installer.qcow2 cableos-installer.tar.gz
