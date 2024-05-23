# xorriso.md
```shell
sudo xorriso -indev "<image name>" -report_el_torito cmd

sudo xorriso -indev "ubuntu-22.04.1-desktop-amd64.iso" -report_el_torito cmd

sudo xorriso -outdev MyDistribution.iso -map extracted / -- -volid "MyDistribution 1.1 Ubuntu Remix amd64" -boot_image grub grub2_mbr=mbr.img -boot_image any partition_table=on -boot_image any partition_cyl_align=off -boot_image any partition_offset=16 -boot_image any mbr_force_bootable=on -append_partition 2 28732ac11ff8d211ba4b00a0c93ec93b EFI.img -boot_image any appended_part_as=gpt -boot_image any iso_mbr_part_type=a2a0d0ebe5b9334487c068b6b72699c7 -boot_image any cat_path='/boot.catalog' -boot_image grub bin_path='/boot/grub/i386-pc/eltorito.img' -boot_image any platform_id=0x00 -boot_image any emul_type=no_emulation -boot_image any load_size=2048 -boot_image any boot_info_table=on -boot_image grub grub2_boot_info=on -boot_image any next -boot_image any efi_path=--interval:appended_partition_2:all:: -boot_image any platform_id=0xef -boot_image any emul_type=no_emulation -boot_image any load_size=4349952
```


xorriso -outdev debirf-live-repack_bullseye_amd64.iso -map cableos-live / -- -volid 'DEBIAN_LIVE' -volume_date uuid '2023011116485500' -boot_image grub grub2_mbr=--interval:imported_iso:0s-15s:zero_mbrpt:'./debirf-live_bullseye_amd64.iso' -boot_image any partition_cyl_align=off -boot_image any partition_offset=0 -boot_image any partition_hd_cyl=64 -boot_image any partition_sec_hd=32 -boot_image any mbr_force_bootable=on -append_partition 2 0xef --interval:imported_iso:318756d-339235d::'./debirf-live_bullseye_amd64.iso' -boot_image any iso_mbr_part_type=0x83 -boot_image any cat_path='/boot/grub/boot.cat' -boot_image grub bin_path='/boot/grub/bios.img' -boot_image any platform_id=0x00 -boot_image any emul_type=no_emulation -boot_image any load_size=2048 -boot_image any boot_info_table=on -boot_image grub grub2_boot_info=on -boot_image any next -boot_image any efi_path='/EFI/efiboot.img' -boot_image any platform_id=0xef -boot_image any emul_type=no_emulation -boot_image any load_size=10485760
