#!/bin/bash -x
echo "---------------- Harmonic Installer - Environment Setup Starting -----------------"
echo "---------------- Harmonic Installer - Fix root authorized_keys  -----------------"
sed -r -i 's/^.+(ssh-.+)$/\1/' /root/.ssh/authorized_keys
echo "---------------- Harmonic Installer - Create working directory -----------------"
echo "---------------- Harmonic Installer - Install Script (DOWNLOAD) -----------------"
wget https://artifactory.charterlab.com:443/artifactory/upload/harmonic/scripts/harmonic-installer.sh -O /opt/harmonic-installer.sh
chmod +x /opt/harmonic-installer.sh
echo "---------------- Harmonic Installer - Environment Setup Complete -----------------"
echo "---------------- Harmonic Installer - Installation Process Starting-----------------"
echo "---------------- Harmonic Installer - Install Script (RUNNING) -----------------"
/opt/harmonic-installer.sh -vip
echo "------------------- Harmonic Installer - Install Script (COMPLETED) ------------------"
wget --no-proxy {{ node_disable_pxe_url | escape.json }} --post-data {{ node_disable_pxe_data|escape.json }} -O /dev/null || true
echo "------------------- Harmonic Installer - Installation Process Complete------------------"
echo "------------------- Harmonic Installer - Rebooting System ------------------"
systemctl --message="Harmonic Post-Install Reboot" reboot