#!/bin/bash -x



export webserverHost="172.22.31.150"
export webserverPort="8080"
export apolloRelease="release-3.21.3.0-7+auto15"
export apolloISO="APOLLO_PLATFORM-${apolloRelease}.iso"
export ostreePackages="ostree-upgrade-bootstrap_2.0.41_all.deb ostree-upgrade_2.0.41_all.deb"
export proxyURI="http://proxy4.spoc.charterlab.com:8080"
export proxyIgnore="localhost,127.0.0.1,127.0.0.53,spoc.charterlab.com,nfv.charterlab.com,proxy4.spoc.charterlab.com,44.10.4.101/32,44.10.4.200/32,172.22.0.0/16"
export workingDir="/opt/apollo-image-mod"
export isoDir="${workingDir}/iso"
export physicalDisk="/dev/sda"
export proxy=0
export download=0

runPrint() {
cat << EOF
===========================================================
  $@
===========================================================
EOF
}

# Set up script logging
: > /var/log/apollo
exec 2> >(tee -a /var/log/apollo >&2) > >(tee -a /var/log/apollo)


harmonicSetup() {
  if [[ ! -e "${workingDir}/${apolloISO}" ]]; then  
    runPrint "Downloading ${apolloISO} to ${workingDir}"
    wget "http://${webserverHost}:${webserverPort}/apollo/latest" -O "${workingDir}/${apolloISO}"
    fi
  return
}
ostreeSetup() {
  for debPkg in ${ostreePackages}; do
    wget "http://${webserverHost}:${webserverPort}/packages/${debPkg}" -O "${workingDir}/${debPkg}"
    runPrint "Installing ${debPkg}"
    dpkg -i "${workingDir}/${debPkg}"
  done
  return
}


chrootSetup() {
  runPrint "Creating ${isoDir}"
  mkdir -p "${isoDir}"
  runPrint "Extracting ${apolloIso}"
  guestfish -a "${workingDir}/${apolloISO}" -m "${physicalDisk}" tar-out / - | tar -C "${isoDir}" xvf - || true
  mount -t squashfs "${isoDir}/rootfs.squashfs" "${workingDir}/rootfs"
  mount -o bind /dev "${isoDir}/rootfs/dev/"
  mount -t proc none "${isoDir}/rootfs/proc/"
  mount -o bind /sys "${isoDir}/rootfs/sys/"
  return
}


chrootCommands() {
chroot "${workingDir}/rootfs" /bin/bash -x << '_END_CHROOT_'
useradd -G sudo -s /bin/bash -m -d /home/charter -p '$6$.CxHcX.s.3z3xZDz$Ir/9q6UADNOz6o5VUsHu41gjAQETOo3BZMxisInlsLs1xKbZ4p4zd/cu5II6OJKkJBt8o7K1MxJp/otdaEiL20' charter


}




# guestfish -a  -m /dev/sda tar-out / - | tar xvf -
 
#  set -e
 
#  guestfish[0]="guestfish"
#  guestfish[1]="--listen"
#  guestfish[2]="--ro"
#  guestfish[3]="-a"
#  guestfish[4]="disk.img"
 
#  GUESTFISH_PID=
#  eval $("${guestfish[@]}")
#  if [ -z "$GUESTFISH_PID" ]; then
#      echo "error: guestfish didn't start up, see error messages above"
#      exit 1
#  fi
 
#  cleanup_guestfish ()
#  {
#      guestfish --remote -- exit >/dev/null 2>&1 ||:
#  }
#  trap cleanup_guestfish EXIT ERR
 
#  guestfish --remote -- run
 
 # ...

# guestfish -a boot.iso -m /dev/sda edit /isolinux/isolinux.cfg
# mkdir /tmp/iso
# cd /tmp/iso
# guestfish -a ../boot.iso -m /dev/sda tar-out / - | tar xvf -
# vi isolinux/isolinux.cfg
# mkisofs [flags - see comments] -o ../newboot.iso .



# #!/usr/bin/guestfish -f
#  sparse test1.img 100M
#  run
#  part-disk /dev/sda mbr
#  mkfs ext2 /dev/sda1


#  $ guestfish
 
#  Welcome to guestfish, the guest filesystem shell for
#  editing virtual machine filesystems.
 
#  Type: 'help' for a list of commands
#        'man' to read the manual
#        'quit' to quit the shell
 
#  ><fs> add-ro disk.img
#  ><fs> run
#  ><fs> list-filesystems
#  add-ro Fedora-11-i686-Live.iso
#  run
#  mkmountpoint /cd
#  mkmountpoint /sqsh
#  mkmountpoint /ext3fs
#  mount /dev/sda /cd
#  mount-loop /cd/LiveOS/squashfs.img /sqsh
#  mount-loop /sqsh/LiveOS/ext3fs.img /ext3fs
#  /dev/sda1: ext4
#  /dev/vg_guest/lv_root: ext4
#  /dev/vg_guest/lv_swap: swap
#  ><fs> mount /dev/vg_guest/lv_root /
#  ><fs> cat /etc/fstab
#  # /etc/fstab
#  # Created by anaconda
#  [...]
#  ><fs> exit



#!/bin/sh
#
# Create a rootfs environment for chroot building.
#
# Requires 
# - OS installing CDROM at the current directory,
# - the root authority.
#

# mount install cd
mkdir /mnt/cdrom
mount CentOS-7-x86_64-Minimal-1503-01.iso /mnt/cdrom -t iso9660 -o loop

# mount squashfs
mkdir /mnt/squashfs
mount /mnt/cdrom/LiveOS/squashfs.img /mnt/squashfs -t squashfs

# mount rootfs
mkdir /mnt/rootfs
mount /mnt/squashfs/LiveOS/rootfs.img /mnt/rootfs -t ext4

# copy rootfs
cp -r /mnt/rootfs rootfs
umount /mnt/rootfs
umount /mnt/squashfs
umount /mnt/cdrom
rm -r /mnt/rootfs /mnt/squashfs /mnt/cdrom

# mount dvd image under rootfs
mkdir rootfs/mnt/cdrom
mount CentOS-7-x86_64-Minimal-1503-01.iso rootfs/mnt/cdrom -t iso9660 -o loop

# chroot
mount -o bind /dev rootfs/dev/
mount -t proc none rootfs/proc/
mount -o bind /sys rootfs/sys/
chroot rootfs /bin/bash -xe << _END_CHROOT_
cd /mnt/cdrom/Packages
rpm -ivh --nodeps rpm-4.11.1-25.el7.x86_64.rpm
rpm -ivh --nodeps yum-3.4.3-125.el7.centos.noarch.rpm
# add the cdrom image to yum repository
cat << _END_ > /etc/yum.repos.d/cdrom.repo
[cdrom]
name=Install CD-ROM 
baseurl=file:///mnt/cdrom
enabled=0
gpgcheck=1
gpgkey=file:///mnt/cdrom/RPM-GPG-KEY-CentOS-7
_END_
yum --disablerepo=\* --enablerepo=cdrom -y reinstall yum
yum --disablerepo=\* --enablerepo=cdrom -y groupinstall "Minimal Install"
# yum --disablerepo=\* --enablerepo=cdrom -y install <required packages>
rm /etc/yum.repos.d/cdrom.repo
_END_CHROOT_

# Clean up
umount rootfs/mnt/cdrom
umount rootfs/dev
umount rootfs/proc
umount rootfs/sys