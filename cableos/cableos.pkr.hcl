


source "qemu" "debirf" {
  boot_command = {
        "<esc><wait>",
        "linux /casper/vmlinuz boot=casper initrd=/casper/initrd quiet -- <enter>",
        "initrd /casper/initrd<enter>",
        "boot<enter>"
      ],  boot_wait        = "3s"
  communicator     = "none"
  disk_size        = "4G"
  headless         = var.headless
  iso_checksum     = "none"
  iso_url          = "${var.cableos_iso_url}"
  memory           = 2048
  qemuargs         = [["-serial", "stdio"], ["-cpu", "host"]]
  shutdown_timeout = var.timeout
  ssh_username = "ubuntu"
  ssh_password = "ubuntu"
  ssh_wait_timeout = "10000s"
  http_content = {
    "/cableos.ks" = templatefile("${var.http_path}/cableos.ks.pkrtpl.hcl",
      {
        KS_PROXY           = local.ks_proxy
      }
    )
  }
}


build {
  sources = ["source.qemu.cableos"]

  post-processor "shell-local" {
    inline = [
      "SOURCE=sles15",
      "ROOT_PARTITION=2",
      "OUTPUT=${var.filename}",
      "source ../scripts/fuse-nbd",
      "source ../scripts/fuse-tar-root"
    ]
    inline_shebang = "/bin/bash -e"
  }
}
q
