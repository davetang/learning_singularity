# Running RStudio Server using Singularity

Build image.

```console
./build.sh
```

Now run!

```console
singularity run rstudio-server-2023.12.1-402-amd64-R-4.3.2.sif
```
```
RStudio URL:            http://localhost:62966/
RStudio Username:       dtang
RStudio Password:       d96c3152b71fe32b

You may need to clean your temporary files by yourself:
RStudio temporary files:        /home/dtang/tmp.C5rfF0uRw3

This image will build its packages in the following directory if it exists:
R_LIBS_USER="~/R/library/R_4.3.2_for_RStudio_Singularity"
```

Note that:

1. The server creates temporary files that you need to clean up yourself.
2. Packages are installed in `~/R/library/R_4.3.2_for_RStudio_Singularity`

# Useful links

* Files in this repository based on <https://github.com/oist/BioinfoUgrp/tree/master/RStudio>.
* Also check out <https://gitlab.oit.duke.edu/chsi-informatics/containers/singularity-rstudio-base>
