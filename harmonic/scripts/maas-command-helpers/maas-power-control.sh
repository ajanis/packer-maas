#!/bin/bash
##############################################################################
#
#   maas-power-control.yml
#
#   Get command line args for BMC control over IPMI
#
##############################################################################
# shellcheck disable=SC2034
# shellcheck disable=SC2312

export sshHost=44.10.4.101
export maasPath="/snap/bin/maas"
maasHostname="maas-poc-aio01"
# Script Help Function
showHelp() {
cat << EOH
Usage: $0 [-h] [-n <hostname> <ipmi command + args>]

Get MAAS host power parameters and run IPMI command

-n | [REQUIRED] <hostname> | The system short hostname as displayed in MAAS

-h |    Display help

EOH

}


function getHostName() {
  read -rp 'Enter the MAAS Host-Name of the system to manage. :  ' readHost
  export hostName=${readHost}
  [[ "${hostName}" =~ ^[[:alnum:]|-]+$ ]] || (echo "Bad Hostname" && showHelp)
}

function setMaasCmd() {
  if [[ "$(hostname -s)" != "${maasHostname}" ]]; then
    export maasCmd="ssh ${sshHost} -C ${maasPath}"
    else
    export maasCmd="${maasPath}"
    fi
}
function getHostId() {
  "${maasCmd}" admin machines read > /tmp/maasHostList
  maasSystemID=$(jq -r --arg maasHost "${hostName}" '.[]|select(.hostname==$maasHost)|.system_id' /tmp/maasHostList)
}

function getCommandArgs() {
ipmitool -I lanplus -U maas -P OoXXStHRb5e -H 2605:1c00:50f2:3303::100c -6 -y a6ff8d5d19792f3e26afc8fe145c4d8e37dc4290 -L ADMINISTRATOR -C3 chassis power status
"${maasCmd}" admin machine power-parameters "${maasSystemId}" > /tmp/powerParams

declare -A powerarray

for powerkey in power_address power_user power_pass k_g privilege_level cipher_suite_id power_driver
do
powerarray[${powerkey}]=$(jq -r --arg key "${powerkey}" 'to_entries[]|select(.key == $key)|.value' /tmp/powerParams)
done
}

function printCommand() {
cat << 'EOC'

=======================================================================================================

Power Command:

ipmitool -H "${powerarray[${power_address}]}" -U "${powerarray[${power_user}]}" -P "${powerarray[${power_pass}]}" -y "${powerarray[${k_g}]}" -L "${powerarray[${privilege_level}]}" -C "${powerarray[${cipher_suite_id}]}" "${ipmiArgs}"

=======================================================================================================

EOC
}

# MENU

while getopts ":hn:" o; do
    case "${o}" in
        h)
            showHelp
            exit 0
            ;;
        n)
            hostName=${OPTARG}
            ;;
        :)
            runPrint "Invalid option: -${OPTARG} requires an argument" 1>&2
            showHelp
            exit 1
            ;;
        \?|*)
            runPrint "Invalid option: -${OPTARG}" 1>&2
            showHelp
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))
ipmiArgs="$*"


# RUN1
getHostName
setMaasCmd
getHostId
getCommandArgs
printCommand

read -rp "Press [Enter/Return] to run this command this configuration : ";echo
ipmitool -H "${powerarray[${power_address}]}" -U "${powerarray[${power_user}]}" -P "${powerarray[${power_pass}]}" -y "${powerarray[${k_g}]}" -L "${powerarray[${privilege_level}]}" -C "${powerarray[${cipher_suite_id}]}" "${ipmiArgs}"



