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
  default     = "centos8.tar.gz"
  description = "The filename of the tarball to produce"
}

variable "centos8_iso_url" {
  type    = string
  default = "https://mirrors.edge.kernel.org/centos/8.4.2105/isos/x86_64/CentOS-8.4.2105-x86_64-boot.iso"
}

variable "centos8_sha256sum_url" {
  type    = string
  default = "https://mirrors.edge.kernel.org/centos/8.4.2105/isos/x86_64/CHECKSUM"
}

source "qemu" "centos8" {
  boot_command     = ["<up><tab> ", "inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/centos8.ks ", "console=ttyS0 inst.cmdline", "<enter>"]
  boot_wait        = "3s"
  communicator     = "none"
  disk_size        = "4G"
  headless         = true
  http_directory   = "http"
  iso_checksum     = "file:${var.centos8_sha256sum_url}"
  iso_url          = var.centos8_iso_url
  memory           = 2048
  qemuargs         = [["-serial", "stdio"]]
  shutdown_timeout = "1h"
}

build {
  sources = ["source.qemu.centos8"]

  post-processor "shell-local" {
    inline = [
      "SOURCE=centos8",
      "OUTPUT=${var.filename}",
      "source ../scripts/fuse-nbd",
      "source ../scripts/fuse-tar-root"
    ]
    inline_shebang = "/bin/bash -e"
  }
}
