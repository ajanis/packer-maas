
# Custom Debirf Image for CableOS Installation

Use existing custom debirf iso with ostree + a number of d, extract iso, extract debirf-live.cgz, extract roots.cxz , add custom files, repack and recreate custom image with debirf

## Unpack, Customize, Repack Custom LiveImage

### Pregame: Environment setup

```shell
: "${USERDATA:=/opt/userdata}"
: "${APOLLO_ISO:=APOLLO_PLATFORM-release-3.21.3.0-7+auto15.iso}"
: "${INSTALL_SCRIPT:=cableos-installer.sh}"
: "${LIVEIMG_BASENAME:=debirf-live_bullseye_6.0.0-0.deb11.6-amd64}"
: "${WORKDIR:=${HOME}/cableos-live}"
: "${LIVEFS_DIR:=${WORKDIR}/${LIVEIMG_BASENAME}}"
: "${ROOTFS_DIR:=${LIVEFS_DIR}/rootfs}"
: "${DEBIRF_MINIMAL:=/usr/share/doc/debirf/example-profiles/minimal.tgz}"
DEBIRF_CONF_CONTENT='IyBEZWJpcmYgY29uZmlndXJhdGlvbiB0byBiZSBzb3VyY2VkIGJ5IGJhc2gKCiMgTGFiZWwgZm9yIGRlYmlyZiBzeXN0ZW0gKGZvciBob3N0bmFtZSBhbmQgaW5pdHJkKS4gICJkZWJpcmYiIHdpbGwgYmUgdXNlZCBpZiB1bnNwZWNpZmllZC4KREVCSVJGX0xBQkVMPSJjYWJsZW9zLWRlYmlyZiIKIAojIFdoZXJlIHNob3VkIGRlYmlyZiBidWlsZCB0aGUgaW1hZ2U/ICBCeSBkZWZhdWx0LCBkZWJpcmYgd2lsbCBidWlsZCBpbiB0aGUgcHJvZmlsZSBkaXJlY3RvcnkuCiNERUJJUkZfQlVJTEREPQoKIyBXaGF0IHN1aXRlIHNob3VsZCBiZSB1c2VkPyAgVGhlIGRlZmF1bHQgaXMgZGV0ZXJtaW5lZCBieSBsc2JfcmVsZWFzZSwgYW5kIGZhbGxzIGJhY2sgdG8gInNpZCIuCiNERUJJUkZfU1VJVEU9dHJ1c3R5CgojIFRoZSBkZWZhdWx0IGRpc3RybyAoZWcuICJkZWJpYW4iIG9yICJ1YnVudHUiKSBpcyBiYXNlZCBvbiB0aGUgZGlzdHJvIG9mIHRoZSBzdWl0ZSBzcGVjaWZpZWQuICBJZiB5b3Ugd2FudCB0byB1c2UgYSBzdWl0ZSBmcm9tIGEgbm9uLURlYmlhbi9VYnVudHUgZGlzdHJvLCBzcGVjaWZ5IHRoZSBkaXN0cm8gZXhwbGljaXRseSBoZXJlIChhbGwgbG93ZXJjYXNlKS4KI0RFQklSRl9ESVNUUk89dWJ1bnR1CiAKIyBXaGF0IG1pcnJvciBzaG91bGQgZGViaXJmIHB1bGwgdGhlIHN1aXRlIGZyb20/ICBCeSBkZWZhdWx0LCB0aGlzIGlzIGJhc2VkIG9uIHRoZSBERUJJUkZfRElTVFJPIChlZy4gImh0dHA6Ly9taXJyb3JzLmtlcm5lbC5vcmcvJHtERUJJUkZfRElTVFJPfSIpLgojREVCSVJGX01JUlJPUj0KCiMgV2hhdCBrZXlyaW5nIHNob3VsZCBiZSB1c2VkIHRvIHZlcmlmeSB0aGUgZGVib290c3RyYXAgZm9yIHRoZSBzcGVjaWZpZWQgc3VpdGU/IFRoaXMgaXMgYWxzbyBiYXNlZCBvbiB0aGUgREVCSVJGX0RJU1RSTyBieSBkZWZhdWx0LgojIElmIHlvdSBhcmUgdHJ5aW5nIHRvIGJ1aWxkIGEgbm9uLURlYmlhbi9VYnVudHUgdmVyc2lvbiBvZiBkZWJpcmYsIHRoZW4geW91IHdpbGwgbmVlZCB0byBzcGVjaWZ5IHRoZSBrZXlyaW5nIGV4cGxpY2l0bHkgaGVyZSBpZiB5b3Ugd2FudCB0byB2ZXJpZnkgdGhlIGRlYm9vdHN0cmFwLgojIE90aGVyd2lzZSwgdW5jb21tZW50IHRoZSB2YXJpYWJsZSBidXQgbGVhdmUgdGhlIGRlZmluaXRpb24gYmxhbmsgdG8gaGF2ZSBkZWJpcmYgc2tpcCB0aGUgZGVib290c3RyYXAgdmVyaWZpY2F0aW9uLgojREVCSVJGX0tFWVJJTkc9CiAKIyBVc2UgYSB3ZWIgcHJveHkgZm9yIGRvd25sb2FkaW5nIHRoZSBwYWNrYWdlcyAodGhlICJleHBvcnQiIGluIGZyb250IG9mIHRoZSB2YXJpYWJsZSBpcyBuZWNlc3NhcnkgdG8gaGF2ZSBpdCByZWNvZ25pemVkIGJ5IGFsbCBpbnRlcm5hbCBmdW5jdGlvbnMpLgpleHBvcnQgaHR0cF9wcm94eT0naHR0cDovL3Byb3h5NC5zcG9jLmNoYXJ0ZXJsYWIuY29tOjgwODAnCg=='

```

### Step 1: Extract the ISO file
- Create a working directory.
- Unpack debirf minimal.tgz into working directory
- Mount the .iso file at /mnt .
- Copy the contents at /mnt/* to the newly created working directory.
- Unmount the .iso from /mnt .
- Change directories to the newly created working directory

```shell
mkdir "${WORKDIR}"
tar -xzvf "${DEBIRF_MINIMAL}" -C "${WORKDIR}"
mount -o loop "${USERDATA}/${LIVEIMG_BASENAME}.iso" /mnt
cp -r /mnt/* "${WORKDIR}/"
umount /mnt
cd "${WORKDIR}"

```

### Step 2: Extract debirf-live.cgz

- Create the target folder for the live filesystem.
- Change directories to the previously created livefs directory.
- Extract the filesystem archive using zcat to read the contents of the .cgz file and pipe the output to cpio to extract them.
- Remove the .cgz file

```shell
(mkdir "${LIVEFS_DIR}" && cd "${LIVEFS_DIR}" && zcat "${WORKDIR}/${LIVEIMG_BASENAME}.cgz" | cpio -idvm && rm -f "${WORKDIR}/${LIVEIMG_BASENAME}.cgz")
```

### Step 3: Extract roots.cxz

- Create a target folder for rootfs.
- Change directories to the previously created rootfs folder.
- Extract the rootfs using xzcat to read the contents of the .cxz file and pipe the output to cpio to extract them.
- Remove the .cxz file

```shell
(mkdir "${ROOTFS_DIR}" && cd "${ROOTFS_DIR}/" && xzcat "${LIVEFS_DIR}/rootfs.cxz" | cpio -idvm && rm -f "${LIVEFS_DIR}/rootfs.cxz")
```

### Step 4: Add custom files

Here we are delaring an array of of files that will be copied into the rootfs directory with the following structure:

  `key`: /path/to/source/file.ext

  `value`: /path/to/rootfs/destination/dir/

The script below performs the following checks and actions.

For each file in the array :
- Check that the destination directory is not present

   **`AND`**

  - Create the destination directory

- Check that the source file exists

  **`AND`**

- (The destination file does not ) **`OR`** (The source and destination files are not identical)

  **`AND`**

  - Copy the source file to the destination directory

```shell
declare -A filePaths
FILE1="${USERDATA}/${APOLLO_ISO}"
FILE2="${USERDATA}/${INSTALL_SCRIPT}"
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
```

### Step 5: Repack the root filesystem

- Recreate the .cpio archive.
- Compress it back to .cxz archive

```shell
( cd "${ROOTFS_DIR}" && find . | cpio -o -H newc | xz -z -T0 > "${LIVEFS_DIR}/rootfs.cxz" && rm -rf "${ROOTFS_DIR}" )
```
### Step 6: Repack debirf-live.cgz

- Recreate the .cpio archive.
- Compress it back to .cgz archive.

```shell
( cd "${LIVEFS_DIR}" && find . | cpio -o -H newc | gzip -6 > "${WORKDIR}/${LIVEIMG_BASENAME}.cgz" && rm -rf "${LIVEFS_DIR}" )
```

### Step 7: Recreate the ISO

- Rebuild the .iso image from the updated working directory contents
```shell
( echo "${DEBIRF_CONF_CONTENT}" | base64 --decode > "${WORKDIR}/debirf.conf" )
debirf make -s "${WORKDIR}"
```

## Complete Auto-Build Script

The complete script will perform all of the steps listed above to:
- Create the directory structures
- Mount the original .iso,
- Copy the files into the proper locations and extrack theew                                                                                                                        op
- Extract them to the proper locations
- Add custom ISO and install script
- Repack the archives
- Recreate the ISO

```shell

#!/bin/bash

: "${USERDATA:=/opt/userdata}"
: "${APOLLO_ISO:=APOLLO_PLATFORM-release-3.21.3.0-7+auto15.iso}"
: "${INSTALL_SCRIPT:=cableos-installer.sh}"
: "${LIVEIMG_BASENAME:=debirf-live_bullseye_6.0.0-0.deb11.6-amd64}"
: "${WORKDIR:=${HOME}/cableos-live}"
: "${LIVEFS_DIR:=${WORKDIR}/${LIVEIMG_BASENAME}}"
: "${ROOTFS_DIR:=${LIVEFS_DIR}/rootfs}"
: "${DEBIRF_MINIMAL:=/usr/share/doc/debirf/example-profiles/minimal.tgz}"
- Create a working directory.
- Unpack debirf minimal.tgz into working directory
- Mount the .iso file at /mnt .
- Copy the contents at /mnt/* to the newly created working directory.
- Unmount the .iso from /mnt .
- Change directories to the newly created working directory

mkdir "${WORKDIR}"
tar -xzvf "${DEBIRF_MINIMAL}" -C "${WORKDIR}"
mount -o loop "${USERDATA}/${LIVEIMG_BASENAME}.iso" /mnt
cp -r /mnt/* "${WORKDIR}/"
umount /mnt
cd "${WORKDIR}"

# Create the target folder for the live filesystem.
# Change directories to the previously created livefs directory.
# Extract the filesystem archive using zcat to read the contents of the .cgz file and pipe the output to cpio to extract them.
# Remove the .cgz file

(mkdir "${LIVEFS_DIR}" && cd "${LIVEFS_DIR}" && zcat "${WORKDIR}/${LIVEIMG_BASENAME}.cgz" | cpio -idvm && rm -f "${WORKDIR}/${LIVEIMG_BASENAME}.cgz")

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
#    **`AND`**
#   - Create the destination directory
# # Check that the source file exists
#   **`AND`**
# # (The destination file does not ) **`OR`** The source and destination files are not identical)
#   **`AND`**
#   - Copy the source file to the destination directory

declare -A filePaths
FILE1="${USERDATA}/${APOLLO_ISO}"
FILE2="${USERDATA}/${INSTALL_SCRIPT}"
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

( cd "${LIVEFS_DIR}" && find . | cpio -o -H newc | gzip -6 > "${WORKDIR}/${LIVEIMG_BASENAME}.cgz" && rm -rf "${LIVEFS_DIR}" )

# Rebiuld the .iso image from the updated working directory contents

debirf makeiso "${WORKDIR}"
```

## Packer Conversion HCL2

```shell
// packer.pkr.hcl
  packer {
    required_plugins {
      qemu = {
        version = ">= 0.0.1"
        source  = "github.com/hashicorp/qemu"
} }
  }
  source "qemu" "debirf-live" {
Feedback
Help Settings
1
"type": "file",
"source": "/initrd.img",
"destination": "output-debirf-live/initrd.img"
"type": "shell-local",
"inline": [
  "qemu-img convert -f qcow2 -O raw new.qcow new.img",
  "maas admin boot-resources create name=custom/new name_title='New Image' architecture=amd64/generic content@=new.img"
make build
iso_url = var.iso_url
iso_checksum = "none"
disk_size = "4096"
output_directory = var.output_directory
vm_name
format
accelerator http_directory = "http" boot_command =[

= var.iso_checksum
= 10240
= var.vm_name
= "qcow2"
= "kvm"
"<enter><wait>",
"linux /install/vmlinuz auto hostname=${var.vm_name} <wait>",
"initrd /install/initrd.gz <wait>",
"boot<enter>"
]
ssh_username
ssh_password
ssh_port
ssh_wait_timeout = "10000s"
headless        = false
= var.ssh_username
= var.ssh_password
= 22
build {
  sources = [
    "source.qemu.debirf-live"
  ]
  provisioner "shell" {
    inline = [
      "sudo ostree-production install --source=Apollo.iso --destination=/",
      "sudo cp /boot/vmlinuz* /vmlinuz",
      "sudo cp /boot/initrd.img* /initrd.img"
    ]
  }
  provisioner "file" {
    source      = "/vmlinuz"
    destination = "${var.output_directory}/vmlinuz"
}
  provisioner "file" {
    source      = "/initrd.img"
    destination = "${var.output_directory}/initrd.img"
  }
  post-processor "qemu" {
    only
    output
    format
    disk_interface = "virtio"
    = ["qemu"]
    = var.new_qcow
    = "qcow2"
  }
  post-processor "shell-local" {
    inline = [
      "qemu-img convert -f qcow2 -O raw ${var.new_qcow} ${var.new_img}",
      "maas admin boot-resources create name=custom/new name_title='New Image' architecture=amd64/generic content@=${var.new_img}"
    ]
  }
}
```
