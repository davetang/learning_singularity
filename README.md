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
