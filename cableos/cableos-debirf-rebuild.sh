#!/bin/bash
###########################################################################################################################
###
### Harmonic VCMTS/CableOS Live-Image Customization/Repackage Script
###
### Repackage Harmonic Installer Debirf LiveImage with resources needed to kick off unattended CableOS install.
### This image must be further customized via the Packer-MaaS build process.
### Custom configurations for this can be found in the MAAS-ANSIBLE git repository at:
### gitrepo:///MAAS-Ansible/packer-maas/cableos Packer-MaaS 'cableos'
###
### Author: Alan Janis
### Email: c-alan.janis@charter.com
### Original image installation and rootfs extraction instructions provided by Oscar Alias Bobadilla
###
###########################################################################################################################


# Variables and Defaults

requiredPkgs=("genisoimage" "mkisofs" "makefs" "mkinitramfs" "livecd-rootfs" "fakeroot" "live-build")
: "${USERDATA:=/opt/userdata}"
: "${APOLLO_ISO:=APOLLO_PLATFORM-release-3.21.3.0-7+auto15.iso}"
: "${INSTALL_SCRIPT:=cableos-installer.sh}"
: "${ELTORITO:=stage2_eltorito}"
: "${LIVEIMG_URL:=https://gemmei.ftp.acc.umu.se/debian-cd/current/amd64/iso-cd/debian-12.5.0-amd64-netinst.iso}"
: "${LIVEIMG_ISO:=$(basename $LIVEIMG_URL)}"
: "${DEBIRF_ISO:=debirf-live_bullseye_6.0.0-0.deb11.6-amd64.iso}"
: "${WORKDIR:=${HOME}/cableos-live}"
: "${LIVEFS_DIR:=${WORKDIR}/${DEBIRF_ISO%.*}}"
: "${ROOTFS_DIR:=${LIVEFS_DIR}/rootfs}"

sudo apt-get -y install "${!requiredPkgs[@]}"

# Create a working directory.
# Unpack debirf minimal.tgz into working directory
# Mount the .iso file at /mnt .
# Copy the contents at /mnt/* to the newly created working directory.
# Unmount the .iso from /mnt .
# Change directories to the newly created working directory

mkdir "${WORKDIR}"
mount -o loop "${USERDATA}/${DEBIRF_ISO}" /mnt
cp -r /mnt/* "${WORKDIR}/"
umount /mnt
cd "${WORKDIR}"


# Subshell Process
# Create the target folder for the live filesystem.
# Change directories to the previously created livefs directory.
# Extract the filesystem archive using zcat to read the contents of the .cgz file and pipe the output to cpio to extract them.
# Remove the .cgz file

(mkdir "${LIVEFS_DIR}" && cd "${LIVEFS_DIR}" && zcat "${WORKDIR}/${DEBIRF_ISO%.*}.cgz" | cpio -idvm && rm -f "${WORKDIR}/${DEBIRF_ISO%.*}.cgz")

# Subshell Process
# Create a target folder for rootfs.
# Change directories to the previously created rootfs folder.
# Extract the rootfs using xzcat to read the contents of the .cxz file and pipe the output to cpio to extract them.
# Remove the .cxz file

(mkdir "${ROOTFS_DIR}" && cd "${ROOTFS_DIR}/" && xzcat "${LIVEFS_DIR}/rootfs.cxz" | cpio -idvm && rm -f "${LIVEFS_DIR}/rootfs.cxz")

# Here we are delaring an array of of files that will be copied into the rootfs directory with the following structure:

#   `key`: /path/to/source/file.ext
#   `value`: /path/to/rootfs/destination/dir/
# The script below performs the following checks and actions.
# For each file in the array :
# # Check that the destination directory is not present
#    AND
#   - Create the destination directory
# # Check that the source file exists
#   AND
# # (The destination file does not ) OR The source and destination files are not identical)
#   AND
#   - Copy the source file to the destination directory

declare -A filePaths
FILE1="${USERDATA}/${APOLLO_ISO}"
FILE2="${USERDATA}/${INSTALL_SCRIPT}"
FILE3="${USERDATA}/${ELTORITO}"
filePaths[$FILE1]="${ROOTFS_DIR}/data"
filePaths[$FILE2]="${ROOTFS_DIR}/root"

for fileName in "${!filePaths[@]}"; do

    [[ ! -d "${filePaths[${fileName}]}" ]] \
    && echo -e "
    ${filePaths[${fileName}]} does not exist.
    mkdir -p ${filePaths[${fileName}]}
    " \
    && mkdir -p "${filePaths[${fileName}]}"

    [[ -e ${fileName} ]] && ([[ ! -e "${filePaths[${fileName}]}/$(basename ${fileName})" ]] || ! ( diff -q "${fileName}" "${filePaths[${fileName}]}/$(basename ${fileName})" )) \
    && echo -e "
    cp ${fileName} ${filePaths[${fileName}]}/ \
    " \
    && cp "${fileName}" "${filePaths[${fileName}]}/"
done

# Recreate the .cpio archive.
# Compress it back to .cxz archive

( cd "${ROOTFS_DIR}" && find . | cpio -o -H newc | xz -z -T0 > "${LIVEFS_DIR}/rootfs.cxz" && rm -rf "${ROOTFS_DIR}" )

# Recreate the .cpio archive.
# Compress it back to .cgz archive.

( cd "${LIVEFS_DIR}" && find . | cpio -o -H newc | gzip -6 > "${WORKDIR}/${DEBIRF_ISO%.*}.cgz" && rm -rf "${LIVEFS_DIR}" )

# Rebuild the .iso image from the updated working directory contents
# If successful, print image and md5sum
# If unsuccessful, print error notice and remove failed image

( mkisofs -R -b boot/grub/bios.img -no-emul-boot -boot-load-size 4 -boot-info-table -c boot/grub/boot.cat -input-charset utf-8 -o "${USERDATA}/REPACK-${DEBIRF_ISO}" ) \
&& ( echo -e "
ISO Repack Completed Successfully.
New Image: ${USERDATA}/REPACK-${DEBIRF_ISO}
" \
&& md5sum ${USERDATA}/REPACK-${DEBIRF_ISO} | tee -a ${USERDATA}/REPACK-${DEBIRF_ISO}.md5sum ) \
|| ( echo -e "
ISO Repack Failed... Removing..
" && rm -f ${USERDATA}/REPACK-${DEBIRF_ISO} )
