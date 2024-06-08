
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
  - [Variables and Defaults, Required package installation](#variables-and-defaults-required-package-installation)
    - [Step 1: Extract the ISO file](#step-1-extract-the-iso-file)
    - [Step 2: Extract debirf-live.cgz](#step-2-extract-debirf-livecgz)
    - [Step 3: Extract roots.cxz](#step-3-extract-rootscxz)
    - [Step 4: Add custom files](#step-4-add-custom-files)
    - [Step 5: Repack the root filesystem](#step-5-repack-the-root-filesystem)
    - [Step 6: Repack debirf-live.cgz](#step-6-repack-debirf-livecgz)
    - [Step 7: Recreate the ISO](#step-7-recreate-the-iso)
  - [Complete Auto-Build Script](#complete-auto-build-script)


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

- ```packer init .```
- ```packer build -var architecture=${ARCH:=amd64} -var ubuntu_series=${SERIES:=jammy} -var timeout=${TIMEOUT:=1h} -var customize_script=${CUSTOMIZE_SCRIPT:=/dev/null}```

To build the image using Make, simply run:
```shell
make all
```
Set variables as follows:
```shell
make all CUSTOMIZE_SCRIPT=<my_custom_commands.sh>
```

`CUSTOMIZE_SCRIPT` is an optional script to perform additional build steps inside the packer build target.  This can be used to make and test changes to the build process without needing to modify the static build content.


#### Accessing external files from you script

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


#### Makefile Parameters

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

Copy the image file to the MAAS server (`44.10.4.101`)

If MAAS has been deployed using **Snaps**, *the image file must be located in your user's home directory*


```shell
maas admin boot-resources create \
  name="custom/harmonic" \
  title="Harmonic cOS" \
  architecture="amd64/generic" \
  filetype="tgz" \
  sha256="$(sha256sum harmonic-installer.tar.gz | cut -d ' ' -f1)" \
  size="$(stat -c'%s' harmonic-installer.tar.gz)" \
  content@='harmonic-installer.tar.gz'
```

## Main configuration script `setup-harmonic-installer.sh`
