#!/bin/bash
##############################################################################
#
#   ephemera-deploy-command.sh <hostname> <user-data file>
#
#   This script will deploy Harmony cOS using a MAAS 'Ephemeral Install'.
#
#   An Ephemeral Install uses the default 'Deploy Image' (Ex: Ubuntu 22.04)
#   to execute the provided cloud-init 'user_data' configuration.
#
#   In most cases, the 'Deploy Image' is booted in memory, and installs the
#   corresponding filesystem and kernel, and any customizations provided via
#   user_data are performed on the installed OS.
#
#   This script operates similarly by booting the 'Deploy Imnage' in memory.
#   However, instead of bootstrapping a selected OS, we execute commands
#   VERY EARLY in the boot process that download and run a custom
#   installer script.
#
#   The user_data commands perform the following steps:
#
#   1. Download the 'harmonic-installer.sh script from the MAAS webserver to
#   /media/root-rw/harmonic-installer.sh
#   2. Execute the harmonic-installer.sh script
#
#   The harmonic-installer.sh script will then perform the following steps:
#
#   1. Download and install the ostree-production .deb packages from the
#   MAAS webserver.
#   2. Download the latest Apollo (Harmony cOS) .iso from the MAAS webserver.
#   3. Create a /data directory and move the Apollo .iso into it.
#   4. Run the 'ostree-production' commands to display and write the .iso
#   to the system's physical disk (/dev/sda)
#   5. Reboot the system to /dev/sda
#
#   The system will reboot into Harmony cOS
#
##############################################################################
# shellcheck disable=SC2034
# shellcheck disable=SC2312

maasHostname="maas-poc-aio01"
if [[ $# -eq 0 ]]; then
	echo "Usage: $0 <hostname> <user-data filepath>"
	exit 0
  fi

if [[ -n $1 ]]; then
  export hostName=$1
  else
  read -rp 'Enter the MAAS Host-Name of the system to deploy. :  ' readHost
  export hostName=${readHost}
  fi

[[ "${hostName}" =~ ^[[:alnum:]|-]+$ ]] || (echo "Bad Hostname" && exit 1)

if [[ -n $2 ]]; then
  userDataFile=$2
  else
  read -rp 'Enter path to 'user-data' configuration file. : ' readUserDataFile
    export userDataFile=${readUserDataFile}
  fi


if [[ -f "${userDataFile}" ]]; then
  userDataFileB64=$(base64 "${userDataFile}" | tr -d '\n')
  else
  unset userDataFile
  fi

ssh maas -C maas admin machines read > /tmp/maasHostList

maasSystemID=$(jq -r --arg maasHost "${hostName}" '.[]|select(.hostname==$maasHost)|.system_id' /tmp/maasHostList)

cat <<EOF

======================================================================================================

Deploying Harmonic cOS via MAAS 'Ephemeral Deploy'

Hostname:               ${hostName}
System ID:              ${maasSystemID}
$([[ -n "${userDataFile}" ]] && echo "Cloud-Init Data File:   ${userDataFile}")

Deploy Command:
  maas admin machine deploy "${maasSystemID}" ephemeral_deploy="true" \
$([[ -n "${userDataFile}" ]] && echo user_data=\""${userDataFileB64}"\")

=======================================================================================================

EOF

read -rp "Press [Enter/Return] to deploy this configuration : ";echo

if [[ "$(hostname)" != "${maasHostname}" ]]; then
  ssh maas -C maas admin machine deploy "${maasSystemID}" ephemeral_deploy="true" $([[ -n "${userDataFile}" ]] && echo user_data="${userDataFileB64}")
else
  maas admin machine deploy "${maasSystemID}" ephemeral_deploy="true" $([[ -n "${userDataFile}" ]] && echo user_data="${userDataFileB64}")
fi