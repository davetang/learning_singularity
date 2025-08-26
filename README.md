## Table of Contents

- [README](#readme)
  - [Fork](#fork)
  - [TL;DR](#tldr)
  - [Installation](#installation)
    - [CentOS/RHEL 7](#centosrhel-7)
    - [Debian](#debian)
    - [General steps](#general-steps)
    - [Docker](#docker)
    - [Apple Silicon](#apple-silicon)
  - [Apptainer](#apptainer)
    - [Debian](#debian)
  - [Getting started](#getting-started)
    - [Images](#images)
  - [Definition file](#definition-file)
  - [BioContainers](#biocontainers)
  - [Running services](#running-services)
  - [Isolation](#isolation)
  - [Limiting Container Resources](#limiting-container-resources)
  - [Troubleshooting](#troubleshooting)
  - [Tips](#tips)

# README

Learning about Singularity (the container platform and not the technological
singularity).

## Fork

Singularity forked into
[Apptainer](https://apptainer.org/news/community-announcement-20211130/) and
[SingularityCE](https://sylabs.io/singularity/). Most of my notes here were
written before I knew about the fork and are based on using SingularityCE.

The Hello World example works the same for `apptainer`.

```console
wget https://github.com/apptainer/apptainer/releases/download/v1.2.5/apptainer_1.2.5_amd64.deb
sudo apt install ./apptainer_1.2.5_amd64.deb

apptainer pull hello-world.sif shub://vsoch/hello-world
apptainer run hello-world.sif
# RaawwWWWWWRRRR!! Avocado!
```

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

Build an image, where `minimal.sif` is the image name and `bookworm_slim.def`
is the Definition File, which is like the Dockerfile for Docker..

```console
singularity build --fakeroot --force minimal.sif bookworm_slim.def
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

### Debian

[Installing](https://github.com/sylabs/singularity/blob/main/INSTALL.md) on
Debian.

```console
cat /etc/os-release
```
```
PRETTY_NAME="Debian GNU/Linux 12 (bookworm)"
NAME="Debian GNU/Linux"
VERSION_ID="12"
VERSION="12 (bookworm)"
VERSION_CODENAME=bookworm
ID=debian
HOME_URL="https://www.debian.org/"
SUPPORT_URL="https://www.debian.org/support"
BUG_REPORT_URL="https://bugs.debian.org/"
```

Install dependencies.

```console
# Ensure repositories are up-to-date
sudo apt-get update
# Install debian packages for dependencies
sudo apt-get install -y \
    autoconf \
    automake \
    cryptsetup \
    fuse2fs \
    git \
    fuse \
    libfuse-dev \
    libglib2.0-dev \
    libseccomp-dev \
    libtool \
    pkg-config \
    runc \
    squashfs-tools \
    squashfs-tools-ng \
    uidmap \
    wget \
    zlib1g-dev
```

### General steps

Download Go and add to `PATH`.

```console
export VERSION=1.21.6 OS=linux ARCH=amd64  # change this as you need

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
git checkout --recurse-submodules v4.1.1
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
# singularity-ce version 4.1.1
```

### Docker

It never occurred to me that you could use Singularity inside Docker!

```console
docker run --rm quay.io/singularity/singularity:v4.1.0 version
# 4.1.0
```

However to build images using the Dockerised Singularity, you need to run
`docker` in privileged mode.

```console
docker run --privileged --rm -it --entrypoint /bin/bash -v $(pwd):$(pwd) -w $(pwd) quay.io/singularity/singularity:v4.1.0

singularity build test.sif Singularity
```

### Apple Silicon

[Installing SingularityCE on macOS with Apple Silicon using UTM and Rocky Linux](https://sylabs.io/2023/03/installing-singularityce-on-macos-with-apple-silicon-using-utm-rocky/).

1. Download [UTM](https://mac.getutm.app/)
2. Download [Rocky Linux ISO image](https://rockylinux.org/)
3. Installing an arm64 Linux VM with UTM
4. Use [DNF](https://docs.fedoraproject.org/en-US/quick-docs/dnf/) to install Singularity

```console
sudo dnf install epel-release
sudo dnf install singularity-ce
singularity --version
singularity run library://lolcow
```

[Alternatively](https://docs.sylabs.io/guides/4.1/admin-guide/installation.html#mac), use the [Lima](https://github.com/lima-vm/lima) VM platform.

1. Install [Homebrew](https://brew.sh/)

```console
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. Install Lima.

```console
brew install lima
```

3. Download example template for using SingularityCE with Lima. The template

* Is based on AlmaLinux 9.
* Supports both Intel and Apple Silicon (ARM64) Macs.
* Installs the latest stable release of SingularityCE that has been published to the Fedora EPEL repositories.

```console
wget https://raw.githubusercontent.com/sylabs/singularity/main/examples/lima/singularity-ce.yml
```

4. Start a Lima VM:

```console
limactl start ./singularity-ce.yml
```

5. Run `singularity` inside your Lima VM:

```console
limactl shell singularity-ce singularity run library://alpine
```

Build images.

```console
limactl shell singularity-ce singularity build --fakeroot test.sif bookworm_slim.def
```
```
FATAL:   While performing build: while creating SIF: while creating container: open test.sif: read-only file system
```

Use `sudo`.

```console
sudo limactl shell singularity-ce singularity build --fakeroot test.sif bookworm_slim.def
```
```
FATA[0000] must not run as the root
```

Edit `vi ~/.lima/singularity-ce/lima.yaml` and add writable to `/tmp/lima`.

```
mounts:
  - location: "~"
  - location: "/tmp/lima"
    writable: true
```

Restart Lima.

```console
limactl stop singularity-ce
limactl start singularity-ce
```

Build in `/tmp/lima`.

```console
limactl shell singularity-ce singularity build --fakeroot /tmp/lima/test.sif bookworm_slim.def
```

Success!

```
limactl shell singularity-ce singularity shell /tmp/lima/test.sif
```

## Apptainer

> [Apptainer](https://apptainer.org/docs/user/latest/introduction.html) is a container platform. It allows you to create and run containers that package up pieces of software in a way that is portable and reproducible. You can build a container using Apptainer on your laptop, and then run it on many of the largest HPC clusters in the world, local university or company clusters, a single server, in the cloud, or on a workstation down the hall. Your container is a single file, and you don’t have to worry about how to install all the software you need on each different operating system.

### Debian

[Install](https://apptainer.org/docs/admin/main/installation.html#install-debian-packages) using pre-built Debian packages (only available on GitHub and only for the amd64 architecture).

```console
cd /tmp
wget https://github.com/apptainer/apptainer/releases/download/v1.4.1/apptainer_1.4.1_amd64.deb
sudo apt install -y ./apptainer_1.4.1_amd64.deb
rm apptainer_1.4.1_amd64.deb

apptainer version
```
```
1.4.1
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

There are two ways to building Singularity images:

1. Building within a sandbox: build a container interactively within a sandbox
   environment
2. Building using a Singularity Definition File, which should be preferred
   since this is more reproducible.

The [Singularity Definition
File](https://docs.sylabs.io/guides/latest/user-guide/definition_files.html) is
similar to the `Dockerfile` for Docker but uses a different syntax. See
[Singularity Definition file versus
Dockerfile](https://docs.sylabs.io/guides/3.7/user-guide/singularity_and_docker.html#singularity-definition-file-vs-dockerfile).

Sections (a.k.a. scriptlets or blobs) in the definition file are specified
using a `%` prefix followed by the name of the section and are optional.

```singularity
Bootstrap: docker
From: ubuntu:20.04

%post
    apt-get -y update && apt-get install -y python

%runscript
    python -c 'print("Hello World!")'
```

The first two lines specify where to bootstrap our image from. ([In
computing](https://stackoverflow.com/a/1254561), a bootstrap loader is the
first piece of code that runs when a machine starts, and is responsible for
loading the rest of the operating system.)

The `%post` section runs code within the context of the new container image.

The `%runscript` section defines what runs with `singularity run`.

See
[Sections](https://docs.sylabs.io/guides/latest/user-guide/definition_files.html#sections)
for more information on other sections.

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

(The
[fakeroot](https://docs.sylabs.io/guides/latest/user-guide/fakeroot.html#build)
option (not used below) lets an unprivileged user build an image from a
definition file with few restrictions.)

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

## Definition file

`sections.def` shows some sections inside a Singularity Definition File.

```
Bootstrap: docker
From: debian:bookworm-slim

%labels
    AUTHOR Dave Tang

%help
    This container is a demo

%setup
    >&2 echo "This runs outside the container on the host, before %post."

%files
    LICENSE /opt/

%environment
    export PATH=$PATH:$HOME/bin
    export MYENV=test

%runscript
    >&2 echo "Hi $@"

%post
    apt update \
    && apt upgrade -y \
    && apt clean
```

Build image.

```console
singularity build --fakeroot --force sections.sif sections.def
```

`%runscript`.

```console
singularity run sections.sif doctor Jones
```
```
Hi doctor Jones
```

`%help`.

```console
singularity run-help sections.sif
```
```
    This container is a demo
```

`%files`.

```console
singularity exec sections.sif ls /opt
```
```
LICENSE
```

`%environment`.

```console
singularity shell sections.sif
Singularity> echo $MYENV
test
```

`%labels`.

```console
singularity inspect sections.sif
```
```
AUTHOR: Dave Tang
org.label-schema.build-arch: amd64
org.label-schema.build-date: Friday_30_May_2025_16:5:48_JST
org.label-schema.schema-version: 1.0
org.label-schema.usage: /.singularity.d/runscript.help
org.label-schema.usage.singularity.deffile.bootstrap: docker
org.label-schema.usage.singularity.deffile.from: debian:bookworm-slim
org.label-schema.usage.singularity.runscript.help: /.singularity.d/runscript.help
org.label-schema.usage.singularity.version: 4.1.3
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

## Running services

From [Instances - Running Services](https://docs.sylabs.io/guides/4.2/user-guide/running_services.html):

> SingularityCE is most commonly used to run containers interactively, or in a batch job, where the container runs in the foreground, performs some work, and then exits. There are different ways in which you can run SingularityCE containers in the foreground. If you use run, exec and shell to interact with processes in the container, then you are running SingularityCE containers in the foreground.
>
> SingularityCE, also allows you to run containers in a “detached” or “daemon” mode where the container runs a service. A “service” is essentially a process running in the background that multiple different clients can use. For example, a web server or a database.
>
> A SingularityCE container running a service in the background is called an instance, to distinguish it from the default mode which runs containers in the foreground.

## Isolation

One of the main goals of using containerisation software is for reproducibility. To ensure that the analysis environment is not polluted with a user's workspace here are some useful arguments.

* Use `--containall` to prevent the container from reading or writing from the host.

```console
# build image for demo
singularity build --fakeroot --force minimal.sif bookworm_slim.def

# lists out files in my home directory
singularity exec minimal.sif ls $HOME

singularity exec --containall minimal.sif ls $HOME
# no output
```

* Use `--cleanenv` to prevent the container from inheriting most of the environment variables from the host.

```console
# lists out my environment variables
singularity exec minimal.sif ls $HOME

singularity exec --cleanenv minimal.sif env
# no host environment variables
```

## Limiting Container Resources

There are three ways to apply [limits to a container](https://docs.sylabs.io/guides/main/user-guide/cgroups.html) that is run with SingularityCE:

* Using the command line flags introduced in v3.10.
    * Using `--cpus` sets the [number of CPUs](https://docs.sylabs.io/guides/main/user-guide/cgroups.html#cpu-limits), or fractional CPUs, that the container can use.
    * Using `--memory` sets the [maximum amount of RAM](https://docs.sylabs.io/guides/main/user-guide/cgroups.html#memory-limits) that a container can use, in bytes. You can use suffixes such as M or G to specify megabytes or gigabytes.
* Using the --apply-cgroups flag to apply a cgroups.toml file that defines the resource limits.
* Using external tools such as systemd-run tool to apply limits, and then call singularity.

Example of using command line flags.

```console
singularity exec --memory 4G --cpus 2 image.sif command
```

[Restrict network access of a container](https://github.com/apptainer/singularity/issues/1634).

```console
singularity exec --net --network none image.sif curl --output test.bed https://davetang.org/file/test.bed
```
```
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0curl: (6) Could not resolve host: davetang.org
```
```console
singularity exec --net --network none ollama.sif curl -I 23.196.3.208
```
```
curl: (7) Failed to connect to 23.196.3.208 port 80 after 0 ms: Couldn't connect to server
```

## Troubleshooting

If you get a "No space left on device error", check the size of `/tmp` directory. Singularity [will use](https://docs.sylabs.io/guides/2.5/user-guide/troubleshooting.html#no-space-left-on-device) the `TMPDIR` environment variable, so set it to a location with more space.

```console
export TMPDIR=$HOME/tmp
```

You can also set the following environment variables.

```
export SINGULARITY_TMPDIR=/dir/with/more/space
export SINGULARITY_CACHEDIR=/dir/with/more/space
```

## Tips

Create an environment variable using `--env`.

```console
singularity exec --env BLAH=1984 minimal.sif bash -c 'env | grep BLAH'
```
```
BLAH=1984
```
