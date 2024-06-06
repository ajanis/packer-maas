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
variable "ubuntu_series" {
  type        = string
  default     = "jammy"
  description = "The codename of the Ubuntu series to build."
}

variable "live_img" {
  type    = string
  default = "ubuntu-20.04.6-live-server-amd64"
}

variable "cloud_img" {
  type    = string
  default = "ubuntu-18.04-server-cloudimg-amd64"
}
variable "filename" {
  type        = string
  default     = "cableos-installer.tar.gz"
  description = "The filename of the tarball to produce"
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
  default = "ubuntu"
}

variable "ssh_username" {
  type    = string
  default = "ubuntu"
}
variable "timeout" {
  type        = string
  default     = "1h"
  description = "Timeout for building the image"
}


source "qemu" "cableos-installer" {
  vm_name          = "cableos-installer"
  qemu_binary      = "qemu-system-x86_64"
  accelerator      = "kvm"
  cpu_model        = "host"
  cpus             = 2
  memory           = 5120
  disk_image       = true
  disk_interface   = "virtio"
  disk_size        = "5120M"
  iso_url          = "https://cloud-images.ubuntu.com/${var.ubuntu_series}/current/${var.ubuntu_series}-server-cloudimg-${var.architecture}.img"
  #iso_url          = "${path.root}/boot-images/${var.live_img}.iso"
  iso_checksum     = "none"
  format           = "qcow2"
  use_backing_file = true
  net_device       = "virtio-net"
  http_directory   = var.http_directory
  qemu_img_args {
    create = ["-F", "qcow2"]
  }
  headless               = var.headless
  boot_wait              = "10s"
  shutdown_command       = "echo 'packer' | shutdown -P now"
  ssh_handshake_attempts = 50
  ssh_password           = "install"
  ssh_timeout            = var.timeout
  ssh_username           = "root"
  ssh_wait_timeout       = var.timeout
  qemuargs = [
    ["-drive", "file=output-cableos-installer/packer-cableos-installer,format=qcow2"],
    ["-drive", "file=user-data.img,format=raw"]
  ]
}

// Define Build
build {
  name = "cableos-installer"
  sources = [
    "source.qemu.cableos-installer"
  ]

  // Provisioners for installation and file extraction

   provisioner "file" {
     destination = "/opt/"
     source      = "${path.root}/http/ostree-upgrade-bootstrap_2.0.41_all.deb"
   }
   provisioner "file" {
     destination = "/opt/"
     source      = "${path.root}/http/ostree-upgrade_2.0.41_all.deb"
   }

  provisioner "file" {
    destination = "/data/"
    source      = "${path.root}/http/${var.apollo_iso}"
  }
  provisioner "file" {
    destination = "/opt/"
    source      = "${path.root}/http/cableos-installer.sh"
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
}

