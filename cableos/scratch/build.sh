["curtin", "in-target", "--", "/bin/bash", "/root/script.sh"]


I do not add my script to curtin file. I run below command and deploy servers.

maas admin machine deploy $system_id user_data=$(base64s -w0 /root/script.sh)




runcmd:
   - [/bin/scp, user@host:/somewhere/script.sh, /root/]


late_commands:
  run_script: ['/bin/bash', '/root/script.sh']




  sudo mkdir /mnt/loop
sudo mount -o ro,loop,offset=1048576 <nameofdebianimage.raw> /mnt/loop


cd /mnt/loop
sudo tar czvf ~/debian.tgz .
sudo umount /mnt/loop


cd ~
maas login your.user http://<maasserver>:5240/MAAS 'user:credentials'
maas your.user boot-resources create name=custom/debian title="debian" architecture=amd64/generic content@=debian.tgz
root@maas:~/custom-oses# mkdir /mnt/custom-os-loop
root@maas:~/custom-oses# mount -o rw,loop,offset=1048576,sync debian-9.7.0-openstack-amd64.raw /mnt/custom-os-loop
root@maas:~/custom-oses# chroot /mnt/custom-os-loop
root@maas:/# echo "deb http://ftp.debian.org/debian buster main contrib non-free" >> /etc/apt/sources.list
root@maas:/# apt update
root@maas:/# exit
root@maas:~/custom-oses# umount /mnt/custom-os-loop
