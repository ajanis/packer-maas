#!/bin/bash

set -e

# Function to check for required tools
check_tools() {
    for tool in xorriso grub-mkstandalone; do
        if ! command -v $tool &> /dev/null; then
            echo "Error: $tool is not installed. Please install it and try again."
            exit 1
        fi
    done
}

# Function to prepare the directory structure
prepare_directories() {
    mkdir -p iso/boot/grub
    mkdir -p iso/boot/{kernel,initrd}
    echo "Directory structure prepared."
}

# Function to copy kernel and initrd
copy_kernel_initrd() {
    cp "$1" iso/boot/kernel/vmlinuz
    cp "$2" iso/boot/initrd/initrd.img
    echo "Kernel and initrd copied."
}

# Function to copy squashfs file
copy_squashfs() {
    cp "$1" iso/boot/
    echo "Squashfs file copied."
}

# Function to create grub.cfg
create_grub_cfg() {
    cat <<EOF > iso/boot/grub/grub.cfg
set timeout=10
set default=0

menuentry "Custom Linux" {
    linux /boot/kernel/vmlinuz boot=live toram
    initrd /boot/initrd/initrd.img
}
EOF
    echo "grub.cfg created."
}

# Function to create EFI directory structure
create_efi_structure() {
    mkdir -p iso/EFI/BOOT
    cp /usr/lib/grub/x86_64-efi/{bootx64.efi,grubx64.efi} iso/EFI/BOOT/
    echo "EFI structure created."
}

# Function to create the ISO
create_iso() {
    xorriso -as mkisofs \
        -iso-level 3 \
        -o bootable-uefi.iso \
        -full-iso9660-filenames \
        -volid "CustomISO" \
        -eltorito-alt-boot \
        -e EFI/BOOT/bootx64.efi \
        -no-emul-boot \
        -isohybrid-gpt-basdat \
        -isohybrid-apm-hfsplus \
        -partition_cyl_align on \
        -partition_offset 16 \
        -append_partition 2 0xef iso/EFI/BOOT/bootx64.efi \
        -c boot.cat \
        -b boot/grub/i386-pc/eltorito.img \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        iso
    echo "Bootable ISO created."
}

# Main script execution
main() {
    if [ "$#" -ne 3 ]; then
        echo "Usage: $0 <path_to_kernel> <path_to_initrd> <path_to_squashfs>"
        exit 1
    fi

    check_tools
    prepare_directories
    copy_kernel_initrd "$1" "$2"
    copy_squashfs "$3"
    create_grub_cfg
    create_efi_structure
    create_iso

    echo "Bootable ISO creation completed successfully."
}

main "$@"
