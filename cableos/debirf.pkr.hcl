

locals {
  qemu_arch = {
    "amd64" = "x86_64"
    "arm64" = "aarch64"
  }
  uefi_imp = {
    "amd64" = "OVMF"
    "arm64" = "AAVMF"
  }
  qemu_machine = {
    "amd64" = "accel=kvm"
    "arm64" = "virt"
  }
  qemu_cpu = {
    "amd64" = "host"
    "arm64" = "cortex-a57"
  }




source "qemu" "cableos" {
  iso_url = var.deb_netinst_url
  iso_checksum = "auto"
  boot_command = [
    "<esc><wait>",
    "install <wait>",
    "auto=true <wait>",
    "priority=critical <wait>",
    "locale=en_US <wait>",
    "keyboard-configuration/xkb-keymap=us <wait>",
    "netcfg/get_hostname=debian <wait>",
    "netcfg/get_domain=vm <wait>",
    "fb=false <wait>",
    "debconf/frontend=noninteractive <wait>",
    "console-setup/ask_detect=false <wait>",
    "interface=auto <wait>",
  ]
  http_directory = "http"
  disk_size = 10240
  http_port_min = 8000
  http_port_max = 9000
  ssh_username = "admin"
  ssh_password = "admin"
  ssh_port = 22
  ssh_wait_timeout = "10000s"
  shutdown_command = "echo 'shutdown -P now' > shutdown.sh; chmod +x shutdown.sh; sudo ./shutdown.sh"
  format = "qemu"
  vm_name = "debian-minimal"
}



build {
  name    = "cableos.image"
  sources = ["source.qemu.debirf"]

  provisioner "shell" {
    environment_vars  = ["DEBIAN_FRONTEND=noninteractive"]
    expect_disconnect = true
    scripts           = ["${var.scripts_directory}/apollo_install.sh"]
  }

  post-processor "shell-local" {
    inline = [
      "IMG_FMT=qcow2",
      "SOURCE=cloudimg",
      "ROOT_PARTITION=1",
      "OUTPUT=${var.filename}",
      "source ../scripts/fuse-nbd",
      "source ../scripts/fuse-tar-root"
    ]
    inline_shebang = "/bin/bash -e"
  }
}
