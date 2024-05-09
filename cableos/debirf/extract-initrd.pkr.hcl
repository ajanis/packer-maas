}
source "null" "dependencies" {
  communicator = "none"
}
build {
  name    = "cableos.deps"
  sources = ["source.null.dependencies"]

  provisioner "shell-local" {
    inline = [
      "cp ${var.source_iso_directory}/${var.debirf_live_bullseye_amd64_iso} ${var.image_path}/"
      "cp ${var.debirf_tmp_path}/${var.debirf_initrd_filename} ${var.image_path}/"
    ]
    inline_shebang = "/bin/bash -e"
  }
}
