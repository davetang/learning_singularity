## Table of Contents

- [Singularity and Apptainer](#singularity-and-apptainer)
- [1. Overview](#1-overview)
  - [What is Singularity?](#what-is-singularity)
  - [Why containers in HPC](#why-containers-in-hpc)
  - [SingularityCE vs Apptainer](#singularityce-vs-apptainer)
  - [Key concepts](#key-concepts)
- [2. Installation](#2-installation)
  - [SingularityCE](#singularityce)
    - [CentOS/RHEL 7](#centosrhel-7)
    - [Debian](#debian)
    - [Build from source](#build-from-source)
    - [Verify the installation](#verify-the-installation)
  - [Apptainer](#apptainer)
  - [Inside Docker](#inside-docker)
  - [macOS (Apple Silicon)](#macos-apple-silicon)
- [3. Quick start](#3-quick-start)
- [4. Obtaining images](#4-obtaining-images)
- [5. Building images](#5-building-images)
  - [Two approaches](#two-approaches)
  - [Definition files](#definition-files)
    - [The %startscript section](#the-startscript-section)
  - [Build privileges](#build-privileges)
  - [A worked example](#a-worked-example)
  - [The %test section](#the-test-section)
  - [Sandbox mode](#sandbox-mode)
  - [Multi-stage builds](#multi-stage-builds)
  - [Overlay filesystems](#overlay-filesystems)
- [6. Running containers](#6-running-containers)
  - [Environment variables and precedence](#environment-variables-and-precedence)
  - [Isolation](#isolation)
  - [Resource limits](#resource-limits)
  - [GPU support](#gpu-support)
  - [Running services (instances)](#running-services-instances)
- [7. Managing images](#7-managing-images)
  - [Inspecting images](#inspecting-images)
  - [Signing and verifying images](#signing-and-verifying-images)
  - [Cache management](#cache-management)
- [8. Use cases](#8-use-cases)
  - [BioContainers](#biocontainers)
  - [Example projects in this repo](#example-projects-in-this-repo)
- [9. Troubleshooting](#9-troubleshooting)
- [10. Tips and further reading](#10-tips-and-further-reading)

# Singularity and Apptainer

Learning about Singularity (the container platform and not the technological singularity).

# 1. Overview

This section gives the background needed to make sense of the rest of the notes: what Singularity is, why it exists alongside Docker in HPC, how it relates to Apptainer, and the handful of concepts that recur throughout.

## What is Singularity?

Singularity is a **container platform**: a tool for packaging an application together with all of its dependencies (libraries, system tools, and configuration) into a single, portable unit that runs the same way wherever it is launched. This is what makes an analysis reproducible: the software environment travels with the container instead of having to be reinstalled and reconfigured on every machine.

A container is not a virtual machine. A virtual machine emulates a complete computer, running its own operating system kernel on top of the host. A container instead shares the host's kernel and isolates only the application and its filesystem, so it is far more lightweight because there is no second operating system to boot.

What distinguishes Singularity from other container tools is its image format. A Singularity container is a **single file** in the Singularity Image Format (SIF), and that file is read-only by default. Because the whole container is one immutable file, you can copy it, version it, share it on a cluster filesystem, or archive it alongside your results.

If you have used Docker the idea is the same, and Singularity can even run Docker and OCI images directly. OCI (the Open Container Initiative) is the open standard that defines the container image format Docker and the major registries use, so an "OCI image" is, in practice, just an image you would pull from somewhere like Docker Hub. Singularity is designed differently, though: there is no background daemon, and a container runs as you, the user who launched it, rather than as root (why that matters is covered in [Why containers in HPC](#why-containers-in-hpc)).

"Singularity" here refers to the container platform, which has since split into two actively maintained successors, **SingularityCE** and **Apptainer**. They share a common origin and a near-identical command set, so these notes apply to both; the history is in [SingularityCE vs Apptainer](#singularityce-vs-apptainer). The official Apptainer documentation sums the platform up:

> [Apptainer](https://apptainer.org/docs/user/latest/introduction.html) is a container platform. It allows you to create and run containers that package up pieces of software in a way that is portable and reproducible. You can build a container using Apptainer on your laptop, and then run it on many of the largest HPC clusters in the world, local university or company clusters, a single server, in the cloud, or on a workstation down the hall. Your container is a single file, and you don’t have to worry about how to install all the software you need on each different operating system.

## Why containers in HPC

HPC (High-Performance Computing) refers to large, shared computing clusters: many compute nodes drawing on a common high-capacity filesystem, with users submitting work as jobs through a batch scheduler such as [Slurm](https://slurm.schedmd.com/). Hundreds of people may share the same hardware, so the system has to stay secure and predictable for everyone at once. This setting is what shaped Singularity. (These notes follow the [Nextflow tutorial](https://training.nextflow.io/basic_training/containers/#singularity) on containers.)

The usual container tool, Docker, does not fit this environment. Docker relies on a root-owned background daemon that runs and manages containers, and a user who can reach that daemon can effectively obtain root on the host (for example by mounting and editing system files). That is fine on a machine you own, but on a shared cluster it is a serious security problem, which is why Docker is generally not available on HPC systems.

You might wonder about Docker's rootless mode (available since Docker 20.10), which runs the daemon and containers inside a user namespace as a non-root user, using the same mechanism as Singularity's [fakeroot builds](#build-privileges). On security grounds it does close the main gap, removing the easy path from container to host root. It still does not suit HPC, though, for architectural rather than security reasons: it still keeps a background daemon, now one per user rather than the single shared system daemon of ordinary Docker, whereas a scheduler expects each job to be an ordinary process; its use of cgroups collides with the scheduler's own cgroup-based resource control; and its images live in the daemon's local layered store rather than as a single portable file on the shared filesystem.

Singularity was built to solve exactly this. It has no daemon, and a container runs as the user who launched it, with no privilege escalation. A running container is simply one of your ordinary processes, so an administrator can allow Singularity without handing out root. This is the payoff of the design noted in [What is Singularity?](#what-is-singularity).

Its single-file image format suits a cluster too. A SIF image is one plain file on the shared filesystem, so every compute node can read the same image with no per-node installation and no registry service running on the cluster. The container launches like any other job under the batch scheduler, fitting into existing HPC workflows rather than replacing them.

Finally, the same properties make work reproducible across the cluster and over time. Because the software environment is baked into the image, a job runs identically on any node and on any day, and the very same file moves unchanged from your laptop to the cluster.

## SingularityCE vs Apptainer

Singularity was created in 2015 by Gregory Kurtzer and a team at Lawrence Berkeley National Laboratory, and was rewritten in Go in 2018. In 2021 the project split in two. [Sylabs](https://sylabs.io/singularity/), the company offering commercial support, forked it and kept the Singularity name for their product, releasing it as **SingularityCE** (Community Edition). A few months later, on 30 November 2021, the original open-source project joined the Linux Foundation and was renamed [Apptainer](https://apptainer.org/news/community-announcement-20211130/).

Most of my notes here were written before I knew about the fork and are based on using SingularityCE. The two share a common origin and their commands remain largely interchangeable, so throughout these notes the `singularity` command is used but you can usually substitute `apptainer` directly. The Hello World example works the same either way:

```console
apptainer pull hello-world.sif shub://vsoch/hello-world
apptainer run hello-world.sif
# RaawwWWWWWRRRR!! Avocado!
```

That interchangeability is real: the SIF image format is identical, so an image built by either tool runs on the other, and an Apptainer install provides a `singularity` symlink so existing scripts keep working. The main exceptions to watch for (the [Singularity compatibility guide](https://apptainer.org/docs/user/latest/singularity_compatibility.html) has the full list):

* **Environment variables**: the `SINGULARITY_` and `SINGULARITYENV_` prefixes become `APPTAINER_` and `APPTAINERENV_`. Apptainer still honours the old names for now, but warns that `SINGULARITYENV_` usage is deprecated and may be removed.
* **No default library endpoint**: SingularityCE resolves an unqualified `library://` pull (and remote builds) to `cloud.sylabs.io`, whereas Apptainer ships with no default remote, so those commands need a remote configured first.
* **Separate config and cache**: the configuration directory moves from `~/.singularity` to `~/.apptainer`. Apptainer migrates configuration and keyrings automatically but not the image cache, which has to be rebuilt.
* **Diverging roadmaps**: the projects are close today but add features independently (for example instance checkpointing in Apptainer, an `--oci` runtime mode in SingularityCE), so expect them to drift apart over time.

## Key concepts

A few ideas come up repeatedly. The single-file SIF image format itself is described in [What is Singularity?](#what-is-singularity); the mechanics below are what the how-to sections assume.

* **Build then run**: the core workflow is two steps. First you *build* an image (from a definition file, from a [sandbox](#sandbox-mode), or by [pulling](#4-obtaining-images) an existing one), then you *run* it. Almost everything in these notes is one of those two steps.
* **Definition files and the base image**: an image is described by a definition (`.def`) file, much like a `Dockerfile`. Every build starts from a base image named in the `Bootstrap:` and `From:` header lines (for example `Bootstrap: docker` with `From: debian:bookworm-slim`), and the rest of the file layers your software on top. See [Building images](#5-building-images).
* **run, exec, and shell**: there are three ways to execute a container. `singularity run` executes the image's built-in `%runscript` (its default action), `singularity exec` runs an arbitrary command that you supply, and `singularity shell` opens an interactive shell inside the container. See [Running containers](#6-running-containers).
* **Building needs privileges, running does not**: creating an image writes a new root-owned filesystem, so a build runs with `--fakeroot` (or `sudo`), which uses Linux user namespaces to map you to root for the duration of the build only. Running an existing image with `run`, `exec`, or `shell` happens entirely as your normal user and needs no special privileges. See [Build privileges](#build-privileges).
* **Bind mounts and host integration**: by default Singularity mounts your home directory, the current working directory, and `/tmp` into the container, and files you create are owned by your host user (unlike Docker). Use `--bind` to map additional host paths, or see [Isolation](#isolation) to turn this sharing off.
* **Read-only images**: a built image is immutable at run time, so you cannot write inside it. Changes persist only to bind-mounted host paths, to a writable [overlay](#overlay-filesystems), or to a [sandbox](#sandbox-mode). This is a common early surprise and the reason those features exist.

# 2. Installation

How to get Singularity or Apptainer onto your system. Pick the path that matches your platform: build SingularityCE from source on Linux, install Apptainer from a Debian package, run Singularity inside Docker, or set up a Linux VM on macOS.

## SingularityCE

[SingularityCE](https://github.com/sylabs/singularity) is the Community Edition of Singularity and is licensed under a [BSD 3-Clause](https://github.com/sylabs/singularity/blob/main/LICENSE.md). Installation is the same for different flavours of Linux except when installing dependencies since different distros use different package managers.

### CentOS/RHEL 7

[Installing](https://github.com/sylabs/singularity/blob/main/INSTALL.md) on CentOS/RHEL 7. (I have left out Git, so please include it back if you do not have Git installed.)

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

[Installing](https://github.com/sylabs/singularity/blob/main/INSTALL.md) on Debian.

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

### Build from source

Once the dependencies above are installed, the build steps are the same across distributions.

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

### Verify the installation

```console
which singularity
# /usr/local/bin/singularity

singularity --version
# singularity-ce version 4.1.1
```

## Apptainer

If you prefer Apptainer, the easiest route on Debian is the pre-built package.

> [Apptainer](https://apptainer.org/docs/user/latest/introduction.html) is a container platform. It allows you to create and run containers that package up pieces of software in a way that is portable and reproducible. You can build a container using Apptainer on your laptop, and then run it on many of the largest HPC clusters in the world, local university or company clusters, a single server, in the cloud, or on a workstation down the hall. Your container is a single file, and you don’t have to worry about how to install all the software you need on each different operating system.

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

## Inside Docker

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

## macOS (Apple Silicon)

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

# 3. Quick start

If you just want to see something work, this is the shortest path: pull an image, look at what it does, and run it. The later sections expand on each step.

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

Build an image, where `minimal.sif` is the image name and `bookworm_slim.def` is the Definition File, which is like the Dockerfile for Docker.

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

# 4. Obtaining images

Before building your own image you can pull a ready-made one. Images come from container registries (Docker Hub, Quay.io), the Singularity/Apptainer library (`library://`), or the legacy Singularity Hub (`shub://`).

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

What you see in the output above is a format conversion. A Docker or OCI image is not a single file but a stack of filesystem layers, listed here as the individual blobs being copied. `pull` downloads those layers from the registry, unpacks each one (the `unpack layer` lines), and flattens them together into a single read-only SIF (`Creating SIF file`). The result, named automatically as `<name>_<tag>.sif` (hence `build_23.04.sif` above), is a self-contained image: running it needs no registry, daemon, or Docker, just the one file. The trade-off is that Docker's layer sharing and caching between images is lost, since each SIF is a standalone flattened copy. Singularity does cache the downloaded blobs, however, so pulling the same image again is much faster (see [Cache management](#cache-management)).

For a large catalogue of ready-made bioinformatics images, see [BioContainers](#biocontainers).

# 5. Building images

When a ready-made image is not enough, you build your own. This section covers the two building approaches, the anatomy of a definition file, the privileges a build needs, and the more advanced building features (sandboxes, multi-stage builds, and overlays).

## Two approaches

There are two ways to building Singularity images:

1. Building within a sandbox: build a container interactively within a sandbox environment
2. Building using a Singularity Definition File, which should be preferred since this is more reproducible.

## Definition files

The [Singularity Definition File](https://docs.sylabs.io/guides/latest/user-guide/definition_files.html) is similar to the `Dockerfile` for Docker but uses a different syntax. See [Singularity Definition file versus Dockerfile](https://docs.sylabs.io/guides/3.7/user-guide/singularity_and_docker.html#singularity-definition-file-vs-dockerfile).

Sections (a.k.a. scriptlets or blobs) in the definition file are specified using a `%` prefix followed by the name of the section and are optional.

```singularity
Bootstrap: docker
From: ubuntu:20.04

%post
    apt-get -y update && apt-get install -y python

%runscript
    python -c 'print("Hello World!")'
```

The first two lines specify where to bootstrap our image from. ([In computing](https://stackoverflow.com/a/1254561), a bootstrap loader is the first piece of code that runs when a machine starts, and is responsible for loading the rest of the operating system.)

The `%post` section runs code within the context of the new container image.

The `%runscript` section defines what runs with `singularity run`.

See
[Sections](https://docs.sylabs.io/guides/latest/user-guide/definition_files.html#sections) for more information on other sections.

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

### The %startscript section

The `%startscript` section defines what runs when a container is started as a background [instance](https://docs.sylabs.io/guides/latest/user-guide/running_services.html) (service/daemon), as opposed to `%runscript` which runs in the foreground.

```singularity
%startscript
    echo "Starting my service..."
    exec my_service --daemon
```

This is used with `singularity instance start` (see [Running services (instances)](#running-services-instances)). The [ollama/](ollama/) directory has a working example of running an LLM service using `%startscript`.

## Build privileges

Building writes a new image, which historically required root. There are three ways to satisfy that requirement.

The [fakeroot](https://docs.sylabs.io/guides/latest/user-guide/fakeroot.html) feature lets unprivileged users build containers from definition files without `sudo`. It uses Linux user namespaces to map your user ID to root (UID 0) inside the container, so commands like `apt-get install` work during `%post`.

To unpack that, a user namespace is a Linux kernel feature that gives a process its own private mapping of user and group IDs, separate from the host's. The root you get inside the build is therefore confined to the namespace: you can `apt-get install`, create root-owned files, and `chown` freely, but you gain no real privileges over the host and cannot touch any file you could not already access as yourself. That confinement is what lets an administrator permit unprivileged builds where they could never permit Docker, and it is the same rootless principle that makes Singularity suitable for HPC (see [Why containers in HPC](#why-containers-in-hpc) and the build-versus-run note in [Key concepts](#key-concepts)). For it to work, the kernel must have user namespaces enabled and each user must be allocated a range of subordinate IDs in `/etc/subuid` and `/etc/subgid`, which is what the administrator configures with the `config fakeroot` command below.

```console
singularity build --fakeroot my_image.sif my_definition.def
```

The system administrator must configure fakeroot for each user:

```console
# Admin grants fakeroot permission to a user
sudo singularity config fakeroot --add <username>
```

You can verify fakeroot is available:

```console
singularity buildcfg | grep FAKEROOT
```

Fakeroot is the recommended way to build containers on shared HPC systems where users do not have root access. If fakeroot is not available and you do not have `sudo`, you can use the `--remote` flag to build on the [Sylabs Cloud](https://cloud.sylabs.io/) instead:

```console
singularity build --remote my_image.sif my_definition.def
```

## A worked example

This ties the pieces together: a definition file that installs `cowsay` and `salmon`, building it, then running and shelling into the result.

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

Create the image, which requires `sudo` permissions. If you do not have `sudo` access build the image on a machine where you have admin privileges. (I have used the full path for singularity because `/usr/local/bin` is not in the `PATH` for `root`.)

(The [fakeroot](https://docs.sylabs.io/guides/latest/user-guide/fakeroot.html#build) option (not used below) lets an unprivileged user build an image from a definition file with few restrictions; see [Build privileges](#build-privileges).)

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

Singularity automatically mounts your home and current working directory. In addition, files created inside the container are owned by you (unlike Docker).

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

## The %test section

The `%test` section runs at the end of the build process to validate the container. An important gotcha: **only the exit code of the last command determines success or failure**. Earlier commands can fail silently.

```singularity
%test
    # BAD: if false fails, but grep succeeds, the test passes
    false
    grep -q "something" /some/file

    # GOOD: use set -e to fail on any error
    set -e
    false
    grep -q "something" /some/file
```

Always use `set -e` at the top of your `%test` section to catch failures from any command, not just the last one. See the [demo/](demo/) directory for examples.

For R package installation, `install.packages()` failures only produce warnings, not errors. Wrap in `tryCatch` to convert them:

```r
tryCatch(
    message = function(x) stop("Warning detected"),
    install.packages("nonexistent_package")
)
```

## Sandbox mode

A sandbox is a writable directory structure that represents a container. Unlike SIF files which are read-only, sandboxes allow you to interactively modify the container's filesystem. This is useful for:

* Debugging failed builds by testing commands interactively
* Experimenting with package installations before writing a definition file
* Developing containers incrementally when you're unsure of all dependencies

**Creating a sandbox.** Use `--sandbox` to create a writable directory instead of a SIF file.

```console
singularity build --sandbox my_sandbox/ docker://debian:bookworm-slim
```
```
INFO:    Starting build...
INFO:    Fetching OCI image...
26.9MiB / 26.9MiB [===========================================================================================================================================================================] 100 % 11.6 MiB/s 0s
INFO:    Extracting OCI image...
INFO:    Inserting Singularity configuration...
INFO:    Creating sandbox directory...
INFO:    Build complete: my_sandbox/
```

This creates a directory `my_sandbox/` containing the full container filesystem.

```console
ls my_sandbox/
```
```
bin
boot
dev
environment
etc
home
lib
lib64
media
mnt
opt
proc
root
run
sbin
singularity
srv
sys
tmp
usr
var
```

**Working inside the sandbox.** Use `--writable` to enter the sandbox with write permissions.

```console
singularity shell --fakeroot --writable my_sandbox/
```

Now you can install packages and make changes that persist.

```console
Singularity> apt update && apt install -y cowsay
Singularity> /usr/games/cowsay "Tada!"
```
```
________
< Tada! >
 -------
        \   ^__^
         \  (oo)\_______
            (__)\       )\/\
                ||----w |
                ||     ||
```

The changes persist in the sandbox directory. You can re-enter and continue where you left off.

**Converting a sandbox to a SIF image.** Once you're satisfied with your sandbox, convert it to a production SIF image.

```console
singularity build --fakeroot my_image.sif my_sandbox/
```

**Building a sandbox from a definition file.** You can also build a sandbox from a definition file, which is helpful for debugging failing builds.

```console
singularity build --fakeroot --sandbox my_sandbox/ my_definition.def
```

If the build fails partway through, the sandbox will contain the state at the point of failure, allowing you to enter it and debug.

**Cleaning up.** Sandboxes can take up significant disk space since they contain the full extracted filesystem. Remove them when no longer needed.

```console
rm -rf my_sandbox/
```

**Sandbox vs definition file workflow.**

| Sandbox                      | Definition File             |
|------------------------------|-----------------------------|
| Interactive, trial-and-error | Scripted, reproducible      |
| Good for exploration         | Good for production         |
| Changes are manual           | Changes are documented      |
| Hard to reproduce exactly    | Easy to rebuild identically |

A common workflow is to experiment in a sandbox, then translate your successful commands into a definition file for reproducibility.

## Multi-stage builds

[Multi-stage builds](https://docs.sylabs.io/guides/latest/user-guide/definition_files.html#multi-stage-builds) let you use one container to compile software and then copy only the results into a smaller final image. This reduces image size by excluding build-time dependencies (compilers, headers, etc.) from the production image.

```singularity
Bootstrap: docker
From: ubuntu:22.04
Stage: build

%post
    apt-get update && apt-get install -y build-essential
    gcc -o /usr/local/bin/myapp myapp.c

Bootstrap: docker
From: debian:bookworm-slim
Stage: final

%files from build
    /usr/local/bin/myapp /usr/local/bin/myapp

%runscript
    exec /usr/local/bin/myapp "$@"
```

The `Stage:` header names each stage. The `%files from build` directive copies files from the `build` stage into the `final` stage. Only the last stage becomes the output image.

## Overlay filesystems

SIF images are read-only by default. [Overlay filesystems](https://docs.sylabs.io/guides/latest/user-guide/persistent_overlays.html) let you add a persistent writable layer on top of a read-only SIF image without converting it to a sandbox. This is useful when you need to install additional software or write data inside the container while keeping the base image intact.

Create a writable overlay image (ext3 format):

```console
# Create a 500MB overlay image
singularity overlay create --size 500 my_overlay.img
```

Use the overlay with a SIF image:

```console
singularity shell --overlay my_overlay.img my_image.sif
```

Changes written inside the container are stored in `my_overlay.img` and persist across runs. The base SIF remains unmodified, so you can use different overlays with the same image.

You can also embed a writable overlay directly into a SIF file:

```console
singularity overlay create --size 500 my_image.sif
singularity shell --writable my_image.sif
```

Overlays are helpful when:

* You need to install a few extra packages on top of a shared base image
* You want writable storage without the overhead of a full sandbox
* Multiple users share the same base image but need different customisations

# 6. Running containers

Once you have an image, `run`, `exec`, and `shell` (shown in [Quick start](#3-quick-start)) cover the basics. This section covers the flags that control *how* a container runs: its environment, its isolation from the host, its resource limits, GPU access, and running it as a background service.

## Environment variables and precedence

Singularity sets environment variables from multiple sources, and the [order of precedence](https://docs.sylabs.io/guides/latest/user-guide/environment_and_metadata.html) (highest to lowest) is:

1. `--env` and `--env-file` flags on the command line
2. Host environment variables (inherited by default)
3. `%environment` section in the definition file

This means host environment variables can override values set in `%environment`, which is a common source of unexpected behavior. Use `--cleanenv` to prevent host variables from leaking into the container:

```console
# Without --cleanenv, host PATH is inherited
singularity exec my_image.sif echo $PATH

# With --cleanenv, only container-defined variables are set
singularity exec --cleanenv my_image.sif echo $PATH
```

You can also pass an env file for multiple variables:

```console
cat my_env.txt
# KEY1=value1
# KEY2=value2

singularity exec --env-file my_env.txt my_image.sif env
```

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

## Resource limits

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

## GPU support

Singularity can pass through host GPUs to containers, which is essential for machine learning and GPU-accelerated workloads.

For **NVIDIA GPUs**, use the `--nv` flag:

```console
singularity exec --nv my_image.sif nvidia-smi
```

The `--nv` flag automatically:

* Binds the host NVIDIA driver libraries into the container
* Sets up the `NVIDIA_VISIBLE_DEVICES` and other required environment variables
* Makes GPU devices available inside the container

For **AMD GPUs**, use the `--rocm` flag:

```console
singularity exec --rocm my_image.sif rocm-smi
```

A typical GPU container uses a CUDA base image from Docker Hub:

```singularity
Bootstrap: docker
From: nvidia/cuda:12.2.0-runtime-ubuntu22.04

%post
    apt-get update && apt-get install -y python3 python3-pip
    pip3 install torch
```

```console
singularity build --fakeroot torch.sif torch.def
singularity exec --nv torch.sif python3 -c "import torch; print(torch.cuda.is_available())"
# True
```

No special driver installation is needed inside the container; the host drivers are shared via `--nv`. The container only needs the CUDA runtime/toolkit matching the host driver version.

## Running services (instances)

From [Instances - Running Services](https://docs.sylabs.io/guides/4.2/user-guide/running_services.html):

> SingularityCE is most commonly used to run containers interactively, or in a batch job, where the container runs in the foreground, performs some work, and then exits. There are different ways in which you can run SingularityCE containers in the foreground. If you use run, exec and shell to interact with processes in the container, then you are running SingularityCE containers in the foreground.
>
> SingularityCE, also allows you to run containers in a "detached" or "daemon" mode where the container runs a service. A "service" is essentially a process running in the background that multiple different clients can use. For example, a web server or a database.
>
> A SingularityCE container running a service in the background is called an instance, to distinguish it from the default mode which runs containers in the foreground.

Start a named instance in the background. This executes the `%startscript` defined in the image (see [The %startscript section](#the-startscript-section)).

```console
singularity instance start my_image.sif my_instance
```

List running instances.

```console
singularity instance list
# INSTANCE NAME    PID      IP    IMAGE
# my_instance      12345          /path/to/my_image.sif
```

Execute a command inside a running instance.

```console
singularity exec instance://my_instance some_command
```

Open a shell inside a running instance.

```console
singularity shell instance://my_instance
```

Stop a named instance.

```console
singularity instance stop my_instance
```

Stop all running instances.

```console
singularity instance stop --all
```

Instances are particularly useful for running web servers, databases, or other long-running services. See the [ollama/](ollama/) directory for a complete example of running an LLM service, and [rstudio/](rstudio/) for running RStudio Server.

# 7. Managing images

Beyond building and running, you will want to inspect images, verify they are trustworthy, and keep the local cache under control.

## Inspecting images

Singularity can report what an image contains and how it will behave. These commands are used throughout the notes above:

```console
singularity inspect <image.sif>      # view %labels metadata
singularity inspect -r <image.sif>   # view the %runscript (what `run` will do)
singularity run-help <image.sif>     # view the %help text
```

See [Definition files](#definition-files) for example output of `inspect` and `run-help`.

## Signing and verifying images

Singularity supports [signing and verifying](https://docs.sylabs.io/guides/latest/user-guide/signNverify.html) container images using PGP keys. This ensures that an image has not been tampered with and comes from a trusted source.

Generate a PGP key (one-time setup):

```console
singularity key newpair
```

Sign an image:

```console
singularity sign my_image.sif
```

Verify a signed image:

```console
singularity verify my_image.sif
```

Manage keys:

```console
# List local keys
singularity key list

# Push your public key to the keyserver so others can verify your images
singularity key push <fingerprint>

# Pull someone else's public key
singularity key pull <fingerprint>
```

Signing is especially important when sharing images across a team or downloading images from remote sources. On systems with strict security policies, administrators can require that all images be signed before execution.

## Cache management

Singularity caches downloaded images and OCI blobs to avoid re-downloading. Over time, the cache can grow large.

View the cache:

```console
singularity cache list
```

Show detailed cache contents:

```console
singularity cache list -v
```

Clean the entire cache:

```console
singularity cache clean
```

Clean only specific cache types:

```console
# Clean only OCI/Docker layer blobs
singularity cache clean --type blob

# Clean only SIF images from library
singularity cache clean --type library

# Dry run to see what would be removed
singularity cache clean --dry-run
```

The default cache location is `~/.singularity/cache`. Override it with the `SINGULARITY_CACHEDIR` environment variable:

```console
export SINGULARITY_CACHEDIR=/scratch/$USER/singularity_cache
```

This is useful on HPC systems where home directories have limited quota but scratch space is plentiful.

# 8. Use cases

Concrete examples of putting the above together, including the worked projects kept in this repository.

## BioContainers

Run [BioContainers](https://biocontainers-edu.readthedocs.io/en/latest/what_is_biocontainers.html) containers. To look for a container, go to the [BioContainers organisation page](https://quay.io/organization/biocontainers) and wait for all the containers to load on the page; this takes several minutes because there's a lot of containers, so go get a tasty beverage while the page loads. (There are 11,073 containers as of 2023/06/06.) Once it finishes loading, you can quickly search for a tool of interest.

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

## Example projects in this repo

* [rstudio/](rstudio/): running RStudio Server in Singularity (uses Rocker images).
* [ollama/](ollama/): running an Ollama LLM as a background service via `%startscript` and instances.
* [demo/](demo/): build-testing examples, including `%test` section behaviour.
* [runscript/](runscript/): examples of `%runscript` usage.

# 9. Troubleshooting

If you get a "No space left on device error", check the size of `/tmp` directory. Singularity [will use](https://docs.sylabs.io/guides/2.5/user-guide/troubleshooting.html#no-space-left-on-device) the `TMPDIR` environment variable, so set it to a location with more space.

```console
export TMPDIR=$HOME/tmp
```

You can also set the following environment variables.

```
export SINGULARITY_TMPDIR=/dir/with/more/space
export SINGULARITY_CACHEDIR=/dir/with/more/space
```

# 10. Tips and further reading

Create an environment variable using `--env`.

```console
singularity exec --env BLAH=1984 minimal.sif bash -c 'env | grep BLAH'
```
```
BLAH=1984
```

[Documentation and examples](https://sylabs.io/docs/).
