#!/bin/bash
echo "==================================================================="
echo "Harmonic Installer: Setup"
echo "==================================================================="
echo "Harmonic Installer: Downloading 'harmonic-installer.sh'"
echo "==================================================================="
if (sudo wget https://artifactory.charterlab.com:443/artifactory/upload/harmonic/scripts/harmonic-installer.sh -O /opt/harmonic-installer.sh && sudo chmod +x /opt/harmonic-installer.sh); then
  echo "Harmonic Installer: Running"
  else
  echo "Harmonic Installer: Failed to download 'harmonic-installer.sh'"
  exit 1
  fi
echo "==================================================================="
if (sudo /opt/harmonic-installer.sh -ip); then
  echo "==================================================================="
  echo "Harmonic Installer: Installation Complete"
  else
  echo "==================================================================="
  echo "Harmonic Installer: Installation Failed"
  exit 1
  fi
