packer {
  required_version = ">= 1.7.0"
  required_plugins {
    qemu = {
      version = "~> 1.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}

// variables.pkr.hcl {}

variable "checkum_type" {
  type = string
  default = "md5"
}

variable "debirf_checksum" {
  type    = string
  default = "md5:1234567890abcdef1234567890abcdef"
}
variable "apollo_iso" {
  type = string
  default = "APOLLO_PLATFORM-release-3.21.3.0-7+auto15.iso"
}
variable "output_directory" {
  type    = string
  default = "output-debirf-live"
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
}                                                                                                                                                                                                                                                                                                                                                                     qqq
variable "debirf_vm_name" {
  type    = string
  default = "debirf-live"
}
variable "debirf_build_path" {
  type = string
  default = "debirf"
  description = "Debian LiveImage build directory"
}

variable "ssh_username" {
  type    = string
  default = "root"
}

variable "ssh_password" {
  type    = string
  default = "install"
}

variable "new_qcow" {
  type    = string
  default = "custom_out.qcow"
}

variable "cableos_tgz" {
  type        = string
  default     = "cableos.tar.gz"
  description = "The filename of the tarball to produce"
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
