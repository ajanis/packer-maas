
# Custom Debirf

Use existing custom debirf iso, extract iso, extract debirf-live.cgz, extract roots.cxz , add custom files, repack and recreate custom image with debirf

## Pregame: Environment setup
```shell

export LIVEIMG_BASENAME="debirf-live_bullseye_6.0.0-0.deb11.6-amd64"
export APOLLO_ISO="APOLLO_PLATFORM-release-3.21.3.0-7+auto15.iso"
export WORKDIR="/opt/${LIVEIMG_BASENAME}"

declare -A userdata
file1="APOLLO_PLATFORM-release-3.21.3.0-7+auto15.iso"
file2="install-cableos.sh"
userdata[$file1]=/data/
userdata[$file2]=/root/

for file in "${!test_var[@]}"; do
    cp "/opt/userdata/$file ${WORKDIR}/${userdata[$file]}"
done

```


## Step 1: Extract the ISO file
Mount the ISO file.
Copy the contents to a working directory.
Extract debirf-live.cgz:

```shell

mount -o loop debirf-live_bullseye_amd64.iso /mnt
mkdir ~/debirf_workdir
cp -r /mnt/iso/* ~/debirf_workdir/
umount /mnt/iso
```

## Step 2: Extract debirf-live.cgz
Use gzip to decompress the .cgz file.
Extract the resulting .cpio archive.


```shell
zcat debirf-live_bullseye_6.0.0-0.deb11.6-amd64.cgz | cpio -idvm
```
```shell
cd ~/debirf_workdir
mkdir debirf_live
cp debirf-live.cgz debirf_live/
cd debirf_live
gzip -d debirf-live.cgz
cpio -idmv < debirf-live.cpio
rm debirf-live.cpio
```

## Step 3: Extract roots.cxz
Use xz to decompress the .cxz file.
Extract the resulting .cpio archive.

```shell
xzcat ../rootfs.cxz | cpio -idvm
```

```shell
mkdir roots
cp roots.cxz roots/
cd roots
xz -d roots.cxz
cpio -idmv < roots.cpio
rm roots.cpio
```

## Step 4: Add custom files
Copy your custom files into the appropriate directories within ~/debirf_workdir/debirf_live/roots.

## Step 5: Repack the root filesystem
Recreate the .cpio archive.
Compress it back to .cxz.

```shell
cd ~/debirf_workdir/debirf_live/roots
find . | cpio -o -H newc | xz -z -9 > ../roots.cxz
```
## Step 6: Repack debirf-live.cgz
Recreate the .cpio archive.
Compress it back to .cgz.

```shell
cd ~/debirf_workdir/debirf_live
find . | cpio -o -H newc | gzip -9 > ../debirf-live.cgz
```
## Step 7: Recreate the ISO
Use a tool like genisoimage or mkisofs to create a new ISO from the modified directory.

```shell
debirf makeiso ${PROFILE}
```


## Packer Conversion

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
