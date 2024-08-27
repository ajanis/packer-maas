#!/bin/bash
##############################################################################
#
#   apollo-customize-and-rebuild.sh
#
#   This script is executed by a user to rebuild the Apollo ISO using
#   a modified squashfs root filesystem.
#
##############################################################################
# shellcheck disable=SC2155
export buildRoot="$(realpath .)"
export isoMount="${buildRoot}/iso.mount"
export chrootPath="${buildRoot}/filesystem.tmp"
export buildDirs=("build.tmp" "iso.mount" "filesystem.tmp" "iso.tmp")
export buildTemp="${buildRoot}/build.tmp"
export isoTemp="${buildRoot}/iso.tmp"
export bindMounts=("run" "dev")
export chrootMounts=('chrootArray["proc"]="/proc"' 'chrootArray["sysfs"]="/sys"' 'chrootArray["devpts"]="/dev/pts"')
export buildLog="${buildRoot}/harmonic-iso.log"
export artifactoryURL="https://artifactory.charterlab.com"
export artifactoryPath="artifactory/upload/harmonic"
declare -A chrootArray
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
Usage: $0 -i <source iso> -f <squashfs path in source iso | default('/rootfs.squashfs')> [-x -c -r -b -d] [-h]

Rebuild Apollo ISO

-i | [REQUIRED] <path to source iso> | ISO image to rebuild (will be used as source and destination filenames)

-f | [REQUIRED] <path to squashfs in source iso> | Path to SquashFS archive in source ISO (used for Chroot customizations)

-x |    Extract squashfs filesystem from original ISO image

-c |    Customize filesystem in chroot environment

-r |    Generate new squashfs from modified filesystem

-b |    Build new iso image from source image and new squashfs

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
function mountIso() {
  if mountpoint "${isoMount}"; then
    runPrint "Unmounting ${isoMount}"
    umount -lf "${isoMount}"
    fi

  runPrint "Mounting ${originalIsoPath} at ${isoMount}"
  mount -o loop "${originalIsoPath}" "${isoMount}"
  return
}


function extractRootfs() {
  if [[ ! -f "${isoMount}/${squashfsIsoPath}" ]]; then
    runPrint "No SquashFS Archive found at ${isoMount}/${squashfsIsoPath}!!"
    runPrint "Leaving ${isoMount} mounted for debugging"
    exit 1
    fi
  
  if [[ -d "${chrootPath}" ]]; then
  runPrint "Removing old files from ${chrootPath}"
  rm -rf "${chrootPath}"
  fi

  runPrint "Extract ${isoMount}/${squashfsIsoPath} to ${chrootPath}"
  unsquashfs -d "${chrootPath}" "${isoMount}/${squashfsIsoPath}"
  return
}
function extractIso() {
  runPrint "Extract ${isoMount} to ${isoTemp}"
  if [[ -d "${isoTemp}" ]]; then
    runPrint "Removing old files from ${isoTemp}"
    rm -rf "${isoTemp:?}/*"
    fi
  rsync -avp "${isoMount}/" "${isoTemp}/"
  return
}

function setupChroot() {

  for bmount in "${bindMounts[@]}"; do
    runPrint "Bind mounting /${bmount} at ${chrootPath}/${bmount}"
    mount --bind "/${bmount}" "${chrootPath}/${bmount}"
    done

  for arraymount in "${chrootMounts[@]}"; do
    eval "${arraymount}"
    done

  runPrint "${!chrootArray[@]}"
  for cmount in "${!chrootArray[@]}"; do
    runPrint "Mounting ${cmount} at ${chrootPath}${chrootArray[${cmount}]}"
    mount -t "${cmount}" none "${chrootPath}${chrootArray[${cmount}]}"
    done

  return
}

function cleanupChroot() {

  for cmount in "${!chrootArray[@]}"; do
    runPrint "Unounting ${cmount} at ${chrootArray[${cmount}]}"
    umount "${chrootPath}${chrootArray[${cmount}]}"
    done

  for bmount in "${bindMounts[@]}"; do
    runPrint "Unmounting bindmount ${bmount} at ${chrootPath}/${bmount}"
    umount "${chrootPath}/${bmount}"
    done

  return
}

function resquashRootfs() {

  if [[ ! -d ${chrootPath} ]]; then
    runPrint "No root source found!!"
    exit 1
    fi

  if [[ -e "${newSquashfs}" ]]; then
    runPrint "Removing old squashfile at ${newSquashfs}"
    rm -f "${newSquashfs}"
    fi

  runPrint "Creating new squashfs at ${newSquashfs} from ${chrootPath} ..."
  mksquashfs "${chrootPath}" "${newSquashfs}" -noappend

  return
}

function updateIsoFiles() {
  runPrint "Updating ${isoTemp}/boot/grub/grub.cfg"

  cat << 'EOG' > "${isoTemp}/boot/grub/grub.cfg"
if loadfont /boot/grub/font.pf2 ; then
	set gfxmode=auto
	insmod efi_gop
	insmod efi_uga
	insmod gfxterm
	terminal_output gfxterm
fi

set menu_color_normal=white/black
set menu_color_highlight=black/light-gray

set timeout=5
menuentry "Ubuntu 20.04 Live-Only" {
   rmmod tpm
   linux /casper/vmlinuz boot=casper iso-scan/filename=${iso_path} noprompt noeject nopersistent maybe-ubiquity nomodeset quiet splash fsck.mode=skip toram
   initrd /casper/initrd
}
EOG

  runPrint "Updating ${isoTemp}/isolinux/txt.cfg"

  cat << 'EOI' > "${isoTemp}/isolinux/txt.cfg"
default ubuntu2004live
label ubuntu2004live
  menu label ^Ubuntu 20.04 Live-Only
  kernel /casper/vmlinuz
  append   initrd=/casper/initrd quiet splash fsck.mode=skip toram
EOI

  runPrint "Updating ${isoTemp}/${squashfsIsoPath}"
  cp "${newSquashfs}" "${isoTemp}/${squashfsIsoPath}"
  return
}

function buildIso() {

  if [[ ! -f ${newSquashfs} ]]; then
    runPrint "No squashFS found!!"
    return 1
    fi
  if [[ -e "${newIso}" ]]; then
    runPrint "Removing existing file ${newIso}"
    rm -f "${newIso}"
    fi
  
cat <<EOG

=====================================================================================

!!ATTENTION!!  If you are building a Ubuntu Live Iso, custom grub and isolinux files
will be added in the following step before creating the bootable ISO.

Are you building a Live Iso [y/n] ?

======================================================================================

EOG
  read -r -p "Build Live Iso? [y/n] : " yesno || return 1

  if [[ ${yesno} =~ (y|Y|es?) ]]; then
    extractIso
    updateIsoFiles
    xorriso -as mkisofs \
    -r -V "ubuntu-custom" -J -l -b isolinux/isolinux.bin \
    -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot -e EFI/BOOT/BOOTx64.EFI -no-emul-boot \
    -isohybrid-gpt-basdat -o "${newIso}" "${isoTemp}/."
    else
    xorriso -overwrite on -indev "${originalIsoPath}" -outdev "${newIso}" -pathspecs on -add "${squashfsIsoPath}=${newSquashfs}"
    fi
  umount -f "${isoMount}"
  return
}

function deployIso() {

  if [[ ! -f ${newIso} ]]; then
    runPrint "No ISO found at ${newIso} to deploy !!"
    return 1
    fi

  cat <<EOD

=====================================================================================

Would you like to deploy ${newIso} to Artifactory? [y/n]

(You will be prompted for your JFrog username and password)

======================================================================================
EOD

  read -rp "Press [Enter/Return] to deploy new ISO : ";echo || return 1
  read -r -p "Enter Jfrog Username : " artifactUser || return 1
  # shellcheck disable=SC2162
  read -s -p "Enter JFrog Password : " artifactPassword || return 1

  curl -u "${artifactUser}:${artifactPassword}" -T "${newIso}" "${artifactoryURL}/${artifactoryPath}/apollo/${isoFile}" || return 1

  return
}

while getopts ":hxcrbdi:f:" o; do
    case "${o}" in
        h)
            showHelp
            exit 0
            ;;
        i)
            originalIsoPath=${OPTARG}
            if [[ -z "${originalIsoPath}" ]]; then
              echo "Error: Must define -i <original iso path>"
              exit 1
              fi
            if [[ ! -f ${originalIsoPath} ]]; then
              runPrint "No source iso found at ${originalIsoPath} !!"
              fi
            isoFile=$(basename "${originalIsoPath}")
            newIso="${buildTemp}/${isoFile}"
            ;;
        f)
            squashfsIsoPath=${OPTARG}

            if [[ -z "${squashfsIsoPath}" ]]; then
              echo "Error: Must define -f <squashfs path>"
              exit 1
              fi
            squashfsFilename=$(basename "${squashfsIsoPath}")
            newSquashfs="${buildTemp}/${squashfsFilename}"
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
  mountIso  >(tee -a "${buildLog}" >&2) > >(tee -a "${buildLog}")  
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