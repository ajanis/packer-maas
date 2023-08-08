#!/bin/sh

echo 'Adding curtin-hooks to image...'
mount_part 1 $TMP_DIR/boot fusefat
cp -rv curtin $TMP_DIR/boot/

echo 'Adding post-install scripts to image...'
cp -v scripts.tar.xz $TMP_DIR/boot/curtin/

echo 'Unmounting image...'
sync -f $TMP_DIR/boot
fusermount -u $TMP_DIR/boot
