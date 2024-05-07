

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

source "qemu" "cableos" {

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




build {
  name    = "cableos.deps"
  sources = ["source.null.dependencies"]

  provisioner "shell-local" {
    inline = [
      "cp ${var.source_iso_directory}/${var.debirf_live_bullseye_amd64_iso} ${var.image_path}/"
      # "sudo mount -o loop ${var.image_path}/${var.debirf_live_bullseye_amd64_iso} ${var.debirf_tmp_path}"
      "cp ${var.debirf_tmp_path}/${var.debirf_initrd_filename} ${var.image_path}/"
      # "cp ${var.source_iso_directory}/${var.apollo_iso} ${var.http_path}/"
      # "sudo umount -lf ${var.debirf_tmp_path}"
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
      "SOURCE=debirf",
      "ROOT_PARTITION=1",
      "OUTPUT=${var.filename}",
      "source ../scripts/fuse-nbd",
      "source ../scripts/fuse-tar-root"
    ]
    inline_shebang = "/bin/bash -e"
  }
}
