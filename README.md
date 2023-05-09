Table of Contents
=================

* [README](#readme)
   * [Installing on CentOS/RHEL 7](#installing-on-centosrhel-7)
   * [Installing on Debian](#installing-on-debian)
   * [Getting started](#getting-started)
      * [Images](#images)

<!-- Created by https://github.com/ekalinin/github-markdown-toc -->

# README

Learning about Singularity (the container platform and not the technological
singularity).

## Installing on CentOS/RHEL 7

[SingularityCE](https://github.com/sylabs/singularity) is the Community Edition
of Singularity.
[Installing](https://github.com/sylabs/singularity/blob/main/INSTALL.md) on
CentOS/RHEL 7.

```console
# Install basic tools for compiling
sudo yum groupinstall -y 'Development Tools'

# Install RPM packages for dependencies
sudo yum install -y \
    libseccomp-devel \
    glib2-devel \
    squashfs-tools \
    cryptsetup \
    runc \
    wget
```

Download Go and add to `PATH`.

```console
export VERSION=1.20.4 OS=linux ARCH=amd64  # change this as you need

wget -O /tmp/go${VERSION}.${OS}-${ARCH}.tar.gz \
  https://dl.google.com/go/go${VERSION}.${OS}-${ARCH}.tar.gz
sudo tar -C /usr/local -xzf /tmp/go${VERSION}.${OS}-${ARCH}.tar.gz

echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
```

Clone repository.

```console
git clone --recurse-submodules https://github.com/sylabs/singularity.git
cd singularity
git checkout --recurse-submodules v3.11.3
```

Configure, build, and install.

```console
./mconfig
make -C builddir
sudo make -C builddir install
```

Check installation.

```console
which singularity
# /usr/local/bin/singularity

singularity --version
# singularity-ce version 3.11.3
```

## Installing on Debian

[Installing](https://github.com/sylabs/singularity/blob/main/INSTALL.md) on
Debian 11.

```console
cat /etc/os-release 
# PRETTY_NAME="Debian GNU/Linux 11 (bullseye)"
# NAME="Debian GNU/Linux"
# VERSION_ID="11"
# VERSION="11 (bullseye)"
# VERSION_CODENAME=bullseye
# ID=debian
# HOME_URL="https://www.debian.org/"
# SUPPORT_URL="https://www.debian.org/support"
# BUG_REPORT_URL="https://bugs.debian.org/"
```

Install dependencies.

```console
# Ensure repositories are up-to-date
sudo apt-get update

# Install debian packages for dependencies
sudo apt-get install -y \
    build-essential \
    libseccomp-dev \
    libglib2.0-dev \
    pkg-config \
    squashfs-tools \
    cryptsetup \
    crun \
    uidmap \
    git \
    wget
```

Download Go and add to `PATH`.

```console
export VERSION=1.20.4 OS=linux ARCH=amd64  # change this as you need

wget -O /tmp/go${VERSION}.${OS}-${ARCH}.tar.gz \
  https://dl.google.com/go/go${VERSION}.${OS}-${ARCH}.tar.gz
sudo tar -C /usr/local -xzf /tmp/go${VERSION}.${OS}-${ARCH}.tar.gz

echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc
```

Clone repository.

```console
git clone --recurse-submodules https://github.com/sylabs/singularity.git
cd singularity
git checkout --recurse-submodules v3.11.3
```

Configure, build, and install.

```console
./mconfig
make -C builddir
sudo make -C builddir install
```

Check installation.

```console
which singularity
# /usr/local/bin/singularity

singularity --version
# singularity-ce version 3.11.3
```

## Getting started

Following the getting started guide from the [Nextflow
tutorial](https://training.nextflow.io/basic_training/containers/#singularity).

Singularity is a container runtime designed to work in high-performance
computing data centers, where the usage of Docker is generally not allowed due
to security reasons.

Singularity implements a container execution model similar to Docker but it
uses a completely different implementation design.

A Singularity container image is archived as a plain file that can be stored in
a shared file system and accessed by many computing nodes managed using a batch
scheduler.

### Images

Singularity images are created using a `Singularity` file similar to a
`Dockerfile` but using a different syntax.

```singularity
Bootstrap: docker
From: debian:bullseye-slim

%environment
export PATH=$PATH:/usr/games/

%labels
AUTHOR <your name>

%post

apt-get update && apt-get install -y locales-all curl cowsay
curl -sSL https://github.com/COMBINE-lab/salmon/releases/download/v1.0.0/salmon-1.0.0_linux_x86_64.tar.gz | tar xz \
&& mv /salmon-*/bin/* /usr/bin/ \
&& mv /salmon-*/lib/* /usr/lib/
```

Create the image, which requires `sudo` permissions. If you do not have `sudo`
access build the image on a machine where you have admin privileges. (I have
used the full path for singularity because `/usr/local/bin` is not in the
`PATH` for `root`.)

```console
singularity build my-image.sif Singularity
# FATAL:   --remote, --fakeroot, or the proot command are required to build this source as a non-root user

/usr/local/bin/singularity build my-image.sif Singularity
# snipped
# INFO:    Adding labels
# INFO:    Adding environment to container
# INFO:    Creating SIF file...
# INFO:    Build complete: my-image.sif

ls -lah my-image.sif
# -rwxr-xr-x. 1 dtang dtang 144M May  9 14:04 my-image.sif
```

Run `cowsay`.

```console
singularity exec my-image.sif cowsay 'Hello Singularity'
#  ___________________
# < Hello Singularity >
#  -------------------
#         \   ^__^
#          \  (oo)\_______
#             (__)\       )\/\
#                 ||----w |
#                 ||     ||
```

Use `shell` for interactive mode.

```console
singularity shell my-image.sif
cat /etc/os-release
# PRETTY_NAME="Debian GNU/Linux 11 (bullseye)"
# NAME="Debian GNU/Linux"
# VERSION_ID="11"
# VERSION="11 (bullseye)"
# VERSION_CODENAME=bullseye
# ID=debian
# HOME_URL="https://www.debian.org/"
# SUPPORT_URL="https://www.debian.org/support"
# BUG_REPORT_URL="https://bugs.debian.org/"
```

Singularity automatically mounts your home and current working directory. In
addition, files created inside the container are owned by you (unlike Docker).

```console
ls /home
# dtang

ls
# LICENSE  my-image.sif  README.md  Singularity

touch test.txt
exit
```

List `test.txt`.

```console
ls -al test.txt
# -rw-rw-r--. 1 dtang dtang 0 May  9 14:11 test.txt

rm test.txt
```

Import a Docker image.

```console
singularity pull docker://davetang/build:23.04
# INFO:    Converting OCI blobs to SIF format
# INFO:    Starting build...
# Getting image source signatures
# Copying blob cdca6f9f82cb done
# Copying blob 7ce21fe1cec0 done
# Copying blob 1d5e550a3240 done
# Copying blob 5ed2aef59034 done
# Copying config a35c69fd06 done
# Writing manifest to image destination
# Storing signatures
# 2023/05/09 14:20:31  info unpack layer: sha256:cdca6f9f82cb2f31168afd36307721605cb5f89b51b97fa630583843ddb624a4
# 2023/05/09 14:20:32  info unpack layer: sha256:1d5e550a324042f3507794112122af6237ddd48f65c93b3155d55f31416bba35
# 2023/05/09 14:20:57  info unpack layer: sha256:5ed2aef5903496318c465752d4345d6aeadd0338b16b45c75a83d012c9ac57eb
# 2023/05/09 14:20:58  info unpack layer: sha256:7ce21fe1cec017cd8bca50c5d7c24c28aca46c6048bc9ba9b8e80beb572cea7c
# INFO:    Creating SIF file...

singularity shell build_23.04.sif
cat /etc/os-release
# PRETTY_NAME="Ubuntu 23.04"
# NAME="Ubuntu"
# VERSION_ID="23.04"
# VERSION="23.04 (Lunar Lobster)"
# VERSION_CODENAME=lunar
# ID=ubuntu
# ID_LIKE=debian
# HOME_URL="https://www.ubuntu.com/"
# SUPPORT_URL="https://help.ubuntu.com/"
# BUG_REPORT_URL="https://bugs.launchpad.net/ubuntu/"
# PRIVACY_POLICY_URL="https://www.ubuntu.com/legal/terms-and-policies/privacy-policy"
# UBUNTU_CODENAME=lunar
# LOGO=ubuntu-logo
```
