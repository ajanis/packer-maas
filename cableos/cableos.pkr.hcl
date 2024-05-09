packer {
  required_version = ">= 1.7.0"
  required_plugins {
    qemu = {
      version = "~> 1.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

variable "filename" {
  type        = string
  default     = "cableos.tar.gz"
  description = "The filename of the tarball to produce"
}
variable "source_iso_directory" {
  type = string
  default = "/opt"
  description = "Location of source Debirf and Apollo ISO files"
}
variable "http_directory" {
  type    = string
  default = "http"
  description = "HTTP directory accessible to images during build"
}
variable "scripts_directory" {
  type = string
  default = "scripts"
  description "Build script directory"
}

variable "image_path" {
  type = string
  default = "images"
  description = "Boot image directory"
}

variable "debirf_build_path" {
  type = string
  default = "debirf"
  description = "Debian LiveImage build directory"
}

variable "debirf_iso" {
  type    = string
  default = "debirf-live_bullseye_amd64.iso"
  description = "Pre-Existing Debirf-Liveimage path"
}
variable "debirf_iso_md5sum" {
  type = string
  default = " e7a29730bf6f0740ba37e9352d22b3cb"
  description "debirf iso md5sum"
}variable "apollo_iso" {
  type = string
  default ="APOLLO_PLATFORM-release-3.21.3.0-7+auto15.iso"
  description = "Apollo PLatform iso location"
}
variable "apollo_iso_md5sum" {
  type = string
  default = "c594fc647758bc607257f036a0fcd2b5"
  description = "Tristed Apollo checksum"
}
variable "deb_netinst_url" {
  type = string
  default = "https://cdimage.debian.org/cdimage/daily-builds/daily/arch-latest/amd64/iso-cd/debian-testing-amd64-netinst.iso"
  description = "debian netinstall iso url"
}
variable "debirf_initrd_filename" {
  type = string 
  default = "live_bullseye_6.0.0-0.deb11.6-amd64.cgz"
  description = "Name of the 'debirf' creation sourcefiles"
}

variable "timeout" {
  type        = string
  default     = "1h"
  description = "Timeout for building the image"
}


source "qemu" "debirf" {
  accelerator = "kvm"
  disk_size = "10240"
  format = "qcow2"
  iso_url = var.debirf_iso
  iso_checksum = "md5:checksum_here"
      "boot_command": [
        "<enter><wait>",
        "linux /live/vmlinuz boot=live union=overlay username=user config components quiet noswap edd=on nomodeset nodmraid noeject ip=frommedia<enter>",
        "initrd /live/initrd.img<enter>",
        "boot<enter>"
  ]  
  http_directory = "http"
  ssh_username = "root"
  ssh_password = "install"
  ssh_timeout = "1h"
}

build {
  sources = ["source.qemu.debirf"]

  provisioner "file" {
    source = "path_to_iso.iso"
    destination = "/tmp/install.iso"
  }

  provisioner "shell" {
    inline = [
      "sudo mount /tmp/install.iso /mnt",
      "sudo ostree admin deploy --os=production /mnt",
      "sudo umount /mnt"
    ]
  }

  post-processor "qemu" {
    output = "debirf_ostree_production.qcow2"
    format = "qcow2"
    compression_level = 9
  }
}
