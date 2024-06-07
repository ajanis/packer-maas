packer {
  required_version = ">= 1.7.0"
  required_plugins {
    qemu = {
      version = "~> 1.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}




variable "customize_script" {
  type        = string
  default     = "/dev/null"
  description = "The filename of the script that will run in the VM to customize the image."
}

variable "headless" {
  type        = bool
  default     = true
  description = "Whether VNC viewer should not be launched."
}

variable "http_directory" {
  type    = string
  default = "http"
}

variable "http_proxy" {
  type    = string
  default = "${env("http_proxy")}"
}
variable "https_proxy" {
  type    = string
  default = "${env("https_proxy")}"
}
variable "no_proxy" {
  type    = string
  default = "${env("no_proxy")}"
}

variable "apollo_iso" {
  type    = string
  default = "APOLLO_PLATFORM-release-3.21.3.0-7+auto15.iso"
}
variable "ubuntu_series" {
  type        = string
  default     = "jammy"
  description = "The codename of the Ubuntu series to build."
}

variable "live_iso" {
  type        = string
  default     = "ubuntu-22.04.4-live-server-amd64.iso"
  description = "The ISO name to build the image from"
}

variable "cloud_img" {
  type    = string
  default = "ubuntu-18.04-server-cloudimg-amd64.img"
}

variable "filename" {
  type        = string
  default     = "cableos-installer"
  description = "The filename of the tarball to produce"
}

variable "ssh_password" {
  type    = string
  default = "ubuntu"
}

variable "ssh_username" {
  type    = string
  default = "root"
}
variable "timeout" {
  type        = string
  default     = "1h"
  description = "Timeout for building the image"
}
variable "architecture" {
  type    = string
  default = "amd64"
}


locals {
  qemu_arch = {
    "amd64" = "x86_64"
    "arm64" = "aarch64"
  }
  uefi_imp = {
    "amd64" = "OVMF"
    "arm64" = "AAVMF"
  }
  qemu_machine = {
    "amd64" = "ubuntu,accel=kvm"
    "arm64" = "virt"
  }
  qemu_cpu = {
    "amd64" = "host"
    "arm64" = "cortex-a57"
  }

  proxy_env = [
    "http_proxy=${var.http_proxy}",
    "https_proxy=${var.https_proxy}",
    "no_proxy=${var.https_proxy}",
  ]
}

source "null" "dependencies" {
  communicator = "none"
}

source "qemu" "cableos-installer" {
  qemu_binary    = "qemu-system-${lookup(local.qemu_arch, var.architecture, "")}"
  cpus            = 1
  memory          = 8120
  # net_device        = "virtio-net"
  # disk_interface    = "virtio"
  disk_image      = true
  disk_size       = "8120M"
  #LIVE
  # iso_url         = "https://releases.ubuntu.com/${var.ubuntu_series}/${var.live_iso}"
  # format          = "raw"
  # iso_target_path = "packer_cache/${var.ubuntu_series}.iso"
  #CLOUD
  iso_url         = "https://cloud-images.ubuntu.com/${var.ubuntu_series}/current/${var.ubuntu_series}-server-cloudimg-${var.architecture}.img"
  format          = "qcow2"
  use_backing_file = true
  iso_checksum = "none"
  http_directory   = var.http_directory
  headless               = var.headless
  boot_wait              = "10s"
  shutdown_command       = "echo 'packer' | sudo -S shutdown -P now"
  ssh_handshake_attempts = 50
  # ssh_password           = var.ssh_password
  ssh_timeout            = var.timeout
  ssh_username           = var.ssh_username
  ssh_wait_timeout       = var.timeout
  qemu_img_args {
      create = ["-F", "qcow2"]
    }
  qemuargs = [
    ["-machine", "${lookup(local.qemu_machine, var.architecture, "")}"],
    ["-cpu", "${lookup(local.qemu_cpu, var.architecture, "")}"],
    ["-device", "virtio-gpu-pci"],
    ["-drive", "if=pflash,format=raw,id=ovmf_code,readonly=on,file=/usr/share/${lookup(local.uefi_imp, var.architecture, "")}/${lookup(local.uefi_imp, var.architecture, "")}_CODE.fd"],
    ["-drive", "if=pflash,format=raw,id=ovmf_vars,file=${lookup(local.uefi_imp, var.architecture, "")}_VARS.fd"],
    ["-drive", "file=output-cableos-installer/packer-cableos-installer,format=qcow2"],
    ["-drive", "file=seeds.iso,format=raw"]
  ]
  # qemuargs = [
  #   ["-vga", "qxl"],
  #   ["-device", "virtio-blk-pci,drive=drive0,bootindex=0"],
  #   ["-device", "virtio-blk-pci,drive=cdrom0,bootindex=1"],
  #   ["-device", "virtio-blk-pci,drive=drive1,bootindex=2"],
  #   ["-drive", "if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE.fd"],
  #   ["-drive", "if=pflash,format=raw,file=OVMF_VARS.fd"],
  #   ["-drive", "file=output-cableos-installer/packer-cableos-installer,if=none,id=drive0,cache=writeback,discard=ignore,format=raw"],
  #   ["-drive", "file=seeds.iso,format=raw,cache=none,if=none,id=drive1,readonly=on"],
  #   ["-drive", "file=packer_cache/${var.ubuntu_series}.iso,if=none,id=cdrom0,media=cdrom"]
  # ]
  # qemuargs = [
  #   ["-drive", "file=output-cableos-installer/packer-cableos-installer,format=qcow2"],
  #   ["-drive", "file=user-data.img,format=raw"]
  # ]
}

// Define Builds
build {
  name    = "cableos-installer.deps"
  sources = ["source.null.dependencies"]

  provisioner "shell-local" {
    inline = [
      "cp /usr/share/${lookup(local.uefi_imp, var.architecture, "")}/${lookup(local.uefi_imp, var.architecture, "")}_VARS.fd ${lookup(local.uefi_imp, var.architecture, "")}_VARS.fd",
      "cloud-localds seeds.iso user-data meta-data"
    ]
    inline_shebang = "/bin/bash -e"
  }
}

build {
  name = "cableos-installer"
  sources = [
    "source.qemu.cableos-installer"
  ]

  // Provisioners for installation and file extraction

  provisioner "file" {
    destination = "/opt/"
    sources = [
      "${path.root}/http/ostree-upgrade-bootstrap_2.0.41_all.deb",
      "${path.root}/http/ostree-upgrade_2.0.41_all.deb",
      "${path.root}/http/cableos-installer-revised.sh"
    ]
  }

  provisioner "file" {
    destination = "/data/"
    source      = "${path.root}/http/${var.apollo_iso}"
  }

  post-processor "manifest" {
    output     = "${path.root}/manifest.json"
    strip_path = true
  }

  post-processor "shell-local" {
    inline = [
      "IMG_FMT=qcow2",
      "SOURCE=cableos-installer",
      "ROOT_PARTITION=1",
      "DETECT_BLS_BOOT=1",
      "OUTPUT=${var.filename}",
      "source ../scripts/fuse-nbd",
      "source ../scripts/fuse-tar-root"
    ]
    inline_shebang = "/bin/bash -e"
  }
  # post-processor "shell-local" {
  #   inline = [
  #     "SOURCE=cableos-installer",
  #     "IMG_FMT=raw",
  #     "ROOT_PARTITION=2",
  #     "OUTPUT=${var.filename}",
  #     "source ../scripts/fuse-nbd",
  #     "source ../scripts/fuse-tar-root"
  #   ]
  #   inline_shebang = "/bin/bash -e"
  # }

}
