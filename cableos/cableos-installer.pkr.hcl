packer {
  required_version = ">= 1.7.0"
  required_plugins {
    qemu = {
      version = "~> 1.0"
      source  = "github.com/hashicorp/qemu"
    }
  }
}


locals {

  proxy_env = [
    "http_proxy=${var.http_proxy}",
    "https_proxy=${var.https_proxy}",
    "no_proxy=${var.https_proxy}",
  ]
}

source "null" "dependencies" {
  communicator = "none"
}

source "qemu" "cableos" {
  boot_wait      = "2s"
  cpus           = 2
  disk_image     = true
  disk_size      = "6G"
  format         = "qcow2"
  headless       = var.headless
  vnc_bind_address = "0.0.0.0"
  http_directory = var.http_directory
  iso_checksum   = "file:https://cloud-images.ubuntu.com/${var.ubuntu_series}/current/SHA256SUMS"
  iso_url        = "https://cloud-images.ubuntu.com/${var.ubuntu_series}/current/${var.ubuntu_series}-server-cloudimg-${var.architecture}.img"
  memory         = 2048
  qemu_binary    = "qemu-system-x86_64"
  qemu_img_args {
    create = ["-F", "qcow2"]
  }
  qemuargs = [
    ["-machine", "ubuntu,accel=kvm"],
    ["-cpu", "host"],
    ["-device", "virtio-gpu-pci"],
    ["-drive", "if=pflash,format=raw,id=ovmf_code,readonly=on,file=/usr/share/OVMF/OVMF_CODE.fd"],
    ["-drive", "if=pflash,format=raw,id=ovmf_vars,file=OVMF_VARS.fd"],
    ["-drive", "file=output-cableos/packer-cableos,format=qcow2"],
    ["-drive", "file=seeds-cableos.iso,format=raw"]
  ]
  shutdown_command       = "sudo -S shutdown -P now"
  ssh_handshake_attempts = 500
  ssh_password           = var.ssh_password
  ssh_timeout            = var.timeout
  ssh_username           = var.ssh_username
  ssh_wait_timeout       = var.timeout
  use_backing_file       = true
}


// Define Builds
build {
  name    = "cableos.deps"
  sources = ["source.null.dependencies"]

  provisioner "shell-local" {
    inline = [
      "cp /usr/share/OVMF/OVMF_VARS.fd OVMF_VARS.fd",
      "cloud-localds seeds-cableos.iso user-data meta-data"
    ]
    inline_shebang = "/bin/bash -e"
  }
}

build {
  name    = "cableos.image"
  sources = ["source.qemu.cableos"]

  provisioner "shell" {
    environment_vars = concat(local.proxy_env, ["DEBIAN_FRONTEND=noninteractive"])
    scripts          = ["${path.root}/scripts/cloudimg/setup-boot.sh"]
  }

  provisioner "file" {
    destination = "/opt/"
    sources = [
      "${path.root}/packages/ostree-upgrade-bootstrap_2.0.41_all.deb",
      "${path.root}/packages/ostree-upgrade_2.0.41_all.deb"
    ]
  }

  provisioner "shell" {
    environment_vars  = concat(local.proxy_env, ["DEBIAN_FRONTEND=noninteractive"])
    expect_disconnect = true
    scripts           = ["${path.root}/scripts/cableos-install/setup-cableos-installer.sh"]
  }

  provisioner "shell" {
    environment_vars  = concat(local.proxy_env, ["DEBIAN_FRONTEND=noninteractive"])
    expect_disconnect = true
    scripts           = [var.customize_script]
  }

  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
    scripts          = ["${path.root}/scripts/cloudimg/cleanup.sh"]
  }

  post-processor "shell-local" {
    inline = [
      "IMG_FMT=qcow2",
      "SOURCE=cableos",
      "ROOT_PARTITION=1",
      "DETECT_BLS_BOOT=1",
      "OUTPUT=${var.filename}",
      "source ../scripts/fuse-nbd",
      "source ../scripts/fuse-tar-root"
    ]
    inline_shebang = "/bin/bash -e"
  }
}
