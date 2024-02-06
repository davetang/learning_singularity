# Running RStudio Server using Singularity

This uses the [verse](https://rocker-project.org/images/versioned/rstudio.html)
image prepared by the Rocker Project. The RStudio Server setup on that image is
for the `rstudio` user. The `run.sh` script binds your home directory to
`/home/rstudio` to get RStudio Server working. One downside of this is that
installing packages using Singularity will **potentially overwrite your local
packages** if you also use `${HOME}/R/x86_64-pc-linux-gnu-library/4.3`. One
easy way to overcome this is simply to change `.libPath`.

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

Packages will be installed in `${HOME}/R/x86_64-pc-linux-gnu-library/4.3` by
default.

```r
.libPaths()
```
```
[1] "/home/rstudio/R/x86_64-pc-linux-gnu-library/4.3" "/usr/local/lib/R/site-library"
[3] "/usr/local/lib/R/library"
```

# Other implementations

* Files in this repository based on <https://github.com/oist/BioinfoUgrp/tree/master/RStudio>.
* Also check out <https://gitlab.oit.duke.edu/chsi-informatics/containers/singularity-rstudio-base>
