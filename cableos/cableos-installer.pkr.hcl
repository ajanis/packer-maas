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
  type = string
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
  type        = string
  default     = "APOLLO_PLATFORM-release-3.21.3.0-7+auto15.iso"
}
variable "live_iso" {
  type = string
  default = "debirf-live_bullseye_amd64.iso"
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


source "qemu" "cableos" {
  boot_wait      = "2s"
  cpus           = 2
  disk_image     = true
  disk_size      = "4G"
  format         = "qcow2"
  headless       = var.headless
  http_directory = var.http_directory
  iso_checksum   = "none"
  iso_url        = "build_images/${var.live_iso}"
  memory         = 2048
  qemu_binary    = "qemu-system-${lookup(local.qemu_arch, var.architecture, "")}"
  qemu_img_args {
    create = ["-F", "qcow2"]
  }
  qemuargs = [
    ["-machine", "${lookup(local.qemu_machine, var.architecture, "")}"],
    ["-cpu", "${lookup(local.qemu_cpu, var.architecture, "")}"],
    ["-device", "virtio-gpu-pci"],
    ["-drive", "file=output-cableos-installer/${var.base_filename},format=qcow2"],
  ]
  shutdown_command       = "sudo -S shutdown -P now"
  ssh_handshake_attempts = 50
  ssh_password           = var.ssh_password
  ssh_timeout            = var.timeout
  ssh_username           = var.ssh_username
  ssh_wait_timeout       = var.timeout
  use_backing_file       = true
}

// Define Build
build {
  name    = "cableos-installer"
  sources = [
    "source.qemu.cableos"
  ]

  // Provisioners for installation and file extraction
  provisioner "file" {
    source      = "/buildfiles/${var.apollo_iso}"
    destination = "/opt/${var.apollo_iso}"
  }

  provisioner "file" {
    source      = "/buildfiles/startup.sh"
    destination = "/etc/init.d/startup.sh"

  }
  provisioner "shell" {
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
      "ROOT_PARTITION=3",
      "DETECT_BLS_BOOT=1",
      "OUTPUT=${var.base_filename}.tar.gz",
      "source ../scripts/fuse-nbd",
      "source ../scripts/fuse-tar-root"
    ]
    inline_shebang = "/bin/bash -e"
  }

  // Create manifest of packer objects
  post-processor "manifest" {
      output = "manifest.json"
      strip_path = true
  }


  # // Create .qcow and .iso images
  # post-processor "qemu" {
  #   only = ["qemu"]
  #   output = "output-cableos-installer/${base_filename}.qcow"
  #   format = "qcow2"
  #   disk_interface = "virtio"
  # }
  # post-processor "shell-local" {
  #   inline = [
  #     "qemu-img convert -f qcow2 -O raw output-cableos-installer/${base_filename}.qcow output-cableos-installer/${base-filename}.img",
  #     "maas admin boot-resources create name=custom/new name_title='New Image' architecture=amd64/generic content@=new.img",
  #     "echo 'Packer Provisioning Complete'"

  #   ]
  # }
}
