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

  proxy_env = [
    "http_proxy=${var.http_proxy}",
    "https_proxy=${var.https_proxy}",
    "no_proxy=${var.https_proxy}",
  ]
}

// Define Packer Source for QEMU
source "null" "dependencies" {
  communicator   = "none"
}

source "qemu" "cableos-installer" {
  boot_wait      = "2s"
  cpus           = 2
  disk_image     = true
  disk_size      = "4G"
  format         = "qcow2"
  headless       = var.headless
  http_directory = var.http_directory
  iso_checksum   = "none"
  iso_url        = "${path.root}/boot-images/${var.live_img}.qcow2"
  memory         = 5120
  qemu_binary    = "qemu-system-${lookup(local.qemu_arch, var.architecture, "")}"
  qemu_img_args {
    create = ["-F", "qcow2"]
  }
  qemuargs = [
    ["-machine", "accel=kvm"
    ["-cpu", host
    ["-device", "virtio-gpu-pci"],
    ["-drive", "if=pflash,format=raw,id=ovmf_code,readonly=on,file=/usr/share/${lookup(local.uefi_imp, var.architecture, "")}/${lookup(local.uefi_imp, var.architecture, "")}_CODE.fd"],
    ["-drive", "if=pflash,format=raw,id=ovmf_vars,file=${lookup(local.uefi_imp, var.architecture, "")}_VARS.fd"],
    ["-drive", "file=output-cloudimg/packer-cloudimg,format=qcow2"],
    ["-drive", "file=seeds-cloudimg.iso,format=raw"]
  ]
  shutdown_command       = "sudo -S shutdown -P now"
  ssh_handshake_attempts = 50
  ssh_password           = var.ssh_password
  ssh_timeout            = var.timeout
  ssh_username           = var.ssh_username
  ssh_wait_timeout       = var.timeout
  use_backing_file       = true
}
source "qemu" "cableos-installer" {
  vm_name                = "cableos-installer"
  type                   = "qemu"
  qemuargs               = [["-serial", "stdio"]]
  qemu_binary            = "qemu-system-x86_64"
  accelerator            = "kvm"
  cpu_model              = "host"
  cpus                   = 2
  memory                 = 5120
  disk_image             = true
  disk_size              = "5120M"
  iso_url                = "${path.root}/boot-images/${var.live_img}.qcow2"
  iso_checksum           = "none"
  format                 = "qcow2"
  use_backing_file       = true
  http_directory         = var.http_directory
  headless               = var.headless
  efi_boot 	             = false
  boot_wait              = "10s"
  shutdown_command       = "echo 'packer' | shutdown -P now"
  ssh_handshake_attempts = 50
  ssh_password           = var.ssh_password
  ssh_timeout            = var.timeout
  ssh_username           = var.ssh_username
  ssh_wait_timeout       = var.timeout
}


// Define Build

build {
  name = "cableos-installer"
  sources = [
    "source.qemu.cableos-installer"
  ]



  // Provisioners for installation and file extraction

  provisioner "shell" {
    inline = [
      "mkdir /data"
    ]
  }

  provisioner "file" {
    destination = "/data/"
    source      = "${path.root}/buildfiles/${var.apollo_iso}"
    timeout     = "10m"
  }

  provisioner "file" {
    destination = "/opt/"
    source      = "${path.root}/buildfiles/cableos.sh"
  }

  // Post-processors to create new images and prepare for MAAS
  // Create tar.gz file
  #post-processor "shell-local" {
  #  inline = [
  #    "IMG_FMT=qcow2",
  ##    "SOURCE=cableos-installer",
  #    "ROOT_PARTITION=3",
  #    "DETECT_BLS_BOOT=1",
  #    "OUTPUT=${var.base_filename}.tar.gz",
  #    "source ../scripts/fuse-nbd",
  #    "source ../scripts/fuse-tar-root"
  #  ]
  #  inline_shebang = "/bin/bash -e"
  #}

  // Create manifest of packer objects
  post-processor "manifest" {
    output     = "${path.root}/manifest.json"
    strip_path = true
  }
}
