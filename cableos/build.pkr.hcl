// Define Packer Source for QEMU
source "qemu" "debirf-live" {
  iso_url = var.debirf_live_bullseye_amd64_iso
  checksum_type = var.checksum_type
  iso_checksum = "md5:1234567890abcdef1234567890abcdef"
  checksum_type = var.debirf_checksum
  disk_size = 10240
  output_directory = "output-debirf-live"
  vm_name = "debirf-live"
  format = "qcow2"
  accelerator = "kvm"
  http_directory = "http"
  boot_command = [
    "<enter><wait>",
    "linux /install/vmlinuz auto hostname=debirf-live <wait>",
    "initrd /install/initrd.gz <wait>",
    "boot<enter>"
  ]
  ssh_username = "root"
  ssh_password = "root"
  ssh_port = 22
  ssh_wait_timeout = "10000s"
  headless = false
}

// Define Build
build {
  sources = [
    "source.qemu.debirf-live"
  ]

  // Provisioners for installation and file extraction
  provisioner "shell" {
    inline = [
      "sudo ostree-production install --source=Apollo.iso --destination=/",
      "sudo cp /boot/vmlinuz* /vmlinuz",
      "sudo cp /boot/initrd.img* /initrd.img"
    ]
  }

  provisioner "file" {
    source = "/vmlinuz"
    destination = "output-debirf-live/vmlinuz"
  }

  provisioner "file" {
    source = "/initrd.img"
    destination = "output-debirf-live/initrd.img"
  }

  // Post-processors to create new images and prepare for MAAS
  post-processor "qemu" {
    only = ["qemu"]
    output = "new.qcow"
    format = "qcow2"
    disk_interface = "virtio"
  }

  post-processor "shell-local" {
    inline = [
      "qemu-img convert -f qcow2 -O raw new.qcow new.img",
      "maas admin boot-resources create name=custom/new name_title='New Image' architecture=amd64/generic content@=new.img"
    ]
  }
}
