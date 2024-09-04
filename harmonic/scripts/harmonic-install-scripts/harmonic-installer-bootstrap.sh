#!/bin/bash -x

echo "====================================================================================="
echo "Harmonic Installer: Setup"
echo "Harmonic Installer: Download 'harmonic-installer.sh' from Artifactory"
wget https://artifactory.charterlab.com:443/artifactory/upload/harmonic/scripts/harmonic-installer.sh -O /opt/harmonic-installer.sh
chmod +x /opt/harmonic-installer.sh
echo "Harmonic Installer: Running"
/opt/harmonic-installer.sh -vip
echo "Harmonic Installer: Complete"
echo "Harmonic Installer: Rebooting System"
systemctl --message="Harmonic Post-Install Reboot" reboot
echo "======================================================================================"



