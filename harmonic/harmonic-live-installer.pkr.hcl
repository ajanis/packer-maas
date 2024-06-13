source "qemu" "harmonic-live" {
  boot_command = [
    "<spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait>",
    "e<wait>",
    "<down><down><down><end>",
    " autoinstall",
    "<f10>"
  ]
  boot_wait        = "2s"
  cpus             = 2
  memory           = 2048
  format           = "raw"
  disk_size        = "8G"
  headless         = var.headless
  vnc_bind_address = "0.0.0.0"
  http_directory   = var.http_directory
  iso_target_path  = "${path.root}/packer-cache/${var.live_iso}"
  iso_url          = "https://releases.ubuntu.com/${var.ubuntu_series}/${var.live_iso}"
  iso_checksum     = "file:http://releases.ubuntu.com/${var.ubuntu_series}/SHA256SUMS"
  # output_directory = "output-${var.vm_name}-live/${var.vm_name}-live"
  efi_firmware_code = "/usr/share/OVMF/OVMF_CODE.fd"
  efi_firmware_vars = "${path.root}/OVMF_VARS.fd"
  efi_boot          = true
  qemuargs = [
    ["-machine", "ubuntu,accel=kvm"],
    ["-cpu", "host"],
    ["-device", "virtio-gpu-pci"],
    ["-device", "virtio-blk-pci,drive=drive0,bootindex=0"],
    ["-device", "virtio-blk-pci,drive=cdrom0,bootindex=1"],
    ["-device", "virtio-blk-pci,drive=drive1,bootindex=2"],
    ["-drive", "if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE.fd"],
    ["-drive", "if=pflash,format=raw,file=OVMF_VARS.fd"],
    ["-drive", "file=${path.root}/output-${var.vm_name}/packer-${var.vm_name},if=none,id=drive0,cache=writeback,discard=ignore,format=raw"],
    ["-drive", "file=harmonic-seeds.iso,format=raw,cache=none,if=none,id=drive1,readonly=on"],
    ["-drive", "file=${path.root}/packer-cache/${var.live_iso},if=none,id=cdrom0,media=cdrom"]
  ]
  shutdown_command       = var.shutdown
  ssh_handshake_attempts = 500
  ssh_password           = var.ssh_password
  ssh_timeout            = var.timeout
  ssh_username           = var.ssh_username
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

  provisioner "shell" {
    environment_vars  = ["HOME_DIR=/home/ubuntu", "http_proxy=${var.http_proxy}", "https_proxy=${var.https_proxy}", "no_proxy=${var.no_proxy}"]
    execute_command   = "echo 'ubuntu' | {{ .Vars }} sudo -S -E sh -eux '{{ .Path }}'"
    expect_disconnect = true
    scripts = [
      "${path.root}/scripts/liveiso/curtin.sh",
      "${path.root}/scripts/liveiso/networking.sh",
      "${path.root}/scripts/liveiso/cleanup.sh"
    ]
  }

  provisioner "file" {
    destination = "/media/root-rw"
    sources = [
      "${path.root}/packages/ostree-upgrade-bootstrap_2.0.41_all.deb",
      "${path.root}/packages/ostree-upgrade_2.0.41_all.deb",
      "${path.root}/scripts/harmonic-install/setup-harmonic-installer.sh",
    ]
  }


  # post-processor "compress" {
  #   output = "harmonic-live.tar.gz"
  # }

  post-processor "shell-local" {
    inline = [
      "SOURCE=${var.vm_name}",
      "IMG_FMT=raw",
      "ROOT_PARTITION=2",
      "OUTPUT=${path.root}/${var.vm_filename}",
      "source ../scripts/fuse-nbd",
      "source ../scripts/fuse-tar-root"
    ]
    inline_shebang = "/bin/bash -e"
  }

  post-processor "manifest" {
    output = "manifest.json"
  }

  post-processor "shell-local" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
    scripts          = ["${path.root}/scripts/harmonic-install/maas-import-command.sh"]
  }
}
