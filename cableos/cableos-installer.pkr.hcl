packer {
  required_version = ">= 1.7.0"
  required_plugins {
    qemu = {
      version = "~> 1.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
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

variable "ssh_password" {
  type    = string
  default = "ubuntu"
}

variable "ssh_username" {
  type    = string
  default = "root"
}

variable "ssh_ubuntu_password" {
  type    = string
  default = "ubuntu"
}

variable "timeout" {
  type        = string
  default     = "1h"
  description = "Timeout for building the image"
}


variable "filename" {
  type        = string
  default     = "cableos-installer.tar.gz"
  description = "The filename of the tarball to produce"
}

variable "ubuntu_series" {
  type        = string
  default     = "jammy"
  description = "The codename of the Ubuntu series to build."
}

variable "customize_script" {
  type        = string
  default     = "customize.sh"
  description = "The filename of the script that will run in the VM to customize the image."
}

variable "architecture" {
  type        = string
  default     = "amd64"
  description = "The architecture to build the image for (amd64 or arm64)"
}

variable "apollo_iso" {
  type    = string
  default = "APOLLO_PLATFORM-release-3.21.3.0-7+auto15.iso"
}

variable "live_iso" {
  type        = string
  default     = "ubuntu-22.04.4-live-server-amd64.iso"
  description = "The ISO name to build the image from"
}

variable "cloud_img" {
  type    = string
  default = "ubuntu-22.04-server-cloudimg-amd64.img"
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

source "qemu" "cableos" {
  boot_wait      = "2s"
  cpus           = 2
  disk_image     = true
  disk_size      = "6G"
  format         = "qcow2"
  headless       = var.headless
  vnc_bind_address = "0.0.0.0"
  http_directory = var.http_directory
  iso_checksum   = "file:https://cloud-images.ubuntu.com/${var.ubuntu_series}/current/SHA256SUMS"
  iso_url        = "https://cloud-images.ubuntu.com/${var.ubuntu_series}/current/${var.ubuntu_series}-server-cloudimg-${var.architecture}.img"
  memory         = 2048
  qemu_binary    = "qemu-system-${lookup(local.qemu_arch, var.architecture, "")}"
  qemu_img_args {
    create = ["-F", "qcow2"]
  }
  qemuargs = [
    ["-machine", "${lookup(local.qemu_machine, var.architecture, "")}"],
    ["-cpu", "${lookup(local.qemu_cpu, var.architecture, "")}"],
    ["-device", "virtio-gpu-pci"],
    ["-drive", "if=pflash,format=raw,id=ovmf_code,readonly=on,file=/usr/share/${lookup(local.uefi_imp, var.architecture, "")}/${lookup(local.uefi_imp, var.architecture, "")}_CODE.fd"],
    ["-drive", "if=pflash,format=raw,id=ovmf_vars,file=${lookup(local.uefi_imp, var.architecture, "")}_VARS.fd"],
    ["-drive", "file=output-cableos/packer-cableos,format=qcow2"],
    ["-drive", "file=seeds-cableos.iso,format=raw"]
  ]
  shutdown_command       = "sudo -S shutdown -P now"
  ssh_handshake_attempts = 500
  ssh_password           = var.ssh_password
  ssh_timeout            = var.timeout
  ssh_username           = var.ssh_username
  ssh_wait_timeout       = var.timeout
  use_backing_file       = true
}


// Define Builds
build {
  name    = "cableos.deps"
  sources = ["source.null.dependencies"]

  provisioner "shell-local" {
    inline = [
      "cp /usr/share/${lookup(local.uefi_imp, var.architecture, "")}/${lookup(local.uefi_imp, var.architecture, "")}_VARS.fd ${lookup(local.uefi_imp, var.architecture, "")}_VARS.fd",
      "cloud-localds seeds-cableos.iso user-data meta-data"
    ]
    inline_shebang = "/bin/bash -e"
  }
}

build {
  name    = "cableos.image"
  sources = ["source.qemu.cableos"]

  # provisioner "shell" {
  #   environment_vars = concat(local.proxy_env, ["DEBIAN_FRONTEND=noninteractive"])
  #   scripts          = ["${path.root}/scripts/cloudimg/setup-boot.sh"]
  # }
  provisioner "file" {
    destination = "/opt/"
    sources = [
      "${path.root}/http/ostree-upgrade-bootstrap_2.0.41_all.deb",
      "${path.root}/http/ostree-upgrade_2.0.41_all.deb"
    ]
  }
  provisioner "shell" {
    environment_vars  = concat(local.proxy_env, ["DEBIAN_FRONTEND=noninteractive"])
    expect_disconnect = true
    scripts           = [var.customize_script]
  }

  # provisioner "shell" {
  #   environment_vars = [
  #     "CLOUDIMG_CUSTOM_KERNEL=${var.kernel}",
  #     "DEBIAN_FRONTEND=noninteractive"
  #   ]
  #   scripts = ["${path.root}/scripts/cloudimg/install-custom-kernel.sh"]
  # }

  # provisioner "file" {
  #   destination = "/tmp/"
  #   sources     = ["${path.root}/scripts/cloudimg/curtin-hooks"]
  # }

  # provisioner "shell" {
  #   environment_vars = ["CLOUDIMG_CUSTOM_KERNEL=${var.kernel}"]
  #   scripts          = ["${path.root}/scripts/cloudimg/setup-curtin.sh"]
  # }

  # provisioner "shell" {
  #   environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
  #   scripts          = ["${path.root}/scripts/cloudimg/cleanup.sh"]
  # }

  post-processor "shell-local" {
    inline = [
      "IMG_FMT=qcow2",
      "SOURCE=cableos",
      "ROOT_PARTITION=1",
      "DETECT_BLS_BOOT=1",
      "OUTPUT=${var.filename}",
      "source ../scripts/fuse-nbd",
      "source ../scripts/fuse-tar-root"
    ]
    inline_shebang = "/bin/bash -e"
  }
}
