// Define Packer Source for QEMU
source "qemu" "debirf-live" {
  iso_url = "/boot-images/debirf-live_bullseye_amd64.iso"
  iso_checksum = "none"
  disk_size = 10240
  output_directory = "output-images"
  vm_name = "debirf-live"
  format = "qcow2"
  accelerator = "kvm"
  http_directory = "http"
  boot_command = [
    "<enter><wait>",
    "linux /boot-images/vmlinuz-6.0.0-0.deb11.6-amd64 auto hostname=debirf-live <wait>",
    "initrd /boot-images/debirf-live_bullseye_6.0.0-0.deb11.6-amd64.cgz <wait>",
    "boot<enter>"
  ]
  ssh_username = "root"
  ssh_password = "install"
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
  provisioner "file" {
    source      = "/buildfiles/APOLLO_PLATFORM-release-3.21.3.0-7+auto15.iso",
    destination = "/opt/APOLLO_PLATFORM-release-3.21.3.0-7+auto15.iso"
  }

  provisioner "file" {
    source      = "/buildfiles/startup.sh"
    destination = "/etc/init.d/startup.sh",

  }
  provisioner "shell" {
    inline = [
      "echo 'Files copied successfully..'"
    ]
  }

  // Post-processors to create new images and prepare for MAAS

  post-processor "qemu" {
    only = ["qemu"]
    output = "output-images/cableos-installer.qcow"
    format = "qcow2"
    disk_interface = "virtio"
  }

  post-processor "shell-local" {
    inline = [
      "qemu-img convert -f qcow2 -O raw cableos-installer.qcow cableos-installer.img",
      "maas admin boot-resources create name=custom/cableos-installer name_title='CableOS Installation Image' architecture=amd64/generic content@=cableos-installer.img"
    ]
  }
}
