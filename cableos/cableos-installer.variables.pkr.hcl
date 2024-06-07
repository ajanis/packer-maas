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
  default     = "/dev/null"
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
