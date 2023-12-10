variable "iso_path" {
  type    = string
  default = ""
}

source "qemu" "autogenerated_1" {
  accelerator      = "kvm"
  boot_command     = ["<wait2s><enter><wait>"]
  boot_wait        = "-1s"
  communicator     = "none"
  disk_interface   = "ide"
  disk_size        = "20G"
  floppy_files     = ["./http/Autounattend.xml", "./http/logon.ps1", "./http/rh.cer"]
  floppy_label     = "flop"
  format           = "raw"
  headless         = false
  http_directory   = "http"
  iso_checksum     = "none"
  iso_url          = "${var.iso_path}"
  machine_type     = "q35"
  memory           = "4096"
  net_device       = "e1000"
  qemuargs         = [["-serial", "stdio"], ["-bios", "/usr/share/OVMF/OVMF_CODE.fd"]]
  shutdown_timeout = "45m"
  vnc_bind_address = "0.0.0.0"
}

build {
  sources = ["source.qemu.autogenerated_1"]

  post-processor "shell-local" {
    inline         = ["echo 'Syncing output-qemu/packer-qemu...'", "sync -f output-qemu/packer-qemu", "IMG_FMT=raw", "source scripts/setup-nbd", "TMP_DIR=$(mktemp -d /tmp/packer-maas-XXXX)", "echo 'Adding curtin-hooks to image...'", "mount -t ntfs $${nbd}p3 $TMP_DIR", "mkdir -p $TMP_DIR/curtin", "cp ./curtin/* $TMP_DIR/curtin/", "sync -f $TMP_DIR/curtin", "umount $TMP_DIR", "qemu-nbd -d $nbd", "rmdir $TMP_DIR"]
    inline_shebang = "/bin/bash -e"
  }
  post-processor "compress" {
    output = "windows.dd.gz"
  }
}
