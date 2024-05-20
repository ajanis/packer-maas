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
  iso_url          = "${path.root}/boot-images/${var.live_img}.iso"
  iso_checksum     = "none"
  format           = "raw"
  use_backing_file = false
  skip_compaction  = true
  disk_compression = false
  net_device       = "virtio-net"
  http_directory   = var.http_directory
  cd_files         = ["${path.root}/http/data/${var.apollo_iso}", "${path.root}/http/cableos.sh"]
  cd_label         = "data"
  qemu_img_args {
    create = ["-F", "raw"]
  }
  headless               = var.headless
  efi_boot               = true
  efi_drop_efivars       = true
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

  provisioner "file" {
    destination = "/"
    source      = "${path.root}/http/data"
  }

  provisioner "file" {
    destination = "/"
    source      = "${path.root}/http/cableos.sh"
  }


  post-processor "manifest" {
    output     = "${path.root}/manifest.json"
    strip_path = true
  }
}
