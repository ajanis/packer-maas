variable "ubuntu_series" {
  type        = string
  default     = "focal"
  description = "The codename of the Ubuntu series to build."
}

variable "filename" {
  type        = string
  default     = "custom-cloudimg.tar.gz"
  description = "The filename of the tarball to produce"
}
variable "apollo_iso" {
  type    = string
  default = "APOLLO_PLATFORM-release-3.21.3.0-7+auto15.iso"
}
variable "kernel" {
  type        = string
  default     = ""
  description = "The package name of the kernel to install. May include version string, e.g linux-image-generic-hwe-22.04=5.15.0.41.43"
}

variable "customize_script" {
  type        = string
  default     = "/dev/null"
  description = "The filename of the script that will run in the VM to customize the image."
}

variable "architecture" {
  type        = string
  default     = "amd64"
  description = "The architecture to build the image for (amd64 or arm64)"
}
