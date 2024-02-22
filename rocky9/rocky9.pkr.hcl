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
  default     = "rocky9.tar.gz"
  description = "The filename of the tarball to produce"
}

variable "headless" {
  type        = bool
  default     = true
  description = "Whether VNC viewer should not be launched."
}

variable "rocky_iso_url" {
  type    = string
  default = "https://download.rockylinux.org/pub/rocky/9/isos/x86_64/Rocky-x86_64-boot.iso"
}

variable "rocky_sha256sum_url" {
  type    = string
  default = "https://download.rockylinux.org/pub/rocky/9/isos/x86_64/CHECKSUM"
}

# use can use "--url" to specify the exact url for os repo
variable "ks_os_repos" {
  type    = string
  default = "--url='https://download.rockylinux.org/pub/rocky/9/BaseOS/x86_64/os/'"
}

# Use --baseurl to specify the exact url for base_os repo
variable "ks_base_os_repos" {
  type    = string
  default = "--mirrorlist='http://mirrors.rockylinux.org/mirrorlist?arch=x86_64&repo=BaseOS-9'"
}

# Use --baseurl to specify the exact url for appstream repo
variable "ks_appstream_repos" {
  type    = string
  default = "--mirrorlist='https://mirrors.rockylinux.org/mirrorlist?arch=x86_64&release=9&repo=AppStream-9'"
}

# Use --baseurl to specify the exact url for extras repo
variable "ks_extras_repos" {
  type    = string
  default = "--mirrorlist='https://mirrors.rockylinux.org/mirrorlist?arch=x86_64&repo=extras-9'"
}

variable ks_proxy {
  type    = string
  default = "${env("KS_PROXY")}"
}

variable ks_mirror {
  type    = string
  default = "${env("KS_MIRROR")}"
}

locals {
  ks_proxy           = var.ks_proxy != "" ? "--proxy=${var.ks_proxy}" : ""
  ks_os_repos        = var.ks_mirror != "" ? "--url=${var.ks_mirror}/BaseOS/x86_64/os" : var.ks_os_repos
  ks_base_os_repos   = var.ks_mirror != "" ? "--url=${var.ks_mirror}/BaseOS/x86_64/os" : var.ks_base_os_repos
  ks_appstream_repos = var.ks_mirror != "" ? "--baseurl=${var.ks_mirror}/AppStream/x86_64/os" : var.ks_appstream_repos
  ks_extras_repos    = var.ks_mirror != "" ? "--baseurl=${var.ks_mirror}/extras/x86_64/os" : var.ks_extras_repos
}

source "qemu" "rocky9" {
  boot_command     = ["<up><tab> ", "inst.ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/rocky.ks ", "console=ttyS0 inst.cmdline", "<enter>"]
  boot_wait        = "3s"
  communicator     = "none"
  disk_size        = "4G"
  headless         = var.headless
  iso_checksum     = "file:${var.rocky_sha256sum_url}"
  iso_url          = "${var.rocky_iso_url}"
  memory           = 2048
  qemuargs         = [["-serial", "stdio"], ["-cpu", "host"]]
  shutdown_timeout = "1h"
  http_content = {
    "/rocky.ks" = templatefile("${path.root}/http/rocky.ks.pkrtpl.hcl",
      {
        KS_PROXY           = local.ks_proxy,
        KS_OS_REPOS        = local.ks_os_repos,
        KS_BASE_OS_REPOS   = local.ks_base_os_repos,
        KS_APPSTREAM_REPOS = local.ks_appstream_repos,
        KS_EXTRAS_REPOS    = local.ks_extras_repos
      }
    )
  }
}

build {
  sources = ["source.qemu.rocky9"]

  post-processor "shell-local" {
    inline = [
      "SOURCE=${source.name}",
      "OUTPUT=${var.filename}",
      "source ../scripts/fuse-nbd",
      "source ../scripts/fuse-tar-root",
      "rm -rf output-${source.name}",
    ]
    inline_shebang = "/bin/bash -e"
  }
}
