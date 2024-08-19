variable "headless" {
  type        = bool
  default     = true
  description = "Whether VNC viewer should not be launched."
}
variable "packer_log" {
  type        = string
  default     = "0"
  description = "Enable/Disable verbose logging"
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

variable "ssh_username" {
  type    = string
  default = "ubuntu"
}

variable "ssh_password" {
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
  default     = "harmonic-installer.tar.gz"
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

variable "apollo_iso" {
  type        = string
  default     = "APOLLO_PLATFORM-release-3.21.3.0-7+auto15.iso"
  description = "Harmonic cOS image file"
}

variable "live_iso" {
  type        = string
  default     = "ubuntu-22.04.4-live-server-amd64.iso"
  description = "Ubuntu Live-Server iso build source"
}

variable "shutdown" {
  type        = string
  default     = "sudo -S shutdown -P now"
  description = "Default shutdown command for qemu builds"
}

variable "vm_name" {
  type        = string
  default     = "harmonic-installer"
  description = "Base vm hostname"
}
