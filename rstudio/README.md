# Running RStudio Server using Singularity

Build image.

```console
singularity build --fakeroot rstudio_server.sif Singularity.def
```

Now run!

```console
singularity run rstudio_server.sif
```
```
RStudio URL:            http://localhost:58316/
RStudio Username:       dtang
RStudio Password:       2c8545abbfd922c1

You may need to clean your temporary files by yourself:
RStudio temporary files:        /home/dtang/tmp.PEHwopoLik

This image will build its packages in the following directory if it exists:
R_LIBS_USER="~/R/library/4.3.2_for_RStudio_Singularity"

TTY detected. Printing informational message about logging configuration. Logging configuration loaded from '/etc/rstudio/logging.conf'. Logging to '/home/dtang/.local/share/rstudio/log/rserver.log'.
```

Note that:

1. The server creates temporary files that you need to clean up yourself.
2. Packages are installed in per `R_LIBS_USER="~/R/library/4.3.2_for_RStudio_Singularity"`

Based on <https://github.com/oist/BioinfoUgrp/tree/master/RStudio>.
