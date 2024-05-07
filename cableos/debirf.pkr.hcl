

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

  boot_wait      = "2s"
  cpus           = 2
  disk_image     = true
  disk_size      = "4G"
  type           = "qemu"
  format         = "qcow2"
  headless       = var.headless
  http_directory = var.http_directory
  iso_checksum   = "none"
  iso_url        = var.debirf_iso_path
  memory         = 2048
  qemu_binary    = "qemu-system-${lookup(local.qemu_arch, var.architecture, "")}"
  qemu_img_args {
    create = ["-F", "qcow2"]
  }
  qemuargs = [
    ["-machine", "${lookup(local.qemu_machine, var.architecture, "")}"],
    ["-cpu", "${lookup(local.qemu_cpu, var.architecture, "")}"],
    ["-device", "virtio-gpu-pci"]
  ]
  shutdown_command       = "sudo -S shutdown -P now"
  ssh_handshake_attempts = 50
  ssh_password           = var.ssh_password
  ssh_timeout            = var.timeout
  ssh_username           = var.ssh_username
  ssh_wait_timeout       = var.timeout
  use_backing_file       = true
}




build {
  name    = "debirf.local"
  sources = ["source.null.dependencies"]

  provisioner "shell-local" {
    inline = [
      "cd ${var.debirf_build_path}"
      "tar -zxvf ${debirf_tgz_path}"
      "debirf makeiso minimal"
      "cd ${path.root}"
      "mv ${var.debirf_livecreator_path} ${var.image_path}/"
      "mv ${var.apollo_iso_src_path} ${var.http_path}/"
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
    scripts           = ["${path.root}/scripts/apollo_install.sh"]
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
