#!/bin/bash
##############################################################################
#
#   rebuild-iso.sh
#
#   This script is executed by a user to rebuild the Apollo ISO using
#   a modified squashfs root filesystem.
#
##############################################################################
export buildRoot="/opt/harmonic-image-build"
export isoMount="${buildRoot}/iso.mount"
export chrootPath="${buildRoot}/squashfs-root"
export buildDirs=("buildtmp" "iso.mount" "squashfs-root")
export buildTemp="${buildRoot}/buildtmp"
export newSquashfs="${buildTemp}/rootfs.squashfs"
export chrootMounts=("sys" "dev")
export buildLog="${buildRoot}/harmonic-iso.log"
export artifactoryURL="https://artifactory.charterlab.com"
export artifactoryPath="artifactory/upload/harmonic"

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
Usage: $0 -i <source iso> [-x -c -r -b -d] [-h] 

Rebuild Apollo ISO

-i <path to source iso> | 
        Create working directories
        Mount source iso and extract rootfs.squashfs

-x |    Extract rootfs from original ISO image

-c |    Customize rootfs in chroot environment

-r |    Generate new root.squashfs from modified rootfs files

-b |    Build new iso image from source image and new rootfs.squashfs

-d |    Deploy iso to Artifactory

-h |    Display help

EOH

}


function createWorkspace() {
  for dir in "${buildDirs[@]}"; do
    if [[ ! -d "${buildRoot}/${dir}" ]]; then
      runPrint "Creating ${buildRoot}/${dir}"
      mkdir -p "${buildRoot}/${dir}"
      fi
    done
  return
}


function extractRootfs() {
  
  runPrint "Mounting ${originalIsoPath} at ${isoMount}"
  mount -o loop "${originalIsoPath}" "${isoMount}"

  runPrint "Removing old ${chrootPath}"
  rm -rf squashfs-root

  runPrint "Extract ${isoMount}/rootfs.squashfs to ${chrootPath}"
  unsquashfs -d "${chrootPath}" "${isoMount}/rootfs.squashfs"

  umount -f "${isoMount}"

}


function setupChroot() {

  for mount in "${chrootMounts[@]}"; do
    runPrint "Bind mounting /${mount} at ${chrootPath}/${mount}"
    mount --bind "/${mount}" "${chrootPath}/${mount}"
    done

  runPrint "Mounting /proc at ${chrootPath}/proc"
  mount -t proc /proc "${chrootPath}/proc"

  return
}


function cleanupChroot() {
  
  for mount in "${chrootMounts[@]}"; do
    runPrint "Unmounting ${chrootPath}/${mount}"
    umount "${chrootPath}/${mount}"
    done
  
  runPrint "Unmounting ${chrootPath}/proc"
  umount "${chrootPath}/proc"

  return
}

function resquashRootfs() {
  
  if [[ ! -d ${chrootPath} ]]; then 
    runPrint "No root source found!!"
    exit 1
    fi
  
  rm -f "${newSquashfs}"
  
  runPrint "Creating new squashfs at ${newSquashfs} from ${chrootPath} ..."

  mksquashfs "${chrootPath}" "${newSquashfs}" -noappend

  return
}

function buildIso() {

  if [[ ! -f ${newSquashfs} ]]; then
    runPrint "No squashFS found!!"
    return 1
    fi
  export newIso="${buildTemp}/${isoFile}"
  rm -f "${newIso}"
  xorriso -overwrite on -indev "${originalIsoPath}" -outdev "${newIso}" -pathspecs on -add rootfs.squashfs="${newSquashfs}"
  return
}

function deployIso() {

  export newIso="${buildTemp}/${isoFile}"
  
  if [[ ! -f ${newIso} ]]; then
    runPrint "No ISO found at ${newIso} to deploy !!"
    return 1
    fi

cat <<EOD

=====================================================================================

Would you like to deploy ${newIso} to Artifactory?

(You will be prompted for your JFrog username and password)

======================================================================================

EOD

read -rp "Press [Enter/Return] to deploy new ISO : ";echo || return 1
read -r -p "Enter Jfrog Username : " artifactUser || return 1 
read -s -p "Enter JFrog Password : " artifactPassword || return 1

curl -u "${artifactUser}:${artifactPassword}" -T "${newIso}" "${artifactoryURL}/${artifactoryPath}/apollo/${isoFile}" || return 1

return
}

while getopts ":hxcrbdi:" o; do
    case "${o}" in
        h)
            showHelp
            exit 0
            ;;
        i)
            originalIsoPath=${OPTARG}
            isoFile=$(basename "${originalIsoPath}")
            if [[ ! -f ${originalIsoPath} ]]; then
              runPrint "No source iso found at ${originalIsoPath} !!"
              fi
            ;;
        x)
            export doSetup=1
            ;;
        c)
            export doChroot=1
            ;;
        r)
            export doBuildRootfs=1
            ;;
        b)
            export doBuildIso=1
            ;;
        d)
            export doDeployIso=1
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

createWorkspace

if [[ ${doSetup} == 1 ]]; then
  # shellcheck disable=SC2312
  extractRootfs  >(tee -a "${buildLog}" >&2) > >(tee -a "${buildLog}")
fi

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
  buildIso >(tee -a "${buildLog}">&2) > >(tee -a "${buildLog}")

cat <<EOB
=====================================================================================
Build Complete!

Generated ${newIso} from:

iso: ${originalIsoPath}
squashfs: ${newSquashfs}
        
Activity log can be viewed at ${buildLog} ...

======================================================================================
EOB

fi

if [[ "${doDeployIso}" == 1 ]]; then
  # shellcheck disable=SC2312
  deployIso >(tee -a "${buildLog}">&2) > >(tee -a "${buildLog}")
  # shellcheck disable=SC2181
  if [[ $? == 0 ]]; then
    echo -e "\n\nDone!\n\n"
    else
    echo -e "\n\nFailed - Check ${buildLog}\n\n"

    fi
fi


