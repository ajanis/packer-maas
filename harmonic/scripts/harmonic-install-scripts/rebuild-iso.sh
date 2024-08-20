#!/bin/bash
##############################################################################
#
#   rebuild-iso.sh
#
#   This script is executed by a user to rebuild the Apollo ISO using
#   a modified squashfs root filesystem.
#
##############################################################################

export buildTemp="${PWD}/buildtmp"
export newSquashfs="${buildTemp}/rootfs.squashfs"
export chrootMounts=("proc" "sys" "dev")
export buildLog="${PWD}/harmonic-iso.log"

runPrint() {
cat << EOF
===========================================================
  $@
===========================================================
EOF
}

# Script Help Function
showHelp() {
cat << EOH
Usage: $0 [-c <chroot directory>] [-r <rootfs source directory> ] [-i <Original Unmodified ISO>] [-h]

Rebuild Apollo ISO

-c|     Setup Chroot Environment in provided directory path

-r|     Use provided rootfs directory to create new  rootfs.squashfs squashfile

-i|     Create a modified ISO file from the original ISO and the modified rootfs.squashfs squashfile.

-h|     Display help

EOH
}



function setupChroot() {
  for mount in "${chrootMounts[@]}"; do
    runPrint "Bind mounting /${mount} at ${chrootPath}/${mount}"
    mount --bind "/${mount}" "${chrootPath}/${mount}"
    done
  return
}

function cleanupChroot() {
  for mount in "${chrootMounts[@]}"; do
    runPrint "Unmounting ${chrootPath}/${mount}"
    umount "${chrootPath}/${mount}"
    done
    return
}

function resquashRootfs() {
  if [[ ! -d ${rootfsSourcePath} ]]; then 
  runPrint "No root source found!!"
  exit 1
  fi
  runPrint "Creating new squashfs at ${newSquashfs} from ${rootfsSourcePath} ..."
  mksquashfs "${rootfsSourcePath}" "${newSquashfs}" -noappend
  return
}

function rebuildIso() {
  if [[ ! -f ${originalIsoPath} ]]; then
  runPrint "No source iso found!!"
  exit 1
  fi
  if [[ ! -f ${newSquashfs} ]]; then
  runPrint "No squashFS found!!"
  exit 1
  fi

  export newIso="${buildTemp}/${isoFile}"
  xorriso -overwrite on -indev "${originalIsoPath}" -outdev "${newIso}" -pathspecs on -add rootfs.squashfs="${newSquashfs}"
  return
}


while getopts ":hc:r:i:" o; do
    case "${o}" in
        h)
            showHelp
            exit 0
            ;;
        c)
            chrootPath=${OPTARG}
            export doChroot=1
            ;;
        r)
            rootfsSourcePath=${OPTARG}
            export doBuildRootfs=1
            ;;
        i)
            originalIsoPath=${OPTARG}
            isoFile=$(basename "${originalIsoPath}")
            export doBuildIso=1
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



# Main Runners

if [[ ${doChroot} == 1 ]]; then
  # shellcheck disable=SC2312
  setupChroot  >(tee -a "${buildLog}" >&2) > >(tee -a "${buildLog}")
  trap cleanupChroot EXIT
  chroot "${chrootPath}"
fi

if [[ "${doBuildRootfs}" == 1 ]]; then
  # shellcheck disable=SC2312
  resquashRootfs >(tee -a  "${buildLog}" >&2) > >(tee -a  "${buildLog}")
fi

if [[ "${doBuildIso}" == 1 ]]; then
  # shellcheck disable=SC2312
  rebuildIso >(tee -a "${buildLog}">&2) > >(tee -a "${buildLog}")

cat <<EOF

=====================================================================================
                          Build Complete!

Generated ${newIso} from ${originalIsoPath} and ${newSquashfs}
        Activity log can be viewed at ${buildLog} ...

Would you like to deploy this new image to /opt/userdata/apollo/${isoFile} ?

            (Note: Soon this will be deployed to artifactory)

======================================================================================

EOF

read -rp "Press [Enter/Return] to deploy new ISO : ";echo
mv "${newIso}" "/opt/userdata/apollo/${isoFile}"

fi

