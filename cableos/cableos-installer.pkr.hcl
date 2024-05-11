packer {
  required_version = ">= 1.7.0"
  required_plugins {
    qemu = {
      version = "~> 1.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}


variable "architecture" {
  type    = string
  default = "amd64"
}
variable "boot_mode" {
  type        = string
  default     = "uefi"
  description = "The default boot mode support baked into the image."
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

variable "apollo_iso" {
  type    = string
  default = "APOLLO_PLATFORM-release-3.21.3.0-7+auto15.iso"
}
variable "live_img" {
  type    = string
  default = "debirf-live_bullseye_amd64"
}

variable "base_filename" {
  type        = string
  default     = "cableos-installer"
  description = "The base filename for outputs"
}
variable "https_proxy" {
  type    = string
  default = "${env("https_proxy")}"
}

variable "no_proxy" {
  type    = string
  default = "${env("no_proxy")}"
}

variable "ssh_password" {
  type    = string
  default = "install"
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
    "amd64" = "accel=kvm"
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
// Define Packer Source for QEMU

# source "null" "dependencies" {
#   communicator = "none"
# }
source "qemu" "cableos-installer" {
  boot_wait      = "2s"
  cpus           = 2
  disk_image     = true
  disk_size      = "10G"
  format         = "qcow2"
  headless       = var.headless
  http_directory = var.http_directory
  iso_checksum   = "md5:37f6ddeaf58b7dfa70bc3615047e4d09"
  iso_url        = "${path.root}/boot-images/${var.live_img}.qcow2"
  memory         = 2048
  qemu_binary    = "qemu-system-${lookup(local.qemu_arch, var.architecture, "")}"
  qemu_img_args {
    create = ["-F", "qcow2"]
  }
  qemuargs = [
    ["-machine", "${lookup(local.qemu_machine, var.architecture, "")}"],
    ["-cpu", "${lookup(local.qemu_cpu, var.architecture, "")}"],
    ["-device", "virtio-gpu-pci"],
    # ["-drive", "if=pflash,format=raw,id=ovmf_code,readonly=on,file=/usr/share/${lookup(local.uefi_imp, var.architecture, "")}/${lookup(local.uefi_imp, var.architecture, "")}_CODE.fd"],
    # ["-drive", "if=pflash,format=raw,id=ovmf_vars,file=${lookup(local.uefi_imp, var.architecture, "")}_VARS.fd"]
    # ["-drive", "file=output-cableos-installer/packer-cableos-installer-img,format=qcow2"]
    ["-drive", "file=${path.root}/buildfiles/${apollo_iso},if=none,id=cdrom0,media=cdrom"]
  ]
  shutdown_command       = "sudo -S shutdown -P now"
  ssh_handshake_attempts = 50
  ssh_password           = var.ssh_password
  ssh_timeout            = "60m"
  ssh_username           = var.ssh_username
  ssh_wait_timeout       = "60m"
  # use_backing_file       = true
}


// Define Build

build {
  name = "cableos-installer"
  sources = [
    "source.qemu.cableos-installer"
  ]

  // Provisioners for installation and file extraction
  provisioner "file" {
    destination = "/etc/init.d/"
    sources     = ["${path.root}/buildfiles/startup.sh"]
  }

 provisioner "shell" {
    inline = [
      "mkdir /data"
    ]
  }

  provisioner "file" {
    destination = "/data/"
    sources     = ["${path.root}/buildfiles/${var.apollo_iso}"]
  }

  provisioner "shell-local" {
    inline = [
      "echo 'Files copied successfully..'"
    ]
  }

  // Post-processors to create new images and prepare for MAAS
  // Create tar.gz file
  post-processor "shell-local" {
    inline = [
      "IMG_FMT=qcow2",
      "SOURCE=cableos",
      "ROOT_PARTITION=2",
      "DETECT_BLS_BOOT=1",
      "OUTPUT=${var.base_filename}.tar.gz",
      "source ../scripts/fuse-nbd",
      "source ../scripts/fuse-tar-root"
    ]
    inline_shebang = "/bin/bash -e"
  }

  // Create manifest of packer objects
  post-processor "manifest" {
    output     = "${path.root}/manifest.json"
    strip_path = true
  }
}
