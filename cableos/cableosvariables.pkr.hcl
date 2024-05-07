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
}

variable "apollo_iso_src_path" {
  type = string
  default = "/opt/APOLLO_PLATFORM-release-3.21.3.0-7+auto15.iso"
}

variable "debirf_livecreator_path" {
  type = string
  default =
}
variable "debirf_live_bullseye_amd64_iso_src_path" {
  type    = string
  default = "/opt/debirf-live_bullseye_amd64.iso"
}

variable "timeout" {
  type        = string
  default     = "1h"
  description = "Timeout for building the image"
}
