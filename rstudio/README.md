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

# Other implementations

* Files in this repository based on <https://github.com/oist/BioinfoUgrp/tree/master/RStudio>.
* Also check out <https://gitlab.oit.duke.edu/chsi-informatics/containers/singularity-rstudio-base>
