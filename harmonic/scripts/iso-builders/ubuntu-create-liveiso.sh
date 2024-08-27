#!/bin/bash

# Variables
# ISO_URL="https://releases.ubuntu.com/20.04/ubuntu-20.04-desktop-amd64.iso"
ISO_NAME="$1"
WORK_DIR="/opt/live-image-build/ubuntu-iso"
MOUNT_DIR="/opt/live-image-build/ubuntu-iso.mount"

# Download Ubuntu ISO
# wget $ISO_URL -O $ISO_NAME

# Install required tools
sudo apt update
sudo apt install -y xorriso squashfs-tools genisoimage

# Mount the ISO
mkdir -p $MOUNT_DIR
sudo mount -o loop $ISO_NAME $MOUNT_DIR

# Copy ISO contents
mkdir -p $WORK_DIR
rsync -a $MOUNT_DIR/ $WORK_DIR/
sudo umount $MOUNT_DIR

# Make filesystem writable
chmod -R u+w $WORK_DIR

cat << 'EOG' >> "${WORK_DIR}/boot/grub/grub.cfg"
menuentry "Ubuntu 22.04 Live-Only" {
   rmmod tpm
   linux /casper/vmlinuz boot=casper iso-scan/filename=${iso_path} noprompt noeject nopersistent maybe-ubiquity nomodeset quiet splash fsck.mode=skip toram
   initrd /casper/initrd
}
EOG

cat << 'EOI' >> "${WORK_DIR}/isolinux/txt.cfg"
label ubuntu2204live
  menu label ^Ubuntu 22.04 Live-Only
  kernel /casper/vmlinuz
  append   initrd=/casper/initrd quiet noprompt noeject nopersistent maybe-ubiquity nomodeset quiet splash fsck.mode=skip toram ---

EOI

# Repack the ISO
cd "${WORK_DIR}" || exit
sudo xorriso -as mkisofs \
    -r -V "Ubuntu Custom" \
    -o /opt/live-image-build/custom-ubuntu.iso \
    -J -l -b isolinux/isolinux.bin \
    -c isolinux/boot.cat -no-emul-boot \
    -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot -e boot/grub/efi.img \
    -no-emul-boot -isohybrid-gpt-basdat \
    .

echo "Custom ISO created at /opt/live-image-build/custom-ubuntu.iso"