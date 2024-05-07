

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

}
source "null" "dependencies" {
  communicator = "none"
}

source "qemu" "debirf" {

  vm_name        = "debirf-live"
  boot_wait      = "2s"
  cpus           = 2
  disk_image     = true
  format         = qcow2
  disk_size      = "10G"
  type           = "qemu"
  headless       = var.headless
  http_directory = var.http_directory
  http_url       = "http://{{ .HTTPIP }}:{{ .HTTPPort }}/"
  iso_checksum   = "none"
  iso_url        = var.image_path/var.debirf_live_bullseye_amd64_iso
  memory         = 2048
  qemu_binary    = "qemu-system-${lookup(local.qemu_arch, var.architecture, "")}"
  qemuargs = [
    ["-machine", "${lookup(local.qemu_machine, var.architecture, "")}"],
    ["-cpu", "${lookup(local.qemu_cpu, var.architecture, "")}"],
    ["-device", "virtio-gpu-pci"]
  ]
  qemu_img_args  = [
    create = ["-F", "qcow2"]
  ]
  boot_command = [
   ["<esc><wait>"],
   ["linux", "/install.amd/vmlinuz", "initrd=/install.amd/initrd.gz", "debirf.boot=live", "fetch=http://{{ .HTTPIP }}:{{ .HTTPPort }}/debirf.cgz<enter>"]
  ]
  shutdown_command       = "sudo -S shutdown -P now"
  ssh_handshake_attempts = 50
  ssh_password           = "install"
  ssh_timeout            = var.timeout
  ssh_username           = "root"
  ssh_wait_timeout       = var.timeout
  use_backing_file       = true
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
    "preseed/url=http://{{ .HTTPIP }}:{{ .HTTPPort }}/preseed.cfg <enter>"
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
  format = "raw"
  vm_name = "debian-minimal"
}


build {
  name    = "debirf.local"
  sources = ["source.null.dependencies"]

  provisioner "shell-local" {
    inline = [
      "cp ${var.source_iso_directory}/${var.debirf_live_bullseye_amd64_iso} ${var.image_path}/"
      "sudo mount -o loop ${var.image_path}/${var.debirf_live_bullseye_amd64_iso} ${var.debirf_tmp_path}"
      "cp ${var.debirf_tmp_path}/${var.debirf_initrd_filename} ${var.image_path}/"
      "cp ${var.source_iso_directory}/${var.apollo_iso} ${var.http_path}/"
      "sudo umount -lf ${var.debirf_tmp_path}"
    ]
    inline_shebang = "/bin/bash -e"
  }
}


build {
  name    = "debirf.image"
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



build {
  sources = [
    "source.qemu.cableos"
  ]

  provisioner "shell" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y openssh-server",
      "sudo apt-get clean"
    ]
  }
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
