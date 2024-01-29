Table of Contents
=================

* [README](#readme)
   * [TL;DR](#tldr)
   * [Installation](#installation)
      * [CentOS/RHEL 7](#centosrhel-7)
      * [Debian 11](#debian-11)
      * [General steps](#general-steps)
   * [Getting started](#getting-started)
      * [Images](#images)
   * [BioContainers](#biocontainers)
   * [Troubleshooting](#troubleshooting)

<!-- Created by https://github.com/ekalinin/github-markdown-toc -->

# README

Learning about Singularity (the container platform and not the technological
singularity).

## TL;DR

[Hello World example](https://carpentries-incubator.github.io/singularity-introduction/01-singularity-gettingstarted/index.html).

```console
mkdir test
cd test
singularity pull hello-world.sif shub://vsoch/hello-world
singularity run hello-world.sif
# RaawwWWWWWRRRR!! Avocado!
```

The image is hosted on [DataLad](https://datasets.datalad.org/?dir=/shub/vsoch/hello-world/latest/2021-04-19-3bac21df-104932c9/) because [Singularity Hub is  no longer maintained](https://singularityhub.github.io/singularityhub-docs/2021/going-read-only/).

Check what an image will RUN by default.

```console
singularity inspect -r hello-world.sif

# #!/bin/sh
#
# exec /bin/bash /rawr.sh
```

Execute a command.

```console
singularity exec hello-world.sif cat /rawr.sh

# #!/bin/bash
#
# echo "RaawwWWWWWRRRR!! Avocado!"
```

`singularity` will automatically mount the current directory and files created
inside the container will be owned by your host user.

Import Docker image; image will be saved as `tidyverse_4.3.2.sif`.

```console
singularity pull docker://rocker/tidyverse:4.3.2
```

Run container.

```console
singularity exec tidyverse_4.3.2.sif R
```

Run a shell within a container.

```console
singularity shell tidyverse_4.3.2.sif

echo $SHELL
# /bin/bash
```

[Mount path](https://docs.sylabs.io/guides/3.7/user-guide/bind_paths_and_mounts.html) using `--bind`.

```console
singularity exec --bind ${HOME}/github/learning_singularity:/mnt my-image.sif ls -1 /mnt
# LICENSE
# my-image.sif
# README.md
# Singularity
```

[Documentation and examples](https://sylabs.io/docs/).

## Installation

[SingularityCE](https://github.com/sylabs/singularity) is the Community Edition
of Singularity and is licensed under a [BSD
3-Clause](https://github.com/sylabs/singularity/blob/main/LICENSE.md).
Installation is the same for different flavours of Linux except when installing
dependencies since different distros use different package managers.

### CentOS/RHEL 7

[Installing](https://github.com/sylabs/singularity/blob/main/INSTALL.md) on
CentOS/RHEL 7. (I have left out Git, so please include it back if you do not
have Git installed.)

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

### Debian 11

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

### General steps

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
`Dockerfile` but using a different syntax. See [Singularity Definition file versus Dockerfile](https://docs.sylabs.io/guides/3.7/user-guide/singularity_and_docker.html#singularity-definition-file-vs-dockerfile).

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

sudo /usr/local/bin/singularity build my-image.sif Singularity
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

## BioContainers

Run
[BioContainers](https://biocontainers-edu.readthedocs.io/en/latest/what_is_biocontainers.html)
containers. To look for a container, go to the [BioContainers organisation
page](https://quay.io/organization/biocontainers) and wait for all the
containers to load on the page; this takes several minutes because there's a
lot of containers, so go get a tasty beverage while the page loads. (There are
11,073 containers as of 2023/06/06.) Once it finishes loading, you can quickly
search for a tool of interest.

SAMtools.

```console
singularity pull docker://quay.io/biocontainers/samtools:1.17--hd87286a_1
wget https://github.com/davetang/learning_bam_file/raw/main/eg/ERR188273_chrX.bam

singularity exec samtools_1.17--hd87286a_1.sif samtools flagstat ERR188273_chrX.bam
# 1176360 + 0 in total (QC-passed reads + QC-failed reads)
# 1160084 + 0 primary
# 16276 + 0 secondary
# 0 + 0 supplementary
# 0 + 0 duplicates
# 0 + 0 primary duplicates
# 1126961 + 0 mapped (95.80% : N/A)
# 1110685 + 0 primary mapped (95.74% : N/A)
# 1160084 + 0 paired in sequencing
# 580042 + 0 read1
# 580042 + 0 read2
# 1060858 + 0 properly paired (91.45% : N/A)
# 1065618 + 0 with itself and mate mapped
# 45067 + 0 singletons (3.88% : N/A)
# 0 + 0 with mate mapped to a different chr
# 0 + 0 with mate mapped to a different chr (mapQ>=5)
```

BCFtools.

```console
singularity pull docker://quay.io/biocontainers/bcftools:1.17--h3cc50cf_1
wget https://github.com/davetang/learning_vcf_file/raw/main/eg/1001genomes_snp-short-indel_only_ACGTN_5000.vcf.gz

singularity exec bcftools_1.17--h3cc50cf_1.sif bcftools stats 1001genomes_snp-short-indel_only_ACGTN_5000.vcf.gz | tail -6
# [W::vcf_parse] Contig '1' is not defined in the header. (Quick workaround: index the file with tabix.)
# # DP, Depth distribution
# # DP    [2]id   [3]bin  [4]number of genotypes  [5]fraction of genotypes (%)    [6]number of sites      [7]fraction of sites (%)
# DP      0       98      0       0.000000        1       0.020036
# DP      0       242     0       0.000000        1       0.020036
# DP      0       457     0       0.000000        1       0.020036
# DP      0       >500    0       0.000000        4988    99.939892
```

MEME.

```console
singularity pull docker://quay.io/biocontainers/meme:5.5.2--py310pl5321h2bc4914_1
singularity exec meme_5.5.2--py310pl5321h2bc4914_1.sif meme -version
# 5.5.2
```

## Troubleshooting

If you get a "No space left on device error", check the size of `/tmp`
directory. Singularity [will
use](https://docs.sylabs.io/guides/2.5/user-guide/troubleshooting.html#no-space-left-on-device)
the `TMPDIR` environment variable, so set it to a location with more space.

```console
export TMPDIR=$HOME/tmp
```
