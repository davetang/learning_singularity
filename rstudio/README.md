# Running RStudio Server using Singularity

This uses the [verse](https://rocker-project.org/images/versioned/rstudio.html)
image prepared by the Rocker Project. The RStudio Server setup on that image is
for the `rstudio` user. The `run.sh` script binds `${HOME}/rstudio` to
`/home/rstudio` to get RStudio Server working. It also sets packages to be
installed in `${HOME}/rstudio` to avoid potentially overwriting local packages.

Build image.

```console
./build.sh
```

Now run!

```console
./run.sh
```
```
RStudio Username:       dtang
RStudio Password:       password
Port:                   8888
```

Packages will be installed in `${HOME}/rstudio`; it shows `/home/rstudio` below
but this is bound/mounted to `${HOME}/rstudio` on the host.

```r
.libPaths()
```
```
[1] "/home/rstudio" "/usr/local/lib/R/site-library" "/usr/local/lib/R/library"
```

# User package directory

Another way to manage the user's package directory is via `R_LIBS_USER`. To prevent using packages installed in the user's home directory, which gets mounted automatically by Singularity, `/home/rstudio_session` is created and hopefully does not exist.

```
mkdir -p /home/rstudio_session
printf 'R_LIBS_USER="/home/rstudio_session"\n' >> /usr/local/lib/R/etc/Renviron.site
```

If R is running inside the container made with the image definition above, `.libPaths()` will return `/home/rstudio_session`.

```r
.libPaths()
```
```
[1] "/home/rstudio_session"         "/usr/local/lib/R/site-library" "/usr/local/lib/R/library"
```

# Other implementations

* Files in this repository based on <https://github.com/oist/BioinfoUgrp/tree/master/RStudio>.
* Also check out <https://gitlab.oit.duke.edu/chsi-informatics/containers/singularity-rstudio-base>

# Troubleshooting

Singularity mounts `${HOME}` by default and therefore can read and write to `~/.local/share/rstudio/`. To start RStudio in a clean session, delete this directory; this is useful when RStudio becomes stuck when it is trying to be restore a problematic session (like one with too much text output!).
