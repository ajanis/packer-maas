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
  default     = "cableos.tar.gz"
  description = "The filename of the tarball to produce"
}

variable "debirf_apollo_filename" {
  type = string
  default = "cableos.iso"
  description = "Debian Live Image with Apollo install completed"
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
}
variable "apollo_iso" {
  type = string
  default = "APOLLO_PLATFORM-release-3.21.3.0-7+auto15.iso"
  description = "Apollo PLatform iso location"
}

variable "source_iso_directory" {
  type = string
  default = "/opt"
  description = "Location of source Debirf and Apollo ISO files"
}


variable "debirf_tmp_path" {
  type = string
  default = "debirf"
  description = "Debian LiveImage build directory"
}

variable "image_path" {
  type = string
  default = "images"
  description = "Boot image directory"
}
variable "debirf_live_bullseye_amd64_iso" {
  type    = string
  default = "debirf-live_bullseye_amd64.iso"
  description = "Pre-Existing Debirf-Liveimage path"
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
