
# Harmonic cOS VCMTS Image Documentation

The traditional cable modem termination system (CMTS) has played a key role in facilitating high speed internet access for millions of subscribers. The advent of cloud computing and containerization has caused a shift in access network solutions, with proposals to replace the traditional “integrated” CMTS (iCMTS) with a virtual CMTS (vCMTS), where the hardware-based iCMTS is replaced with open, interoperable, cloud-native and fully containerized applications that deliver the same functionality.

By decoupling the CMTS implementation from the underlying hardware, vCMTS was proposed as a way of providing cable providers the flexibility to update their networks to support next-gen cable modem technologies. (e.g.: DOCSIS 4.0 and Turbo DOCSIS 3.1) without significant hardware replacements,  and to scale-up on demand to support increasing density and demand for higher throughput.

For example, when deployed in a distributed access architecture, where the digital nodes can be placed closer to the homes they serve instead of in the headend, vCMTS can provide improved service with significantly increased density while also reducing headend infrastructure costs.

vCMTS products are available from several companies (Cisco, Harmonic, Arcadyan, Casa Systems, CommScope, Sagemcom, Ubee, Vantiva, Vecima)

Harmonic vCMTS products have been on the market as early as 2018, with Harmonic’s CableOS platform already connected to about 18.4 million modems worldwide.


- [Harmonic cOS VCMTS Image Documentation](#harmonic-cos-vcmts-image-documentation)
  - [Image-Build Dependencies and Prerequisites](#image-build-dependencies-and-prerequisites)
  - [Image-Deployment Requirements](#image-deployment-requirements)
  - [Creating `harmonic-installer` Image](#creating-harmonic-installer-image)
    - [Building the image](#building-the-image)
    - [Accessing external files from you script](#accessing-external-files-from-you-script)
    - [Makefile Parameters](#makefile-parameters)
    - [Default Credentials](#default-credentials)
  - [Importing `harmonic-installer.tar.gz` into MAAS](#importing-harmonic-installertargz-into-maas)
  - [Main configuration script `setup-harmonic-installer.sh`](#main-configuration-script-setup-harmonic-installersh)


## Image-Build Dependencies and Prerequisites

* A machine running Ubuntu 18.04+ with the ability to run KVM virtual machines.
* Packages:
  * qemu-system
  * qemu-utils
  * nbdkit
  * libnbd-bin
  * fuse2fs
  * ovmf
  * cloud-image-utils
  * parted
  * [Packer](https://www.packer.io/intro/getting-started/install.html), v1.7.0 or newer

## Image-Deployment Requirements

* [MAAS](https://maas.io) 3.0+
* [Curtin](https://launchpad.net/curtin) 21.0+



## Creating `harmonic-installer` Image

This Packer template will build a customized `harmonic-installer` image from an official Ubuntu Server cloud-enabled image.

The resulting image can be imported into MAAS and deployed to a bare-metal server, which bootstraps a fully automated CableOS installation.

Upon initial boot, a single-use (*oneshot*) SystemD service that downloads the latest `Apollo` (*Harmonic cOS*) .iso and executes the commands that will write the image content to the system's physical disk.


### Building the image

The image can be built using the following packer commands, however the including Makefile simplifies the process:

- ```shell
  packer init .
  ```
- ```shell
  packer build \
    -var ubuntu_series=${SERIES:=jammy} \
    -var timeout=${TIMEOUT:=1h} \
    -var customize_script=${CUSTOMIZE_SCRIPT:=/dev/null}
   ```

To build the image using Make, simply run:
```shell
make all
```
Set variables as follows:
```shell
make all CUSTOMIZE_SCRIPT=<my_custom_commands.sh>
```

`CUSTOMIZE_SCRIPT` is an optional script to perform additional build steps inside the packer build target.  This can be used to make and test changes to the build process without needing to modify the static build content.


### Accessing external files from you script

Files can be included in your `CUSTOMIZE_SCRIPT` using the HTTP server that Packer creates at build time.
The server IP and port can be accessed using the `PACKER_HTTP_IP` and `PACKER_HTTP_PORT` vars

```shell
!#/bin/bash
#
# Fetch a debian package from the Packer HTTP server and install it.
#

curl http://${PACKER_HTTP_IP}:${PACKER_HTTP_PORT}:/example.deb --output /opt/example.deb

dpkg --install /opt/example.deb

rm -f /opt/example.deb
```


### Makefile Parameters

- PACKER_LOG

Enable (1) or Disable (0) verbose packer logs. The default value is set to 0.

- SERIES

Specify the Ubuntu Series to build. The default value is set to Jammy.

- TIMEOUT

The timeout to apply when building the image. The default value is set to 1h.

- CUSTOMIZE_SCRIPT

Specify path to a script that will be executed inside the Packer build environment.  The default is set to /dev/null


### Default Credentials

The default username and password are set by the `user-data` file when the build VM is started.  You generally will not need to log in to the image unless troubleshooting.

- User: ```root```
- Password: ```ubuntu```

## Importing `harmonic-installer.tar.gz` into MAAS

- Copy the image file to the MAAS server (`44.10.4.101`) and SSH into it.
- Log into the MAAS API using the CLI
  ```shell
  maas login admin http://44.10.4.101:5240/MAAS
  ```
  (*The API Key can be found in the MAAS UI under User settings*)

- Run the command provided at the end of the Packer build process, whiuch will contain correct `sha256sum` and `byte size` values for the new image
  (*If MAAS has been deployed using **Snaps**, then the image file **must** be located in your user's home directory*)

Example (*With embedded commands to insert the correct `sha256sum` and `byte size` values*):
```shell
maas admin boot-resources create \
  name="custom/harmonic" \
  title="Harmonic cOS" \
  architecture="amd64/generic" \
  filetype="tgz" \
  sha256="$(sha256sum harmonic-installer.tar.gz | cut -d ' ' -f1)" \
  size="$(stat -c'%s' harmonic-installer.tar.gz)" \
  content@="harmonic-installer.tar.gz"
```

## Main configuration script `setup-harmonic-installer.sh`
```shell
#!/bin/bash -ex
##############################################################################
#
#   /opt/setup-harmonic-installer.sh
#
# - Install debian packages containing Harmonic wrapper-scripts for OSTree
#
# - Create 'harmonic-install.service' :
#   A single-use (oneshot) SystemD service file that will run on 1st boot.
#
# - Create 'harmonic-installer.sh' :
#   The script executed by 'harmonic-install.service' that fetches the
#   Apollo (Harmonic cOS) .iso file and executes the 'ostree-production'
#   commands that will to write the .iso to the system '/dev/sda' disk.
#
##############################################################################


## Install OSTree wrapper-scripts packages
dpkg -i /opt/ostree-upgrade-bootstrap_2.0.41_all.deb
dpkg -i /opt/ostree-upgrade_2.0.41_all.deb
rm -f /opt/*.deb

## Create systemd service to run on boot
touch /etc/systemd/system/harmonic-install.service
cat > /etc/systemd/system/harmonic-install.service <<EOF
[Unit]
Description=Harmonic cOS Installation Single-Use Startup Script
ConditionFirstBoot=yes

[Service]
Type=oneshot
ExecStart=/usr/local/bin/harmonic-installer.sh -v -i
RemainAfterExit=true
StandardOutput=journal

[Install]
WantedBy=multi-user.target
EOF

## Create script called by systemd service
touch /usr/local/bin/harmonic-installer.sh
cat > /usr/local/bin/harmonic-installer.sh <<EOF
#!/bin/bash -ex
##############################################################################
#
#   /usr/local/bin/harmonic-installer.sh
#
#   This script is executed by 'harmonic-install.service' that fetches the
#   Apollo (Harmonic cOS) .iso file and executes the 'ostree-production'
#   commands that will to write the .iso to the system '/dev/sda' disk.
#
##############################################################################


export WS_HOST="172.22.31.150"
export WS_PORT="8080"
export APOLLO_RELEASE="release-3.21.3.0-7+auto15"
export APOLLO_ISO="APOLLO_PLATFORM-${APOLLO_RELEASE}.iso"
export OSTREE_PKG=ostree-upgrade.tar.gz
export OSTREE_PKGS="ostree-upgrade-bootstrap_2.0.41_all.deb ostree-upgrade_2.0.41_all.deb"
export MAAS_RESOURCE_URL=http://maas.spoc.charterlab.com:5248/images
export PROXY_URL='http://proxy4.spoc.charterlab.com:8080'
export PROXY_IGNORE='spoc.charterlab.com,nfv.charterlab.com,.svc,172.22.73.0/24,35.135.192.0/24,10.240.72.0/22,44.0.0.0/8,[2600:6ce6:4410:803/64],[2605:1c00:50f2:2800/64],[2605:1c00:50f3:70/64],proxy4.spoc.charterlab.com,localhost,127.0.0.1,44.10.4.0/24,44.10.4.101:5240/MAAS,44.10.4.200:5240/MAAS'

export proxy=0
export verbose=0
unset http_proxy
unset https_proxy

showHelp() {
cat << EOT
Usage: $0 [-p|--proxy] [-v|--verbose] [-i|--install] [-h|--help]

Image a physical server with Harmonic cOS

-p|--proxy 	  	Enable the HTTP Proxy
			Note: HTTP Proxy is disabled by default

-v|--verbose 	  	Enable verbose and xtrace mode (set -xv)

-i|--install            Install Apollo (Harmonic cOS) .iso located in /data using ostree scripts

-h|--help               Display help

EOT
}

proxySetup() {
  : "${http_proxy:=${PROXY_URL}}"
  : "${https_proxy:=${PROXY_URL}}"
  : "${no_proxy:=${PROXY_IGNORE}}"

  echo -n "
  http_proxy is set: ${http_proxy}
  https_proxy is set: ${https_proxy}

  no_proxy value is set: ${no_proxy}

  "
}

proxyTeardown() {

  if [[ -n ${http_proxy} ]]; then
    unset http_proxy
    echo "http_proxy unset"
  fi

  if [[ -n ${https_proxy} ]]; then
    unset https_proxy
    echo "https_proxy unset"
  fi

}

ostreeSetup() {

  command -v ostree-production ||
  # # Fetch and install OSTree wrapper-script dpkgs
  for PACKAGE in ${OSTREE_PKGS}; do
    curl "http://${WS_HOST}:${WS_PORT}/packages/${PACKAGE}" --output "/opt/${PACKAGE}" && dpkg -i "/opt/${PACKAGE}"
  done

  # Fetch Harmonic cOS iso
  mkdir /data
  curl "http://${WS_HOST}:${WS_PORT}/apollo/latest" --output "/data/${APOLLO_ISO}"
}

ostreeInstall() {
  ostree-production list-isos
  ostree-production -D /dev/sda from "/data/${APOLLO_ISO}"
}

options=$(getopt -l "help,proxy,verbose,install" -o "hpvi" -- "$@")
eval set -- "${options}"
while true
do
case "$1" in
-h|--help)
    showHelp
    exit 0
    ;;
-p|--proxy)
    export proxy=1
    ;;
-v|--verbose)
    set -xv  # Set xtrace and verbose mode.
    ;;
-i|--install)
    if [[ ${proxy} == 1 ]]; then
      proxySetup
      else
      proxyTeardown
      fi
    ostreeSetup
    ostreeInstall
    #shutdown -r now
    ;;
*)
    showHelp
    exit 1
    ;;
esac
shift
done
EOF

## Fix script ownership
chmod +x /usr/local/bin/harmonic-installer.sh
```
