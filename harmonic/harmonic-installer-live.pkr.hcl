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

source "qemu" "harmonic-live" {
  boot_command    = ["<wait>e<wait5>", "<down><wait><down><wait><down><wait2><end><wait5>", "<bs><bs><bs><bs><wait>autoinstall ---<wait><f10>"]
  boot_wait       = "2s"
  cpus            = 2
  disk_size       = "8G"
  format          = "raw"
  headless        = var.headless
  http_directory  = var.http_directory
  iso_target_path 	  = "${path.root}/packer-cache/${var.live_iso}"
  iso_url = "https://releases.ubuntu.com/${var.ubuntu_series}/${var.live_iso}"
  iso_checksum    = "file:http://releases.ubuntu.com/${var.ubuntu_series}/SHA256SUMS"
  memory          = 2048
  qemuargs = [
    ["-machine", "ubuntu,accel=kvm"],
    ["-cpu", "host"],
    ["-device", "virtio-gpu-pci"],
    ["-device", "virtio-blk-pci,drive=drive0,bootindex=0"],
    ["-device", "virtio-blk-pci,drive=cdrom0,bootindex=1"],
    ["-device", "virtio-blk-pci,drive=drive1,bootindex=2"],
    ["-drive", "if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE.fd"],
    ["-drive", "if=pflash,format=raw,file=OVMF_VARS.fd"],
    ["-drive", "file=output-harmonic/packer-harmonic-live,if=none,id=drive0,cache=writeback,discard=ignore,format=raw"],
    ["-drive", "file=harmonic-seeds-live.iso,format=raw,cache=none,if=none,id=drive1,readonly=on"],
    ["-drive", "file=${path.root}/packer-cache/${var.live_iso},if=none,id=cdrom0,media=cdrom"]
  ]
  shutdown_command       = "shutdown -P now"
  ssh_handshake_attempts = 500
  ssh_password           = var.ssh_password
  ssh_timeout            = var.timeout
  ssh_username           = "root"
}

build {
  name    = "harmonic-live.image"
  sources = ["source.qemu.harmonic-live"]

  provisioner "file" {
    destination = "/tmp/"
    sources = [
      "${path.root}/scripts/liveiso/curtin-hooks",
      "${path.root}/scripts/liveiso/setup-bootloader"
    ]
  }

  provisioner "file" {
    destination = "/opt/"
    sources = [
      "${path.root}/packages/ostree-upgrade-bootstrap_2.0.41_all.deb",
      "${path.root}/packages/ostree-upgrade_2.0.41_all.deb"
    ]
  }

  provisioner "shell" {
    environment_vars = concat(local.proxy_env, ["DEBIAN_FRONTEND=noninteractive"])
    scripts           = [
      "${path.root}/scripts/liveiso/curtin.sh",
      "${path.root}/scripts/liveiso/networking.sh",
      "${path.root}/scripts/harmonic-install/setup-harmonic-installer.sh",
      "${path.root}/scripts/liveiso/cleanup.sh"
      ]
  }

  post-processor "shell-local" {
    inline = [
      "IMG_FMT=raw",
      "SOURCE=harmonic",
      "ROOT_PARTITION=2",
      "OUTPUT=${var.filename}-live",
      "source ../scripts/fuse-nbd",
      "source ../scripts/fuse-tar-root"
    ]
    inline_shebang = "/bin/bash -e"
  }

#  post-processor "compress" {
#    output = "${var.filename}"
#  }

  post-processor "manifest" {
    output     = "manifest.json"
  }

  post-processor "shell-local" {
    environment_vars  = ["DEBIAN_FRONTEND=noninteractive"]
    scripts           = ["${path.root}/scripts/harmonic-install/maas-import-command.sh"]
  }
}
